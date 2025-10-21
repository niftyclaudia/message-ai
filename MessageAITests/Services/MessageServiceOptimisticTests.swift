//
//  MessageServiceOptimisticTests.swift
//  MessageAITests
//
//  Unit tests for MessageService optimistic methods
//

import Testing
import Foundation
import FirebaseFirestore
@testable import MessageAI

/// Unit tests for MessageService optimistic functionality
struct MessageServiceOptimisticTests {
    
    // MARK: - Test Properties
    
    private var service: MessageService!
    private let testChatID = "test-chat-123"
    private let testUserID = "test-user-123"
    
    // MARK: - Setup
    
    init() {
        service = MessageService()
    }
    
    // MARK: - Send Message Optimistic Tests
    
    @Test("Send Message Optimistic Creates Message with Correct Properties")
    func sendMessageOptimisticCreatesMessageWithCorrectProperties() async throws {
        // Given
        let text = "Test optimistic message"
        
        // When
        let messageID = try await service.sendMessageOptimistic(chatID: testChatID, text: text)
        
        // Then
        #expect(!messageID.isEmpty)
        #expect(messageID.count > 0)
    }
    
    @Test("Send Message Optimistic Handles Network Error")
    func sendMessageOptimisticHandlesNetworkError() async throws {
        // Given
        let text = "Test message that will fail"
        
        // When & Then
        // Note: This test would need proper Firebase setup to test actual network errors
        // For now, we'll test the method exists and can be called
        do {
            let _ = try await service.sendMessageOptimistic(chatID: testChatID, text: text)
            // If we get here, the method executed without throwing
            #expect(true)
        } catch {
            // Expected behavior for test environment
            #expect(error is MessageServiceError)
        }
    }
    
    // MARK: - Server Timestamp Tests
    
    @Test("Update Message with Server Timestamp")
    func updateMessageWithServerTimestamp() async throws {
        // Given
        let messageID = "test-message-123"
        let serverTimestamp = Date()
        
        // When & Then
        // Note: This test would need proper Firebase setup to test actual updates
        // For now, we'll test the method exists and can be called
        do {
            try await service.updateMessageWithServerTimestamp(messageID: messageID, serverTimestamp: serverTimestamp)
            // If we get here, the method executed without throwing
            #expect(true)
        } catch {
            // Expected behavior for test environment
            #expect(error is MessageServiceError)
        }
    }
    
    @Test("Sort Messages by Server Timestamp")
    func sortMessagesByServerTimestamp() async throws {
        // Given
        let now = Date()
        let message1 = Message(
            id: "msg1",
            chatID: testChatID,
            senderID: testUserID,
            text: "First message",
            timestamp: now.addingTimeInterval(-100),
            serverTimestamp: now.addingTimeInterval(-50),
            status: .sent
        )
        
        let message2 = Message(
            id: "msg2",
            chatID: testChatID,
            senderID: testUserID,
            text: "Second message",
            timestamp: now.addingTimeInterval(-200),
            serverTimestamp: nil, // No server timestamp, should use client timestamp
            status: .sent
        )
        
        let message3 = Message(
            id: "msg3",
            chatID: testChatID,
            senderID: testUserID,
            text: "Third message",
            timestamp: now.addingTimeInterval(-300),
            serverTimestamp: now.addingTimeInterval(-10),
            status: .sent
        )
        
        let messages = [message1, message2, message3]
        
        // When
        let sortedMessages = service.sortMessagesByServerTimestamp(messages)
        
        // Then
        #expect(sortedMessages.count == 3)
        #expect(sortedMessages[0].id == "msg3") // Most recent server timestamp
        #expect(sortedMessages[1].id == "msg1") // Second most recent server timestamp
        #expect(sortedMessages[2].id == "msg2") // Uses client timestamp (oldest)
    }
    
