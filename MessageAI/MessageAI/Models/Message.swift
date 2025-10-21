//
//  Message.swift
//  MessageAI
//
//  Message data model for chat functionality
//

import Foundation
import FirebaseFirestore

/// Message data model representing a single message in a chat
/// - Note: Maps to Firestore collection 'messages' with document ID = messageID
struct Message: Codable, Identifiable {
    /// Unique message identifier
    let id: String
    
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
    }
    
    // MARK: - Initialization
    
    init(id: String, chatID: String, senderID: String, text: String, timestamp: Date, readBy: [String] = []) {
        self.id = id
        self.chatID = chatID
        self.senderID = senderID
        self.text = text
        self.timestamp = timestamp
        self.readBy = readBy
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
        
        // Convert date to Firestore Timestamp
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
    }
}
