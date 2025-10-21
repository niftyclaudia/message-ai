//
//  QueuedMessage.swift
//  MessageAI
//
//  Queued message model for offline storage
//

import Foundation

/// Queued message model for offline message storage
/// - Note: Used for storing messages locally when offline
struct QueuedMessage: Codable, Identifiable {
    /// Unique message identifier
    let id: String
    
    /// ID of the chat this message belongs to
    let chatID: String
    
    /// The message text content
    let text: String
    
    /// When this message was created
    let timestamp: Date
    
    /// Number of retry attempts
    var retryCount: Int = 0
    
    /// Last attempt timestamp
    var lastAttempt: Date?
    
    /// User ID of who sent this message
    let senderID: String
    
    // MARK: - Initialization
    
    init(id: String, chatID: String, text: String, timestamp: Date, senderID: String, retryCount: Int = 0, lastAttempt: Date? = nil) {
        self.id = id
        self.chatID = chatID
        self.text = text
        self.timestamp = timestamp
        self.senderID = senderID
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
    }
    
    // MARK: - Helper Methods
    
    /// Creates a QueuedMessage from a Message
    /// - Parameter message: The message to queue
    /// - Returns: QueuedMessage instance
    static func from(message: Message) -> QueuedMessage {
        return QueuedMessage(
            id: message.id,
            chatID: message.chatID,
            text: message.text,
            timestamp: message.timestamp,
            senderID: message.senderID,
            retryCount: message.retryCount,
            lastAttempt: Date()
        )
    }
    
    /// Converts QueuedMessage to Message
    /// - Returns: Message instance
    func toMessage() -> Message {
        return Message(
            id: id,
            chatID: chatID,
            senderID: senderID,
            text: text,
            timestamp: timestamp,
            readBy: [senderID],
            status: .queued,
            senderName: nil,
            isOffline: true,
            retryCount: retryCount
        )
    }
}
