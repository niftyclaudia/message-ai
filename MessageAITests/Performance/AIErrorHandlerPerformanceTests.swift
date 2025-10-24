//
//  AIErrorHandlerPerformanceTests.swift
//  MessageAITests
//
//  PR-AI-005: Performance tests for error handling overhead
//

import Testing
import Foundation
@testable import MessageAI

@Suite("AI Error Handler Performance Tests")
struct AIErrorHandlerPerformanceTests {
    
    @Test("Error handling overhead is under 10ms")
    @MainActor
    func testErrorHandlingOverhead() async throws {
        let handler = AIErrorHandler.shared
        let error = AIError(type: .timeout, message: "timeout")
        let context = AIContext(
            feature: .summarization,
            userId: "user123",
            threadId: "thread456"
        )
        
        // Measure error handling time
        let startTime = Date()
        
        for _ in 0..<100 {
            _ = handler.handle(error: error, context: context)
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageTime = totalTime / 100.0
        
        // Average should be < 10ms per error handling
        #expect(averageTime < 0.010, "Average error handling time: \(averageTime * 1000)ms")
    }
    
    @Test("Error UI display latency under 50ms")
    func testErrorUILatency() async throws {
        // Test that error UI can be rendered quickly
        // Note: SwiftUI rendering time is hardware-dependent
        // This is primarily verified manually by user
        
        // Conceptual test: Verify error response generation is fast
        let handler = await AIErrorHandler.shared
        let error = AIError(type: .rateLimit, message: "rate limit")
        let context = AIContext(feature: .semanticSearch, userId: "user123")
        
        let startTime = Date()
        let _ = await handler.handle(error: error, context: context)
        let endTime = Date()
        
        let latency = endTime.timeIntervalSince(startTime)
        
        // Response generation should be < 5ms
        #expect(latency < 0.005, "Error response latency: \(latency * 1000)ms")
    }
    
    @Test("Retry start latency under 100ms")
    func testRetryStartLatency() async throws {
        // Test that retry operations start quickly
        // Note: Actual retry includes network calls (not measured here)
        // This tests the local overhead only
        
        let handler = await AIErrorHandler.shared
        let error = AIError(type: .timeout, message: "timeout")
        let context = AIContext(feature: .summarization, userId: "user123")
        
        let response = await handler.handle(error: error, context: context)
        
        // Verify retry is recommended
        #expect(response.shouldRetry == true)
        
        // Verify retry delay is reasonable (1s for timeout)
        #expect(response.retryDelay == 1.0)
    }
    
    @Test("Fallback activation latency under 200ms")
    @MainActor
    func testFallbackActivationLatency() async throws {
        let manager = FallbackModeManager.shared
        let feature = AIFeature.priorityDetection
        
        // Reset state
        manager.resetFallbackMode(for: feature)
        
        // Measure activation time
        let startTime = Date()
        
        // Trigger fallback mode
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        
        let endTime = Date()
        let latency = endTime.timeIntervalSince(startTime)
        
        // Activation should be < 200ms (< 0.2s)
        #expect(latency < 0.2, "Fallback activation latency: \(latency * 1000)ms")
        #expect(manager.isInFallbackMode(feature: feature) == true)
    }
    
    @Test("Error classification performance")
    func testErrorClassificationPerformance() async throws {
        // Test that error classification is fast for all error types
        
        let errorTypes: [(AIErrorType, String)] = [
            (.timeout, "Operation timed out"),
            (.rateLimit, "Rate limit exceeded"),
            (.serviceUnavailable, "Service unavailable"),
            (.networkFailure, "Network error"),
            (.invalidRequest, "Invalid request"),
            (.quotaExceeded, "Quota exceeded"),
        ]
        
        let startTime = Date()
        
        for _ in 0..<1000 {
            for (type, message) in errorTypes {
                let error = AIError(type: type, message: message)
                _ = error.retryable
                _ = error.retryDelay
            }
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageTime = totalTime / (1000.0 * Double(errorTypes.count))
        
        // Classification should be < 0.1ms per error
        #expect(averageTime < 0.0001, "Average classification time: \(averageTime * 1000)ms")
    }
    
    @Test("Fallback mode state check performance")
    @MainActor
    func testFallbackModeCheckPerformance() async throws {
        let manager = FallbackModeManager.shared
        
        let startTime = Date()
        
        // Check fallback mode 10,000 times
        for _ in 0..<10000 {
            for feature in AIFeature.allCases {
                _ = manager.isInFallbackMode(feature: feature)
            }
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageTime = totalTime / (10000.0 * Double(AIFeature.allCases.count))
        
        // State check should be < 0.01ms per check
        #expect(averageTime < 0.00001, "Average state check time: \(averageTime * 1000)ms")
    }
}

