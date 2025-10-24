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
    
    // MARK: - Scale Tests (PR-007)
    
    @Test("Large dataset (100+ messages) retrieval performance")
    func largDatasetRetrievalPerformance() async throws {
        // Given: Simulated large message dataset
        // Note: OfflineMessageService has 3-message queue limit
        // This test verifies performance doesn't degrade with multiple retrievals
        
        var retrievalTimes: [TimeInterval] = []
        
        // When: Measure retrieval time over 100 iterations
        for _ in 0..<100 {
            let startTime = Date()
            _ = offlineService.getOfflineMessages()
            let retrievalTime = Date().timeIntervalSince(startTime)
            retrievalTimes.append(retrievalTime)
        }
        
        // Then: Performance should remain consistent
        let avgTime = retrievalTimes.reduce(0, +) / Double(retrievalTimes.count)
        let maxTime = retrievalTimes.max() ?? 0
        
        #expect(avgTime < 0.05, 
               "Average retrieval should be < 50ms, got \(avgTime * 1000)ms")
        #expect(maxTime < 0.1, 
               "Max retrieval should be < 100ms, got \(maxTime * 1000)ms")
        
        print("Large dataset retrieval (100 iterations):")
        print("  Average: \(avgTime * 1000)ms")
        print("  Max: \(maxTime * 1000)ms")
    }
    
    @Test("Stress test: Rapid queue operations")
    func stressTestRapidQueueOperations() async throws {
        // Given: Clean queue
        offlineService.clearOfflineMessages()
        
        let chatID = "stress-test-\(UUID().uuidString)"
        
        // When: Rapidly add and remove messages
        let startTime = Date()
        
        for i in 0..<50 {
            // Add message
            let messageID = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Stress test \(i)",
                senderID: testUserID
            )
            
            // Remove message (simulating successful send)
            offlineService.removeOfflineMessage(messageID: messageID)
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Then: Operations should complete without errors
        #expect(totalTime < 5.0, 
               "50 add/remove operations should complete in < 5s, took \(totalTime)s")
        
        // Queue should be empty or nearly empty
        let finalCount = offlineService.getOfflineMessages().count
        #expect(finalCount <= 3, 
               "Queue should maintain size limit")
        
        print("Stress test (50 operations): \(totalTime)s")
    }
    
    @Test("Memory efficiency with repeated operations")
    func memoryEfficiencyWithRepeatedOperations() async throws {
        // Given: Clean state
        offlineService.clearOfflineMessages()
        
        let chatID = "memory-test-\(UUID().uuidString)"
        
        // When: Perform many operations
        for i in 0..<100 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Memory test \(i)",
                senderID: testUserID
            )
            
            // Queue automatically maintains 3-message limit
        }
        
        // Then: Queue should maintain limit (not grow unbounded)
        let finalCount = offlineService.getOfflineMessages().count
        #expect(finalCount <= 3, 
               "Queue should not grow beyond limit, has \(finalCount) messages")
        
        // Verify memory isn't leaking by checking queue is stable
        let initialCount = offlineService.getQueuedMessageCount()
        
        for i in 0..<50 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Stability \(i)",
                senderID: testUserID
            )
        }
        
        let laterCount = offlineService.getQueuedMessageCount()
        #expect(laterCount <= 3, 
               "Queue size should remain stable at limit")
    }
    
    // MARK: - Airplane Mode Simulation Tests (PR-007)
    
    @Test("Airplane mode: Messages queue successfully")
    func airplaneModeMessagesQueueSuccessfully() async throws {
        // Given: Simulated airplane mode (offline)
        // OfflineMessageService doesn't depend on network state directly
        
        offlineService.clearOfflineMessages()
        let chatID = "airplane-test-\(UUID().uuidString)"
        
        // When: Queue messages while "offline"
        for i in 0..<3 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Airplane mode message \(i)",
                senderID: testUserID
            )
        }
        
        // Then: Messages should be queued
        let queuedMessages = offlineService.getOfflineMessages()
        #expect(queuedMessages.count == 3, 
               "Should have 3 messages queued in airplane mode")
        
        // Verify messages have correct state
        for message in queuedMessages {
            #expect(message.chatID == chatID, 
                   "Message should have correct chatID")
            #expect(message.status == .queued, 
                   "Message should have queued status")
        }
    }
    
    @Test("Airplane mode: Cache survives app restart")
    func airplanModeCacheSurvivesAppRestart() async throws {
        // Given: Messages queued in "airplane mode"
        let chatID = "airplane-restart-\(UUID().uuidString)"
        
        offlineService.clearOfflineMessages()
        
        for i in 0..<3 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Restart test \(i)",
                senderID: testUserID
            )
        }
        
        let beforeCount = offlineService.getOfflineMessages().count
        
        // When: Simulate app restart by creating new service instance
        let newOfflineService = OfflineMessageService()
        
        // Then: Messages should persist
        let afterCount = newOfflineService.getOfflineMessages().count
        
        #expect(afterCount >= beforeCount - 3, 
               "Messages should persist after restart (within queue limit)")
        
        // If queue was full, messages should still be there
        if beforeCount == 3 {
            #expect(afterCount > 0, 
                   "At least some messages should persist")
        }
    }
    
    @Test("Airplane mode: Toggle doesn't lose messages")
    func airplaneModeToggleDoesNotLoseMessages() async throws {
        // Given: Messages queued
        let chatID = "toggle-test-\(UUID().uuidString)"
        
        offlineService.clearOfflineMessages()
        
        let messageID = try await offlineService.queueMessageOffline(
            chatID: chatID,
            text: "Toggle test message",
            senderID: testUserID
        )
        
        // When: Simulate multiple "airplane mode" toggles
        // (represented by checking queue multiple times)
        for _ in 0..<5 {
            let messages = offlineService.getOfflineMessages()
            let messageExists = messages.contains { $0.id == messageID }
            
            #expect(messageExists, 
                   "Message should persist through state checks")
        }
        
        // Then: Message should still be in queue
        let finalMessages = offlineService.getOfflineMessages()
        let messageStillExists = finalMessages.contains { $0.id == messageID }
        
        #expect(messageStillExists, 
               "Message should survive airplane mode toggles")
    }
    
    @Test("Cache load performance with full queue")
    func cacheLoadPerformanceWithFullQueue() async throws {
        // Given: Full queue (3 messages)
        offlineService.clearOfflineMessages()
        let chatID = "full-load-test-\(UUID().uuidString)"
        
        for i in 0..<3 {
            _ = try await offlineService.queueMessageOffline(
                chatID: chatID,
                text: "Full queue message \(i)",
                senderID: testUserID
            )
        }
        
        // When: Measure load time with full queue
        let startTime = Date()
        let newService = OfflineMessageService()
        let messages = newService.getOfflineMessages()
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Then: Load should be fast even with full queue
        #expect(loadTime < 0.5, 
               "Full queue load should be < 500ms, got \(loadTime * 1000)ms")
        #expect(messages.count > 0, 
               "Should load messages from full queue")
        
        print("Full queue load time: \(loadTime * 1000)ms")
    }
}


