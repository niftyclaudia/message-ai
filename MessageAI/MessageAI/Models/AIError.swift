//
//  AIError.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Main error structure for AI service failures
//

import Foundation

/// Error structure for AI service failures
struct AIError: Error, Codable {
    /// Classification of the error
    let type: AIErrorType
    
    /// Human-readable error message for debugging
    let message: String
    
    /// HTTP status code if applicable
    let statusCode: Int?
    
    /// Whether this error can be automatically retried
    let retryable: Bool
    
    /// Delay before retry in seconds (0 if not retryable)
    let retryDelay: TimeInterval
    
    /// When this error occurred
    let timestamp: Date
    
    init(
        type: AIErrorType,
        message: String,
        statusCode: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.type = type
        self.message = message
        self.statusCode = statusCode
        self.retryable = type.isRetryable
        self.retryDelay = type.initialRetryDelay
        self.timestamp = timestamp
    }
    
    /// Create an AIError from a generic Error
    static func from(_ error: Error, context: String = "") -> AIError {
        // Check if it's already an AIError
        if let aiError = error as? AIError {
            return aiError
        }
        
        // Check for URL errors (network issues)
        if let urlError = error as? URLError {
            return AIError(
                type: .networkFailure,
                message: "\(context): \(urlError.localizedDescription)",
                statusCode: urlError.errorCode
            )
        }
        
        // Default to unknown error type
        return AIError(
            type: .unknown,
            message: "\(context): \(error.localizedDescription)"
        )
    }
}

