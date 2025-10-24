//
//  ConversationHistoryEntry.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation
import FirebaseFirestore

/// Conversation history entry for AI interactions
struct ConversationHistoryEntry: Codable, Identifiable {
    let id: String
    let userQuery: String
    let aiResponse: String
    let featureSource: AIFeature
    let contextUsed: [String]  // IDs of context items used
    let confidence: Double  // 0.0 - 1.0
    var wasHelpful: Bool?
    let timestamp: Date
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        userQuery: String,
        aiResponse: String,
        featureSource: AIFeature,
        contextUsed: [String] = [],
        confidence: Double,
        wasHelpful: Bool? = nil,
        timestamp: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userQuery = userQuery
        self.aiResponse = aiResponse
        self.featureSource = featureSource
        self.contextUsed = contextUsed
        // Clamp confidence between 0.0 and 1.0
        self.confidence = min(max(confidence, 0.0), 1.0)
        self.wasHelpful = wasHelpful
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case id, userQuery, aiResponse, featureSource, contextUsed
        case confidence, wasHelpful, timestamp, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userQuery = try container.decode(String.self, forKey: .userQuery)
        aiResponse = try container.decode(String.self, forKey: .aiResponse)
        featureSource = try container.decode(AIFeature.self, forKey: .featureSource)
        contextUsed = try container.decode([String].self, forKey: .contextUsed)
        confidence = try container.decode(Double.self, forKey: .confidence)
        wasHelpful = try container.decodeIfPresent(Bool.self, forKey: .wasHelpful)
        
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
        
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = firestoreTimestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userQuery, forKey: .userQuery)
        try container.encode(aiResponse, forKey: .aiResponse)
        try container.encode(featureSource, forKey: .featureSource)
        try container.encode(contextUsed, forKey: .contextUsed)
        try container.encode(confidence, forKey: .confidence)
        try container.encodeIfPresent(wasHelpful, forKey: .wasHelpful)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}

