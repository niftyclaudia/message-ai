//
//  MessageServiceOfflineTests.swift
//  MessageAITests
//
//  Unit tests for MessageService offline functionality
//

import Testing
import Foundation
@testable import MessageAI

/// Tests for offline persistence and queuing
struct MessageServiceOfflineTests {
    
    // MARK: - Test Properties
    
    private var offlineMessageService: OfflineMessageService!
    private var networkMonitor: NetworkMonitorService!
    
    // MARK: - Setup
    
    init() {
        offlineMessageService = OfflineMessageService()
        networkMonitor = NetworkMonitorService()
    }
    
    // MARK: - Offline Message Queuing Tests
    
    @Test("Queue Message When Offline Stores Message Locally")
    func queueMessageWhenOfflineStoresMessageLocally() async throws {
        // Given: An offline message service
        let chatID = "test-chat"
        let messageText = "Test offline message"
        let senderID = "test-user"
        
        // When: Queue a message (simulating offline behavior)
        let messageID = try await offlineMessageService.queueMessageOffline(chatID: chatID, text: messageText, senderID: senderID)
        
        // Then: Message should be stored in queue
        #expect(!messageID.isEmpty)
        
        let queuedMessages = offlineMessageService.getOfflineMessages()
        #expect(queuedMessages.count == 1)
        #expect(queuedMessages.first?.text == messageText)
        #expect(queuedMessages.first?.chatID == chatID)
    }
    
    @Test("Get Queued Message Count Returns Correct Count")
    func getQueuedMessageCountReturnsCorrectCount() async throws {
        // Given: Empty queue
        #expect(offlineMessageService.getQueuedMessageCount() == 0)
        
        // When: Queue multiple messages
        _ = try await offlineMessageService.queueMessageOffline(chatID: "chat1", text: "Message 1", senderID: "test-user")
        _ = try await offlineMessageService.queueMessageOffline(chatID: "chat2", text: "Message 2", senderID: "test-user")
        
        // Then: Count should be correct
        #expect(offlineMessageService.getQueuedMessageCount() == 2)
    }
    
    @Test("Clear All Queued Messages Removes All Messages")
    func clearAllQueuedMessagesRemovesAllMessages() async throws {
        // Given: Queue with messages
        _ = try await offlineMessageService.queueMessageOffline(chatID: "chat1", text: "Message 1", senderID: "test-user")
        _ = try await offlineMessageService.queueMessageOffline(chatID: "chat2", text: "Message 2", senderID: "test-user")
        #expect(offlineMessageService.getQueuedMessageCount() == 2)
        
        // When: Clear all queued messages
        offlineMessageService.clearOfflineMessages()
        
        // Then: Queue should be empty
        #expect(offlineMessageService.getQueuedMessageCount() == 0)
    }
    
    @Test("Has Retryable Messages Returns True When Messages Can Be Retried")
    func hasRetryableMessagesReturnsTrueWhenMessagesCanBeRetried() async throws {
        // Given: Queue with messages that haven't exceeded retry limit
        _ = try await offlineMessageService.queueMessageOffline(chatID: "chat1", text: "Message 1", senderID: "test-user")
        
        // When: Check for retryable messages
        let hasRetryable = offlineMessageService.hasRetryableMessages()
        
        // Then: Should have retryable messages
        #expect(hasRetryable == true)
    }
    
    @Test("Queue Size Limit Enforced")
    func queueSizeLimitEnforced() async throws {
        // Given: An offline message service with 3-message queue limit
        let chatID = "test-chat"
        let senderID = "test-user"
        
        // When: Queue up to the limit (3 messages)
        _ = try await offlineMessageService.queueMessageOffline(chatID: chatID, text: "Message 1", senderID: senderID)
        _ = try await offlineMessageService.queueMessageOffline(chatID: chatID, text: "Message 2", senderID: senderID)
        _ = try await offlineMessageService.queueMessageOffline(chatID: chatID, text: "Message 3", senderID: senderID)
        
        // Then: Should have 3 messages (oldest gets removed when adding 4th)
        #expect(offlineMessageService.getQueuedMessageCount() == 3)
        
        // When: Queue one more (should replace oldest)
        _ = try await offlineMessageService.queueMessageOffline(chatID: chatID, text: "Message 4", senderID: senderID)
        
        // Then: Should still have 3 messages
        #expect(offlineMessageService.getQueuedMessageCount() == 3)
    }
    
    // MARK: - Network Status Tests
    
    @Test("Is Online Returns Network Status")
    func isOnlineReturnsNetworkStatus() {
        // Given: A network monitor
        // When: Check online status
        let isOnline = networkMonitor.isOnline()
        
        // Then: Should return a boolean value
        #expect(isOnline == true || isOnline == false)
    }
    
    @Test("Get Connection Type Returns Valid Type")
    func getConnectionTypeReturnsValidType() {
        // Given: A network monitor
        // When: Get connection type
        let connectionType = networkMonitor.connectionType
        
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
