//
//  FocusModeClassificationTests.swift
//  MessageAITests
//
//  Tests for AI message classification system
//

import XCTest
import FirebaseFirestore
@testable import MessageAI

final class FocusModeClassificationTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // MARK: - Message Model Tests
    
    func testMessageModelWithClassificationFields() throws {
        // Test that Message model properly handles classification fields
        let message = Message(
            id: "test-message-id",
            chatID: "test-chat-id",
            senderID: "test-sender-id",
            text: "This is an urgent message!",
            timestamp: Date(),
            priority: "urgent",
            classificationConfidence: 0.9,
            classificationMethod: "openai",
            classificationTimestamp: Date()
        )
        
        XCTAssertEqual(message.priority, "urgent")
        XCTAssertEqual(message.classificationConfidence, 0.9)
        XCTAssertEqual(message.classificationMethod, "openai")
        XCTAssertNotNil(message.classificationTimestamp)
    }
    
    func testMessageModelWithoutClassificationFields() throws {
        // Test that Message model works without classification fields
        let message = Message(
            id: "test-message-id",
            chatID: "test-chat-id",
            senderID: "test-sender-id",
            text: "Regular message",
            timestamp: Date()
        )
        
        XCTAssertNil(message.priority)
        XCTAssertNil(message.classificationConfidence)
        XCTAssertNil(message.classificationMethod)
        XCTAssertNil(message.classificationTimestamp)
    }
    
    func testMessageModelFirestoreEncoding() throws {
        // Test that Message model properly encodes to Firestore
        let message = Message(
            id: "test-message-id",
            chatID: "test-chat-id",
            senderID: "test-sender-id",
            text: "Test message",
            timestamp: Date(),
            priority: "urgent",
            classificationConfidence: 0.8,
            classificationMethod: "keyword",
            classificationTimestamp: Date()
        )
        
        let encoder = Firestore.Encoder()
        let data = try encoder.encode(message)
        
        XCTAssertEqual(data["priority"] as? String, "urgent")
        XCTAssertEqual(data["classificationConfidence"] as? Double, 0.8)
        XCTAssertEqual(data["classificationMethod"] as? String, "keyword")
        XCTAssertNotNil(data["classificationTimestamp"])
    }
    
    func testMessageModelFirestoreDecoding() throws {
        // Test that Message model properly decodes from Firestore
        let timestamp = Timestamp(date: Date())
        let data: [String: Any] = [
            "id": "test-message-id",
            "chatID": "test-chat-id",
            "senderID": "test-sender-id",
            "text": "Test message",
            "timestamp": timestamp,
            "priority": "normal",
            "classificationConfidence": 0.7,
            "classificationMethod": "openai",
            "classificationTimestamp": timestamp,
            "readBy": [],
            "readAt": [:],
            "status": "sent",
            "isOffline": false,
            "retryCount": 0,
            "isOptimistic": false
        ]
        
        let decoder = Firestore.Decoder()
        let message = try decoder.decode(Message.self, from: data)
        
        XCTAssertEqual(message.priority, "normal")
        XCTAssertEqual(message.classificationConfidence, 0.7)
        XCTAssertEqual(message.classificationMethod, "openai")
        XCTAssertNotNil(message.classificationTimestamp)
    }
    
    // MARK: - ClassificationResult Model Tests
    
    func testClassificationResultInitialization() throws {
        let result = ClassificationResult(
            priority: "urgent",
            confidence: 0.9,
            method: "openai",
            processingTimeMs: 1500
        )
        
        XCTAssertEqual(result.priority, "urgent")
        XCTAssertEqual(result.confidence, 0.9)
        XCTAssertEqual(result.method, "openai")
        XCTAssertEqual(result.processingTimeMs, 1500)
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.isUrgent)
        XCTAssertTrue(result.isHighConfidence)
        XCTAssertFalse(result.needsReview)
    }
    
    func testClassificationResultValidation() throws {
        // Test valid result
        let validResult = ClassificationResult(
            priority: "normal",
            confidence: 0.8,
            method: "keyword",
            processingTimeMs: 500
        )
        XCTAssertTrue(validResult.isValid)
        
        // Test invalid priority
        let invalidPriority = ClassificationResult(
            priority: "invalid",
            confidence: 0.8,
            method: "openai",
            processingTimeMs: 500
        )
        XCTAssertFalse(invalidPriority.isValid)
        
        // Test invalid confidence
        let invalidConfidence = ClassificationResult(
            priority: "urgent",
            confidence: 1.5,
            method: "openai",
            processingTimeMs: 500
        )
        XCTAssertFalse(invalidConfidence.isValid)
        
        // Test invalid method
        let invalidMethod = ClassificationResult(
            priority: "normal",
            confidence: 0.8,
            method: "invalid",
            processingTimeMs: 500
        )
        XCTAssertFalse(invalidMethod.isValid)
    }
    
    func testClassificationResultConvenienceMethods() throws {
        // Test urgent classification
        let urgentResult = ClassificationResult(
            priority: "urgent",
            confidence: 0.9,
            method: "openai",
            processingTimeMs: 1000
        )
        XCTAssertTrue(urgentResult.isUrgent)
        XCTAssertTrue(urgentResult.isHighConfidence)
        XCTAssertFalse(urgentResult.needsReview)
        
        // Test normal classification with low confidence
        let lowConfidenceResult = ClassificationResult(
            priority: "normal",
            confidence: 0.6,
            method: "keyword",
            processingTimeMs: 200
        )
        XCTAssertFalse(lowConfidenceResult.isUrgent)
        XCTAssertFalse(lowConfidenceResult.isHighConfidence)
        XCTAssertTrue(lowConfidenceResult.needsReview)
        
        // Test high confidence normal
        let highConfidenceNormal = ClassificationResult(
            priority: "normal",
            confidence: 0.85,
            method: "openai",
            processingTimeMs: 800
        )
        XCTAssertFalse(highConfidenceNormal.isUrgent)
        XCTAssertTrue(highConfidenceNormal.isHighConfidence)
        XCTAssertFalse(highConfidenceNormal.needsReview)
    }
    
    // MARK: - Performance Tests
    
    func testMessageModelPerformance() throws {
        // Test that Message model operations are performant
        measure {
            for i in 0..<1000 {
                let message = Message(
                    id: "message-\(i)",
                    chatID: "chat-\(i)",
                    senderID: "sender-\(i)",
                    text: "Test message \(i)",
                    timestamp: Date(),
                    priority: i % 2 == 0 ? "urgent" : "normal",
                    classificationConfidence: Double.random(in: 0.0...1.0),
                    classificationMethod: i % 3 == 0 ? "openai" : "keyword",
                    classificationTimestamp: Date()
                )
                
                // Test encoding
                let encoder = Firestore.Encoder()
                _ = try? encoder.encode(message)
            }
        }
    }
    
    func testClassificationResultPerformance() throws {
        // Test that ClassificationResult operations are performant
        measure {
            for i in 0..<10000 {
                let result = ClassificationResult(
                    priority: i % 2 == 0 ? "urgent" : "normal",
                    confidence: Double.random(in: 0.0...1.0),
                    method: i % 3 == 0 ? "openai" : "keyword",
                    processingTimeMs: Int.random(in: 100...2000)
                )
                
                // Test validation and convenience methods
                _ = result.isValid
                _ = result.isUrgent
                _ = result.isHighConfidence
                _ = result.needsReview
            }
        }
    }
}
