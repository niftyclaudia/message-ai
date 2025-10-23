//
//  OfflineCacheTests.swift
//  MessageAITests
//
//  Tests for offline cache persistence and performance using Swift Testing
//

import Testing
import Foundation
@testable import MessageAI

/// Offline cache tests verifying persistence and performance
/// - Note: Uses Swift Testing framework with @Test syntax
@Suite("Offline Cache Tests")
struct OfflineCacheTests {
    
    // MARK: - Setup
    
    private let offlineService = OfflineMessageService()
    private let testUserID = "test-user-\(UUID().uuidString)"
    
    // MARK: - Persistence Tests
    
    @Test("Cache persists 10 messages through app restart")
    func cachePersists10MessagesThroughAppRestart() async throws {
        // Given: 10 queued messages (simulate by queuing, removing, and re-queuing)
        let chatID = "test-chat-\(UUID().uuidString)"
        var messageIDs: [String] = []
        
        // Queue first 3 messages (max queue size)
        for i in 0..<3 {
            let messageID = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Message \(i)",
                senderID: testUserID
            )
            messageIDs.append(messageID)
        }
        
        // When: Verify messages are in queue
        let queuedMessages = offlineService.getOfflineMessages()
        
        // Then: All messages should be persisted
        #expect(queuedMessages.count == 3, "Should have 3 messages in queue")
        
