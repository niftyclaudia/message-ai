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
    private let networkMonitor = NetworkMonitor()
    let optimisticService = OptimisticUpdateService()
    private let presenceService = PresenceService()
    private let typingService = TypingService()
    private var presenceHandles: [String: DatabaseHandle] = [:]
    private var typingHandle: DatabaseHandle?
    private var typingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // PR-2: Offline persistence system
    private let offlineViewModel = OfflineViewModel()
    
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
        // NetworkMonitor cleanup is handled in its own deinit
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
                print("Failed to mark chat as read: \(error)")
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
                print("Failed to mark all messages as read: \(error)")
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
                    print("Failed to mark message as delivered: \(error)")
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
                if isOffline {
                    // PR-2: Use new offline system with 3-message queue
                    _ = try await offlineViewModel.queueMessageOffline(
                        chatID: chat.id,
                        text: text,
                        senderID: currentUserID
                    )
                    await MainActor.run {
                        updateOfflineState()
                    }
                } else {
                    // Send message with optimized delivery
                    do {
                        _ = try await messageService.sendMessage(chatID: chat.id, text: text)
                        
                    } catch {
                        // Send failed - automatically queue it for retry using offline system
                        do {
                            _ = try await offlineViewModel.queueMessageOffline(
                                chatID: chat.id,
                                text: text,
                                senderID: currentUserID
                            )
                            await MainActor.run {
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
                        _ = try await messageService.queueMessage(chatID: chat.id, text: text)
                    }
                    await MainActor.run {
                        updateQueuedMessageCount()
                    }
                } else {
                    // Send burst messages with optimized delivery
                    do {
                        _ = try await messageService.sendBurstMessages(chatID: chat.id, messages: messages)
                        
                    } catch {
                        // Burst failed - queue individual messages
                        for text in messages {
                            do {
                                _ = try await messageService.queueMessage(chatID: chat.id, text: text)
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
                    // Fallback to regular retry
                    try await messageService.retryFailedMessage(messageID: messageID)
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
            do {
                try await messageService.syncQueuedMessages()
                await MainActor.run {
                    updateQueuedMessageCount()
                }
            } catch {
                await MainActor.run {
                    updateQueuedMessageCount() // Update even on failure
                    errorMessage = "Failed to sync messages: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Updates the queued message count
    func updateQueuedMessageCount() {
        queuedMessageCount = messageService.getQueuedMessages().count
    }
    
    /// PR-2: Updates offline state from the offline view model
    func updateOfflineState() {
        connectionState = offlineViewModel.getConnectionState()
        queuedMessageCount = offlineViewModel.queuedMessageCount
        isOffline = !offlineViewModel.isOnline()
    }
    
    /// Monitors network status and updates offline state
    @MainActor
    func monitorNetworkStatus() {
        isOffline = !networkMonitor.isConnected
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
        // Observe network connection changes
        networkMonitor.$isConnected
            .sink { [weak self] isConnected in
                Task { @MainActor in
                    self?.isOffline = !isConnected
                    
                    // When coming back online, update count first, then sync
                    self?.updateQueuedMessageCount()
                    
                    if isConnected && (self?.queuedMessageCount ?? 0) > 0 {
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
        hasRetryableMessages = messageService.hasRetryableMessages()
    }
    
    /// Retries all failed messages
    func retryAllFailedMessages() {
        Task { @MainActor in
            isRetrying = true
        }
        
        Task {
            do {
                try await messageService.retryAllFailedMessages()
                await MainActor.run {
                    updateQueuedMessageCount()
                    updateRetryableMessages()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to retry messages: \(error.localizedDescription)"
                }
            }
            
            await MainActor.run {
                isRetrying = false
            }
        }
    }
    
    /// Clears all queued messages
    func clearAllQueuedMessages() {
        messageService.clearAllQueuedMessages()
        Task { @MainActor in
            updateQueuedMessageCount()
            updateRetryableMessages()
        }
    }
    
    /// Gets the current connection type
    func getConnectionType() -> ConnectionType {
        return messageService.getConnectionType()
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
    
}
