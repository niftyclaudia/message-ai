//
//  OfflineMessageServiceTests.swift
//  MessageAITests
//
//  Unit tests for offline message service
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for OfflineMessageService
/// - Note: Tests offline message queue management with 3-message limit
struct OfflineMessageServiceTests {
    
    // MARK: - Test Properties
    
    private var service: OfflineMessageService!
    
    // MARK: - Setup
    
    init() {
        // Create fresh service for each test
        service = OfflineMessageService()
        service.clearOfflineMessages() // Ensure clean state
    }
    
    // MARK: - Queue Management Tests
    
    @Test("Queue Message Offline Successfully")
    func queueMessageOfflineSuccessfully() async throws {
        // Given
        let chatID = "test-chat"
        let text = "Test message"
        let senderID = "test-user"
        
        // When
        let messageID = try await service.queueMessageOffline(
            chatID: chatID,
            text: text,
            senderID: senderID
        )
        
        // Then
        #expect(!messageID.isEmpty)
        #expect(service.getQueuedMessageCount() == 1)
        #expect(service.getOfflineMessages().count == 1)
        
        let queuedMessage = service.getOfflineMessages().first!
        #expect(queuedMessage.id == messageID)
        #expect(queuedMessage.chatID == chatID)
        #expect(queuedMessage.text == text)
        #expect(queuedMessage.senderID == senderID)
        #expect(queuedMessage.status == .queued)
    }
    
    @Test("Queue Size Limit Enforced")
    func queueSizeLimitEnforced() async throws {
        // Given
        let chatID = "test-chat"
        let senderID = "test-user"
        
        // When - Add 4 messages (exceeds 3-message limit)
        for i in 1...4 {
            _ = try await service.queueMessageOffline(
                chatID: chatID,
                text: "Message \(i)",
                senderID: senderID
            )
        }
        
        // Then - Should only have 3 messages (oldest removed)
        #expect(service.getQueuedMessageCount() == 3)
        #expect(service.isQueueFull == true)
        
        let messages = service.getOfflineMessages()
        #expect(messages.count == 3)
        
        // First message should be removed (oldest)
        let messageTexts = messages.map { $0.text }
        #expect(!messageTexts.contains("Message 1"))
        #expect(messageTexts.contains("Message 2"))
        #expect(messageTexts.contains("Message 3"))
        #expect(messageTexts.contains("Message 4"))
    }
    
    @Test("Clear Offline Messages")
    func clearOfflineMessages() async throws {
        // Given - Add some messages
        for i in 1...3 {
            _ = try await service.queueMessageOffline(
                chatID: "test-chat",
                text: "Message \(i)",
                senderID: "test-user"
            )
        }
        #expect(service.getQueuedMessageCount() == 3)
        
        // When
        service.clearOfflineMessages()
        
        // Then
        #expect(service.getQueuedMessageCount() == 0)
        #expect(service.getOfflineMessages().isEmpty)
        #expect(service.isQueueFull == false)
    }
    
    @Test("Update Message Status")
    func updateMessageStatus() async throws {
        // Given
        let messageID = try await service.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        
        // When
        service.updateMessageStatus(messageID: messageID, status: .sending)
        
        // Then
        let message = service.getOfflineMessages().first!
        #expect(message.status == .sending)
    }
    
    @Test("Remove Offline Message")
    func removeOfflineMessage() async throws {
        // Given
        let messageID = try await service.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        #expect(service.getQueuedMessageCount() == 1)
        
        // When
        service.removeOfflineMessage(messageID: messageID)
        
        // Then
        #expect(service.getQueuedMessageCount() == 0)
        #expect(service.getOfflineMessages().isEmpty)
    }
    
    @Test("Get Messages For Chat")
    func getMessagesForChat() async throws {
        // Given
        let chatID1 = "chat-1"
        let chatID2 = "chat-2"
        
        _ = try await service.queueMessageOffline(
            chatID: chatID1,
            text: "Message 1",
            senderID: "test-user"
        )
        _ = try await service.queueMessageOffline(
            chatID: chatID2,
            text: "Message 2",
            senderID: "test-user"
        )
        _ = try await service.queueMessageOffline(
            chatID: chatID1,
            text: "Message 3",
            senderID: "test-user"
        )
        
        // When
        let chat1Messages = service.getMessagesForChat(chatID: chatID1)
        let chat2Messages = service.getMessagesForChat(chatID: chatID2)
        
        // Then
        #expect(chat1Messages.count == 2)
        #expect(chat2Messages.count == 1)
        #expect(chat1Messages.allSatisfy { $0.chatID == chatID1 })
        #expect(chat2Messages.allSatisfy { $0.chatID == chatID2 })
    }
    
    @Test("Retry Count Management")
    func retryCountManagement() async throws {
        // Given
        let messageID = try await service.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        
        // When - Increment retry count
        service.incrementRetryCount(messageID: messageID)
        
        // Then
        let message = service.getOfflineMessages().first!
        #expect(message.retryCount == 1)
        #expect(message.lastAttempt != nil)
    }
    
    @Test("Retryable Messages Detection")
    func retryableMessagesDetection() async throws {
        // Given
        let messageID = try await service.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        
        // When - Increment retry count to max
        for _ in 1...3 {
            service.incrementRetryCount(messageID: messageID)
        }
        
        // Then
        #expect(service.hasRetryableMessages() == false)
        #expect(service.getRetryableMessages().isEmpty)
        
        // Remove expired messages
        service.removeExpiredMessages()
        #expect(service.getQueuedMessageCount() == 0)
    }
    
    @Test("Queue Space Detection")
    func queueSpaceDetection() async throws {
        // Given - Empty queue
        #expect(service.hasQueueSpace() == true)
        #expect(service.getMaxQueueSize() == 3)
        
        // When - Add 2 messages
        for i in 1...2 {
            _ = try await service.queueMessageOffline(
                chatID: "test-chat",
                text: "Message \(i)",
                senderID: "test-user"
            )
        }
        
        // Then
        #expect(service.hasQueueSpace() == true)
        #expect(service.getQueuedMessageCount() == 2)
        
        // When - Add one more message (queue full)
        _ = try await service.queueMessageOffline(
            chatID: "test-chat",
            text: "Message 3",
            senderID: "test-user"
        )
        
        // Then
        #expect(service.hasQueueSpace() == false)
        #expect(service.isQueueFull == true)
    }
    
    @Test("Message Status Counting")
    func messageStatusCounting() async throws {
        // Given
        let messageID1 = try await service.queueMessageOffline(
            chatID: "test-chat",
            text: "Message 1",
            senderID: "test-user"
        )
        let messageID2 = try await service.queueMessageOffline(
            chatID: "test-chat",
            text: "Message 2",
            senderID: "test-user"
        )
        
        // When - Update statuses
        service.updateMessageStatus(messageID: messageID1, status: .sending)
        service.updateMessageStatus(messageID: messageID2, status: .queued)
        
        // Then
        #expect(service.getMessageCount(with: .queued) == 1)
        #expect(service.getMessageCount(with: .sending) == 1)
        #expect(service.getMessageCount(with: .sent) == 0)
    }
}
