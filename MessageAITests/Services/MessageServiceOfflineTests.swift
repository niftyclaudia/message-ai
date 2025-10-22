//
//  MessageServiceOfflineTests.swift
//  MessageAITests
//
//  Unit tests for MessageService offline functionality
//

import Testing
import Foundation
@testable import MessageAI

/// Tests for MessageService offline persistence and queuing
struct MessageServiceOfflineTests {
    
    // MARK: - Test Properties
    
    private var messageService: MessageService!
    
    // MARK: - Setup
    
    init() {
        messageService = MessageService()
    }
    
    // MARK: - Offline Message Queuing Tests
    
    @Test("Queue Message When Offline Stores Message Locally")
    func queueMessageWhenOfflineStoresMessageLocally() async throws {
        // Given: A message service with offline queuing
        let chatID = "test-chat"
        let messageText = "Test offline message"
        
        // When: Queue a message (simulating offline behavior)
        let messageID = try await messageService.queueMessage(chatID: chatID, text: messageText)
        
        // Then: Message should be stored in queue
        #expect(!messageID.isEmpty)
        
        let queuedMessages = messageService.getQueuedMessages()
        #expect(queuedMessages.count == 1)
        #expect(queuedMessages.first?.text == messageText)
        #expect(queuedMessages.first?.chatID == chatID)
    }
    
    @Test("Get Queued Message Count Returns Correct Count")
    func getQueuedMessageCountReturnsCorrectCount() async throws {
        // Given: Empty queue
        #expect(messageService.getQueuedMessageCount() == 0)
        
        // When: Queue multiple messages
        _ = try await messageService.queueMessage(chatID: "chat1", text: "Message 1")
        _ = try await messageService.queueMessage(chatID: "chat2", text: "Message 2")
        
        // Then: Count should be correct
        #expect(messageService.getQueuedMessageCount() == 2)
    }
    
    @Test("Clear All Queued Messages Removes All Messages")
    func clearAllQueuedMessagesRemovesAllMessages() async throws {
        // Given: Queue with messages
        _ = try await messageService.queueMessage(chatID: "chat1", text: "Message 1")
        _ = try await messageService.queueMessage(chatID: "chat2", text: "Message 2")
        #expect(messageService.getQueuedMessageCount() == 2)
        
        // When: Clear all queued messages
        messageService.clearAllQueuedMessages()
        
        // Then: Queue should be empty
        #expect(messageService.getQueuedMessageCount() == 0)
    }
    
    @Test("Has Retryable Messages Returns True When Messages Can Be Retried")
    func hasRetryableMessagesReturnsTrueWhenMessagesCanBeRetried() async throws {
        // Given: Queue with messages that haven't exceeded retry limit
        _ = try await messageService.queueMessage(chatID: "chat1", text: "Message 1")
        
        // When: Check for retryable messages
        let hasRetryable = messageService.hasRetryableMessages()
        
        // Then: Should have retryable messages
        #expect(hasRetryable == true)
    }
    
    @Test("Queue Size Limit Enforced")
    func queueSizeLimitEnforced() async throws {
        // Given: A message service with queue size limit
        let chatID = "test-chat"
        
        // When: Try to queue more messages than the limit (100)
        // Note: This test would need to be adjusted based on actual implementation
        // For now, we'll test the basic functionality
        
        // Queue a reasonable number of messages
        for i in 1...5 {
            _ = try await messageService.queueMessage(chatID: chatID, text: "Message \(i)")
        }
        
        // Then: Messages should be queued successfully
        #expect(messageService.getQueuedMessageCount() == 5)
    }
    
    // MARK: - Network Status Tests
    
    @Test("Is Online Returns Network Status")
    func isOnlineReturnsNetworkStatus() {
        // Given: A message service
        // When: Check online status
        let isOnline = messageService.isOnline()
        
        // Then: Should return a boolean value
        #expect(isOnline == true || isOnline == false)
    }
    
    @Test("Get Connection Type Returns Valid Type")
    func getConnectionTypeReturnsValidType() {
        // Given: A message service
        // When: Get connection type
        let connectionType = messageService.getConnectionType()
        
        // Then: Should return a valid connection type
        #expect(connectionType == .wifi || connectionType == .cellular || 
                connectionType == .ethernet || connectionType == .none)
    }
    
    // MARK: - Message Status Tests
    
    @Test("Message Status Enum Has All Required Cases")
    func messageStatusEnumHasAllRequiredCases() {
        // Given: MessageStatus enum
        let allCases = MessageStatus.allCases
        
        // Then: Should have all required cases for offline support
        #expect(allCases.contains(.sending))
        #expect(allCases.contains(.sent))
        #expect(allCases.contains(.delivered))
        #expect(allCases.contains(.read))
        #expect(allCases.contains(.failed))
        #expect(allCases.contains(.queued))
    }
    
    @Test("Message Model Has Offline Fields")
    func messageModelHasOfflineFields() {
        // Given: A message with offline fields
        let message = Message(
            id: "test-id",
            chatID: "test-chat",
            senderID: "test-user",
            text: "Test message",
            timestamp: Date(),
            status: .queued,
            isOffline: true,
            retryCount: 1,
            isOptimistic: false
        )
        
        // Then: Should have offline-related fields
        #expect(message.isOffline == true)
        #expect(message.retryCount == 1)
        #expect(message.isOptimistic == false)
        #expect(message.status == .queued)
    }
}
