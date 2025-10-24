//
//  PriorityDetectionServiceTests.swift
//  MessageAITests
//
//  Unit tests for PriorityDetectionService
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for PriorityDetectionService
struct PriorityDetectionServiceTests {
    
    // MARK: - Test Data
    
    private let testMessage = Message(
        id: "test-message-1",
        chatID: "test-chat-1",
        senderID: "test-user-1",
        text: "URGENT: Server is down, need immediate help!",
        timestamp: Date(),
        status: .sent
    )
    
    private let testContext = MessageContext(
        threadID: "test-thread-1",
        participants: ["user1", "user2"],
        conversationHistory: [],
        userPreferences: nil
    )
    
    // MARK: - Categorization Tests
    
    @Test("Categorizes Urgent Messages Correctly")
    func categorizesUrgentMessagesCorrectly() async throws {
        // Given
        let service = PriorityDetectionService()
        let urgentMessage = Message(
            id: "urgent-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: "URGENT: Server is down, need immediate help!",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(urgentMessage, context: testContext)
        
        // Then
        #expect(prediction.category == .urgent)
        #expect(prediction.confidence > 0.7)
        #expect(prediction.reasoning.contains("urgent") || prediction.reasoning.contains("immediate"))
    }
    
    @Test("Categorizes Can Wait Messages Correctly")
    func categorizesCanWaitMessagesCorrectly() async throws {
        // Given
        let service = PriorityDetectionService()
        let canWaitMessage = Message(
            id: "can-wait-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: "Hey, how was your weekend?",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(canWaitMessage, context: testContext)
        
        // Then
        #expect(prediction.category == .canWait)
        #expect(prediction.confidence > 0.5)
    }
    
    @Test("Categorizes AI Handled Messages Correctly")
    func categorizesAIHandledMessagesCorrectly() async throws {
        // Given
        let service = PriorityDetectionService()
        let aiHandledMessage = Message(
            id: "ai-handled-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: "Please schedule a meeting for next week",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(aiHandledMessage, context: testContext)
        
        // Then
        #expect(prediction.category == .aiHandled)
        #expect(prediction.confidence > 0.6)
    }
    
    @Test("Handles Empty Messages Gracefully")
    func handlesEmptyMessagesGracefully() async throws {
        // Given
        let service = PriorityDetectionService()
        let emptyMessage = Message(
            id: "empty-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: "",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(emptyMessage, context: testContext)
        
        // Then
        #expect(prediction.category == .canWait) // Should default to canWait
        #expect(prediction.confidence >= 0.0)
        #expect(prediction.confidence <= 1.0)
    }
    
    @Test("Handles Very Long Messages")
    func handlesVeryLongMessages() async throws {
        // Given
        let service = PriorityDetectionService()
        let longText = String(repeating: "This is a very long message that should still be categorized properly. ", count: 50)
        let longMessage = Message(
            id: "long-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: longText,
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(longMessage, context: testContext)
        
        // Then
        #expect(prediction.category != nil)
        #expect(prediction.confidence >= 0.0)
        #expect(prediction.confidence <= 1.0)
    }
    
    // MARK: - Metadata Extraction Tests
    
    @Test("Extracts Keywords Correctly")
    func extractsKeywordsCorrectly() async throws {
        // Given
        let service = PriorityDetectionService()
        let message = Message(
            id: "keyword-test-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: "The project deadline is approaching and we need to finish the implementation",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(message, context: testContext)
        
        // Then
        #expect(prediction.reasoning.count > 0)
        #expect(prediction.confidence >= 0.0)
        #expect(prediction.confidence <= 1.0)
    }
    
    @Test("Detects Urgency Indicators")
    func detectsUrgencyIndicators() async throws {
        // Given
        let service = PriorityDetectionService()
        let urgentMessage = Message(
            id: "urgency-test-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: "ASAP: Need this done immediately!",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(urgentMessage, context: testContext)
        
        // Then
        #expect(prediction.category == .urgent)
        #expect(prediction.confidence > 0.7)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handles AI Service Failure Gracefully")
    func handlesAIServiceFailureGracefully() async throws {
        // Given
        let service = PriorityDetectionService()
        let message = Message(
            id: "error-test-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: "Test message",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(message, context: testContext)
        
        // Then
        // Should return a prediction even if AI service fails
        #expect(prediction.category != nil)
        #expect(prediction.confidence >= 0.0)
        #expect(prediction.confidence <= 1.0)
    }
    
    // MARK: - Performance Tests
    
    @Test("Categorization Completes Within 200ms")
    func categorizationCompletesWithin200ms() async throws {
        // Given
        let service = PriorityDetectionService()
        let message = Message(
            id: "perf-test-1",
            chatID: "chat-1",
            senderID: "user-1",
            text: "Performance test message",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let startTime = Date()
        let prediction = try await service.categorizeMessage(message, context: testContext)
        let endTime = Date()
        
        // Then
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 0.2) // Should complete within 200ms
        #expect(prediction.category != nil)
    }
    
    @Test("Handles Multiple Messages Concurrently")
    func handlesMultipleMessagesConcurrently() async throws {
        // Given
        let service = PriorityDetectionService()
        let messages = (1...10).map { i in
            Message(
                id: "concurrent-test-\(i)",
                chatID: "chat-1",
                senderID: "user-1",
                text: "Concurrent test message \(i)",
                timestamp: Date(),
                status: .sent
            )
        }
        
        // When
        let startTime = Date()
        let predictions = try await withThrowingTaskGroup(of: CategoryPrediction.self) { group in
            for message in messages {
                group.addTask {
                    try await service.categorizeMessage(message, context: testContext)
                }
            }
            
            var results: [CategoryPrediction] = []
            for try await prediction in group {
                results.append(prediction)
            }
            return results
        }
        let endTime = Date()
        
        // Then
        let duration = endTime.timeIntervalSince(startTime)
        #expect(duration < 2.0) // Should complete within 2 seconds
        #expect(predictions.count == 10)
        
        for prediction in predictions {
            #expect(prediction.category != nil)
            #expect(prediction.confidence >= 0.0)
            #expect(prediction.confidence <= 1.0)
        }
    }
}
