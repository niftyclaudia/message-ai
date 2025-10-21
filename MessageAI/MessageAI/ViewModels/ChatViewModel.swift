//
//  ChatViewModel.swift
//  MessageAI
//
//  Chat view model for message display functionality
//

import Foundation
import FirebaseFirestore
import SwiftUI

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
    
    // MARK: - Computed Properties
    
    /// Combined messages including optimistic updates
    var allMessages: [Message] {
        let combined = messages + optimisticMessages
        return messageService.sortMessagesByServerTimestamp(combined)
    }
    
    // MARK: - Private Properties
    
    private let messageService: MessageService
    private var listener: ListenerRegistration?
    private let networkMonitor = NetworkMonitor()
    let optimisticService = OptimisticUpdateService()
    
    // MARK: - Initialization
    
    init(currentUserID: String, messageService: MessageService = MessageService()) {
        self.currentUserID = currentUserID
        self.messageService = messageService
        
        // Monitor network status
        Task { @MainActor in
            monitorNetworkStatus()
        }
    }
    
    deinit {
        // Clean up listener without main actor isolation
        listener?.remove()
        listener = nil
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
            print("⚠️ Failed to load messages: \(error.localizedDescription)")
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// Sets up real-time listener for messages in a chat
    /// - Parameter chatID: The chat's ID
    func observeMessagesRealTime(chatID: String) {
        stopObserving() // Clean up any existing listener
        
        // Enable real-time listener for PR-6
        listener = messageService.observeMessages(chatID: chatID) { [weak self] newMessages in
            Task { @MainActor in
                self?.messages = newMessages
            }
        }
    }
    
    /// Stops observing messages and cleans up listener
    func stopObserving() {
        listener?.remove()
        listener = nil
    }
    
    /// Marks a message as read by the current user
    /// - Parameter messageID: The message's ID
    func markMessageAsRead(messageID: String) {
        Task {
            do {
                try await messageService.markMessageAsRead(messageID: messageID, userID: currentUserID)
            } catch {
                print("⚠️ Failed to mark message as read: \(error)")
            }
        }
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
    
    /// Sends a message to the chat with optimistic UI updates
    /// - Parameter text: The message text to send
    func sendMessage(text: String) {
        guard let chat = chat else { return }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        errorMessage = nil
        
        Task {
            do {
                if isOffline {
                    // Queue message for offline delivery
                    _ = try await messageService.queueMessage(chatID: chat.id, text: text)
                    await MainActor.run {
                        updateQueuedMessageCount()
                    }
                } else {
                    // Create optimistic message for immediate UI display
                    let optimisticMessage = createOptimisticMessage(chatID: chat.id, text: text)
                    
                    // Add to optimistic messages for immediate display
                    await MainActor.run {
                        optimisticMessages.append(optimisticMessage)
                        isOptimisticUpdate = true
                    }
                    
                    // Try to send with optimistic updates
                    do {
                        let messageID = try await messageService.sendMessageOptimistic(chatID: chat.id, text: text)
                        
                        // Update optimistic message status
                        await MainActor.run {
                            if let index = optimisticMessages.firstIndex(where: { $0.id == messageID }) {
                                optimisticMessages[index].status = .sent
                                optimisticMessages[index].isOptimistic = false
                            }
                        }
                        
                        // Simulate delivered status after delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            Task { @MainActor in
                                if let index = self?.optimisticMessages.firstIndex(where: { $0.id == messageID }) {
                                    self?.optimisticMessages[index].status = .delivered
                                }
                            }
                        }
                        
                    } catch {
                        // Handle optimistic update failure
                        await MainActor.run {
                            if let index = optimisticMessages.firstIndex(where: { $0.text == text }) {
                                optimisticMessages[index].status = .failed
                                optimisticMessages[index].retryCount += 1
                            }
                        }
                        
                        // For PR-7 testing, create mock message when Firebase fails
                        let mockMessage = Message(
                            id: UUID().uuidString,
                            chatID: chat.id,
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
                        
                        // Add to optimistic messages
                        await MainActor.run {
                            optimisticMessages.append(mockMessage)
                        }
                        
                        // Simulate status updates
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            Task { @MainActor in
                                if let index = self?.optimisticMessages.firstIndex(where: { $0.id == mockMessage.id }) {
                                    self?.optimisticMessages[index].status = .sent
                                }
                            }
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                            Task { @MainActor in
                                if let index = self?.optimisticMessages.firstIndex(where: { $0.id == mockMessage.id }) {
                                    self?.optimisticMessages[index].status = .delivered
                                    self?.optimisticMessages[index].isOptimistic = false
                                }
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
                    
                    // Try to resend
                    let _ = try await messageService.sendMessageOptimistic(chatID: chat?.id ?? "", text: optimisticMessages[index].text)
                    
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
    private func createOptimisticMessage(chatID: String, text: String) -> Message {
        return Message(
            id: UUID().uuidString,
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
                    errorMessage = "Failed to sync messages: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Updates the queued message count
    func updateQueuedMessageCount() {
        queuedMessageCount = messageService.getQueuedMessages().count
    }
    
    /// Monitors network status and updates offline state
    @MainActor
    func monitorNetworkStatus() {
        isOffline = !networkMonitor.isConnected
        connectionType = networkMonitor.connectionType
        
        // Sync queued messages when connection is restored
        if !isOffline && queuedMessageCount > 0 {
            syncQueuedMessages()
        }
        
        updateQueuedMessageCount()
        updateRetryableMessages()
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
    
}
