//
//  ClassificationFeedbackTests.swift
//  MessageAITests
//
//  Unit tests for ClassificationFeedback model
//

import XCTest
@testable import MessageAI

class ClassificationFeedbackTests: XCTestCase {
    
    // MARK: - ClassificationFeedback Tests
    
    func testClassificationFeedbackInitialization() {
        let feedback = ClassificationFeedback(
            messageId: "test-message-1",
            userId: "test-user-1",
            originalPriority: "normal",
            suggestedPriority: "urgent",
            feedbackReason: "This is clearly urgent"
        )
        
        XCTAssertEqual(feedback.messageId, "test-message-1")
        XCTAssertEqual(feedback.userId, "test-user-1")
        XCTAssertEqual(feedback.originalPriority, "normal")
        XCTAssertEqual(feedback.suggestedPriority, "urgent")
        XCTAssertEqual(feedback.feedbackReason, "This is clearly urgent")
        XCTAssertTrue(feedback.isValid)
    }
    
    func testClassificationFeedbackWithoutReason() {
        let feedback = ClassificationFeedback(
            messageId: "test-message-1",
            userId: "test-user-1",
            originalPriority: "urgent",
            suggestedPriority: "normal"
        )
        
        XCTAssertNil(feedback.feedbackReason)
        XCTAssertTrue(feedback.isValid)
    }
    
    func testClassificationFeedbackValidation() {
        // Valid feedback
        let validFeedback = ClassificationFeedback(
            messageId: "test-message-1",
            userId: "test-user-1",
            originalPriority: "urgent",
            suggestedPriority: "normal"
        )
        XCTAssertTrue(validFeedback.isValid)
        
        // Invalid feedback - empty messageId
        let invalidMessageId = ClassificationFeedback(
            messageId: "",
            userId: "test-user-1",
            originalPriority: "urgent",
            suggestedPriority: "normal"
        )
        XCTAssertFalse(invalidMessageId.isValid)
        
        // Invalid feedback - empty userId
        let invalidUserId = ClassificationFeedback(
            messageId: "test-message-1",
            userId: "",
            originalPriority: "urgent",
            suggestedPriority: "normal"
        )
        XCTAssertFalse(invalidUserId.isValid)
        
        // Invalid feedback - invalid original priority
        let invalidOriginalPriority = ClassificationFeedback(
            messageId: "test-message-1",
            userId: "test-user-1",
            originalPriority: "invalid",
            suggestedPriority: "normal"
        )
        XCTAssertFalse(invalidOriginalPriority.isValid)
        
        // Invalid feedback - invalid suggested priority
        let invalidSuggestedPriority = ClassificationFeedback(
            messageId: "test-message-1",
            userId: "test-user-1",
            originalPriority: "normal",
            suggestedPriority: "invalid"
        )
        XCTAssertFalse(invalidSuggestedPriority.isValid)
    }
    
    func testClassificationFeedbackCodable() throws {
        let originalFeedback = ClassificationFeedback(
            messageId: "test-message-1",
            userId: "test-user-1",
            originalPriority: "normal",
            suggestedPriority: "urgent",
            feedbackReason: "This is clearly urgent"
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalFeedback)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedFeedback = try decoder.decode(ClassificationFeedback.self, from: data)
        
        XCTAssertEqual(decodedFeedback.messageId, originalFeedback.messageId)
        XCTAssertEqual(decodedFeedback.userId, originalFeedback.userId)
        XCTAssertEqual(decodedFeedback.originalPriority, originalFeedback.originalPriority)
        XCTAssertEqual(decodedFeedback.suggestedPriority, originalFeedback.suggestedPriority)
        XCTAssertEqual(decodedFeedback.feedbackReason, originalFeedback.feedbackReason)
    }
    
    // MARK: - ClassificationStatus Tests
    
    func testClassificationStatusPending() {
        let status = ClassificationStatus.pending
        
        // Test equality
        XCTAssertEqual(status, .pending)
        
        // Test codable
        let encoded = try! JSONEncoder().encode(status)
        let decoded = try! JSONDecoder().decode(ClassificationStatus.self, from: encoded)
        XCTAssertEqual(decoded, .pending)
    }
    