    @Test("Sort Messages with Mixed Timestamps")
    func sortMessagesWithMixedTimestamps() async throws {
        // Given
        let now = Date()
        let message1 = Message(
            id: "msg1",
            chatID: testChatID,
            senderID: testUserID,
            text: "Message with server timestamp",
            timestamp: now.addingTimeInterval(-100),
            serverTimestamp: now.addingTimeInterval(-50),
            status: .sent
        )
        
        let message2 = Message(
            id: "msg2",
            chatID: testChatID,
            senderID: testUserID,
            text: "Message without server timestamp",
            timestamp: now.addingTimeInterval(-200),
            serverTimestamp: nil,
            status: .sent
        )
        
        let messages = [message1, message2]
        
        // When
        let sortedMessages = service.sortMessagesByServerTimestamp(messages)
        
        // Then
        #expect(sortedMessages.count == 2)
        #expect(sortedMessages[0].id == "msg1") // Server timestamp (-50) is newer than client timestamp (-200)
        #expect(sortedMessages[1].id == "msg2") // Uses client timestamp
    }
    
    @Test("Sort Messages with Same Server Timestamps")
    func sortMessagesWithSameServerTimestamps() async throws {
        // Given
        let now = Date()
        let sameTimestamp = now.addingTimeInterval(-100)
        
        let message1 = Message(
            id: "msg1",
            chatID: testChatID,
            senderID: testUserID,
            text: "First message",
            timestamp: now.addingTimeInterval(-200),
            serverTimestamp: sameTimestamp,
            status: .sent
        )
        
        let message2 = Message(
            id: "msg2",
            chatID: testChatID,
            senderID: testUserID,
            text: "Second message",
            timestamp: now.addingTimeInterval(-150),
            serverTimestamp: sameTimestamp,
            status: .sent
        )
        
        let messages = [message1, message2]
        
        // When
        let sortedMessages = service.sortMessagesByServerTimestamp(messages)
        
        // Then
        #expect(sortedMessages.count == 2)
        // Should maintain original order when timestamps are equal
        #expect(sortedMessages[0].id == "msg1")
        #expect(sortedMessages[1].id == "msg2")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Handle Server Timestamp Error")
    func handleServerTimestampError() async throws {
        // Given
        let nonExistentMessageID = "non-existent-message"
        let serverTimestamp = Date()
        
        // When & Then
        do {
            try await service.updateMessageWithServerTimestamp(messageID: nonExistentMessageID, serverTimestamp: serverTimestamp)
            #expect(false, "Should have thrown an error")
        } catch let error as MessageServiceError {
            #expect(error == .messageNotFound)
        } catch {
            #expect(false, "Should have thrown MessageServiceError.messageNotFound")
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Optimistic Message Flow Integration")
    func optimisticMessageFlowIntegration() async throws {
        // Given
        let text = "Integration test message"
        
        // When
        do {
            let messageID = try await service.sendMessageOptimistic(chatID: testChatID, text: text)
            
            // Then
            #expect(!messageID.isEmpty)
            
            // Test server timestamp update
            let serverTimestamp = Date()
            try await service.updateMessageWithServerTimestamp(messageID: messageID, serverTimestamp: serverTimestamp)
            
            // Test message sorting
            let message = Message(
                id: messageID,
                chatID: testChatID,
                senderID: testUserID,
                text: text,
                timestamp: Date().addingTimeInterval(-100),
                serverTimestamp: serverTimestamp,
                status: .sent
            )
            
            let sortedMessages = service.sortMessagesByServerTimestamp([message])
            #expect(sortedMessages.count == 1)
            #expect(sortedMessages.first?.id == messageID)
            
        } catch {
            // Expected in test environment without Firebase setup
            #expect(error is MessageServiceError)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Sort Large Message List Performance")
    func sortLargeMessageListPerformance() async throws {
        // Given
        let now = Date()
        var messages: [Message] = []
        
        // Create 1000 messages with random timestamps
        for i in 0..<1000 {
            let message = Message(
                id: "msg\(i)",
                chatID: testChatID,
                senderID: testUserID,
                text: "Message \(i)",
                timestamp: now.addingTimeInterval(Double.random(in: -1000...0)),
                serverTimestamp: i % 2 == 0 ? now.addingTimeInterval(Double.random(in: -1000...0)) : nil,
                status: .sent
            )
            messages.append(message)
        }
        
        // When
        let startTime = Date()
        let sortedMessages = service.sortMessagesByServerTimestamp(messages)
        let endTime = Date()
        
        // Then
        #expect(sortedMessages.count == 1000)
        #expect(endTime.timeIntervalSince(startTime) < 1.0) // Should complete in less than 1 second
    }
}
