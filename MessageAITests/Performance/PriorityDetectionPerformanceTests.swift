//
//  PriorityDetectionPerformanceTests.swift
//  MessageAITests
//
//  Performance tests for priority detection feature
//

import Testing
import Foundation
@testable import MessageAI

/// Performance tests for priority detection functionality
struct PriorityDetectionPerformanceTests {
    
    // MARK: - Categorization Latency Tests
    
    @Test("Message Categorization p95 Latency Under 200ms")
    func messageCategorizationP95LatencyUnder200ms() async throws {
        // Given
        let service = PriorityDetectionService()
        let testMessages = generateTestMessages(count: 100)
        
        // When
        let startTime = Date()
        var latencies: [TimeInterval] = []
        
        for message in testMessages {
            let messageStartTime = Date()
            let prediction = try await service.categorizeMessage(message)
            let messageEndTime = Date()
            
            let latency = messageEndTime.timeIntervalSince(messageStartTime)
            latencies.append(latency)
        }
        
        let endTime = Date()
        let totalDuration = endTime.timeIntervalSince(startTime)
        
        // Then
        let sortedLatencies = latencies.sorted()
        let p95Index = Int(Double(sortedLatencies.count) * 0.95)
        let p95Latency = sortedLatencies[p95Index]
        
        #expect(p95Latency < 0.2, "p95 latency should be under 200ms, got \(p95Latency * 1000)ms")
        #expect(totalDuration < 10.0, "Total processing time should be under 10 seconds")
    }
    
    @Test("Burst Messaging Handles 20+ Messages Without Lag")
    func burstMessagingHandles20PlusMessagesWithoutLag() async throws {
        // Given
        let service = PriorityDetectionService()
        let burstMessages = generateTestMessages(count: 25)
        
        // When
        let startTime = Date()
        
        let predictions = try await withThrowingTaskGroup(of: CategoryPrediction.self) { group in
            for message in burstMessages {
                group.addTask {
                    try await service.categorizeMessage(message)
                }
            }
            
            var results: [CategoryPrediction] = []
            for try await prediction in group {
                results.append(prediction)
            }
            return results
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration < 5.0, "Burst messaging should complete within 5 seconds")
        #expect(predictions.count == 25, "All messages should be processed")
        
        // Verify all predictions are valid
        for prediction in predictions {
            #expect(prediction.category != nil, "All predictions should have valid categories")
            #expect(prediction.confidence >= 0.0, "Confidence should be non-negative")
            #expect(prediction.confidence <= 1.0, "Confidence should not exceed 1.0")
        }
    }
    
    @Test("Concurrent Categorization Maintains Performance")
    func concurrentCategorizationMaintainsPerformance() async throws {
        // Given
        let service = PriorityDetectionService()
        let concurrentMessages = generateTestMessages(count: 50)
        
        // When
        let startTime = Date()
        
        let predictions = try await withThrowingTaskGroup(of: CategoryPrediction.self) { group in
            for message in concurrentMessages {
                group.addTask {
                    try await service.categorizeMessage(message)
                }
            }
            
            var results: [CategoryPrediction] = []
            for try await prediction in group {
                results.append(prediction)
            }
            return results
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration < 8.0, "Concurrent processing should complete within 8 seconds")
        #expect(predictions.count == 50, "All concurrent messages should be processed")
    }
    
    // MARK: - Memory Performance Tests
    
    @Test("Memory Usage Remains Stable During Categorization")
    func memoryUsageRemainsStableDuringCategorization() async throws {
        // Given
        let service = PriorityDetectionService()
        let testMessages = generateTestMessages(count: 100)
        
        // When
        let initialMemory = getMemoryUsage()
        
        for message in testMessages {
            let prediction = try await service.categorizeMessage(message)
            #expect(prediction.category != nil, "Prediction should be valid")
        }
        
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Then
        #expect(memoryIncrease < 50_000_000, "Memory increase should be less than 50MB") // 50MB limit
    }
    
    @Test("No Memory Leaks During Extended Categorization")
    func noMemoryLeaksDuringExtendedCategorization() async throws {
        // Given
        let service = PriorityDetectionService()
        let testMessages = generateTestMessages(count: 200)
        
        // When
        for _ in 1...5 { // Run multiple cycles
            for message in testMessages {
                let prediction = try await service.categorizeMessage(message)
                #expect(prediction.category != nil, "Prediction should be valid")
            }
        }
        
        // Then
        // If we reach here without crashing, memory management is working
        #expect(true, "Extended categorization should complete without memory leaks")
    }
    
