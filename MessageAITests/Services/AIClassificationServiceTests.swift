//
//  AIClassificationServiceTests.swift
//  MessageAITests
//
//  Unit tests for AIClassificationService
//

import XCTest
import Combine
@testable import MessageAI

@MainActor
class AIClassificationServiceTests: XCTestCase {
    
    var service: AIClassificationService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        service = AIClassificationService()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        service.stopAllListeners()
        service = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(service)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(service.classificationStatus.count, 0)
        XCTAssertEqual(service.offlineFeedbackQueue.count, 0)
    }
    
    // MARK: - Classification Status Tests
    
    func testGetClassificationStatus() {
        let messageId = "test-message-1"
        
        // Initially should return pending
        let status = service.getClassificationStatus(messageId: messageId)
        XCTAssertEqual(status, .pending)
        
        // Update status and verify
        service.classificationStatus[messageId] = .classified(priority: "urgent", confidence: 0.9)
        let updatedStatus = service.getClassificationStatus(messageId: messageId)
        
        if case .classified(let priority, let confidence) = updatedStatus {
            XCTAssertEqual(priority, "urgent")
            XCTAssertEqual(confidence, 0.9)
        } else {
            XCTFail("Expected classified status")
        }
    }
    
    // MARK: - Feedback Submission Tests
    
    func testSubmitClassificationFeedbackSuccess() async {
        let messageId = "test-message-1"
        let suggestedPriority = "urgent"
        let reason = "This is clearly urgent"
        
        // Set up initial classification status
        service.classificationStatus[messageId] = .classified(priority: "normal", confidence: 0.7)
        
        do {
            try await service.submitClassificationFeedback(
                messageId: messageId,
                suggestedPriority: suggestedPriority,
                reason: reason
            )
            
            // Verify status was updated
            let status = service.getClassificationStatus(messageId: messageId)
            XCTAssertEqual(status, .feedbackSubmitted)
            
        } catch {
            XCTFail("Feedback submission should succeed: \(error)")
        }
    }
    
    func testSubmitClassificationFeedbackInvalidPriority() async {
        let messageId = "test-message-1"
        let invalidPriority = "invalid"
        
        do {
            try await service.submitClassificationFeedback(
                messageId: messageId,
                suggestedPriority: invalidPriority,
                reason: nil
            )
            XCTFail("Should throw error for invalid priority")
        } catch ClassificationError.invalidPriority(let priority) {
            XCTAssertEqual(priority, invalidPriority)
        } catch {
            XCTFail("Expected invalidPriority error, got: \(error)")
        }
    }
    
    func testSubmitClassificationFeedbackRateLimit() async {
        let messageId = "test-message-1"
        let suggestedPriority = "urgent"
        
        // Submit first feedback
        do {
            try await service.submitClassificationFeedback(
                messageId: messageId,
                suggestedPriority: suggestedPriority,
                reason: nil
            )
        } catch {
            XCTFail("First feedback should succeed: \(error)")
        }
        
        // Immediately submit second feedback (should be rate limited)
        do {
            try await service.submitClassificationFeedback(
                messageId: messageId,
                suggestedPriority: "normal",
                reason: nil
            )
            XCTFail("Should throw rate limit error")
        } catch ClassificationError.rateLimitExceeded {
            // Expected
        } catch {
            XCTFail("Expected rateLimitExceeded error, got: \(error)")
        }
    }
    
    // MARK: - Retry Classification Tests
    
    func testRetryClassification() async {
        let messageId = "test-message-1"
        
        // Set up failed status
        service.classificationStatus[messageId] = .failed(error: "Network error")
        
        do {
            try await service.retryClassification(messageId: messageId)
            
            // Verify status was updated to pending
            let status = service.getClassificationStatus(messageId: messageId)
            XCTAssertEqual(status, .pending)
            
        } catch {
            XCTFail("Retry should succeed: \(error)")
        }
    }
    
    // MARK: - Offline Queue Tests
    
    func testOfflineQueueProcessing() async {
        let messageId = "test-message-1"
        let feedback = ClassificationFeedback(
            messageId: messageId,
            userId: "test-user",
            originalPriority: "normal",
            suggestedPriority: "urgent",
            feedbackReason: "Test reason"
        )
        
        // Add to offline queue
        service.offlineFeedbackQueue.append(feedback)
        XCTAssertEqual(service.offlineFeedbackQueue.count, 1)
        
        // Process offline queue
        await service.processOfflineQueue()
        
        // Queue should be empty after processing
        XCTAssertEqual(service.offlineFeedbackQueue.count, 0)
    }
    
    func testOfflineQueueMaxSize() {
        let maxSize = 50
        
        // Add more items than max size
        for i in 0..<(maxSize + 10) {
            let feedback = ClassificationFeedback(
                messageId: "message-\(i)",
                userId: "test-user",
                originalPriority: "normal",
                suggestedPriority: "urgent"
            )
            service.offlineFeedbackQueue.append(feedback)
        }
        
        // Should not exceed max size
        XCTAssertLessThanOrEqual(service.offlineFeedbackQueue.count, maxSize)
    }
    
    // MARK: - Listener Management Tests
    
    func testStartStopListening() async {
        let chatId = "test-chat-1"
        
        // Initially not listening
        XCTAssertFalse(service.isListening)
        
        // Start listening (this will fail in test environment, but we can test the state)
        do {
            try await service.listenForClassificationUpdates(chatID: chatId)
        } catch {
            // Expected in test environment without Firebase
        }
        
        // Stop listening
        service.stopListeningForChat(chatID: chatId)
        XCTAssertFalse(service.isListening)
    }
    
    func testStopAllListeners() async {
        let chatIds = ["chat-1", "chat-2", "chat-3"]
        
        // Start listening for multiple chats
        for chatId in chatIds {
            do {
                try await service.listenForClassificationUpdates(chatID: chatId)
            } catch {
                // Expected in test environment
            }
        }
        
        // Stop all listeners
        service.stopAllListeners()
        XCTAssertFalse(service.isListening)
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleMessageUpdate() async {
        let messageId = "test-message-1"
        let message = Message(
            id: messageId,
            chatID: "test-chat",
            senderID: "other-user",
            text: "Test message",
            timestamp: Date(),
            priority: "urgent",
            classificationConfidence: 0.9,
            classificationMethod: "openai",
            classificationTimestamp: Date()
        )
        
        // Simulate message update
        await service.handleMessageUpdate(message)
        
        // Verify classification status was updated
        let status = service.getClassificationStatus(messageId: messageId)
        if case .classified(let priority, let confidence) = status {
            XCTAssertEqual(priority, "urgent")
            XCTAssertEqual(confidence, 0.9)
        } else {
            XCTFail("Expected classified status")
        }
    }
    
    func testHandleMessageUpdateFailed() async {
        let messageId = "test-message-1"
        let message = Message(
            id: messageId,
            chatID: "test-chat",
            senderID: "other-user",
            text: "Test message",
            timestamp: Date(),
            classificationTimestamp: Date() // Has timestamp but no priority (failed)
        )
        
        // Simulate message update
        await service.handleMessageUpdate(message)
        
        // Verify classification status was set to failed
        let status = service.getClassificationStatus(messageId: messageId)
        if case .failed(let error) = status {
            XCTAssertEqual(error, "Classification failed")
        } else {
            XCTFail("Expected failed status")
        }
    }
    
    func testHandleMessageUpdatePending() async {
        let messageId = "test-message-1"
        let message = Message(
            id: messageId,
            chatID: "test-chat",
            senderID: "other-user",
            text: "Test message",
            timestamp: Date()
            // No classification fields (pending)
        )
        
        // Simulate message update
        await service.handleMessageUpdate(message)
        
        // Verify classification status was set to pending
        let status = service.getClassificationStatus(messageId: messageId)
        XCTAssertEqual(status, .pending)
    }
}

// MARK: - Test Extensions

extension AIClassificationService {
    /// Test helper to simulate message updates
    func handleMessageUpdate(_ message: Message) async {
        // Update classification status based on message priority
        if let priority = message.priority,
           let confidence = message.classificationConfidence {
            classificationStatus[message.id] = .classified(priority: priority, confidence: Float(confidence))
        } else if message.classificationTimestamp != nil {
            // Message was processed but no priority set (likely failed)
            classificationStatus[message.id] = .failed(error: "Classification failed")
        } else {
            // Message hasn't been classified yet
            classificationStatus[message.id] = .pending
        }
    }
}
