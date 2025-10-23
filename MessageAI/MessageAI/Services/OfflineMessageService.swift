//
//  OfflineMessageService.swift
//  MessageAI
//
//  Offline message service for 3-message queue management
//

import Foundation
import FirebaseAuth

/// Service for managing offline message queue with 3-message limit
/// - Note: Handles offline message storage, retrieval, and queue management
class OfflineMessageService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var queuedMessages: [OfflineMessage] = []
    @Published var isQueueFull: Bool = false
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let maxQueueSize = 3 // PR-2 requirement: 3-message queue
    private let maxRetryCount = 3
    
    // Make queue key user-specific to prevent cross-device conflicts
    private var queueKey: String {
        guard let userID = Auth.auth().currentUser?.uid else {
            return "offline_messages"
        }
        return "offline_messages_\(userID)"
    }
    
    // MARK: - Initialization
    
    init() {
        loadQueuedMessages()
    }
    
    // MARK: - Public Methods
    
    /// Queues a message for offline delivery
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - text: The message text
    ///   - senderID: The sender's user ID
    /// - Returns: Message ID
    /// - Throws: OfflineMessageServiceError for various failure scenarios
    func queueMessageOffline(chatID: String, text: String, senderID: String) async throws -> String {
        // Check if queue is full
        if queuedMessages.count >= maxQueueSize {
            // Remove oldest message to make room
            if let oldestMessage = queuedMessages.min(by: { $0.timestamp < $1.timestamp }) {
                removeOfflineMessage(messageID: oldestMessage.id)
            }
        }
        
        let messageID = UUID().uuidString
        let timestamp = Date()
        
        let offlineMessage = OfflineMessage(
            id: messageID,
            chatID: chatID,
            text: text,
            senderID: senderID,
            timestamp: timestamp,
            status: .queued
        )
        
        // Add to queue
        queuedMessages.append(offlineMessage)
        saveQueuedMessages()
        
        // Update queue full status
        isQueueFull = queuedMessages.count >= maxQueueSize
        
        return messageID
    }
    
    /// Gets all queued offline messages
    /// - Returns: Array of offline messages
    func getOfflineMessages() -> [OfflineMessage] {
        return queuedMessages
    }
    
    /// Clears all offline messages from the queue
    func clearOfflineMessages() {
        queuedMessages.removeAll()
        saveQueuedMessages()
        isQueueFull = false
    }
    
    /// Updates the status of a specific offline message
    /// - Parameters:
    ///   - messageID: The message ID to update
    ///   - status: The new status
    func updateMessageStatus(messageID: String, status: MessageStatus) {
        if let index = queuedMessages.firstIndex(where: { $0.id == messageID }) {
            queuedMessages[index].status = status
            saveQueuedMessages()
        }
    }
    
    /// Removes a specific offline message from the queue
    /// - Parameter messageID: The message ID to remove
    func removeOfflineMessage(messageID: String) {
        queuedMessages.removeAll { $0.id == messageID }
        saveQueuedMessages()
        isQueueFull = queuedMessages.count >= maxQueueSize
    }
    
    /// Gets the count of queued messages
    /// - Returns: Number of queued messages
    func getQueuedMessageCount() -> Int {
        return queuedMessages.count
    }
    
    /// Gets the count of messages with a specific status
    /// - Parameter status: The status to count
    /// - Returns: Number of messages with that status
    func getMessageCount(with status: MessageStatus) -> Int {
        return queuedMessages.filter { $0.status == status }.count
    }
    
    /// Checks if there are any retryable messages
    /// - Returns: True if there are messages that can be retried
    func hasRetryableMessages() -> Bool {
        return queuedMessages.contains { $0.canRetry(maxRetries: maxRetryCount) }
    }
    
    /// Gets all retryable messages
    /// - Returns: Array of messages that can be retried
    func getRetryableMessages() -> [OfflineMessage] {
        return queuedMessages.filter { $0.canRetry(maxRetries: maxRetryCount) }
    }
    
    /// Increments retry count for a specific message
    /// - Parameter messageID: The message ID to update
    func incrementRetryCount(messageID: String) {
        if let index = queuedMessages.firstIndex(where: { $0.id == messageID }) {
            queuedMessages[index].incrementRetry()
            saveQueuedMessages()
        }
    }
    
    /// Removes messages that have exceeded the retry limit
    func removeExpiredMessages() {
        queuedMessages.removeAll { !$0.canRetry(maxRetries: maxRetryCount) }
        saveQueuedMessages()
        isQueueFull = queuedMessages.count >= maxQueueSize
    }
    
    /// Gets messages for a specific chat
    /// - Parameter chatID: The chat ID to filter by
    /// - Returns: Array of offline messages for that chat
    func getMessagesForChat(chatID: String) -> [OfflineMessage] {
        return queuedMessages.filter { $0.chatID == chatID }
    }
    
    /// Checks if the queue has space for new messages
    /// - Returns: True if queue has space
    func hasQueueSpace() -> Bool {
        return queuedMessages.count < maxQueueSize
    }
    
    /// Gets the maximum queue size
    /// - Returns: Maximum number of messages allowed in queue
    func getMaxQueueSize() -> Int {
        return maxQueueSize
    }
    
    // MARK: - Private Methods
    
    /// Loads queued messages from local storage
    private func loadQueuedMessages() {
        guard let data = userDefaults.data(forKey: queueKey),
              let messages = try? JSONDecoder().decode([OfflineMessage].self, from: data) else {
            queuedMessages = []
            return
        }
        queuedMessages = messages
        isQueueFull = queuedMessages.count >= maxQueueSize
    }
    
    /// Saves queued messages to local storage
    private func saveQueuedMessages() {
        do {
            let data = try JSONEncoder().encode(queuedMessages)
            userDefaults.set(data, forKey: queueKey)
        } catch {
            // Silently fail - queued messages will be lost but not critical
        }
    }
}

// MARK: - OfflineMessageServiceError

/// Errors that can occur in OfflineMessageService operations
enum OfflineMessageServiceError: LocalizedError {
    case queueFull
    case messageNotFound
    case invalidMessage
    case storageError(Error)
    case permissionDenied
    
    var errorDescription: String? {
        switch self {
        case .queueFull:
            return "Offline message queue is full (3 message limit)"
        case .messageNotFound:
            return "Offline message not found"
        case .invalidMessage:
            return "Invalid message data"
        case .storageError(let error):
            return "Storage error: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied to access offline messages"
        }
    }
}
