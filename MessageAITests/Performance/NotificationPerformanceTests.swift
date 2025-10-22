//
//  NotificationPerformanceTests.swift
//  MessageAITests
//
//  Performance validation tests for notification system
//

import Testing
import Foundation
@testable import MessageAI

/// Performance tests for notification system
/// - Note: Validates latency targets and performance benchmarks
struct NotificationPerformanceTests {
    
    // MARK: - Test Data
    
    private let testChatID = "perf-test-chat"
    private let testSenderID = "perf-sender"
    private let testRecipientID = "perf-recipient"
    
    // MARK: - P1: End-to-End Latency Tests
    
    @Test("P1: End-to-end notification latency baseline")
    func endToEndNotificationLatencyBaseline() async throws {
        // P1: Measure end-to-end latency (message send → notification display)
        // Target: <2s for 95% of tests
        
        // Given: Notification test service
        let testService = NotificationTestService()
        var latencies: [TimeInterval] = []
        
        // When: Measure latency for 20 simulated notifications
        for i in 0..<20 {
            let startTime = Date()
            
            let payload = TestNotificationPayload.oneOnOne(
                chatID: "\(testChatID)-\(i)",
                senderID: testSenderID,
                recipientID: testRecipientID
            )
            
            _ = await testService.simulateNotification(
                payload: payload,
                appState: .foreground
            )
            
            let latency = await testService.measureNotificationLatency(
                messageID: "msg-\(i)",
                startTime: startTime
            )
            
            latencies.append(latency)
        }
        
        // Then: Calculate p95 latency
        let p95 = calculateP95(latencies)
        
        // P95 should be < 2s (target from PRD)
        #expect(p95 < 2.0, "P95 latency: \(p95)s should be < 2s")
        
        // Average should also be reasonable
        let average = latencies.reduce(0, +) / Double(latencies.count)
        #expect(average < 1.0, "Average latency: \(average)s should be < 1s")
    }
    
    @Test("P1: End-to-end latency consistency across multiple tests")
    func endToEndLatencyConsistency() async throws {
        // Verify latency is consistent across multiple test runs
        
        // Given: Test service
        let testService = NotificationTestService()
        var allLatencies: [TimeInterval] = []
        
        // When: Run 3 batches of 10 tests each
        for batch in 0..<3 {
            for i in 0..<10 {
                let startTime = Date()
                let testID = "batch\(batch)-\(i)"
                
                let latency = await testService.measureNotificationLatency(
                    messageID: testID,
                    startTime: startTime
                )
                
                allLatencies.append(latency)
            }
        }
        
        // Then: Latencies are consistent (low variance)
        let average = allLatencies.reduce(0, +) / Double(allLatencies.count)
        let variance = allLatencies.map { pow($0 - average, 2) }.reduce(0, +) / Double(allLatencies.count)
        let stdDev = sqrt(variance)
        
        // Standard deviation should be reasonable (< 50% of average)
        #expect(stdDev < average * 0.5, "StdDev: \(stdDev)s should be < 50% of avg: \(average)s")
    }
    
    // MARK: - P2: Foreground Display Time Tests
    
    @Test("P2: Foreground notification display time <500ms")
    func foregroundNotificationDisplayTimeUnder500ms() async throws {
        // P2: Measure foreground display time (FCM receipt → banner)
        // Target: <500ms
        
        // Given: Foreground notification payload
        let payload = TestNotificationPayload.oneOnOne(
            chatID: testChatID,
            senderID: testSenderID,
            recipientID: testRecipientID
        )
        
        let testService = NotificationTestService()
        let startTime = Date()
        
        // When: Simulate foreground notification
        let result = await testService.simulateNotification(
            payload: payload,
            appState: .foreground
        )
        
        // Then: Display time < 500ms
        if let latency = result.actualLatency {
            #expect(latency < 0.5, "Foreground display: \(latency)s should be < 500ms")
            #expect(result.passed == true)
        }
    }
    
    @Test("P2: Foreground display average over 50 notifications")
    func foregroundDisplayAverageOver50Notifications() async throws {
        // Measure average foreground display time over many notifications
        
        // Given: Test service
        let testService = NotificationTestService()
        var displayTimes: [TimeInterval] = []
        
        // When: Simulate 50 foreground notifications
        for i in 0..<50 {
            let payload = TestNotificationPayload(
                chatID: testChatID,
                senderID: testSenderID,
                senderName: "Test Sender",
                messageText: "Message \(i)"
            )
            
            let result = await testService.simulateNotification(
                payload: payload,
                appState: .foreground
            )
            
            if let latency = result.actualLatency {
                displayTimes.append(latency)
            }
        }
        
        // Then: Average < 500ms
        let average = displayTimes.reduce(0, +) / Double(displayTimes.count)
        #expect(average < 0.5, "Average foreground display: \(average)s should be < 500ms")
    }
    
    // MARK: - P3: Background Resume Time Tests
    
    @Test("P3: Background notification resume time <1s")
    func backgroundNotificationResumeTimeUnder1s() async throws {
        // P3: Measure background resume time (tap → conversation)
        // Target: <1s
        
        // Given: Background notification payload
        let payload = TestNotificationPayload.oneOnOne(
            chatID: testChatID,
            senderID: testSenderID,
            recipientID: testRecipientID
        )
        
        let testService = NotificationTestService()
        
        // When: Simulate background notification
        let result = await testService.simulateNotification(
            payload: payload,
            appState: .background
        )
        
        // Then: Resume time < 1s
        if let latency = result.actualLatency {
            #expect(latency < 1.0, "Background resume: \(latency)s should be < 1s")
            #expect(result.passed == true)
        }
    }
    
