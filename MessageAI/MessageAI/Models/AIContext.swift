//
//  AIContext.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Context information for AI operations to aid error handling and logging
//

import Foundation

/// Context information for an AI operation
struct AIContext: Codable {
    /// Unique identifier for this AI request
    let requestId: String
    
    /// Which AI feature is being used
    let feature: AIFeature
    
    /// User ID (will be hashed for privacy in logs)
    let userId: String
    
    /// Optional message ID if operation involves a specific message
    let messageId: String?
    
    /// Optional thread ID if operation involves a thread
    let threadId: String?
    
    /// Optional search query (will be hashed for privacy in logs)
    let query: String?
    
    /// Timestamp when operation started
    let timestamp: Date
    
    /// Current retry attempt (0 for first attempt)
    let retryCount: Int
    
    init(
        requestId: String = UUID().uuidString,
        feature: AIFeature,
        userId: String,
        messageId: String? = nil,
        threadId: String? = nil,
        query: String? = nil,
        timestamp: Date = Date(),
        retryCount: Int = 0
    ) {
        self.requestId = requestId
        self.feature = feature
        self.userId = userId
        self.messageId = messageId
        self.threadId = threadId
        self.query = query
        self.timestamp = timestamp
        self.retryCount = retryCount
    }
}

