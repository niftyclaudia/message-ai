//
//  SearchResult.swift
//  MessageAI
//
//  Search result data model for semantic search functionality
//

import Foundation
import FirebaseFirestore

/// Represents a single search result from semantic search
/// Contains message reference and relevance score
struct SearchResult: Codable, Identifiable {
    /// Unique identifier for this search result
    var id: String
    
    /// Reference to the message that matched
    let messageId: String
    
    /// Reference to the conversation containing the message
    let conversationId: String
    
    /// Relevance score from vector similarity (0.0-1.0)
    let relevanceScore: Double
    
    /// Preview text of the message (first 100 characters)
    let messagePreview: String
    
    /// When the message was sent
    let timestamp: Date
    
    /// Name of the message sender
    let senderName: String
    
    /// Full message text (optional, loaded on demand)
    var fullMessageText: String?
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case messageId
        case conversationId
        case relevanceScore
        case messagePreview
        case timestamp
        case senderName
        case fullMessageText
    }
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString, messageId: String, conversationId: String, relevanceScore: Double, messagePreview: String, timestamp: Date, senderName: String, fullMessageText: String? = nil) {
        self.id = id
        self.messageId = messageId
        self.conversationId = conversationId
        self.relevanceScore = relevanceScore
        self.messagePreview = messagePreview
        self.timestamp = timestamp
        self.senderName = senderName
        self.fullMessageText = fullMessageText
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        messageId = try container.decode(String.self, forKey: .messageId)
        conversationId = try container.decode(String.self, forKey: .conversationId)
        relevanceScore = try container.decode(Double.self, forKey: .relevanceScore)
        messagePreview = try container.decode(String.self, forKey: .messagePreview)
        senderName = try container.decode(String.self, forKey: .senderName)
        fullMessageText = try container.decodeIfPresent(String.self, forKey: .fullMessageText)
        
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
        try container.encode(messageId, forKey: .messageId)
        try container.encode(conversationId, forKey: .conversationId)
        try container.encode(relevanceScore, forKey: .relevanceScore)
        try container.encode(messagePreview, forKey: .messagePreview)
        try container.encode(senderName, forKey: .senderName)
        try container.encodeIfPresent(fullMessageText, forKey: .fullMessageText)
        
        // Convert date to Firestore Timestamp
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
    }
}

// MARK: - Helper Methods

extension SearchResult {
    /// Check if relevance score meets minimum threshold
    func meetsRelevanceThreshold(_ threshold: Double = 0.7) -> Bool {
        return relevanceScore >= threshold
    }
    
    /// Get formatted relevance percentage
    var relevancePercentage: String {
        return String(format: "%.0f%%", relevanceScore * 100)
    }
    
    /// Check if this is a high-confidence match
    var isHighConfidence: Bool {
        return relevanceScore >= 0.8
    }
}

