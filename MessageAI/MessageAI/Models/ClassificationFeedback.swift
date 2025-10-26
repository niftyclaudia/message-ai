//
//  ClassificationFeedback.swift
//  MessageAI
//
//  Classification feedback data models for AI classification system
//

import Foundation
import FirebaseFirestore

/// Classification status enum representing the state of message classification
enum ClassificationStatus: Codable, Equatable {
    case pending
    case classified(priority: String, confidence: Float)
    case failed(error: String)
    case feedbackSubmitted
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case type
        case priority
        case confidence
        case error
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "pending":
            self = .pending
        case "classified":
            let priority = try container.decode(String.self, forKey: .priority)
            let confidence = try container.decode(Float.self, forKey: .confidence)
            self = .classified(priority: priority, confidence: confidence)
        case "failed":
            let error = try container.decode(String.self, forKey: .error)
            self = .failed(error: error)
        case "feedbackSubmitted":
            self = .feedbackSubmitted
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid ClassificationStatus type: \(type)")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .pending:
            try container.encode("pending", forKey: .type)
        case .classified(let priority, let confidence):
            try container.encode("classified", forKey: .type)
            try container.encode(priority, forKey: .priority)
            try container.encode(confidence, forKey: .confidence)
        case .failed(let error):
            try container.encode("failed", forKey: .type)
            try container.encode(error, forKey: .error)
        case .feedbackSubmitted:
            try container.encode("feedbackSubmitted", forKey: .type)
        }
    }
}

/// Classification feedback model for user corrections
struct ClassificationFeedback: Codable, Identifiable {
    /// Unique feedback identifier
    let id: String
    
    /// ID of the message this feedback is for
    let messageId: String
    
    /// ID of the user who submitted the feedback
    let userId: String
    
    /// Original priority that was classified
    let originalPriority: String
    
    /// User's suggested priority
    let suggestedPriority: String
    
    /// Optional reason for the feedback
    let feedbackReason: String?
    
    /// When this feedback was submitted
    let submittedAt: Date
    
    /// Firestore collection name
    static let collectionName = "classification_feedback"
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString, messageId: String, userId: String, originalPriority: String, suggestedPriority: String, feedbackReason: String? = nil, submittedAt: Date = Date()) {
        self.id = id
        self.messageId = messageId
        self.userId = userId
        self.originalPriority = originalPriority
        self.suggestedPriority = suggestedPriority
        self.feedbackReason = feedbackReason
        self.submittedAt = submittedAt
    }
    
    // MARK: - Validation
    
    /// Validates that the feedback data is correct
    var isValid: Bool {
        return !messageId.isEmpty &&
               !userId.isEmpty &&
               !originalPriority.isEmpty &&
               !suggestedPriority.isEmpty &&
               MessagePriority.isValid(originalPriority) &&
               MessagePriority.isValid(suggestedPriority)
    }
}

/// Classification retry request model
struct ClassificationRetryRequest: Codable {
    /// ID of the message to retry classification for
    let messageId: String
    
    /// ID of the user requesting the retry
    let userId: String
    
    /// Reason for the retry (optional)
    let reason: String?
    
    /// When this retry was requested
    let requestedAt: Date
    
    init(messageId: String, userId: String, reason: String? = nil, requestedAt: Date = Date()) {
        self.messageId = messageId
        self.userId = userId
        self.reason = reason
        self.requestedAt = requestedAt
    }
}

// MARK: - Error Types

/// Errors that can occur during classification operations
enum ClassificationError: LocalizedError {
    case networkError(Error)
    case invalidMessageId
    case invalidPriority(String)
    case feedbackSubmissionFailed
    case retryFailed
    case userNotAuthenticated
    case messageNotFound
    case rateLimitExceeded
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidMessageId:
            return "Invalid message ID provided"
        case .invalidPriority(let priority):
            return "Invalid priority: \(priority). Must be one of: \(MessagePriority.allValues.joined(separator: ", "))"
        case .feedbackSubmissionFailed:
            return "Failed to submit classification feedback"
        case .retryFailed:
            return "Failed to retry classification"
        case .userNotAuthenticated:
            return "User not authenticated"
        case .messageNotFound:
            return "Message not found"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later"
        }
    }
}
