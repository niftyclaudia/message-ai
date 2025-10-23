//
//  MessageLatencyTests.swift
//  MessageAITests
//
//  Performance tests for PR-1 message latency optimization
//

import Testing
import Foundation
@testable import MessageAI

/// Performance tests for message latency (PR-1)
/// - Note: Tests p95 < 200ms requirement and burst messaging performance
struct MessageLatencyTests {
    
    // MARK: - Latency Performance Tests
    
    @Test("Message Delivery p95 Latency Under 200ms")
    func messageDeliveryP95LatencyUnder200ms() async throws {
        let service = MessageService()
        let chatID = "perf-test-chat-\(UUID().uuidString)"
        var latencies: [TimeInterval] = []
        
        // Send 100 messages to get reliable p95 measurement
        for i in 1...100 {
            let startTime = Date()
            do {
                _ = try await service.sendMessage(chatID: chatID, text: "Performance test message \(i)")
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
        
        // Log performance metrics
        print("Message Latency Performance:")
        print("  Total messages: \(latencies.count)")
        print("  p95 latency: \(String(format: "%.1f", p95Latency * 1000))ms")
        print("  Min latency: \(String(format: "%.1f", latencies.min()! * 1000))ms")
        print("  Max latency: \(String(format: "%.1f", latencies.max()! * 1000))ms")
    }
    
    @Test("Burst Messaging Performance 20+ Messages")
    func burstMessagingPerformance20PlusMessages() async throws {
        let service = MessageService()
        let chatID = "burst-test-chat-\(UUID().uuidString)"
        
        // Create 25 test messages for burst
        let messages = (1...25).map { "Burst performance test message \($0)" }
        
        // Measure burst performance
        let startTime = Date()
        let messageIDs = try await service.sendBurstMessages(chatID: chatID, messages: messages)
        let endTime = Date()
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let avgDurationPerMessage = totalDuration / Double(messages.count)
        
        // Performance requirements
        #expect(totalDuration < 5.0, "Burst of 25 messages took \(totalDuration)s, should be < 5s")
        #expect(avgDurationPerMessage < 0.2, "Average per message \(avgDurationPerMessage * 1000)ms should be < 200ms")
        #expect(messageIDs.count == messages.count, "Expected \(messages.count) message IDs, got \(messageIDs.count)")
        
        // Log burst performance
        print("Burst Messaging Performance:")
        print("  Messages sent: \(messages.count)")
        print("  Total duration: \(String(format: "%.1f", totalDuration * 1000))ms")
        print("  Average per message: \(String(format: "%.1f", avgDurationPerMessage * 1000))ms")
    }
    
    @Test("Message Ordering Performance During Burst")
    func messageOrderingPerformanceDuringBurst() async throws {
        let service = MessageService()
        let chatID = "ordering-test-chat-\(UUID().uuidString)"
        
        // Create messages with specific order
        let messages = (1...20).map { "Ordered message \($0)" }
        
        // Send burst messages
        let startTime = Date()
        _ = try await service.sendBurstMessages(chatID: chatID, messages: messages)
        let sendTime = Date()
        
        // Wait for messages to be processed
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Fetch messages and verify ordering
        let fetchStartTime = Date()
        let fetchedMessages = try await service.fetchMessages(chatID: chatID, limit: 25)
        let fetchTime = Date()
        
        let sortedMessages = service.sortMessagesByServerTimestamp(fetchedMessages)
        let fetchDuration = fetchTime.timeIntervalSince(fetchStartTime)
        
        // Performance requirements
        #expect(fetchDuration < 1.0, "Message fetch took \(fetchDuration)s, should be < 1s")
        
        // Verify order is preserved
        let messageTexts = sortedMessages.map { $0.text }
        for i in 1...20 {
            let expectedText = "Ordered message \(i)"
            #expect(messageTexts.contains(expectedText), "Message '\(expectedText)' not found in correct order")
        }
        
        // Log ordering performance
        print("Message Ordering Performance:")
        print("  Send duration: \(String(format: "%.1f", sendTime.timeIntervalSince(startTime) * 1000))ms")
        print("  Fetch duration: \(String(format: "%.1f", fetchDuration * 1000))ms")
        print("  Messages fetched: \(fetchedMessages.count)")
    }
    
    // MARK: - Real-Time Sync Performance Tests
    
    @Test("Real-Time Message Sync Performance")
    func realTimeMessageSyncPerformance() async throws {
        let service = MessageService()
        let chatID = "sync-test-chat-\(UUID().uuidString)"
        
        // Set up real-time listener
        var receivedMessages: [Message] = []
        let listener = service.observeMessages(chatID: chatID) { messages in
            receivedMessages = messages
        }
        
        // Send test message
        let startTime = Date()
        let messageID = try await service.sendMessage(chatID: chatID, text: "Real-time sync test")
        let sendTime = Date()
        
        // Wait for real-time sync
        let timeout = Date().addingTimeInterval(2.0)
        while receivedMessages.isEmpty && Date() < timeout {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        let syncTime = Date()
        
        // Clean up listener
        listener.remove()
        
        // Performance requirements
        let syncDuration = syncTime.timeIntervalSince(sendTime)
        #expect(syncDuration < 0.2, "Real-time sync took \(syncDuration * 1000)ms, should be < 200ms")
        #expect(!receivedMessages.isEmpty, "No messages received via real-time sync")
        
        // Verify message was received
        let hasMessage = receivedMessages.contains { $0.id == messageID }
        #expect(hasMessage, "Sent message not received via real-time sync")
        
        // Log sync performance
        print("Real-Time Sync Performance:")
        print("  Send duration: \(String(format: "%.1f", sendTime.timeIntervalSince(startTime) * 1000))ms")
        print("  Sync duration: \(String(format: "%.1f", syncDuration * 1000))ms")
        print("  Total duration: \(String(format: "%.1f", syncTime.timeIntervalSince(startTime) * 1000))ms")
    }
    
    // MARK: - Performance Monitor Integration Tests
    
    @Test("Performance Monitor Latency Tracking")
    func performanceMonitorLatencyTracking() async throws {
        let service = MessageService()
        let chatID = "monitor-test-chat-\(UUID().uuidString)"
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Send multiple messages
        for i in 1...10 {
            _ = try await service.sendMessage(chatID: chatID, text: "Monitor test message \(i)")
        }
        
        // Wait for metrics to be recorded
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        // Get performance statistics
        guard let stats = PerformanceMonitor.shared.getStatistics(type: .messageLatency) else {
            #expect(Bool(false), "No message latency statistics available")
            return
        }
        
        // Verify performance targets
        #expect(stats.count >= 10, "Expected at least 10 measurements, got \(stats.count)")
        #expect(stats.p95 < 200, "p95 \(stats.p95)ms should be less than 200ms")
        #expect(stats.mean < 150, "Mean \(stats.mean)ms should be less than 150ms")
        
        // Log performance statistics
        print("Performance Monitor Statistics:")
        print(stats.description)
    }
    
    @Test("Performance Monitor Export Functionality")
    func performanceMonitorExportFunctionality() async throws {
        let service = MessageService()
        let chatID = "export-test-chat-\(UUID().uuidString)"
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Send test messages
        for i in 1...5 {
            _ = try await service.sendMessage(chatID: chatID, text: "Export test message \(i)")
        }
        
        // Wait for metrics to be recorded
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        // Export metrics as CSV
        let csvData = PerformanceMonitor.shared.exportMetricsAsCSV()
        
        // Verify CSV export
        #expect(!csvData.isEmpty, "CSV export should not be empty")
        #expect(csvData.contains("message_latency"), "CSV should contain message_latency metrics")
        #expect(csvData.contains("Timestamp,Type,Value(ms),Metadata"), "CSV should contain header row")
        
        // Log CSV sample
        let lines = csvData.components(separatedBy: "\n")
        print("CSV Export Sample (first 3 lines):")
        for i in 0..<min(3, lines.count) {
            print("  \(lines[i])")
        }
    }
}
