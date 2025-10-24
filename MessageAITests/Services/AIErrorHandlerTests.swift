//
//  AIErrorHandlerTests.swift
//  MessageAITests
//
//  PR-AI-005: Unit tests for AIErrorHandler service
//

import Testing
import Foundation
@testable import MessageAI

@Suite("AIErrorHandler Tests")
struct AIErrorHandlerTests {
    
    @Test("Error classification for timeout errors")
    @MainActor
    func testTimeoutErrorHandling() async throws {
        let handler = AIErrorHandler.shared
        let error = AIError(type: .timeout, message: "Operation timed out")
        let context = AIContext(
            feature: .summarization,
            userId: "user123",
            threadId: "thread456"
        )
        
        let response = handler.handle(error: error, context: context)
        
        #expect(response.error.type == .timeout)
        #expect(response.shouldRetry == true)
        #expect(response.retryDelay == 1.0)
        #expect(response.userMessage.contains("having trouble"))
        #expect(response.primaryActionTitle == "Try Again")
    }
    
    @Test("Error classification for rate limit errors")
    @MainActor
    func testRateLimitErrorHandling() async throws {
        let handler = AIErrorHandler.shared
        let error = AIError(type: .rateLimit, message: "Rate limit exceeded", statusCode: 429)
        let context = AIContext(
            feature: .semanticSearch,
            userId: "user123",
            query: "search query"
        )
        
        let response = handler.handle(error: error, context: context)
        
        #expect(response.error.type == .rateLimit)
        #expect(response.shouldRetry == false)
        #expect(response.userMessage.contains("moment to catch up"))
        #expect(response.primaryActionTitle == "Got It")
    }
    
    @Test("Error classification for service unavailable")
    @MainActor
    func testServiceUnavailableErrorHandling() async throws {
        let handler = AIErrorHandler.shared
        let error = AIError(type: .serviceUnavailable, message: "Service down", statusCode: 503)
        let context = AIContext(
            feature: .actionItemExtraction,
            userId: "user123",
            messageId: "msg789"
        )
        
        let response = handler.handle(error: error, context: context)
        
        #expect(response.error.type == .serviceUnavailable)
        #expect(response.shouldRetry == true)
        #expect(response.retryDelay == 2.0)
        #expect(response.userMessage.contains("longer than expected"))
    }
    
    @Test("Fallback action for thread summarization")
    @MainActor
    func testSummarizationFallback() async throws {
        let handler = AIErrorHandler.shared
        let context = AIContext(
            feature: .summarization,
            userId: "user123",
            threadId: "thread456"
        )
        
        let fallback = handler.getFallbackOption(feature: .summarization, context: context)
        
        #expect(fallback != nil)
        if case .openFullThread(let threadId) = fallback {
            #expect(threadId == "thread456")
        } else {
            Issue.record("Expected openFullThread fallback")
        }
    }
    
    @Test("Fallback action for semantic search")
    @MainActor
    func testSemanticSearchFallback() async throws {
        let handler = AIErrorHandler.shared
        let context = AIContext(
            feature: .semanticSearch,
            userId: "user123",
            query: "important messages"
        )
        
        let fallback = handler.getFallbackOption(feature: .semanticSearch, context: context)
        
        #expect(fallback != nil)
        if case .useKeywordSearch(let query) = fallback {
            #expect(query == "important messages")
        } else {
            Issue.record("Expected useKeywordSearch fallback")
        }
    }
    
    @Test("Fallback action for priority detection")
    @MainActor
    func testPriorityDetectionFallback() async throws {
        let handler = AIErrorHandler.shared
        let context = AIContext(
            feature: .priorityDetection,
            userId: "user123"
        )
        
        let fallback = handler.getFallbackOption(feature: .priorityDetection, context: context)
        
        #expect(fallback != nil)
        if case .showInbox = fallback {
            // Correct fallback
        } else {
            Issue.record("Expected showInbox fallback")
        }
    }
    
    @Test("User message tone is first-person and calm")
    @MainActor
    func testUserMessageTone() async throws {
        let handler = AIErrorHandler.shared
        let errorTypes: [AIErrorType] = [.timeout, .rateLimit, .networkFailure]
        
        for errorType in errorTypes {
            let message = handler.getUserMessage(for: AIError(type: errorType, message: "test"), feature: .summarization)
            
            // Should use first-person pronouns
            let containsFirstPerson = message.contains("I") || message.contains("I'm") || message.contains("my")
            #expect(containsFirstPerson, "Message should use first-person: \(message)")
            
            // Should not contain technical jargon
            #expect(!message.contains("ERROR"))
            #expect(!message.contains("FAILED"))
            #expect(!message.contains("500"))
            #expect(!message.contains("503"))
        }
    }
    
    @Test("Retry logic respects retryability")
    @MainActor
    func testRetryLogic() async throws {
        let handler = AIErrorHandler.shared
        
        // Retryable errors
        let timeoutError = AIError(type: .timeout, message: "timeout")
        let timeoutRetry = handler.shouldRetry(error: timeoutError)
        #expect(timeoutRetry.shouldRetry == true)
        #expect(timeoutRetry.delay == 1.0)
        
        // Non-retryable errors
        let invalidError = AIError(type: .invalidRequest, message: "invalid")
        let invalidRetry = handler.shouldRetry(error: invalidError)
        #expect(invalidRetry.shouldRetry == false)
        #expect(invalidRetry.delay == 0.0)
    }
    
    @Test("Fallback mode tracks consecutive failures")
    @MainActor
    func testFallbackModeTracking() async throws {
        let handler = AIErrorHandler.shared
        let feature = AIFeature.summarization
        
        // Reset state
        handler.recordSuccess(for: feature)
        #expect(handler.shouldUseFallbackMode(feature: feature) == false)
        
        // Record failures
        let error = AIError(type: .timeout, message: "timeout")
        let context1 = AIContext(feature: feature, userId: "user123", retryCount: 0)
        let context2 = AIContext(feature: feature, userId: "user123", retryCount: 1)
        let context3 = AIContext(feature: feature, userId: "user123", retryCount: 2)
        
        _ = handler.handle(error: error, context: context1)
        #expect(handler.shouldUseFallbackMode(feature: feature) == false)
        
        _ = handler.handle(error: error, context: context2)
        #expect(handler.shouldUseFallbackMode(feature: feature) == false)
        
        _ = handler.handle(error: error, context: context3)
        #expect(handler.shouldUseFallbackMode(feature: feature) == true)
        
        // Reset on success
        handler.recordSuccess(for: feature)
        #expect(handler.shouldUseFallbackMode(feature: feature) == false)
    }
    
    @Test("Action titles appropriate for error type")
    @MainActor
    func testActionTitles() async throws {
        let handler = AIErrorHandler.shared
        
        // Retryable error should offer retry
        let retryableError = AIError(type: .timeout, message: "timeout")
        let retryableTitles = handler.getActionTitles(for: retryableError)
        #expect(retryableTitles.primary == "Try Again")
        #expect(retryableTitles.secondary == "View Anyway")
        
        // Non-retryable error should offer acknowledgment
        let nonRetryableError = AIError(type: .quotaExceeded, message: "quota")
        let nonRetryableTitles = handler.getActionTitles(for: nonRetryableError)
        #expect(nonRetryableTitles.primary == "Got It")
        #expect(nonRetryableTitles.secondary == nil)
    }
}

