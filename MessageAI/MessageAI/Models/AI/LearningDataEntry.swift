//
//  LearningDataEntry.swift
//  MessageAI
//
//  Learning data entry for tracking AI categorization overrides
//

import Foundation
import FirebaseFirestore

/// Learning data entry tracking when users override AI categorization
/// - Note: Maps to Firestore collection 'users/{userId}/aiState/learningData'
struct LearningDataEntry: Codable, Identifiable {
    /// Unique entry identifier
    var id: String
    
    /// Message ID that was recategorized
    var messageId: String
    
    /// Chat ID where the message was sent
    var chatId: String
    
    /// AI's original category prediction
    var originalCategory: MessageCategory
    
    /// User's corrected category
    var userCategory: MessageCategory
    
    /// When the override occurred
    var timestamp: Date
    
    /// Message context for learning patterns
    var messageContext: MessageContext
    
    /// When this entry was created (for 90-day cleanup)
    var createdAt: Date
    
    /// Firestore collection name
    static let collectionName = "learningData"
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case messageId
        case chatId
        case originalCategory
        case userCategory
        case timestamp
        case messageContext
        case createdAt
    }
    
    // MARK: - Initialization
    
    init(id: String, messageId: String, chatId: String, originalCategory: MessageCategory, userCategory: MessageCategory, timestamp: Date, messageContext: MessageContext, createdAt: Date) {
        self.id = id
        self.messageId = messageId
        self.chatId = chatId
        self.originalCategory = originalCategory
        self.userCategory = userCategory
        self.timestamp = timestamp
        self.messageContext = messageContext
        self.createdAt = createdAt
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        messageId = try container.decode(String.self, forKey: .messageId)
        chatId = try container.decode(String.self, forKey: .chatId)
        originalCategory = try container.decode(MessageCategory.self, forKey: .originalCategory)
        userCategory = try container.decode(MessageCategory.self, forKey: .userCategory)
        messageContext = try container.decode(MessageContext.self, forKey: .messageContext)
        
        // Handle Firestore Timestamp conversion for timestamp
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
        
        // Handle Firestore Timestamp conversion for createdAt
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = firestoreTimestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(originalCategory, forKey: .originalCategory)
        try container.encode(userCategory, forKey: .userCategory)
        try container.encode(messageContext, forKey: .messageContext)
        
        // Convert dates to Firestore Timestamps
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}

