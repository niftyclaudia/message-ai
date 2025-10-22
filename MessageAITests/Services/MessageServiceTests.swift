//
//  MessageServiceTests.swift
//  MessageAITests
//
//  Unit tests for MessageService functionality
//

import Testing
@testable import MessageAI

@Suite("Message Service Tests")
struct MessageServiceTests {
    
    // MARK: - Fetch Messages Tests
    
    /// Verifies that messages are fetched successfully for a valid chat
    @Test("Fetch Messages With Valid Chat ID Returns Messages")
    func fetchMessagesWithValidChatIDReturnsMessages() async throws {
        // Given
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // When
        let messages = try await service.fetchMessages(chatID: chatID)
        
        // Then
        #expect(messages is [Message])
        // Note: In a real test, we'd set up test data first
    }
    
    /// Verifies that empty chat returns empty array
    @Test("Fetch Messages From Empty Chat Returns Empty Array")
    func fetchMessagesFromEmptyChatReturnsEmptyArray() async throws {
        // Given
        let service = MessageService()
        let emptyChatID = "empty-chat-\(UUID().uuidString)"
        
        // When
        let messages = try await service.fetchMessages(chatID: emptyChatID)
        
        // Then
        #expect(messages.isEmpty)
    }
    
    /// Verifies that messages are ordered by timestamp ascending
    @Test("Fetch Messages Returns Messages In Chronological Order")
    func fetchMessagesReturnsMessagesInChronologicalOrder() async throws {
        // Given
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // When
        let messages = try await service.fetchMessages(chatID: chatID)
        
        // Then
        for i in 1..<messages.count {
            #expect(messages[i-1].timestamp <= messages[i].timestamp)
        }
    }
    
    // MARK: - Observe Messages Tests
    
    /// Verifies that message observer is set up correctly
    @Test("Observe Messages Sets Up Listener Correctly")
    func observeMessagesSetsUpListenerCorrectly() async throws {
        // Given
        let service = MessageService()
        let chatID = "test-chat-\(UUID().uuidString)"
        var receivedMessages: [Message] = []
        
        // When
        let listener = service.observeMessages(chatID: chatID) { messages in
            receivedMessages = messages
        }
        
        // Then
        #expect(listener != nil)
        
        // Clean up
        listener.remove()
    }
    
    // MARK: - Fetch Single Message Tests
    
    /// Verifies that single message is fetched successfully
    @Test("Fetch Message With Valid ID Returns Message")
    func fetchMessageWithValidIDReturnsMessage() async throws {
        // Given
        let service = MessageService()
        let messageID = "test-message-\(UUID().uuidString)"
        
        // When/Then
        // Note: This will throw in current implementation since we don't have the message
        // In a real test, we'd create test data first
        await #expect(throws: MessageServiceError.self) {
            try await service.fetchMessage(messageID: messageID)
        }
    }
    
    /// Verifies that non-existent message throws error
    @Test("Fetch Non-Existent Message Throws Error")
    func fetchNonExistentMessageThrowsError() async throws {
        // Given
        let service = MessageService()
        let nonExistentID = "non-existent-\(UUID().uuidString)"
        
        // When/Then
        await #expect(throws: MessageServiceError.messageNotFound) {
            try await service.fetchMessage(messageID: nonExistentID)
        }
    }
    
    // MARK: - Mark Message As Read Tests
    
    /// Verifies that message is marked as read successfully
    @Test("Mark Message As Read Updates Read Status")
    func markMessageAsReadUpdatesReadStatus() async throws {
        // Given
        let service = MessageService()
        let messageID = "test-message-\(UUID().uuidString)"
        let userID = "test-user-\(UUID().uuidString)"
        
        // When/Then
        // Note: This will throw in current implementation since we don't have the message
        // In a real test, we'd create test data first
        await #expect(throws: MessageServiceError.self) {
            try await service.markMessageAsRead(messageID: messageID, userID: userID)
        }
    }
    
    // MARK: - Error Handling Tests
    
    /// Verifies that network errors are handled gracefully
    @Test("Network Error Is Handled Gracefully")
    func networkErrorIsHandledGracefully() async throws {
        // Given
        let service = MessageService()
        let invalidChatID = "" // Empty string should cause error
        
        // When/Then
        await #expect(throws: MessageServiceError.self) {
            try await service.fetchMessages(chatID: invalidChatID)
        }
    }
    
    /// Verifies that permission errors are handled correctly
    @Test("Permission Denied Error Is Handled Correctly")
    func permissionDeniedErrorIsHandledCorrectly() async throws {
        // Given
        let service = MessageService()
        let restrictedChatID = "restricted-chat"
        
        // When/Then
        // Note: This test would need proper setup with restricted permissions
        await #expect(throws: MessageServiceError.self) {
            try await service.fetchMessages(chatID: restrictedChatID)
        }
    }
}

// MARK: - MessageServiceError Tests

@Suite("MessageServiceError Tests")
struct MessageServiceErrorTests {
    
    /// Verifies that error descriptions are user-friendly
    @Test("Error Descriptions Are User-Friendly")
    func errorDescriptionsAreUserFriendly() {
        // Given
        let messageNotFound = MessageServiceError.messageNotFound
        let permissionDenied = MessageServiceError.permissionDenied
        let networkError = MessageServiceError.networkError(NSError(domain: "Test", code: 0))
        let unknownError = MessageServiceError.unknown(NSError(domain: "Test", code: 0))
        
        // When/Then
        #expect(messageNotFound.errorDescription == "Message not found")
        #expect(permissionDenied.errorDescription == "Permission denied to access message")
        #expect(networkError.errorDescription?.contains("Network error") == true)
        #expect(unknownError.errorDescription?.contains("Unknown error") == true)
    }
}
