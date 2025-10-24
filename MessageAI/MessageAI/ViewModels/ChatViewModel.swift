//
//  ChatViewModel.swift
//  MessageAI
//
//  Chat view model for message display functionality
//

import Foundation
import FirebaseFirestore
import FirebaseDatabase
import FirebaseAuth
import SwiftUI
import Combine

/// ViewModel for managing chat view state and message operations
/// - Note: Handles message loading, real-time updates, and status management
@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [Message] = []
    @Published var chat: Chat?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUserID: String
    @Published var isSending: Bool = false
    @Published var isOffline: Bool = false
    @Published var queuedMessageCount: Int = 0
    @Published var optimisticMessages: [Message] = []
    @Published var isOptimisticUpdate: Bool = false
    @Published var connectionType: ConnectionType = .wifi
    @Published var isRetrying: Bool = false
    @Published var hasRetryableMessages: Bool = false
    @Published var connectionState: ConnectionState = .online
    @Published var groupMemberPresence: [String: PresenceStatus] = [:]
    @Published var groupMembers: [String] = []
    @Published var readReceipts: [String: [String: Date]] = [:] // messageID -> [userID: readAt]
    @Published var typingUsers: [TypingUser] = []
    
    // MARK: - Computed Properties
    
    /// Combined messages including optimistic updates
    var allMessages: [Message] {
        // Combine real and optimistic messages
        var combined = messages
        
        // Only add optimistic messages that aren't already in real messages
        let realMessageIDs = Set(messages.map { $0.id })
        let uniqueOptimistic = optimisticMessages.filter { !realMessageIDs.contains($0.id) }
        combined.append(contentsOf: uniqueOptimistic)
        
        return messageService.sortMessagesByServerTimestamp(combined)
    }
    
    // MARK: - Private Properties
    
    private let messageService: MessageService
    private let readReceiptService: ReadReceiptService
    private var listener: ListenerRegistration?
    private var readReceiptListener: ListenerRegistration?
    private let networkMonitor = NetworkMonitorService()
    let optimisticService = OptimisticUpdateService()
    private let presenceService = PresenceService()
    private let typingService = TypingService()
    private var presenceHandles: [String: DatabaseHandle] = [:]
    private var typingHandle: DatabaseHandle?
    private var typingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // PR-2: Offline persistence system
    private let offlineViewModel = OfflineViewModel()
    
    // PR-009: Priority detection system
    private let priorityDetectionService = PriorityDetectionService()
    
    // Track messages being categorized to prevent duplicate processing
    private var categorizingMessages: Set<String> = []
    
    // MARK: - Initialization
    
    init(currentUserID: String, messageService: MessageService = MessageService(), readReceiptService: ReadReceiptService? = nil) {
        self.currentUserID = currentUserID
        self.messageService = messageService
        self.readReceiptService = readReceiptService ?? ReadReceiptService()
        
        // Set initial network status
        Task { @MainActor in
            monitorNetworkStatus()
            setupNetworkObserver()
        }
    }
    
    deinit {
        // Clean up listeners without main actor isolation
        listener?.remove()
        listener = nil
        readReceiptListener?.remove()
        readReceiptListener = nil
        // NetworkMonitorService cleanup is handled in its own deinit
    }
    
    // MARK: - Public Methods
    
    /// Loads messages for a specific chat
    /// - Parameter chatID: The chat's ID
    func loadMessages(chatID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMessages = try await messageService.fetchMessages(chatID: chatID)
            messages = fetchedMessages
            isLoading = false
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Sets the current chat for the view model
    /// - Parameter chat: The chat to set
    func setChat(_ chat: Chat) {
        self.chat = chat
    }
    
    /// Sets up real-time listener for messages in a chat
    /// - Parameter chatID: The chat's ID
    func observeMessagesRealTime(chatID: String) {
        stopObserving() // Clean up any existing listener
        
        // Enable real-time listener for PR-6
        listener = messageService.observeMessages(chatID: chatID) { [weak self] newMessages in
            Task { @MainActor in
                self?.messages = newMessages
                
                // Track render latency for performance monitoring (only for messages sent by current user)
                for message in newMessages {
                    if message.senderID == self?.currentUserID {
                        PerformanceMonitor.shared.endMessageSend(messageID: message.id, phase: "rendered")
                    }
                }
                
                // Mark received messages as delivered for the sender
                await self?.markReceivedMessagesAsDelivered(newMessages: newMessages)
                
                // PR-009: Categorize new messages for priority detection
                await self?.categorizeNewMessages(newMessages: newMessages)
                
                // Remove optimistic messages that now exist in real messages
                self?.removeConfirmedOptimisticMessages(realMessages: newMessages)
            }
        }
        
        // Enable real-time listener for read receipts (PR-12)
        readReceiptListener = readReceiptService.observeReadReceipts(chatID: chatID) { [weak self] receipts in
            Task { @MainActor in
                self?.readReceipts = receipts
                self?.updateMessageStatusesWithReadReceipts()
            }
        }
    }
    
    /// Stops observing messages and cleans up listener
    func stopObserving() {
        listener?.remove()
        listener = nil
        readReceiptListener?.remove()
        readReceiptListener = nil
        stopObservingTyping()
    }
    
    /// Marks a message as read by the current user
    /// - Parameter messageID: The message's ID
    func markMessageAsRead(messageID: String) {
        guard let chat = chat else { return }
        
        Task {
            do {
                try await readReceiptService.markMessageAsRead(messageID: messageID, userID: currentUserID, chatID: chat.id)
            } catch {
            }
        }
    }
    
    /// Marks all messages in the current chat as read
    func markChatAsRead() {
        guard let chat = chat else { return }
        
        Task {
            do {
                try await readReceiptService.markChatAsRead(chatID: chat.id, userID: currentUserID)
            } catch {
                // Silently fail - read receipts are not critical
            }
        }
    }
    
    /// Automatically marks all messages as read when chat is opened
    func markAllMessagesAsReadOnOpen() {
        guard let chat = chat else { return }
        
        Task {
            do {
                try await readReceiptService.markChatAsRead(chatID: chat.id, userID: currentUserID)
            } catch {
                // Silently fail - read receipts are not critical
            }
        }
    }
    
    /// Marks received messages as delivered for the sender
    /// - Parameter newMessages: Array of newly received messages
    private func markReceivedMessagesAsDelivered(newMessages: [Message]) async {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        
        for message in newMessages {
            // Only process messages not sent by current user and with sent status
            if message.senderID != currentUserID && message.status == .sent {
                do {
                    try await messageService.markMessageAsDelivered(messageID: message.id)
                } catch {
                    // Silently fail - delivery status is not critical
                }
            }
        }
    }
    
    /// Updates message statuses based on read receipts
    private func updateMessageStatusesWithReadReceipts() {
        
        for i in 0..<messages.count {
            let message = messages[i]
            if let readAt = readReceipts[message.id], !readAt.isEmpty {
                // Message has been read by at least one user
                if message.status != .read {
                    messages[i].status = .read
                }
            } else {
                // If message is delivered but not read, keep it as delivered
                if message.status == .sent {
                    messages[i].status = .delivered
                }
            }
        }
        
        // Also update optimistic messages
        for i in 0..<optimisticMessages.count {
            let message = optimisticMessages[i]
            if let readAt = readReceipts[message.id], !readAt.isEmpty {
                if message.status != .read {
                    optimisticMessages[i].status = .read
                }
            } else {
                // If message is delivered but not read, keep it as delivered
                if message.status == .sent {
                    optimisticMessages[i].status = .delivered
                }
            }
        }
    }
    
    /// Gets read status for a message
    /// - Parameter messageID: The message ID
    /// - Returns: Dictionary of user IDs to read timestamps
    func getReadStatus(messageID: String) -> [String: Date] {
        return readReceipts[messageID] ?? [:]
    }
    
    /// Formats a timestamp into a user-friendly string
    /// - Parameter date: The date to format
    /// - Returns: Formatted timestamp string
    func formatTimestamp(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Gets the status of a message for display
    /// - Parameter message: The message to check
    /// - Returns: The message status
    func getMessageStatus(message: Message) -> MessageStatus {
        return message.status
    }
    
    /// Checks if a message was sent by the current user
    /// - Parameter message: The message to check
    /// - Returns: True if sent by current user
    func isMessageFromCurrentUser(message: Message) -> Bool {
        return message.senderID == currentUserID
    }
    
    /// Gets the display name for a message sender
    /// - Parameter message: The message to check
    /// - Returns: Sender display name
    func getSenderDisplayName(message: Message) -> String {
        if isMessageFromCurrentUser(message: message) {
            return "You"
        } else if let senderName = message.senderName {
            return senderName
        } else {
            return "Unknown"
        }
    }
    
    /// Checks if a message should show sender name (for group chats)
    /// - Parameter message: The message to check
    /// - Returns: True if sender name should be displayed
    func shouldShowSenderName(message: Message) -> Bool {
        guard let chat = chat else { return false }
        return chat.isGroupChat && !isMessageFromCurrentUser(message: message)
    }
    
    /// Checks if a message should show timestamp (based on previous message)
    /// - Parameters:
    ///   - message: The current message
    ///   - previousMessage: The previous message in the list
    /// - Returns: True if timestamp should be displayed
    func shouldShowTimestamp(message: Message, previousMessage: Message?) -> Bool {
        guard let previousMessage = previousMessage else { return true }
        
        let timeDifference = message.timestamp.timeIntervalSince(previousMessage.timestamp)
        return timeDifference > 300 // Show timestamp if more than 5 minutes apart
    }
    
    /// Sends a message to the chat with optimized delivery
    /// - Note: Optimized for < 200ms latency (PR-1 requirement)
    /// - Parameter text: The message text to send
    func sendMessage(text: String) {
        guard let chat = chat else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        errorMessage = nil
        
        Task {
            do {
                // PR-3: Get current user's display name for group attribution
                let senderName = chat.isGroupChat ? await getCurrentUserDisplayName() : nil
                
                if isOffline {
                    // PR-2: Use new offline system with 3-message queue
                    let messageID = try await offlineViewModel.queueMessageOffline(
                        chatID: chat.id,
                        text: text,
                        senderID: currentUserID
                    )
                    
                    // Create optimistic message with queued status for UI display
                    await MainActor.run {
                        let queuedMessage = Message(
                            id: messageID,
                            chatID: chat.id,
                            senderID: currentUserID,
                            text: text,
                            timestamp: Date(),
                            serverTimestamp: nil,
                            readBy: [currentUserID],
                            status: .queued,
                            senderName: senderName,
                            isOffline: true,
                            retryCount: 0,
                            isOptimistic: true
                        )
                        optimisticMessages.append(queuedMessage)
                        updateOfflineState()
                    }
                } else {
                    // Send message with optimized delivery and sender name for groups
                    do {
                        _ = try await messageService.sendMessage(chatID: chat.id, text: text, senderName: senderName)
                        
                    } catch {
                        // Send failed - automatically queue it for retry using offline system
                        do {
                            let messageID = try await offlineViewModel.queueMessageOffline(
                                chatID: chat.id,
                                text: text,
                                senderID: currentUserID
                            )
                            
                            // Create optimistic message with queued status for UI display
                            await MainActor.run {
                                let queuedMessage = Message(
                                    id: messageID,
                                    chatID: chat.id,
                                    senderID: currentUserID,
                                    text: text,
                                    timestamp: Date(),
                                    serverTimestamp: nil,
                                    readBy: [currentUserID],
                                    status: .queued,
                                    senderName: senderName,
                                    isOffline: true,
                                    retryCount: 0,
                                    isOptimistic: true
                                )
                                optimisticMessages.append(queuedMessage)
                                updateOfflineState()
                                // Don't set errorMessage - ConnectionStatusBanner handles offline state
                            }
                        } catch {
                            await MainActor.run {
                                errorMessage = "Failed to send message: \(error.localizedDescription)"
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    isSending = false
                    isOptimisticUpdate = false
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    isOptimisticUpdate = false
                    errorMessage = "Failed to send message: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Sends multiple messages in a burst for optimized performance
    /// - Note: Handles 20+ rapid messages with no lag (PR-1 requirement)
    /// - Parameter messages: Array of message texts to send
    func sendBurstMessages(messages: [String]) {
        guard let chat = chat else { return }
        guard !messages.isEmpty else { return }
        
        isSending = true
        errorMessage = nil
        
        Task {
            do {
                if isOffline {
                    // Queue all messages for offline delivery
                    for text in messages {
                        _ = try await offlineViewModel.queueMessageOffline(chatID: chat.id, text: text, senderID: currentUserID)
                    }
                    await MainActor.run {
                        updateQueuedMessageCount()
                    }
                } else {
                    // PR-3: Get current user's display name for group attribution
                    let senderName = chat.isGroupChat ? await getCurrentUserDisplayName() : nil
                    
                    // Send burst messages with optimized delivery and sender name for groups
                    do {
                        _ = try await messageService.sendBurstMessages(chatID: chat.id, messages: messages, senderName: senderName)
                        
                    } catch {
                        // Burst failed - queue individual messages
                        for text in messages {
                            do {
                                _ = try await offlineViewModel.queueMessageOffline(chatID: chat.id, text: text, senderID: currentUserID)
                            } catch {
                                // Individual queue failure - continue with others
                            }
                        }
                        await MainActor.run {
                            updateQueuedMessageCount()
                            // Don't set errorMessage - ConnectionStatusBanner handles offline state
                        }
                    }
                }
                
                await MainActor.run {
                    isSending = false
                    isOptimisticUpdate = false
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    isOptimisticUpdate = false
                    errorMessage = "Failed to send burst messages: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Retries a failed message
    /// - Parameter messageID: The message ID to retry
    func retryMessage(messageID: String) {
        Task {
            do {
                // Find the optimistic message
                if let index = optimisticMessages.firstIndex(where: { $0.id == messageID }) {
                    await MainActor.run {
                        optimisticMessages[index].status = .sending
                        optimisticMessages[index].retryCount += 1
                    }
                    
                    // Try to resend (use same ID)
                    let _ = try await messageService.sendMessageOptimistic(chatID: chat?.id ?? "", text: optimisticMessages[index].text, messageID: messageID)
                    
                    await MainActor.run {
                        optimisticMessages[index].status = .sent
                        optimisticMessages[index].isOptimistic = false
                    }
                } else {
                    // Retry all failed messages through offline service
                    await offlineViewModel.retryFailedMessages()
                    await MainActor.run {
                        updateQueuedMessageCount()
                    }
                }
            } catch {
                // Mark as failed
                if let index = optimisticMessages.firstIndex(where: { $0.id == messageID }) {
                    await MainActor.run {
                        optimisticMessages[index].status = .failed
                    }
                }
                await MainActor.run {
                    errorMessage = "Failed to retry message: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Creates an optimistic message for immediate UI display
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - text: The message text
    /// - Returns: Optimistic message
    private func createOptimisticMessage(chatID: String, text: String, messageID: String) -> Message {
        return Message(
            id: messageID,
            chatID: chatID,
            senderID: currentUserID,
            text: text,
            timestamp: Date(),
            serverTimestamp: nil,
            readBy: [currentUserID],
            status: .sending,
            senderName: nil,
            isOffline: false,
            retryCount: 0,
            isOptimistic: true
        )
    }
    
    /// Syncs queued messages when connection is restored
    func syncQueuedMessages() {
        Task {
            await offlineViewModel.retryFailedMessages()
            await MainActor.run {
                updateQueuedMessageCount()
                updateRetryableMessages()
            }
        }
    }
    
    /// Updates the queued message count
    func updateQueuedMessageCount() {
        queuedMessageCount = offlineViewModel.getOfflineMessages().count
    }
    
    /// PR-2: Updates offline state from the offline view model
    func updateOfflineState() {
        let isOnline = offlineViewModel.isOnline()
        let newConnectionState = offlineViewModel.getConnectionState()
        let newQueuedCount = offlineViewModel.queuedMessageCount
        
        connectionState = newConnectionState
        queuedMessageCount = newQueuedCount
        isOffline = !isOnline
    }
    
    /// Monitors network status and updates offline state
    @MainActor
    func monitorNetworkStatus() {
        // Use OfflineViewModel as the single source of truth for offline state
        isOffline = !offlineViewModel.isOnline()
        connectionType = networkMonitor.connectionType
        
        // PR-2: Update offline state from offline view model
        updateOfflineState()
        
        // Sync queued messages when connection is restored
        if !isOffline && queuedMessageCount > 0 {
            syncQueuedMessages()
        }
        
        updateQueuedMessageCount()
        updateRetryableMessages()
    }
    
    /// Sets up reactive network observer using Combine
    private func setupNetworkObserver() {
        // Observe OfflineViewModel's connectionState changes (single source of truth)
        offlineViewModel.$connectionState
            .sink { [weak self] newState in
                Task { @MainActor in
                    let isOnline = newState.isOnline
                    let wasOffline = self?.isOffline ?? false
                    
                    // Update both connectionState and isOffline from same source
                    self?.connectionState = newState
                    self?.isOffline = !isOnline
                    
                    // Update queued message count
                    self?.updateQueuedMessageCount()
                    
                    // Sync queued messages when coming back online
                    if isOnline && wasOffline && (self?.queuedMessageCount ?? 0) > 0 {
                        self?.syncQueuedMessages()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe connection type changes
        networkMonitor.$connectionType
            .sink { [weak self] connectionType in
                Task { @MainActor in
                    self?.connectionType = connectionType
                }
            }
            .store(in: &cancellables)
    }
    
    /// Updates the retryable messages state
    func updateRetryableMessages() {
        hasRetryableMessages = offlineViewModel.getOfflineMessages().contains { $0.canRetry(maxRetries: 3) }
    }
    
    /// Retries all failed messages
    func retryAllFailedMessages() {
        Task { @MainActor in
            isRetrying = true
        }
        
        Task {
            await offlineViewModel.retryFailedMessages()
            await MainActor.run {
                updateQueuedMessageCount()
                updateRetryableMessages()
                isRetrying = false
            }
        }
    }
    
    /// Clears all queued messages
    func clearAllQueuedMessages() {
        offlineViewModel.clearOfflineMessages()
        Task { @MainActor in
            updateQueuedMessageCount()
            updateRetryableMessages()
        }
    }
    
    /// Gets the current connection type
    func getConnectionType() -> ConnectionType {
        return networkMonitor.connectionType
    }
    
    // MARK: - Group Chat Methods
    
    /// Sets up group member presence monitoring
    /// - Parameter chat: The chat to monitor
    func setupGroupMemberPresence(chat: Chat) {
        guard chat.isGroupChat else { return }
        
        // Store group members
        groupMembers = chat.members
        
        // Clean up existing observers
        presenceService.removeObservers(handles: presenceHandles)
        presenceHandles.removeAll()
        
        // Set up presence observers for all group members
        presenceHandles = presenceService.observeMultipleUsersPresence(userIDs: chat.members) { [weak self] presenceDict in
            Task { @MainActor in
                self?.groupMemberPresence = presenceDict
            }
        }
    }
    
    /// Stops monitoring group member presence
    func stopGroupMemberPresence() {
        presenceService.removeObservers(handles: presenceHandles)
        presenceHandles.removeAll()
        groupMemberPresence.removeAll()
        groupMembers.removeAll()
    }
    
    /// Gets the presence status for a specific group member
    /// - Parameter userID: The user's ID
    /// - Returns: Presence status or offline if not found
    func getGroupMemberPresence(userID: String) -> PresenceStatus {
        return groupMemberPresence[userID] ?? .offline
    }
    
    /// Gets read receipt information for a message in group chat
    /// - Parameter message: The message to check
    /// - Returns: Read receipt information
    func getGroupReadReceiptInfo(message: Message) -> (readCount: Int, totalMembers: Int, readMembers: [String], unreadMembers: [String]) {
        let readMembers = message.readBy.filter { $0 != currentUserID }
        let unreadMembers = groupMembers.filter { !message.readBy.contains($0) && $0 != currentUserID }
        
        return (
            readCount: message.readBy.count,
            totalMembers: groupMembers.count,
            readMembers: readMembers,
            unreadMembers: unreadMembers
        )
    }
    
    /// Gets the display name for a group member
    /// - Parameter userID: The user's ID
    /// - Returns: Display name for the user
    func getGroupMemberDisplayName(userID: String) -> String {
        if userID == currentUserID {
            return "You"
        } else {
            // In a real app, you'd fetch this from a user service
            // For now, return a simplified display name
            return "User \(userID.prefix(4))"
        }
    }
    
    // MARK: - PR-3: Group Chat Member Management
    
    /// Fetches group member profiles with caching
    /// - Note: Uses UserService cache for optimal performance (PR-3 requirement)
    /// - Performance: Target < 400ms for 10 members
    func fetchGroupMembers() async {
        guard let chat = chat, chat.isGroupChat else { return }
        
        do {
            let userService = UserService()
            _ = try await userService.fetchMultipleUserProfiles(userIDs: chat.members)
            
            await MainActor.run {
                groupMembers = chat.members
            }
        } catch {
            // Silently fail - group member fetching is not critical
        }
    }
    
    /// Observes presence for all group members
    /// - Note: Uses PresenceService for real-time updates (PR-3 requirement)
    /// - Performance: Presence updates propagate in < 500ms
    func observeGroupMemberPresence() {
        guard let chat = chat, chat.isGroupChat else { return }
        
        // Clean up existing observers
        cleanupPresenceObservers()
        
        // Set up presence observers for all members
        presenceHandles = presenceService.observeMultipleUsersPresence(userIDs: chat.members) { [weak self] presenceMap in
            Task { @MainActor in
                self?.groupMemberPresence = presenceMap
            }
        }
    }
    
    /// Cleans up presence observers
    func cleanupPresenceObservers() {
        guard !presenceHandles.isEmpty else { return }
        
        presenceService.removeObservers(handles: presenceHandles)
        presenceHandles.removeAll()
    }
    
    /// Gets display name for a group member from cache or fallback
    /// - Parameter userID: The user's ID
    /// - Returns: Display name for the user
    func getCachedMemberDisplayName(userID: String) async -> String {
        if userID == currentUserID {
            return "You"
        }
        
        do {
            let userService = UserService()
            let user = try await userService.fetchUserProfile(userID: userID)
            return user.displayName
        } catch {
            return "User \(userID.prefix(8))"
        }
    }
    
    /// Gets current user's display name for message attribution
    /// - Returns: Current user's display name
    private func getCurrentUserDisplayName() async -> String? {
        do {
            let userService = UserService()
            let user = try await userService.fetchUserProfile(userID: currentUserID)
            return user.displayName
        } catch {
            // Silently fail - sender name is optional for group messages
            return nil
        }
    }
    
    // MARK: - Typing Indicator Methods
    
    /// Sets up typing indicator observer for a chat
    /// - Parameter chatID: The chat ID to observe
    func observeTyping(chatID: String) {
        stopObservingTyping()
        
        typingHandle = typingService.observeTyping(chatID: chatID, currentUserID: currentUserID) { [weak self] users in
            Task { @MainActor in
                self?.typingUsers = users
            }
        }
    }
    
    /// Stops observing typing indicators
    func stopObservingTyping() {
        guard let chat = chat, let handle = typingHandle else { return }
        typingService.removeObserver(chatID: chat.id, handle: handle)
        typingHandle = nil
        typingUsers.removeAll()
    }
    
    /// Called when user starts typing
    /// - Parameter userName: Current user's display name
    func userStartedTyping(userName: String) {
        guard let chat = chat else { return }
        
        // Cancel any existing timer
        typingTimer?.invalidate()
        
        Task {
            do {
                try await typingService.setUserTyping(userID: currentUserID, chatID: chat.id, userName: userName)
            } catch {
                // Silently fail - typing indicator is not critical
            }
        }
        
        // Set up auto-clear timer (3 seconds of inactivity)
        typingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.userStoppedTyping()
            }
        }
    }
    
    /// Called when user stops typing
    func userStoppedTyping() {
        guard let chat = chat else { return }
        
        typingTimer?.invalidate()
        typingTimer = nil
        
        Task {
            do {
                try await typingService.clearUserTyping(userID: currentUserID, chatID: chat.id)
            } catch {
                // Silently fail - typing indicator is not critical
            }
        }
    }
    
    /// Removes optimistic messages that now exist in real messages
    /// - Parameter realMessages: Messages received from Firebase
    private func removeConfirmedOptimisticMessages(realMessages: [Message]) {
        let realMessageIDs = Set(realMessages.map { $0.id })
        let realMessageTexts = Set(realMessages.map { $0.text })
        
        // Remove optimistic messages that match by ID OR by text+sender
        optimisticMessages.removeAll { optimisticMsg in
            // Match by ID (preferred)
            if realMessageIDs.contains(optimisticMsg.id) {
                return true
            }
            // Also match by text if sent by current user (backup for race conditions)
            if optimisticMsg.senderID == currentUserID && realMessageTexts.contains(optimisticMsg.text) {
                // Check if there's a real message with same text sent recently (within 5 seconds)
                if realMessages.contains(where: { 
                    $0.text == optimisticMsg.text && 
                    $0.senderID == currentUserID &&
                    abs($0.timestamp.timeIntervalSince(optimisticMsg.timestamp)) < 5
                }) {
                    return true
                }
            }
            return false
        }
        
        // If no optimistic messages left, clear the flag
        if optimisticMessages.isEmpty {
            isOptimisticUpdate = false
        }
    }
    
    // MARK: - PR-4 Deep Link Support
    
    /// Message ID to highlight (set from deep link)
    @Published var highlightedMessageID: String?
    
    /// Whether to scroll to a specific message
    @Published var scrollToMessageID: String?
    
    /// Scrolls to a specific message and optionally highlights it
    /// - PR #4: Used for deep-link navigation from push notifications (< 400ms target)
    /// - Parameters:
    ///   - messageID: The message ID to scroll to
    ///   - shouldHighlight: Whether to highlight the message with animation
    func scrollToMessage(messageID: String, shouldHighlight: Bool = true) {
        // Set scroll target
        scrollToMessageID = messageID
        
        // Set highlight if requested
        if shouldHighlight {
            highlightedMessageID = messageID
            
            // Auto-clear highlight after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.highlightedMessageID = nil
            }
        }
        
        // Track navigation time
        PerformanceMonitor.shared.endDeepLinkNavigation()
    }
    
    /// Clears the scroll target and highlight
    func clearScrollTarget() {
        scrollToMessageID = nil
        highlightedMessageID = nil
    }
    
    // MARK: - PR-009: Priority Detection Methods
    
    /// Categorizes new messages for priority detection
    /// - Parameter newMessages: Array of new messages to categorize
    private func categorizeNewMessages(newMessages: [Message]) async {
        // Only categorize messages that don't already have categorization and aren't being processed
        let messagesToCategorize = newMessages.filter { message in
            message.categoryPrediction == nil && !categorizingMessages.contains(message.id)
        }
        
        guard !messagesToCategorize.isEmpty else { return }
        
        // Mark messages as being categorized to prevent duplicates
        for message in messagesToCategorize {
            categorizingMessages.insert(message.id)
        }
        
        // Categorize messages in background to avoid blocking UI
        Task.detached { [weak self] in
            guard let self = self else { return }
            
            for message in messagesToCategorize {
                do {
                    // Create message context for categorization
                    let context = MessageContext(
                        senderUserId: message.senderID,
                        messagePreview: message.text,
                        hadDeadline: ["urgent", "asap", "deadline", "today", "tomorrow"].contains(where: { message.text.lowercased().contains($0) }),
                        hadMention: message.text.contains("@"),
                        matchedKeywords: extractKeywords(from: message.text)
                    )
                    
                    // Debug: Log message details
                    print("🧪 Categorizing message: \"\(message.text)\"")
                    print("🔍 Context: hadDeadline=\(context.hadDeadline), hadMention=\(context.hadMention)")
                    print("📝 Keywords: \(context.matchedKeywords)")
                    
                    // Categorize the message
                    let prediction = try await self.priorityDetectionService.categorizeMessage(message, context: context)
                    
                    print("✅ Categorization result: \(prediction.category.displayName) (confidence: \(Int(prediction.confidence * 100))%)")
                    
                    // Update the message with categorization (this will trigger UI update)
                    await MainActor.run {
                        self.updateMessageWithCategorization(messageID: message.id, prediction: prediction)
                        // Remove from categorizing set
                        self.categorizingMessages.remove(message.id)
                    }
                    
                } catch {
                    // Log error but don't block message display
                    print("Failed to categorize message \(message.id): \(error)")
                    
                    // Remove from categorizing set even on error
                    await MainActor.run {
                        self.categorizingMessages.remove(message.id)
                    }
                }
            }
        }
    }
    
    /// Updates a message with categorization prediction
    /// - Parameters:
    ///   - messageID: The message ID to update
    ///   - prediction: The categorization prediction
    private func updateMessageWithCategorization(messageID: String, prediction: CategoryPrediction) {
        // Check if message already has categorization to prevent flickering
        if let existingMessage = messages.first(where: { $0.id == messageID }),
           existingMessage.categoryPrediction != nil {
            print("⚠️ Message \(messageID) already has categorization, skipping update to prevent flickering")
            return
        }
        
        print("🔄 Updating message \(messageID) with categorization: \(prediction.category.displayName)")
        
        // Update in main messages array
        if let index = messages.firstIndex(where: { $0.id == messageID }) {
            let existingMessage = messages[index]
            messages[index] = Message(
                id: existingMessage.id,
                chatID: existingMessage.chatID,
                senderID: existingMessage.senderID,
                text: existingMessage.text,
                timestamp: existingMessage.timestamp,
                serverTimestamp: existingMessage.serverTimestamp,
                readBy: existingMessage.readBy,
                readAt: existingMessage.readAt,
                status: existingMessage.status,
                senderName: existingMessage.senderName,
                isOffline: existingMessage.isOffline,
                retryCount: existingMessage.retryCount,
                isOptimistic: existingMessage.isOptimistic,
                categoryPrediction: prediction,
                embeddingGenerated: true,
                searchableMetadata: existingMessage.searchableMetadata
            )
        }
        
        // Update in optimistic messages array if present
        if let index = optimisticMessages.firstIndex(where: { $0.id == messageID }) {
            let existingMessage = optimisticMessages[index]
            optimisticMessages[index] = Message(
                id: existingMessage.id,
                chatID: existingMessage.chatID,
                senderID: existingMessage.senderID,
                text: existingMessage.text,
                timestamp: existingMessage.timestamp,
                serverTimestamp: existingMessage.serverTimestamp,
                readBy: existingMessage.readBy,
                readAt: existingMessage.readAt,
                status: existingMessage.status,
                senderName: existingMessage.senderName,
                isOffline: existingMessage.isOffline,
                retryCount: existingMessage.retryCount,
                isOptimistic: existingMessage.isOptimistic,
                categoryPrediction: prediction,
                embeddingGenerated: true,
                searchableMetadata: existingMessage.searchableMetadata
            )
        }
    }
    
    // MARK: - Helper Functions
    
    /// Extract keywords from message text for categorization
    private nonisolated func extractKeywords(from text: String) -> [String] {
        let urgencyKeywords = ["urgent", "asap", "deadline", "today", "tomorrow", "immediately", "critical", "emergency"]
        let questionKeywords = ["?", "how", "what", "when", "where", "why", "who"]
        let actionKeywords = ["please", "need", "request", "ask", "help"]
        
        let lowercasedText = text.lowercased()
        var keywords: [String] = []
        
        // Check for urgency keywords
        for keyword in urgencyKeywords {
            if lowercasedText.contains(keyword) {
                keywords.append(keyword)
            }
        }
        
        // Check for question indicators
        for keyword in questionKeywords {
            if lowercasedText.contains(keyword) {
                keywords.append("question")
                break
            }
        }
        
        // Check for action keywords
        for keyword in actionKeywords {
            if lowercasedText.contains(keyword) {
                keywords.append("action")
                break
            }
        }
        
        return keywords
    }
    
}
