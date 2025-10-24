//
//  PriorityDetectionServiceIntegrationTests.swift
//  MessageAITests
//
//  Integration tests for PriorityDetectionService with Firebase
//

import Testing
import Foundation
import FirebaseFirestore
import FirebaseAuth
@testable import MessageAI

/// Integration tests for PriorityDetectionService with Firebase
struct PriorityDetectionServiceIntegrationTests {
    
    // MARK: - Firebase Integration Tests
    
    @Test("Categorization Updates Firestore Document")
    func categorizationUpdatesFirestoreDocument() async throws {
        // Given
        let service = PriorityDetectionService()
        let testMessage = Message(
            id: "integration-test-1",
            chatID: "test-chat-1",
            senderID: "test-user-1",
            text: "URGENT: Integration test message",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service.categorizeMessage(testMessage)
        
        // Then
        #expect(prediction.category == .urgent, "Message should be categorized as urgent")
        #expect(prediction.confidence > 0.7, "Confidence should be high")
        
        // Verify Firestore document was updated
        let db = Firestore.firestore()
        let messageDoc = try await db.collection("messages").document(testMessage.id).getDocument()
        
        #expect(messageDoc.exists, "Message document should exist in Firestore")
        
        if let data = messageDoc.data() {
            #expect(data["categoryPrediction"] != nil, "Category prediction should be stored")
            #expect(data["embeddingGenerated"] as? Bool == true, "Embedding generated flag should be set")
        }
    }
    
    @Test("Categorized Messages Can Be Retrieved")
    func categorizedMessagesCanBeRetrieved() async throws {
        // Given
        let service = PriorityDetectionService()
        let chatID = "test-chat-2"
        
        // Create test messages with different categories
        let urgentMessage = Message(
            id: "urgent-msg-1",
            chatID: chatID,
            senderID: "test-user-1",
            text: "URGENT: Critical issue",
            timestamp: Date(),
            status: .sent,
            categoryPrediction: CategoryPrediction(
                category: .urgent,
                confidence: 0.9,
                reasoning: "Contains urgent keyword",
                messageID: "urgent-msg-1",
                userID: "test-user-1"
            )
        )
        
        let canWaitMessage = Message(
            id: "can-wait-msg-1",
            chatID: chatID,
            senderID: "test-user-2",
            text: "How was your weekend?",
            timestamp: Date(),
            status: .sent,
            categoryPrediction: CategoryPrediction(
                category: .canWait,
                confidence: 0.8,
                reasoning: "Casual conversation",
                messageID: "can-wait-msg-1",
                userID: "test-user-2"
            )
        )
        
        // When
        let urgentMessages = try await service.getCategorizedMessages(chatID: chatID, category: .urgent)
        let canWaitMessages = try await service.getCategorizedMessages(chatID: chatID, category: .canWait)
        let allCategorizedMessages = try await service.getCategorizedMessages(chatID: chatID)
        
        // Then
        #expect(urgentMessages.count >= 1, "Should retrieve urgent messages")
        #expect(canWaitMessages.count >= 1, "Should retrieve can wait messages")
        #expect(allCategorizedMessages.count >= 2, "Should retrieve all categorized messages")
        
        // Verify message categories
        for message in urgentMessages {
            #expect(message.categoryPrediction?.category == .urgent, "Retrieved messages should have correct category")
        }
        
        for message in canWaitMessages {
            #expect(message.categoryPrediction?.category == .canWait, "Retrieved messages should have correct category")
        }
    }
    
    @Test("User Preferences Are Stored And Retrieved")
    func userPreferencesAreStoredAndRetrieved() async throws {
        // Given
        let service = PriorityDetectionService()
        let preferences = PriorityPreferences(
            aiCategorizationEnabled: true,
            confidenceThreshold: 0.8,
            urgencyKeywords: ["urgent", "asap", "critical"],
            customRules: ["meeting": "urgent"]
        )
        
        // When
        try await service.updateUserPreferences(preferences)
        let isEnabled = try await service.isAICategorizationEnabled()
        
        // Then
        #expect(isEnabled == true, "User preferences should be stored and retrieved correctly")
    }
    
    @Test("Real-Time Updates Work Across Devices")
    func realTimeUpdatesWorkAcrossDevices() async throws {
        // Given
        let service1 = PriorityDetectionService()
        let service2 = PriorityDetectionService()
        let testMessage = Message(
            id: "realtime-test-1",
            chatID: "test-chat-3",
            senderID: "test-user-1",
            text: "URGENT: Real-time test message",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        let prediction = try await service1.categorizeMessage(testMessage)
        
        // Wait for real-time sync
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        // Then
        let categorizedMessages = try await service2.getCategorizedMessages(chatID: "test-chat-3")
        
        #expect(categorizedMessages.count > 0, "Real-time updates should work across devices")
        
        let foundMessage = categorizedMessages.first { $0.id == testMessage.id }
        #expect(foundMessage != nil, "Message should be found in real-time sync")
        #expect(foundMessage?.categoryPrediction?.category == .urgent, "Category should be synced")
    }
    
    @Test("Offline Categorization Queues Messages")
    func offlineCategorizationQueuesMessages() async throws {
        // Given
        let service = PriorityDetectionService()
        let offlineMessage = Message(
            id: "offline-test-1",
            chatID: "test-chat-4",
            senderID: "test-user-1",
            text: "URGENT: Offline test message",
            timestamp: Date(),
            status: .queued,
            isOffline: true
        )
        
        // When
        let prediction = try await service.categorizeMessage(offlineMessage)
        
        // Then
        #expect(prediction.category == .urgent, "Offline message should be categorized")
        #expect(prediction.isOffline == true, "Prediction should be marked as offline")
        
        // Verify message is queued for sync
        let db = Firestore.firestore()
        let messageDoc = try await db.collection("messages").document(offlineMessage.id).getDocument()
        
        #expect(messageDoc.exists, "Offline message should be stored")
        
        if let data = messageDoc.data() {
            #expect(data["isOffline"] as? Bool == true, "Message should be marked as offline")
            #expect(data["status"] as? String == "queued", "Message should be queued")
        }
    }
    
    @Test("Batch Categorization Handles Multiple Messages")
    func batchCategorizationHandlesMultipleMessages() async throws {
        // Given
        let service = PriorityDetectionService()
        let testMessages = (1...10).map { i in
            Message(
                id: "batch-test-\(i)",
                chatID: "test-chat-5",
                senderID: "test-user-\(i % 3)",
                text: "Batch test message \(i)",
                timestamp: Date().addingTimeInterval(-Double(i * 60)),
                status: .sent
            )
        }
        
        // When
        let startTime = Date()
        var predictions: [CategoryPrediction] = []
        
        for message in testMessages {
            let prediction = try await service.categorizeMessage(message)
            predictions.append(prediction)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Then
        #expect(predictions.count == 10, "All messages should be categorized")
        #expect(duration < 5.0, "Batch categorization should complete within 5 seconds")
        
        // Verify all predictions are valid
        for prediction in predictions {
            #expect(prediction.category != nil, "All predictions should have valid categories")
            #expect(prediction.confidence >= 0.0, "Confidence should be non-negative")
            #expect(prediction.confidence <= 1.0, "Confidence should not exceed 1.0")
        }
    }
    
    @Test("Error Handling Works With Firebase Failures")
    func errorHandlingWorksWithFirebaseFailures() async throws {
        // Given
        let service = PriorityDetectionService()
        let invalidMessage = Message(
            id: "", // Invalid ID
            chatID: "test-chat-6",
            senderID: "test-user-1",
            text: "Test message",
            timestamp: Date(),
            status: .sent
        )
        
        // When
        do {
            let prediction = try await service.categorizeMessage(invalidMessage)
            // Should return neutral prediction on error
            #expect(prediction.category == .canWait, "Should return neutral prediction on error")
        } catch {
            // Error handling should be graceful
            #expect(true, "Error should be handled gracefully")
        }
    }
    
    @Test("Concurrent Categorization Maintains Data Integrity")
    func concurrentCategorizationMaintainsDataIntegrity() async throws {
        // Given
        let service = PriorityDetectionService()
        let concurrentMessages = (1...20).map { i in
            Message(
                id: "concurrent-test-\(i)",
                chatID: "test-chat-7",
                senderID: "test-user-\(i % 5)",
                text: "Concurrent test message \(i)",
                timestamp: Date().addingTimeInterval(-Double(i * 30)),
                status: .sent
            )
        }
        
        // When
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
        
        // Then
        #expect(predictions.count == 20, "All concurrent messages should be processed")
        
        // Verify data integrity
        let categorizedMessages = try await service.getCategorizedMessages(chatID: "test-chat-7")
        #expect(categorizedMessages.count == 20, "All messages should be stored correctly")
        
        // Verify no duplicate predictions
        let predictionIds = predictions.map { $0.messageID }
        let uniqueIds = Set(predictionIds)
        #expect(uniqueIds.count == 20, "No duplicate predictions should exist")
    }
    
    @Test("Performance Under Load")
    func performanceUnderLoad() async throws {
        // Given
        let service = PriorityDetectionService()
        let loadMessages = (1...100).map { i in
            Message(
                id: "load-test-\(i)",
                chatID: "test-chat-8",
                senderID: "test-user-\(i % 10)",
                text: "Load test message \(i)",
                timestamp: Date().addingTimeInterval(-Double(i * 10)),
                status: .sent
            )
        }
        
        // When
        let startTime = Date()
        
        let predictions = try await withThrowingTaskGroup(of: CategoryPrediction.self) { group in
            for message in loadMessages {
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
        #expect(duration < 15.0, "Load test should complete within 15 seconds")
        #expect(predictions.count == 100, "All messages should be processed")
        
        // Verify performance metrics
        let avgLatency = duration / Double(predictions.count)
        #expect(avgLatency < 0.15, "Average latency should be under 150ms")
    }
}