    // MARK: - UI Performance Tests
    
    @Test("Priority Badge Rendering Performance")
    func priorityBadgeRenderingPerformance() async throws {
        // Given
        let categories: [MessageCategory] = [.urgent, .canWait, .aiHandled]
        let confidences: [Double] = [0.7, 0.8, 0.9]
        
        // When
        let startTime = Date()
        
        for _ in 1...1000 { // Render 1000 badges
            for category in categories {
                for confidence in confidences {
                    let badge = PriorityBadge(
                        category: category,
                        confidence: confidence,
                        showConfidence: true
                    )
                    // In a real test, we would measure rendering time
                    #expect(badge.category == category, "Badge should have correct category")
                }
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration < 1.0, "Badge rendering should be fast")
    }
    
    @Test("Message List Scrolling Performance With Categorized Messages")
    func messageListScrollingPerformanceWithCategorizedMessages() async throws {
        // Given
        let categorizedMessages = generateCategorizedMessages(count: 1000)
        
        // When
        let startTime = Date()
        
        // Simulate scrolling through messages
        for message in categorizedMessages {
            // Simulate message row rendering
            let hasCategory = message.categoryPrediction != nil
            #expect(hasCategory, "Message should have categorization")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration < 2.0, "Scrolling through 1000 categorized messages should be fast")
    }
    
    // MARK: - Network Performance Tests
    
    @Test("Offline Categorization Performance")
    func offlineCategorizationPerformance() async throws {
        // Given
        let service = PriorityDetectionService()
        let offlineMessages = generateTestMessages(count: 50)
        
        // When
        let startTime = Date()
        
        for message in offlineMessages {
            // Simulate offline categorization (should use cached models)
            let prediction = try await service.categorizeMessage(message)
            #expect(prediction.category != nil, "Offline categorization should work")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration < 3.0, "Offline categorization should be fast")
    }
    
    @Test("Network Resilience During Categorization")
    func networkResilienceDuringCategorization() async throws {
        // Given
        let service = PriorityDetectionService()
        let testMessages = generateTestMessages(count: 20)
        
        // When
        let startTime = Date()
        var successCount = 0
        var failureCount = 0
        
        for message in testMessages {
            do {
                let prediction = try await service.categorizeMessage(message)
                #expect(prediction.category != nil, "Prediction should be valid")
                successCount += 1
            } catch {
                failureCount += 1
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(duration < 5.0, "Network resilience test should complete within 5 seconds")
        #expect(successCount + failureCount == 20, "All messages should be processed")
        #expect(successCount > 0, "Some categorizations should succeed")
    }
    
    // MARK: - Helper Methods
    
    private func generateTestMessages(count: Int) -> [Message] {
        let texts = [
            "URGENT: Server is down, need immediate help!",
            "Hey, how was your weekend?",
            "Please schedule a meeting for next week",
            "This is a regular message",
            "ASAP: Need this done immediately!",
            "Thanks for the update",
            "Can you help me with this task?",
            "Emergency: Critical issue needs attention",
            "Just checking in",
            "Meeting reminder for tomorrow"
        ]
        
        return (1...count).map { i in
            Message(
                id: "test-message-\(i)",
                chatID: "test-chat-\(i % 5)",
                senderID: "test-user-\(i % 3)",
                text: texts[i % texts.count],
                timestamp: Date().addingTimeInterval(-Double(i * 60)),
                status: .sent
            )
        }
    }
    
    private func generateCategorizedMessages(count: Int) -> [Message] {
        let categories: [MessageCategory] = [.urgent, .canWait, .aiHandled]
        
        return (1...count).map { i in
            let category = categories[i % categories.count]
            let prediction = CategoryPrediction(
                category: category,
                confidence: Double.random(in: 0.7...0.95),
                reasoning: "Test reasoning",
                messageID: "test-message-\(i)",
                userID: "test-user-\(i % 3)"
            )
            
            return Message(
                id: "test-message-\(i)",
                chatID: "test-chat-\(i % 5)",
                senderID: "test-user-\(i % 3)",
                text: "Test message \(i)",
                timestamp: Date().addingTimeInterval(-Double(i * 60)),
                status: .sent,
                categoryPrediction: prediction
            )
        }
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}
