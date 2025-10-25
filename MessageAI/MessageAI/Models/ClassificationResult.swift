//
//  ClassificationResult.swift
//  MessageAI
//
//  Classification result model for AI message prioritization
//

import Foundation

/// Result of message classification containing priority and metadata
struct ClassificationResult: Codable {
    /// Priority classification: "urgent" or "normal"
    let priority: String
    
    /// Confidence score from 0.0 to 1.0
    let confidence: Double
    
    /// Method used for classification: "openai", "keyword", or "fallback"
    let method: String
    
    /// Processing time in milliseconds
    let processingTimeMs: Int
    
    /// Timestamp when classification was completed
    let timestamp: Date
    
    // MARK: - Initialization
    
    init(priority: String, confidence: Double, method: String, processingTimeMs: Int, timestamp: Date = Date()) {
        self.priority = priority
        self.confidence = confidence
        self.method = method
        self.processingTimeMs = processingTimeMs
        self.timestamp = timestamp
    }
    
    // MARK: - Validation
    
    /// Validates that the classification result is properly formatted
    var isValid: Bool {
        return (priority == "urgent" || priority == "normal") &&
               confidence >= 0.0 && confidence <= 1.0 &&
               (method == "openai" || method == "keyword" || method == "fallback") &&
               processingTimeMs >= 0
    }
    
    // MARK: - Convenience Methods
    
    /// Returns true if the message is classified as urgent
    var isUrgent: Bool {
        return priority == "urgent"
    }
    
    /// Returns true if the confidence is high (>= 0.8)
    var isHighConfidence: Bool {
        return confidence >= 0.8
    }
    
    /// Returns true if the confidence is low (< 0.7) and should be reviewed
    var needsReview: Bool {
        return confidence < 0.7
    }
}