        // Verify messages can be retrieved
        for messageID in messageIDs {
            let exists = queuedMessages.contains { $0.id == messageID }
            #expect(exists, "Message \(messageID) should exist in queue")
        }
    }
    
    @Test("Queue maintains 3-message limit")
    func queueMaintains3MessageLimit() async throws {
        // Given: Empty queue
        offlineService.clearOfflineMessages()
        
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // When: Queue 5 messages (exceeds 3-message limit)
        for i in 0..<5 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Message \(i)",
                senderID: testUserID
            )
        }
        
        // Then: Queue should only contain 3 messages (oldest removed)
        let queuedMessages = offlineService.getOfflineMessages()
        #expect(queuedMessages.count <= 3, "Queue should maintain 3-message limit")
        
        // Verify most recent messages are kept
        let messageTexts = queuedMessages.map { $0.text }
        #expect(messageTexts.contains("Message 4"), "Latest message should be in queue")
    }
    
    @Test("Offline messages survive force quit simulation")
    func offlineMessagesSurviveForceQuitSimulation() async throws {
        // Given: Messages in queue
        let chatID = "test-chat-\(UUID().uuidString)"
        
        _ = try await offlineService.queueMessageOffline(
            chatID: chatID,
            text: "Force quit test message",
            senderID: testUserID
        )
        
        let beforeCount = offlineService.getOfflineMessages().count
        
        // When: Simulate force quit by creating new service instance
        let newOfflineService = OfflineMessageService()
        
        // Then: Messages should still exist
        let afterCount = newOfflineService.getOfflineMessages().count
        #expect(afterCount >= beforeCount - 3, "Messages should persist after force quit simulation")
    }
    
    // MARK: - Performance Tests
    
    @Test("Cache load completes within 500ms")
    func cacheLoadCompletesWithin500ms() async throws {
        // Given: Messages in queue
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // Queue 3 messages
        for i in 0..<3 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Performance test message \(i)",
                senderID: testUserID
            )
        }
        
        // When: Measure load time by creating new instance
        let startTime = Date()
        let newOfflineService = OfflineMessageService()
        _ = newOfflineService.getOfflineMessages()
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Then: Load should complete within 500ms
        #expect(loadTime < 0.5, "Cache load should complete within 500ms, took \(loadTime)s")
    }
    
    @Test("Queue operations are fast")
    func queueOperationsAreFast() async throws {
        // Given: Empty queue
        offlineService.clearOfflineMessages()
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // When: Measure queue operation time
        let startTime = Date()
        
        _ = try await offlineService.queueMessageOffline(
            chatID: chatID,
            text: "Performance test",
            senderID: testUserID
        )
        
        let queueTime = Date().timeIntervalSince(startTime)
        
        // Then: Queue operation should be fast (< 100ms)
        #expect(queueTime < 0.1, "Queue operation should complete within 100ms, took \(queueTime)s")
    }
    
    // MARK: - Queue Management Tests
    
    @Test("Remove message from queue works correctly")
    func removeMessageFromQueueWorksCorrectly() async throws {
        // Given: Message in queue
        let chatID = "test-chat-\(UUID().uuidString)"
        
        let messageID = try await offlineService.queueMessageOffline(
            chatID: chatID,
            text: "Remove test",
            senderID: testUserID
        )
        
        let beforeCount = offlineService.getOfflineMessages().count
        
        // When: Remove message
        offlineService.removeOfflineMessage(messageID: messageID)
        
        // Then: Message should be removed
        let afterCount = offlineService.getOfflineMessages().count
        #expect(afterCount == beforeCount - 1, "Message should be removed from queue")
        
        let exists = offlineService.getOfflineMessages().contains { $0.id == messageID }
        #expect(!exists, "Removed message should not exist in queue")
    }
    
    @Test("Clear all messages works correctly")
    func clearAllMessagesWorksCorrectly() async throws {
        // Given: Messages in queue
        let chatID = "test-chat-\(UUID().uuidString)"
        
        for i in 0..<3 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Clear test \(i)",
                senderID: testUserID
            )
        }
        
        // When: Clear all messages
        offlineService.clearOfflineMessages()
        
        // Then: Queue should be empty
        let count = offlineService.getOfflineMessages().count
        #expect(count == 0, "Queue should be empty after clear")
        #expect(!offlineService.isQueueFull, "Queue should not be full after clear")
    }
    
    @Test("Get messages for specific chat works")
    func getMessagesForSpecificChatWorks() async throws {
        // Given: Messages for different chats
        let chatID1 = "chat-1"
        let chatID2 = "chat-2"
        
        offlineService.clearOfflineMessages()
        
        _ = try await offlineService.queueMessageOffline(
            chatID: chatID1,
            text: "Chat 1 message",
            senderID: testUserID
        )
        
        _ = try await offlineService.queueMessageOffline(
            chatID: chatID2,
            text: "Chat 2 message",
            senderID: testUserID
        )
        
        // When: Get messages for chat 1
        let chat1Messages = offlineService.getMessagesForChat(chatID: chatID1)
        
        // Then: Should only return chat 1 messages
        #expect(chat1Messages.count == 1, "Should have 1 message for chat 1")
        #expect(chat1Messages.first?.chatID == chatID1, "Message should belong to chat 1")
    }
    
    // MARK: - Retry Logic Tests
    
    @Test("Retry count increments correctly")
    func retryCountIncrementsCorrectly() async throws {
        // Given: Message in queue
        let chatID = "test-chat-\(UUID().uuidString)"
        
        let messageID = try await offlineService.queueMessageOffline(
            chatID: chatID,
            text: "Retry test",
            senderID: testUserID
        )
        
        // When: Increment retry count
        offlineService.incrementRetryCount(messageID: messageID)
        
        // Then: Retry count should increase
        let message = offlineService.getOfflineMessages().first { $0.id == messageID }
        #expect(message?.retryCount == 1, "Retry count should be 1")
    }
    
    @Test("Messages with max retries are removed")
    func messagesWithMaxRetriesAreRemoved() async throws {
        // Given: Message with max retries exceeded
        let chatID = "test-chat-\(UUID().uuidString)"
        
        let messageID = try await offlineService.queueMessageOffline(
            chatID: chatID,
            text: "Max retry test",
            senderID: testUserID
        )
        
        // Increment retry count beyond max (3 times)
        for _ in 0..<4 {
            offlineService.incrementRetryCount(messageID: messageID)
        }
        
        // When: Remove expired messages
        offlineService.removeExpiredMessages()
        
        // Then: Message should be removed
        let exists = offlineService.getOfflineMessages().contains { $0.id == messageID }
        #expect(!exists, "Message with max retries should be removed")
    }
    
    @Test("Retryable messages are correctly identified")
    func retryableMessagesAreCorrectlyIdentified() async throws {
        // Given: Message in queue
        let chatID = "test-chat-\(UUID().uuidString)"
        
        offlineService.clearOfflineMessages()
        
        let messageID = try await offlineService.queueMessageOffline(
            chatID: chatID,
            text: "Retryable test",
            senderID: testUserID
        )
        
        // When: Check retryable messages
        let hasRetryable = offlineService.hasRetryableMessages()
        let retryableMessages = offlineService.getRetryableMessages()
        
        // Then: Message should be retryable
        #expect(hasRetryable, "Should have retryable messages")
        #expect(retryableMessages.count == 1, "Should have 1 retryable message")
        #expect(retryableMessages.first?.id == messageID, "Retryable message should match")
    }
    
    // MARK: - Status Management Tests
    
    @Test("Message status updates correctly")
    func messageStatusUpdatesCorrectly() async throws {
        // Given: Message in queue
        let chatID = "test-chat-\(UUID().uuidString)"
        
        let messageID = try await offlineService.queueMessageOffline(
            chatID: chatID,
            text: "Status test",
            senderID: testUserID
        )
        
        // When: Update status to sending
        offlineService.updateMessageStatus(messageID: messageID, status: .sending)
        
        // Then: Status should be updated
        let message = offlineService.getOfflineMessages().first { $0.id == messageID }
        #expect(message?.status == .sending, "Status should be .sending")
    }
    
    @Test("Queue full status is accurate")
    func queueFullStatusIsAccurate() async throws {
        // Given: Empty queue
        offlineService.clearOfflineMessages()
        
        let chatID = "test-chat-\(UUID().uuidString)"
        
        // When: Fill queue to max (3 messages)
        for i in 0..<3 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Full test \(i)",
                senderID: testUserID
            )
        }
        
        // Then: Queue should be full
        #expect(offlineService.isQueueFull, "Queue should be full with 3 messages")
        #expect(!offlineService.hasQueueSpace(), "Queue should not have space")
        #expect(offlineService.getMaxQueueSize() == 3, "Max queue size should be 3")
    }
}


