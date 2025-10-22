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
    
    /// When this message was sent (client timestamp for optimistic UI)
    var timestamp: Date
    
    /// Server timestamp for consistent ordering across devices
    var serverTimestamp: Date?
    
    /// Array of user IDs who have read this message
    var readBy: [String]
    
    /// Map of user IDs to timestamps when they read the message
    var readAt: [String: Date]
    
    /// Current status of the message (sending, sent, delivered, read, failed)
    var status: MessageStatus
    
    /// Sender's display name (for group chats)
    var senderName: String?
    
    /// Whether this message was created offline (for queued messages)
    var isOffline: Bool = false
    
    /// Number of retry attempts for failed messages
    var retryCount: Int = 0
    
    /// Whether this is an optimistic update (not yet confirmed by server)
    var isOptimistic: Bool = false
    
    /// Firestore collection name
    static let collectionName = "messages"
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case chatID
        case senderID
        case text
        case timestamp
        case serverTimestamp
        case readBy
        case readAt
        case status
        case senderName
        case isOffline
        case retryCount
        case isOptimistic
    }
    
    // MARK: - Initialization
    
    init(id: String, chatID: String, senderID: String, text: String, timestamp: Date, serverTimestamp: Date? = nil, readBy: [String] = [], readAt: [String: Date] = [:], status: MessageStatus = .sending, senderName: String? = nil, isOffline: Bool = false, retryCount: Int = 0, isOptimistic: Bool = false) {
        self.id = id
        self.chatID = chatID
        self.senderID = senderID
        self.text = text
        self.timestamp = timestamp
        self.serverTimestamp = serverTimestamp
        self.readBy = readBy
        self.readAt = readAt
        self.status = status
        self.senderName = senderName
        self.isOffline = isOffline
        self.retryCount = retryCount
        self.isOptimistic = isOptimistic
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
        isOptimistic = try container.decodeIfPresent(Bool.self, forKey: .isOptimistic) ?? false
        
        // Handle readAt dictionary with Timestamp conversion
        if let readAtTimestamps = try? container.decodeIfPresent([String: Timestamp].self, forKey: .readAt) {
            self.readAt = readAtTimestamps.mapValues { $0.dateValue() }
        } else {
            self.readAt = try container.decodeIfPresent([String: Date].self, forKey: .readAt) ?? [:]
        }
        
        // Handle Firestore Timestamp conversion for client timestamp
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
        
        // Handle server timestamp (optional)
        if let serverTimestamp = try? container.decode(Timestamp.self, forKey: .serverTimestamp) {
            self.serverTimestamp = serverTimestamp.dateValue()
        } else if let serverTimestamp = try? container.decodeIfPresent(Date.self, forKey: .serverTimestamp) {
            self.serverTimestamp = serverTimestamp
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
        
        // Convert readAt dates to Firestore Timestamps
        let readAtTimestamps = readAt.mapValues { Timestamp(date: $0) }
        try container.encode(readAtTimestamps, forKey: .readAt)
        
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(senderName, forKey: .senderName)
        try container.encode(isOffline, forKey: .isOffline)
        try container.encode(retryCount, forKey: .retryCount)
        try container.encode(isOptimistic, forKey: .isOptimistic)
        
        // Convert date to Firestore Timestamp
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        
        // Handle server timestamp if present
        if let serverTimestamp = serverTimestamp {
            try container.encode(Timestamp(date: serverTimestamp), forKey: .serverTimestamp)
        }
    }
}
