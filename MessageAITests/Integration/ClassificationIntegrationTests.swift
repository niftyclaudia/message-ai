//
//  ClassificationIntegrationTests.swift
//  MessageAITests
//
//  Integration tests for message classification system
//

import XCTest
import FirebaseFirestore
import FirebaseAuth
@testable import MessageAI

final class ClassificationIntegrationTests: XCTestCase {
    
    var db: Firestore!
    var testUser: User!
    
    override func setUpWithError() throws {
        // Configure Firebase for testing
        db = Firestore.firestore()
        db.settings.isPersistenceEnabled = false
        
        // Create test user (mock authentication)
        // Note: In real tests, you would use Firebase Auth testing utilities
        testUser = User(uid: "test-user-id", email: "test@example.com")
    }
    
    override func tearDownWithError() throws {
        // Clean up test data
        db = nil
        testUser = nil
    }
    
    // MARK: - End-to-End Classification Tests
    
    func testMessageCreationTriggersClassification() async throws {
        // This test would verify that creating a message in Firestore
        // triggers the classification Cloud Function
        
        let messageID = "test-message-\(UUID().uuidString)"
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Create a message that should be classified as urgent
        let urgentMessage = Message(
            id: messageID,
            chatID: chatID,
            senderID: testUser.uid,
            text: "This is urgent! Please respond ASAP",
            timestamp: Date()
        )
        
        // Write message to Firestore
        let messageRef = db.collection("messages").document(messageID)
        try messageRef.setData(from: urgentMessage)
        
        // Wait for classification to complete (up to 5 seconds)
        let expectation = XCTestExpectation(description: "Message classification completed")
        var attempts = 0
        let maxAttempts = 50 // 5 seconds with 100ms intervals
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            attempts += 1
            
            Task {
                do {
                    let snapshot = try await messageRef.getDocument()
                    if let data = snapshot.data(),
                       let priority = data["priority"] as? String,
                       let confidence = data["classificationConfidence"] as? Double {
                        
                        XCTAssertEqual(priority, "urgent")
                        XCTAssertGreaterThan(confidence, 0.5)
                        expectation.fulfill()
                        timer.invalidate()
                    }
                } catch {
                    // Continue waiting
                }
                
                if attempts >= maxAttempts {
                    timer.invalidate()
                    XCTFail("Classification did not complete within timeout")
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 6.0)
        
        // Clean up
        try await messageRef.delete()
    }
    
    func testNormalMessageClassification() async throws {
        let messageID = "test-normal-message-\(UUID().uuidString)"
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Create a message that should be classified as normal
        let normalMessage = Message(
            id: messageID,
            chatID: chatID,
            senderID: testUser.uid,
            text: "Thanks for the update. Have a good day!",
            timestamp: Date()
        )
        
        // Write message to Firestore
        let messageRef = db.collection("messages").document(messageID)
        try messageRef.setData(from: normalMessage)
        
        // Wait for classification
        let expectation = XCTestExpectation(description: "Normal message classification completed")
        var attempts = 0
        let maxAttempts = 50
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            attempts += 1
            
            Task {
                do {
                    let snapshot = try await messageRef.getDocument()
                    if let data = snapshot.data(),
                       let priority = data["priority"] as? String {
                        
                        XCTAssertEqual(priority, "normal")
                        expectation.fulfill()
                        timer.invalidate()
                    }
                } catch {
                    // Continue waiting
                }
                
                if attempts >= maxAttempts {
                    timer.invalidate()
                    XCTFail("Classification did not complete within timeout")
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 6.0)
        
        // Clean up
        try await messageRef.delete()
    }
    
    func testClassificationLogging() async throws {
        // Test that classification results are properly logged
        let messageID = "test-logging-message-\(UUID().uuidString)"
        let chatID = "test-chat-\(UUID().uuidString)"
        
        let testMessage = Message(
            id: messageID,
            chatID: chatID,
            senderID: testUser.uid,
            text: "Test message for logging",
            timestamp: Date()
        )
        
        // Write message to Firestore
        let messageRef = db.collection("messages").document(messageID)
        try messageRef.setData(from: testMessage)
        
        // Wait for classification
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        // Check classification logs
        let logsQuery = db.collection("classificationLogs")
            .whereField("messageID", isEqualTo: messageID)
            .limit(1)
        
        let logsSnapshot = try await logsQuery.getDocuments()
        XCTAssertGreaterThan(logsSnapshot.documents.count, 0, "Classification log should be created")
        
        if let logDoc = logsSnapshot.documents.first {
            let logData = logDoc.data()
            XCTAssertEqual(logData["messageID"] as? String, messageID)
            XCTAssertNotNil(logData["classificationResult"])
            XCTAssertNotNil(logData["confidence"])
            XCTAssertNotNil(logData["method"])
            XCTAssertNotNil(logData["processingTimeMs"])
        }
        
        // Clean up
        try await messageRef.delete()
        
        // Clean up logs
        for doc in logsSnapshot.documents {
            try await doc.reference.delete()
        }
    }
    
    func testMultipleMessagesClassification() async throws {
        // Test that multiple messages can be classified simultaneously
        let chatID = "test-chat-\(UUID().uuidString)"
        let messageCount = 5
        var messageRefs: [DocumentReference] = []
        
        // Create multiple messages
        for i in 0..<messageCount {
            let messageID = "test-multi-message-\(i)-\(UUID().uuidString)"
            let message = Message(
                id: messageID,
                chatID: chatID,
                senderID: testUser.uid,
                text: i % 2 == 0 ? "Urgent message \(i)!" : "Normal message \(i)",
                timestamp: Date()
            )
            
            let messageRef = db.collection("messages").document(messageID)
            try messageRef.setData(from: message)
            messageRefs.append(messageRef)
        }
        
        // Wait for all classifications to complete
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Verify all messages were classified
        for messageRef in messageRefs {
            let snapshot = try await messageRef.getDocument()
            XCTAssertTrue(snapshot.exists, "Message should exist")
            
            if let data = snapshot.data() {
                XCTAssertNotNil(data["priority"], "Message should have priority")
                XCTAssertNotNil(data["classificationConfidence"], "Message should have confidence")
                XCTAssertNotNil(data["classificationMethod"], "Message should have method")
                XCTAssertNotNil(data["classificationTimestamp"], "Message should have timestamp")
            }
        }
        
        // Clean up
        for messageRef in messageRefs {
            try await messageRef.delete()
        }
    }
    
    func testClassificationPerformance() async throws {
        // Test that classification completes within performance targets
        let messageID = "test-performance-message-\(UUID().uuidString)"
        let chatID = "test-chat-\(UUID().uuidString)"
        
        let testMessage = Message(
            id: messageID,
            chatID: chatID,
            senderID: testUser.uid,
            text: "Performance test message",
            timestamp: Date()
        )
        
        let startTime = Date()
        
        // Write message to Firestore
        let messageRef = db.collection("messages").document(messageID)
        try messageRef.setData(from: testMessage)
        
        // Wait for classification
        let expectation = XCTestExpectation(description: "Performance test classification completed")
        var attempts = 0
        let maxAttempts = 30 // 3 seconds with 100ms intervals
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            attempts += 1
            
            Task {
                do {
                    let snapshot = try await messageRef.getDocument()
                    if let data = snapshot.data(),
                       let priority = data["priority"] as? String {
                        
                        let endTime = Date()
                        let processingTime = endTime.timeIntervalSince(startTime)
                        
                        // Classification should complete within 3 seconds
                        XCTAssertLessThan(processingTime, 3.0, "Classification should complete within 3 seconds")
                        expectation.fulfill()
                        timer.invalidate()
                    }
                } catch {
                    // Continue waiting
                }
                
                if attempts >= maxAttempts {
                    timer.invalidate()
                    XCTFail("Classification did not complete within timeout")
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 4.0)
        
        // Clean up
        try await messageRef.delete()
    }
}

// Mock User class for testing
class User {
    let uid: String
    let email: String
    
    init(uid: String, email: String) {
        self.uid = uid
        self.email = email
    }
}
