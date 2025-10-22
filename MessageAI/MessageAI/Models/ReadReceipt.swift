//
//  ReadReceipt.swift
//  MessageAI
//
//  Read receipt data model for tracking when messages are read
//

import Foundation
import FirebaseFirestore

/// Read receipt data model representing when a user read a message
/// - Note: Can be embedded in Message or stored as separate document
struct ReadReceipt: Codable, Identifiable {
    /// Unique identifier for this read receipt
    var id: String
    
    /// ID of the message this read receipt is for
    let messageID: String
    
    /// ID of the user who read the message
    let userID: String
    
    /// ID of the chat containing the message
    let chatID: String
    
    /// When the user read the message
    var readAt: Date
    
    /// Firestore collection name
    static let collectionName = "readReceipts"
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case messageID
        case userID
        case chatID
        case readAt
    }
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString, messageID: String, userID: String, chatID: String, readAt: Date = Date()) {
        self.id = id
        self.messageID = messageID
        self.userID = userID
        self.chatID = chatID
        self.readAt = readAt
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        messageID = try container.decode(String.self, forKey: .messageID)
        userID = try container.decode(String.self, forKey: .userID)
        chatID = try container.decode(String.self, forKey: .chatID)
        
        // Handle Firestore Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .readAt) {
            self.readAt = timestamp.dateValue()
        } else {
            self.readAt = try container.decode(Date.self, forKey: .readAt)
        }
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(messageID, forKey: .messageID)
        try container.encode(userID, forKey: .userID)
        try container.encode(chatID, forKey: .chatID)
        
        // Convert date to Firestore Timestamp
        try container.encode(Timestamp(date: readAt), forKey: .readAt)
    }
}

