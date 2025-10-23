//
//  OfflineMessage.swift
//  MessageAI
//
//  Offline message model for 3-message queue system
//

import Foundation

/// Offline message model for the 3-message queue system
/// - Note: Used for storing messages locally when offline with strict size limits
struct OfflineMessage: Codable, Identifiable {
    /// Unique message identifier
    let id: String
    
    /// ID of the chat this message belongs to
    let chatID: String
    
    /// The message text content
    let text: String
    
    /// User ID of who sent this message
    let senderID: String
    
    /// When this message was created
    let timestamp: Date
    
    /// Current status of the offline message
    var status: MessageStatus
    
    /// Number of retry attempts for failed messages
    var retryCount: Int = 0
    
    /// Last attempt timestamp
    var lastAttempt: Date?
    
    /// Whether this message was created during offline state
    let isOffline: Bool = true
    
    // MARK: - Initialization
    
    init(id: String, chatID: String, text: String, senderID: String, timestamp: Date, status: MessageStatus = .queued, retryCount: Int = 0, lastAttempt: Date? = nil) {
        self.id = id
        self.chatID = chatID
        self.text = text
        self.senderID = senderID
        self.timestamp = timestamp
        self.status = status
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
    }
    
    // MARK: - Helper Methods
    
    /// Creates an OfflineMessage from a Message
    /// - Parameter message: The message to convert
    /// - Returns: OfflineMessage instance
    static func from(message: Message) -> OfflineMessage {
        return OfflineMessage(
            id: message.id,
            chatID: message.chatID,
            text: message.text,
            senderID: message.senderID,
            timestamp: message.timestamp,
            status: .queued,
            retryCount: message.retryCount,
            lastAttempt: Date()
        )
    }
    
    /// Converts OfflineMessage to Message for Firebase sync
    /// - Returns: Message instance ready for Firebase
    func toMessage() -> Message {
        return Message(
            id: id,
            chatID: chatID,
            senderID: senderID,
            text: text,
            timestamp: timestamp,
            serverTimestamp: nil,
            readBy: [senderID],
            status: status,
            senderName: nil,
            isOffline: true,
            retryCount: retryCount,
            isOptimistic: false
        )
    }
    
    /// Updates the retry count and last attempt timestamp
    mutating func incrementRetry() {
        retryCount += 1
        lastAttempt = Date()
    }
    
    /// Checks if this message can be retried
    /// - Parameter maxRetries: Maximum number of retries allowed
    /// - Returns: True if message can be retried
    func canRetry(maxRetries: Int = 3) -> Bool {
        return retryCount < maxRetries
    }
}
