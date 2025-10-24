//
//  AIQuery.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation
import FirebaseFirestore

/// AI query and response pair for session context (response truncated to 300 chars)
struct AIQuery: Codable {
    let queryId: String
    let queryText: String
    let responseText: String  // Truncated to 300 chars
    let featureSource: AIFeature
    let timestamp: Date
    
    init(
        queryId: String = UUID().uuidString,
        queryText: String,
        responseText: String,
        featureSource: AIFeature,
        timestamp: Date = Date()
    ) {
        self.queryId = queryId
        self.queryText = queryText
        // Truncate response to 300 characters
        self.responseText = String(responseText.prefix(300))
        self.featureSource = featureSource
        self.timestamp = timestamp
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case queryId, queryText, responseText, featureSource, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        queryId = try container.decode(String.self, forKey: .queryId)
        queryText = try container.decode(String.self, forKey: .queryText)
        responseText = try container.decode(String.self, forKey: .responseText)
        featureSource = try container.decode(AIFeature.self, forKey: .featureSource)
        
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(queryId, forKey: .queryId)
        try container.encode(queryText, forKey: .queryText)
        try container.encode(responseText, forKey: .responseText)
        try container.encode(featureSource, forKey: .featureSource)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
    }
}

