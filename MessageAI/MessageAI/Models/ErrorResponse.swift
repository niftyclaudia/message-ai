//
//  ErrorResponse.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Complete response from error handler including user messaging and actions
//

import Foundation

/// Complete error handling response with user-facing content
struct ErrorResponse {
    /// The underlying AI error
    let error: AIError
    
    /// User-friendly calm message in first-person tone
    let userMessage: String
    
    /// Optional fallback action the user can take
    let fallbackAction: FallbackAction?
    
    /// Whether the operation should be automatically retried
    let shouldRetry: Bool
    
    /// Delay before retry in seconds (0 if no retry)
    let retryDelay: TimeInterval
    
    /// Title for the primary action button
    let primaryActionTitle: String
    
    /// Optional title for secondary action button
    let secondaryActionTitle: String?
    
    init(
        error: AIError,
        userMessage: String,
        fallbackAction: FallbackAction? = nil,
        shouldRetry: Bool,
        retryDelay: TimeInterval,
        primaryActionTitle: String,
        secondaryActionTitle: String? = nil
    ) {
        self.error = error
        self.userMessage = userMessage
        self.fallbackAction = fallbackAction
        self.shouldRetry = shouldRetry
        self.retryDelay = retryDelay
        self.primaryActionTitle = primaryActionTitle
        self.secondaryActionTitle = secondaryActionTitle
    }
}