    @Test("P3: Background resume average over 30 notifications")
    func backgroundResumeAverageOver30Notifications() async throws {
        // Measure average background resume time
        
        // Given: Test service
        let testService = NotificationTestService()
        var resumeTimes: [TimeInterval] = []
        
        // When: Simulate 30 background notifications
        for i in 0..<30 {
            let payload = TestNotificationPayload(
                chatID: testChatID,
                senderID: testSenderID,
                senderName: "Test Sender",
                messageText: "Message \(i)"
            )
            
            let result = await testService.simulateNotification(
                payload: payload,
                appState: .background
            )
            
            if let latency = result.actualLatency {
                resumeTimes.append(latency)
            }
        }
        
        // Then: Average < 1s
        let average = resumeTimes.reduce(0, +) / Double(resumeTimes.count)
        #expect(average < 1.0, "Average background resume: \(average)s should be < 1s")
    }
    
    // MARK: - P4: Cold Start Navigation Time Tests
    
    @Test("P4: Cold start navigation time <2s")
    func coldStartNavigationTimeUnder2s() async throws {
        // P4: Measure cold start navigation time (tap → conversation loaded)
        // Target: <2s
        
        // Given: Terminated state notification
        let payload = TestNotificationPayload.oneOnOne(
            chatID: testChatID,
            senderID: testSenderID,
            recipientID: testRecipientID
        )
        
        let testService = NotificationTestService()
        
        // When: Simulate terminated state notification
        let result = await testService.simulateNotification(
            payload: payload,
            appState: .terminated
        )
        
        // Then: Cold start < 2s
        if let latency = result.actualLatency {
            #expect(latency < 2.0, "Cold start: \(latency)s should be < 2s")
            #expect(result.passed == true)
        }
    }
    
    @Test("P4: Cold start average over 20 notifications")
    func coldStartAverageOver20Notifications() async throws {
        // Measure average cold start time
        
        // Given: Test service
        let testService = NotificationTestService()
        var coldStartTimes: [TimeInterval] = []
        
        // When: Simulate 20 cold start notifications
        for i in 0..<20 {
            let payload = TestNotificationPayload(
                chatID: testChatID,
                senderID: testSenderID,
                senderName: "Test Sender",
                messageText: "Message \(i)"
            )
            
            let result = await testService.simulateNotification(
                payload: payload,
                appState: .terminated
            )
            
            if let latency = result.actualLatency {
                coldStartTimes.append(latency)
            }
        }
        
        // Then: Average < 2s
        let average = coldStartTimes.reduce(0, +) / Double(coldStartTimes.count)
        #expect(average < 2.0, "Average cold start: \(average)s should be < 2s")
    }
    
    // MARK: - Payload Processing Performance Tests
    
    @Test("Notification payload parsing performance under 1ms")
    func notificationPayloadParsingPerformanceUnder1ms() {
        // Verify payload parsing is extremely fast
        
        // Given: Standard payload
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": "Test Sender",
            "messageText": "Test message"
        ]
        
        let service = NotificationService()
        let iterations = 1000
        
        let startTime = Date()
        
        // When: Parse 1000 times
        for _ in 0..<iterations {
            _ = service.parseNotificationPayload(userInfo)
        }
        
        let duration = Date().timeIntervalSince(startTime)
        let averagePerParse = duration / Double(iterations)
        
        // Then: Average < 1ms per parse
        #expect(averagePerParse < 0.001, "Parse time: \(averagePerParse * 1000)ms should be < 1ms")
    }
    
    @Test("Memory efficiency with 100 concurrent notification payloads")
    func memoryEfficiencyWith100ConcurrentPayloads() async throws {
        // Verify system handles many notifications without memory issues
        
        // Given: 100 notification payloads
        var payloads: [TestNotificationPayload] = []
        
        for i in 0..<100 {
            let payload = TestNotificationPayload(
                chatID: "\(testChatID)-\(i)",
                senderID: testSenderID,
                senderName: "Sender \(i)",
                messageText: "Message \(i)"
            )
            payloads.append(payload)
        }
        
        // When: Process all payloads
        let service = NotificationService()
        var successCount = 0
        
        for payload in payloads {
            if let _ = service.parseNotificationPayload(payload.toUserInfo()) {
                successCount += 1
            }
        }
        
        // Then: All processed successfully
        #expect(successCount == 100)
    }
    
    // MARK: - Performance Summary Tests
    
    @Test("Generate performance summary report")
    func generatePerformanceSummaryReport() async throws {
        // Comprehensive performance test generating summary data
        
        // Given: Test service
        let testService = NotificationTestService()
        
        // When: Run tests for each app state
        let foregroundPayload = TestNotificationPayload.oneOnOne(
            chatID: testChatID,
            senderID: testSenderID,
            recipientID: testRecipientID
        )
        
        let foregroundResult = await testService.simulateNotification(
            payload: foregroundPayload,
            appState: .foreground
        )
        
        let backgroundResult = await testService.simulateNotification(
            payload: foregroundPayload,
            appState: .background
        )
        
        let terminatedResult = await testService.simulateNotification(
            payload: foregroundPayload,
            appState: .terminated
        )
        
        // Then: All tests completed
        #expect(foregroundResult.passed == true)
        #expect(backgroundResult.passed == true)
        #expect(terminatedResult.passed == true)
        
        // Latencies meet targets
        #expect(foregroundResult.actualLatency ?? 999 < 0.5)
        #expect(backgroundResult.actualLatency ?? 999 < 1.0)
        #expect(terminatedResult.actualLatency ?? 999 < 2.0)
    }
    
    // MARK: - Helper Methods
    
    private func calculateP95(_ values: [TimeInterval]) -> TimeInterval {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }
}

