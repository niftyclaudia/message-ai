//
//  CategoryPrediction.swift
//  MessageAI
//
//  AI categorization prediction model for priority message detection
//

import Foundation

/// AI categorization prediction result for message priority detection
struct CategoryPrediction: Codable, Identifiable {
    /// Unique identifier for this prediction
    let id: String
    
    /// Predicted message category
    let category: MessageCategory
    
    /// Confidence score (0.0 to 1.0)
    let confidence: Double
    
    /// AI reasoning for the categorization
    let reasoning: String
    
    /// Timestamp when prediction was made
    let timestamp: Date
    
    /// Message ID this prediction applies to
    let messageID: String
    
    /// User ID who received this message
    let userID: String
    
    /// Whether this prediction was made offline
    let isOffline: Bool
    
    /// Version of the AI model used
    let modelVersion: String
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        category: MessageCategory,
        confidence: Double,
        reasoning: String,
        timestamp: Date = Date(),
        messageID: String,
        userID: String,
        isOffline: Bool = false,
        modelVersion: String = "1.0"
    ) {
        self.id = id
        self.category = category
        self.confidence = confidence
        self.reasoning = reasoning
        self.timestamp = timestamp
        self.messageID = messageID
        self.userID = userID
        self.isOffline = isOffline
        self.modelVersion = modelVersion
    }
    
    // MARK: - Validation
    
    /// Validates that confidence is within acceptable range
    var isValid: Bool {
        return confidence >= 0.0 && confidence <= 1.0
    }
    
    /// Returns confidence as percentage
    var confidencePercentage: Int {
        return Int(confidence * 100)
    }
    
    /// Returns formatted confidence string
    var confidenceString: String {
        return "\(confidencePercentage)%"
    }
    
    // MARK: - Helper Methods
    
    /// Creates a neutral prediction for fallback scenarios
    static func neutral(messageID: String, userID: String) -> CategoryPrediction {
        return CategoryPrediction(
            category: .canWait,
            confidence: 0.5,
            reasoning: "Neutral categorization due to AI service unavailability",
            messageID: messageID,
            userID: userID,
            isOffline: true
        )
    }
    
    /// Creates a high-confidence urgent prediction
    static func urgent(messageID: String, userID: String, reasoning: String) -> CategoryPrediction {
        return CategoryPrediction(
            category: .urgent,
            confidence: 0.9,
            reasoning: reasoning,
            messageID: messageID,
            userID: userID
        )
    }
    
    /// Creates a high-confidence AI-handled prediction
    static func aiHandled(messageID: String, userID: String, reasoning: String) -> CategoryPrediction {
        return CategoryPrediction(
            category: .aiHandled,
            confidence: 0.85,
            reasoning: reasoning,
            messageID: messageID,
            userID: userID
        )
    }
}
