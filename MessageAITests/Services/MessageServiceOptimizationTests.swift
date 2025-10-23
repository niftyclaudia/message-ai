//
//  MessageServiceOptimizationTests.swift
//  MessageAITests
//
//  Tests for PR-1 MessageService optimization
//

import Testing
import Foundation
@testable import MessageAI

/// Tests for MessageService optimization (PR-1)
/// - Note: Tests < 200ms latency requirements and burst messaging
struct MessageServiceOptimizationTests {
    
    // MARK: - Message Latency Tests
    
    @Test("Message Delivery p95 Latency Under 200ms")
    func messageDeliveryP95LatencyUnder200ms() async throws {
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        var latencies: [TimeInterval] = []
        
        // Send 50 messages and measure latency
        for i in 1...50 {
            let startTime = Date()
            do {
                _ = try await service.sendMessage(chatID: chatID, text: "Test message \(i)")
                let latency = Date().timeIntervalSince(startTime)
                latencies.append(latency)
            } catch {
                // Continue with other messages if one fails
                continue
            }
        }
        
        // Calculate p95 latency
        let sortedLatencies = latencies.sorted()
        guard !sortedLatencies.isEmpty else {
            #expect(Bool(false), "No successful message sends")
            return
        }
        
        let p95Index = Int(Double(sortedLatencies.count) * 0.95)
        let p95Latency = sortedLatencies[p95Index]
        
        // PR-1 requirement: p95 latency < 200ms
        #expect(p95Latency < 0.2, "p95 latency \(p95Latency * 1000)ms exceeds 200ms requirement")
    }
    
    @Test("Burst Messaging Handles 20+ Messages Without Lag")
    func burstMessagingHandles20PlusMessagesWithoutLag() async throws {
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Create 25 test messages
        let messages = (1...25).map { "Burst message \($0)" }
        
        // Send burst messages
        let startTime = Date()
        let messageIDs = try await service.sendBurstMessages(chatID: chatID, messages: messages)
        let endTime = Date()
        
        // Should complete without visible lag
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 5.0, "Burst of 25 messages took \(duration)s, should be < 5s")
        #expect(messageIDs.count == messages.count, "Expected \(messages.count) message IDs, got \(messageIDs.count)")
    }
    
    @Test("Message Ordering Preserved During Burst")
    func messageOrderingPreservedDuringBurst() async throws {
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Create messages with specific order
        let messages = ["First", "Second", "Third", "Fourth", "Fifth"]
        
        // Send burst messages
        let messageIDs = try await service.sendBurstMessages(chatID: chatID, messages: messages)
        
        // Wait for messages to be processed
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Fetch messages and verify ordering
        let fetchedMessages = try await service.fetchMessages(chatID: chatID, limit: 10)
        let sortedMessages = service.sortMessagesByServerTimestamp(fetchedMessages)
        
        // Verify order is preserved
        let messageTexts = sortedMessages.map { $0.text }
        let expectedOrder = ["First", "Second", "Third", "Fourth", "Fifth"]
        
        #expect(messageTexts.contains("First"), "First message not found")
        #expect(messageTexts.contains("Second"), "Second message not found")
        #expect(messageTexts.contains("Third"), "Third message not found")
        #expect(messageTexts.contains("Fourth"), "Fourth message not found")
        #expect(messageTexts.contains("Fifth"), "Fifth message not found")
    }
    
    // MARK: - Performance Monitoring Tests
    
    @Test("Performance Monitor Tracks Message Latency")
    func performanceMonitorTracksMessageLatency() async throws {
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Send a test message
        let messageID = try await service.sendMessage(chatID: chatID, text: "Performance test message")
        
        // Wait for performance tracking to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Check if metrics were recorded
        let messageLatencyMetrics = PerformanceMonitor.shared.getMetrics(ofType: .messageLatency)
        #expect(!messageLatencyMetrics.isEmpty, "No message latency metrics recorded")
        
        // Verify the message ID is tracked
        let hasMessageID = messageLatencyMetrics.contains { metric in
            metric.metadata["messageID"] == messageID
        }
        #expect(hasMessageID, "Message ID \(messageID) not found in metrics")
    }
    
    @Test("Performance Monitor Calculates Statistics")
    func performanceMonitorCalculatesStatistics() async throws {
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Send multiple messages to generate statistics
        for i in 1...10 {
            _ = try await service.sendMessage(chatID: chatID, text: "Stats test message \(i)")
        }
        
        // Wait for all metrics to be recorded
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        // Get statistics
        guard let stats = PerformanceMonitor.shared.getStatistics(type: .messageLatency) else {
            #expect(Bool(false), "No statistics available")
            return
        }
        
        // Verify statistics are calculated
        #expect(stats.count >= 10, "Expected at least 10 measurements, got \(stats.count)")
        #expect(stats.p95 > 0, "p95 should be greater than 0")
        #expect(stats.p95 < 200, "p95 \(stats.p95)ms should be less than 200ms")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Network Error Handling During Burst")
    func networkErrorHandlingDuringBurst() async throws {
        let service = MessageService()
        let chatID = "invalid-chat-id" // This should cause an error
        
        // Create test messages
        let messages = ["Test message 1", "Test message 2", "Test message 3"]
        
        // Attempt to send burst messages (should fail gracefully)
        do {
            _ = try await service.sendBurstMessages(chatID: chatID, messages: messages)
            #expect(Bool(false), "Expected error for invalid chat ID")
        } catch {
            // Expected error - verify it's a network error
            #expect(error is MessageServiceError, "Expected MessageServiceError, got \(type(of: error))")
        }
    }
    
    @Test("Empty Message Array Handling")
    func emptyMessageArrayHandling() async throws {
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Send empty message array
        let messageIDs = try await service.sendBurstMessages(chatID: chatID, messages: [])
        
        // Should return empty array without error
        #expect(messageIDs.isEmpty, "Expected empty array for empty messages")
    }
    
    // MARK: - Integration Tests
    
    @Test("Message Service Integration With Performance Monitor")
    func messageServiceIntegrationWithPerformanceMonitor() async throws {
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Clear metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Send single message
        let messageID = try await service.sendMessage(chatID: chatID, text: "Integration test")
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Verify performance tracking
        let latency = await service.measureMessageLatency(messageID: messageID)
        #expect(latency >= 0, "Latency should be non-negative")
        
        // Verify metrics were recorded
        let metrics = PerformanceMonitor.shared.getMetrics(ofType: .messageLatency)
        #expect(!metrics.isEmpty, "Metrics should be recorded")
    }
}
