//
//  MessageServiceRealTimeTests.swift
//  MessageAITests
//
//  Unit tests for MessageService real-time messaging functionality
//

import Testing
import Foundation
@testable import MessageAI

/// Tests for MessageService real-time messaging features
struct MessageServiceRealTimeTests {
    
    @Test("MessageService Can Queue Messages Offline")
    func messageServiceCanQueueMessagesOffline() async throws {
        // Given: A MessageService
        let service = MessageService()
        let chatID = "test-chat"
        let messageText = "Test offline message"
        
        // When: Queuing a message
        let messageID = try await service.queueMessage(chatID: chatID, text: messageText)
        
        // Then: Message should be queued
        #expect(!messageID.isEmpty)
        
        let queuedMessages = service.getQueuedMessages()
        #expect(queuedMessages.count == 1)
        #expect(queuedMessages.first?.id == messageID)
        #expect(queuedMessages.first?.text == messageText)
        #expect(queuedMessages.first?.chatID == chatID)
    }
    
    @Test("MessageService Can Get Queued Messages")
    func messageServiceCanGetQueuedMessages() async throws {
        // Given: A MessageService with queued messages
        let service = MessageService()
        let chatID = "test-chat"
        
        // When: Queuing multiple messages
        let messageID1 = try await service.queueMessage(chatID: chatID, text: "Message 1")
        let messageID2 = try await service.queueMessage(chatID: chatID, text: "Message 2")
        
        // Then: Should return all queued messages
        let queuedMessages = service.getQueuedMessages()
        #expect(queuedMessages.count == 2)
        #expect(queuedMessages.contains { $0.id == messageID1 })
        #expect(queuedMessages.contains { $0.id == messageID2 })
    }
    
    @Test("OfflineMessage Can Convert To Message")
    func offlineMessageCanConvertToMessage() {
        // Given: An OfflineMessage
        let offlineMessage = OfflineMessage(
            id: "test-id",
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user",
            timestamp: Date(),
            status: .queued
        )
        
        // When: Converting to Message
        let message = offlineMessage.toMessage()
        
        // Then: Should have correct properties
        #expect(message.id == "test-id")
        #expect(message.chatID == "test-chat")
        #expect(message.text == "Test message")
        #expect(message.senderID == "test-user")
        #expect(message.status == .queued)
        #expect(message.isOffline == true)
    }
    
    @Test("Message Can Convert To OfflineMessage")
    func messageCanConvertToOfflineMessage() {
        // Given: A Message
        let message = Message(
            id: "test-id",
            chatID: "test-chat",
            senderID: "test-user",
            text: "Test message",
            timestamp: Date(),
            readBy: ["test-user"],
            status: .sending,
            senderName: nil,
            isOffline: true,
            retryCount: 0
        )
        
        // When: Converting to OfflineMessage
        let offlineMessage = OfflineMessage.from(message: message)
        
        // Then: Should have correct properties
        #expect(offlineMessage.id == "test-id")
        #expect(offlineMessage.chatID == "test-chat")
        #expect(offlineMessage.text == "Test message")
        #expect(offlineMessage.senderID == "test-user")
    }
    
    @Test("MessageService Error Cases Are Handled")
    func messageServiceErrorCasesAreHandled() {
        // Given: MessageServiceError cases
        let errors: [MessageServiceError] = [
            .messageNotFound,
            .permissionDenied,
            .networkError(NSError(domain: "test", code: 1)),
            .offlineQueueFull,
            .retryLimitExceeded,
            .unknown(NSError(domain: "test", code: 2))
        ]
        
        // When: Getting error descriptions
        let descriptions = errors.compactMap { $0.errorDescription }
        
        // Then: All should have descriptions
        #expect(descriptions.count == errors.count)
        #expect(descriptions.allSatisfy { !$0.isEmpty })
    }
}