    func testClassificationStatusClassified() {
        let status = ClassificationStatus.classified(priority: "urgent", confidence: 0.9)
        
        // Test equality
        XCTAssertEqual(status, .classified(priority: "urgent", confidence: 0.9))
        XCTAssertNotEqual(status, .classified(priority: "normal", confidence: 0.9))
        XCTAssertNotEqual(status, .classified(priority: "urgent", confidence: 0.8))
        
        // Test codable
        let encoded = try! JSONEncoder().encode(status)
        let decoded = try! JSONDecoder().decode(ClassificationStatus.self, from: encoded)
        
        if case .classified(let priority, let confidence) = decoded {
            XCTAssertEqual(priority, "urgent")
            XCTAssertEqual(confidence, 0.9)
        } else {
            XCTFail("Expected classified status")
        }
    }
    
    func testClassificationStatusFailed() {
        let status = ClassificationStatus.failed(error: "Network error")
        
        // Test equality
        XCTAssertEqual(status, .failed(error: "Network error"))
        XCTAssertNotEqual(status, .failed(error: "Different error"))
        
        // Test codable
        let encoded = try! JSONEncoder().encode(status)
        let decoded = try! JSONDecoder().decode(ClassificationStatus.self, from: encoded)
        
        if case .failed(let error) = decoded {
            XCTAssertEqual(error, "Network error")
        } else {
            XCTFail("Expected failed status")
        }
    }
    
    func testClassificationStatusFeedbackSubmitted() {
        let status = ClassificationStatus.feedbackSubmitted
        
        // Test equality
        XCTAssertEqual(status, .feedbackSubmitted)
        
        // Test codable
        let encoded = try! JSONEncoder().encode(status)
        let decoded = try! JSONDecoder().decode(ClassificationStatus.self, from: encoded)
        XCTAssertEqual(decoded, .feedbackSubmitted)
    }
    
    // MARK: - ClassificationRetryRequest Tests
    
    func testClassificationRetryRequestInitialization() {
        let request = ClassificationRetryRequest(
            messageId: "test-message-1",
            userId: "test-user-1",
            reason: "User requested retry"
        )
        
        XCTAssertEqual(request.messageId, "test-message-1")
        XCTAssertEqual(request.userId, "test-user-1")
        XCTAssertEqual(request.reason, "User requested retry")
    }
    
    func testClassificationRetryRequestWithoutReason() {
        let request = ClassificationRetryRequest(
            messageId: "test-message-1",
            userId: "test-user-1"
        )
        
        XCTAssertNil(request.reason)
    }
    
    func testClassificationRetryRequestCodable() throws {
        let originalRequest = ClassificationRetryRequest(
            messageId: "test-message-1",
            userId: "test-user-1",
            reason: "User requested retry"
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalRequest)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedRequest = try decoder.decode(ClassificationRetryRequest.self, from: data)
        
        XCTAssertEqual(decodedRequest.messageId, originalRequest.messageId)
        XCTAssertEqual(decodedRequest.userId, originalRequest.userId)
        XCTAssertEqual(decodedRequest.reason, originalRequest.reason)
    }
    
    // MARK: - ClassificationError Tests
    
    func testClassificationErrorDescriptions() {
        let networkError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test network error"])
        
        let errors: [ClassificationError] = [
            .networkError(networkError),
            .invalidMessageId,
            .invalidPriority("invalid"),
            .feedbackSubmissionFailed,
            .retryFailed,
            .userNotAuthenticated,
            .messageNotFound,
            .rateLimitExceeded
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testClassificationErrorNetworkError() {
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test network error"])
        let error = ClassificationError.networkError(underlyingError)
        
        XCTAssertEqual(error.errorDescription, "Network error: Test network error")
    }
    
    func testClassificationErrorInvalidPriority() {
        let error = ClassificationError.invalidPriority("invalid")
        XCTAssertEqual(error.errorDescription, "Invalid priority: invalid. Must be 'urgent' or 'normal'")
    }
}
