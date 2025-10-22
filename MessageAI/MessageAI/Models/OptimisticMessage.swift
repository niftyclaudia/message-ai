//
//  OptimisticMessage.swift
//  MessageAI
//
//  Optimistic message model for local tracking
//

import Foundation

/// Optimistic message model for tracking messages before server confirmation
/// - Note: Used for optimistic UI updates and local storage
struct OptimisticMessage: Codable, Identifiable {
    /// Unique message identifier
    let id: String
    
    /// ID of the chat this message belongs to
    let chatID: String
    
    /// The message text content
    let text: String
    
    /// When this message was created (client timestamp)
    let timestamp: Date
    
    /// User ID of who sent this message
    let senderID: String
    
    /// Current status of the optimistic message
    var status: MessageStatus = .sending
    
    /// Number of retry attempts for failed messages
    var retryCount: Int = 0
    
    /// Last attempt timestamp
    var lastAttempt: Date?
    
    // MARK: - Initialization
    
    init(id: String, chatID: String, text: String, timestamp: Date, senderID: String, status: MessageStatus = .sending, retryCount: Int = 0, lastAttempt: Date? = nil) {
        self.id = id
        self.chatID = chatID
        self.text = text
        self.timestamp = timestamp
        self.senderID = senderID
        self.status = status
        self.retryCount = retryCount
        self.lastAttempt = lastAttempt
    }
    
    // MARK: - Conversion Methods
    
    /// Converts optimistic message to full Message model
    /// - Returns: Message object with optimistic flag set
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
            isOffline: false,
            retryCount: retryCount,
            isOptimistic: true
        )
    }
}
