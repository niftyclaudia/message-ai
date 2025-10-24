//
//  AIErrorType.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Defines the error types that can occur in AI operations
//

import Foundation

/// Classification of AI service errors for consistent handling
enum AIErrorType: String, Codable, CaseIterable {
    /// Request took longer than timeout threshold (>10s)
    case timeout
    
    /// API rate limit exceeded (HTTP 429)
    case rateLimit
    
    /// Service temporarily unavailable (HTTP 500/503)
    case serviceUnavailable
    
    /// Network connectivity issue
    case networkFailure
    
    /// Invalid request format or parameters (HTTP 400)
    case invalidRequest
    
    /// API quota or billing limit exceeded (HTTP 402)
    case quotaExceeded
    
    /// Unknown or unclassified error
    case unknown
    
    /// Whether this error type should be automatically retried
    var isRetryable: Bool {
        switch self {
        case .timeout, .serviceUnavailable, .networkFailure:
            return true
        case .rateLimit, .invalidRequest, .quotaExceeded, .unknown:
            return false
        }
    }
    
    /// Initial retry delay for exponential backoff (in seconds)
    var initialRetryDelay: TimeInterval {
        switch self {
        case .timeout, .networkFailure:
            return 1.0
        case .serviceUnavailable:
            return 2.0
        case .rateLimit:
            return 30.0
        default:
            return 0.0
        }
    }
}

