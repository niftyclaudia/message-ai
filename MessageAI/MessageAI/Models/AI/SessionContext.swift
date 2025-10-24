//
//  SessionContext.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation
import FirebaseFirestore

/// Session context tracking the last 20 messages and 5 queries for AI prompt context
struct SessionContext: Codable {
    var currentConversationId: String?
    var lastActiveTimestamp: Date
    var recentMessages: [ContextMessage]
    var recentQueries: [AIQuery]
    var contextVersion: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(
        currentConversationId: String? = nil,
        lastActiveTimestamp: Date = Date(),
        recentMessages: [ContextMessage] = [],
        recentQueries: [AIQuery] = [],
        contextVersion: Int = 1,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.currentConversationId = currentConversationId
        self.lastActiveTimestamp = lastActiveTimestamp
        self.recentMessages = recentMessages
        self.recentQueries = recentQueries
        self.contextVersion = contextVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Validation
    
    /// Validates that context doesn't exceed limits (20 messages, 5 queries)
    func isValid() -> Bool {
        return recentMessages.count <= 20 && recentQueries.count <= 5
    }
    
    /// Returns a pruned copy that enforces limits (FIFO)
    func pruned() -> SessionContext {
        var copy = self
        
        // Keep only last 20 messages
        if copy.recentMessages.count > 20 {
            copy.recentMessages = Array(copy.recentMessages.suffix(20))
        }
        
        // Keep only last 5 queries
        if copy.recentQueries.count > 5 {
            copy.recentQueries = Array(copy.recentQueries.suffix(5))
        }
        
        copy.updatedAt = Date()
        return copy
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case currentConversationId
        case lastActiveTimestamp
        case recentMessages
        case recentQueries
        case contextVersion
        case createdAt
        case updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currentConversationId = try container.decodeIfPresent(String.self, forKey: .currentConversationId)
        
        // Decode Firestore Timestamps
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastActiveTimestamp) {
            lastActiveTimestamp = timestamp.dateValue()
        } else {
            lastActiveTimestamp = try container.decode(Date.self, forKey: .lastActiveTimestamp)
        }
        
        recentMessages = try container.decode([ContextMessage].self, forKey: .recentMessages)
        recentQueries = try container.decode([AIQuery].self, forKey: .recentQueries)
        contextVersion = try container.decode(Int.self, forKey: .contextVersion)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(currentConversationId, forKey: .currentConversationId)
        try container.encode(Timestamp(date: lastActiveTimestamp), forKey: .lastActiveTimestamp)
        try container.encode(recentMessages, forKey: .recentMessages)
        try container.encode(recentQueries, forKey: .recentQueries)
        try container.encode(contextVersion, forKey: .contextVersion)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
    }
}

