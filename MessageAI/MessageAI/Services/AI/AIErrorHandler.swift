//
//  AIErrorHandler.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Central service for handling AI errors with calm intelligence UX
//

import Foundation
import FirebaseFirestore
import FirebaseCrashlytics

/// Central error handler for all AI features
/// Provides calm, first-person error messages and fallback options
@MainActor
class AIErrorHandler: ObservableObject {
    static let shared = AIErrorHandler()
    
    @Published private(set) var isInFallbackMode: [AIFeature: Bool] = [:]
    private var consecutiveFailures: [AIFeature: Int] = [:]
    
    private init() {}
    
    // MARK: - Core Error Handling
    
    /// Handle an AI error and generate user-facing response
    func handle(error: AIError, context: AIContext) -> ErrorResponse {
        let userMessage = getUserMessage(for: error, feature: context.feature)
        let fallbackAction = getFallbackOption(feature: context.feature, context: context)
        let retry = shouldRetry(error: error)
        let actionTitles = getActionTitles(for: error)
        
        // Track consecutive failures for fallback mode
        recordFailure(for: context.feature)
        
        // Log error asynchronously
        Task {
            await logError(error: error, context: context)
        }
        
        return ErrorResponse(
            error: error,
            userMessage: userMessage,
            fallbackAction: fallbackAction,
            shouldRetry: retry.shouldRetry,
            retryDelay: retry.delay,
            primaryActionTitle: actionTitles.primary,
            secondaryActionTitle: actionTitles.secondary
        )
    }
    
    /// Determine if an error should be retried
    func shouldRetry(error: AIError) -> (shouldRetry: Bool, delay: TimeInterval) {
        guard error.retryable else {
            return (false, 0)
        }
        
        return (true, error.retryDelay)
    }
    
    /// Get fallback action for a specific feature
    func getFallbackOption(feature: AIFeature, context: AIContext) -> FallbackAction? {
        switch feature {
        case .threadSummary:
            return context.threadId != nil ? .openFullThread(threadId: context.threadId!) : nil
            
        case .actionItems:
            return .showRecentMessages(count: 10)
            
        case .smartSearch:
            return context.query != nil ? .useKeywordSearch(query: context.query!) : nil
            
        case .summarization:
            return context.threadId != nil ? .openFullThread(threadId: context.threadId!) : nil
            
        case .actionItemExtraction:
            return .showRecentMessages(count: 10)
            
        case .semanticSearch:
            return context.query != nil ? .useKeywordSearch(query: context.query!) : nil
            
        case .priorityDetection:
            return .showInbox
            
        case .decisionTracking:
            return .skipDetection
            
        case .proactiveAssistant:
            return .showInbox
            
        case .proactiveScheduling:
            return .manualScheduling
        }
    }
    
    // MARK: - User Messaging
    
    /// Get calm, first-person error message
    func getUserMessage(for error: AIError, feature: AIFeature) -> String {
        switch error.type {
        case .timeout:
            return "I'm having trouble right now. Want to try again?"
            
        case .rateLimit:
            return "I need a moment to catch up. Try again in 30 seconds?"
            
        case .serviceUnavailable:
            return "Taking longer than expected. Want to try the full version while I work on it?"
            
        case .networkFailure:
            return "I can't reach my AI assistant right now. Check your connection?"
            
        case .invalidRequest:
            return "Something doesn't look quite right. Let me know if this keeps happening."
            
        case .quotaExceeded:
            return "AI features are temporarily limited. I'll be back soon!"
            
        case .unknown:
            return "Something unexpected happened. Want to try again?"
        }
    }
    
    /// Get action button titles
    func getActionTitles(for error: AIError) -> (primary: String, secondary: String?) {
        if error.retryable {
            return ("Try Again", "View Anyway")
        } else {
            return ("Got It", nil)
        }
    }
    
    // MARK: - Logging
    
    /// Log error to Crashlytics and Firestore
    func logError(error: AIError, context: AIContext) async {
        // Log to Crashlytics
        Crashlytics.crashlytics().record(error: error, userInfo: [
            "feature": context.feature.rawValue,
            "errorType": error.type.rawValue,
            "requestId": context.requestId,
            "retryCount": context.retryCount
        ])
        
        // Log to Firestore (privacy-preserving)
        do {
            try await ErrorLogger.shared.logToFirestore(error: error, context: context)
        } catch {
            print("Failed to log error to Firestore: \(error.localizedDescription)")
        }
    }
    
    /// Add failed request to retry queue
    func queueForRetry(error: AIError, context: AIContext) async throws -> String {
        guard error.retryable && context.retryCount < 4 else {
            throw NSError(domain: "AIErrorHandler", code: -1, 
                         userInfo: [NSLocalizedDescriptionKey: "Error not retryable or max retries exceeded"])
        }
        
        return try await RetryQueue.shared.addToQueue(error: error, context: context)
    }
    
    // MARK: - Fallback Mode Management
    
    /// Check if feature should enter fallback mode
    func shouldUseFallbackMode(feature: AIFeature) -> Bool {
        return isInFallbackMode[feature] ?? false
    }
    
    /// Record a failure for fallback mode tracking
    private func recordFailure(for feature: AIFeature) {
        let count = (consecutiveFailures[feature] ?? 0) + 1
        consecutiveFailures[feature] = count
        
        // Enter fallback mode after 3 consecutive failures
        if count >= 3 {
            isInFallbackMode[feature] = true
            print("⚠️ Feature \(feature.rawValue) entering fallback mode after \(count) failures")
        }
    }
    
    /// Record a success to reset fallback mode
    func recordSuccess(for feature: AIFeature) {
        consecutiveFailures[feature] = 0
        if isInFallbackMode[feature] == true {
            isInFallbackMode[feature] = false
            print("✅ Feature \(feature.rawValue) exiting fallback mode")
        }
    }
}

