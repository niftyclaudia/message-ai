//
//  Message.swift
//  MessageAI
//
//  Message data model for chat functionality
//

import Foundation
import FirebaseFirestore

/// Message status enum representing the delivery state of a message
enum MessageStatus: String, Codable, CaseIterable {
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case read = "read"
    case failed = "failed"
    case queued = "queued"       // For offline messages
}

/// Message data model representing a single message in a chat
/// - Note: Maps to Firestore collection 'messages' with document ID = messageID
struct Message: Codable, Identifiable {
    /// Unique message identifier
    var id: String
    
    /// ID of the chat this message belongs to
    let chatID: String
    
    /// User ID of who sent this message
    let senderID: String
    
    /// The message text content
    var text: String
    
    /// When this message was sent
    var timestamp: Date
    
    /// Array of user IDs who have read this message
    var readBy: [String]
    
    /// Current status of the message (sending, sent, delivered, read, failed)
    var status: MessageStatus
    
    /// Sender's display name (for group chats)
    var senderName: String?
    
    /// Whether this message was created offline (for queued messages)
    var isOffline: Bool = false
    
    /// Number of retry attempts for failed messages
    var retryCount: Int = 0
    
    /// Firestore collection name
    static let collectionName = "messages"
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatID
        case senderID
        case text
        case timestamp
        case readBy
        case status
        case senderName
        case isOffline
        case retryCount
    }
    
    // MARK: - Initialization
    
    init(id: String, chatID: String, senderID: String, text: String, timestamp: Date, readBy: [String] = [], status: MessageStatus = .sending, senderName: String? = nil, isOffline: Bool = false, retryCount: Int = 0) {
        self.id = id
        self.chatID = chatID
        self.senderID = senderID
        self.text = text
        self.timestamp = timestamp
        self.readBy = readBy
        self.status = status
        self.senderName = senderName
        self.isOffline = isOffline
        self.retryCount = retryCount
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        chatID = try container.decode(String.self, forKey: .chatID)
        senderID = try container.decode(String.self, forKey: .senderID)
        text = try container.decode(String.self, forKey: .text)
        readBy = try container.decodeIfPresent([String].self, forKey: .readBy) ?? []
        status = try container.decodeIfPresent(MessageStatus.self, forKey: .status) ?? .sending
        senderName = try container.decodeIfPresent(String.self, forKey: .senderName)
        isOffline = try container.decodeIfPresent(Bool.self, forKey: .isOffline) ?? false
        retryCount = try container.decodeIfPresent(Int.self, forKey: .retryCount) ?? 0
        
        // Handle Firestore Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(chatID, forKey: .chatID)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(text, forKey: .text)
        try container.encode(readBy, forKey: .readBy)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(senderName, forKey: .senderName)
        try container.encode(isOffline, forKey: .isOffline)
        try container.encode(retryCount, forKey: .retryCount)
        
        // Convert date to Firestore Timestamp
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
    }
}
