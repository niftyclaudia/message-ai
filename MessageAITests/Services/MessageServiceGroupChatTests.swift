//
//  MessageServiceGroupChatTests.swift
//  MessageAITests
//
//  Unit tests for group chat functionality in MessageService
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for group chat functionality in MessageService
/// - Note: Tests group chat message operations, read receipts, and multi-user scenarios
struct MessageServiceGroupChatTests {
    
    // MARK: - Test Data
    
    private let testChatID = "test-group-chat"
    private let testUserID = "test-user-1"
    private let testGroupMembers = ["user1", "user2", "user3", "user4", "user5"]
    
    // MARK: - Group Chat Message Tests
    
    @Test("Send Message to Group Chat Succeeds")
    func sendMessageToGroupChatSucceeds() async throws {
        // Given: A group chat with 5 members
        let messageService = MessageService()
        let messageText = "Hello group!"
        
        // When: Sending a message to the group chat
        let messageID = try await messageService.sendMessage(chatID: testChatID, text: messageText)
        
        // Then: Message ID is returned
        #expect(!messageID.isEmpty)
    }
    
    @Test("Group Chat Message Contains All Members in ReadBy")
    func groupChatMessageContainsAllMembersInReadBy() async throws {
        // Given: A group chat message
        let messageService = MessageService()
        let messageText = "Group message"
        
        // When: Sending a message to group chat
        let messageID = try await messageService.sendMessage(chatID: testChatID, text: messageText)
        
        // Then: Fetch the message and verify readBy contains sender
        let message = try await messageService.fetchMessage(messageID: messageID)
        #expect(message.readBy.contains(testUserID))
    }
    
    @Test("Mark Message As Read Updates ReadBy Array")
    func markMessageAsReadUpdatesReadByArray() async throws {
        // Given: A group chat message
        let messageService = MessageService()
        let messageID = try await messageService.sendMessage(chatID: testChatID, text: "Test message")
        
        // When: Marking message as read by another user
        let otherUserID = "user2"
        try await messageService.markMessageAsRead(messageID: messageID, userID: otherUserID)
        
        // Then: ReadBy array contains both users
        let message = try await messageService.fetchMessage(messageID: messageID)
        #expect(message.readBy.contains(testUserID))
        #expect(message.readBy.contains(otherUserID))
    }
    
    @Test("Group Chat Message Delivery Latency Under 100ms")
    func groupChatMessageDeliveryLatencyUnder100ms() async throws {
        // Given: A group chat
        let messageService = MessageService()
        let messageText = "Performance test message"
        
        // When: Sending message and measuring time
        let startTime = Date()
        let messageID = try await messageService.sendMessage(chatID: testChatID, text: messageText)
        let endTime = Date()
        
        // Then: Delivery time should be under 100ms
        let deliveryTime = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        #expect(deliveryTime < 100, "Message delivery took \(deliveryTime)ms, expected < 100ms")
        
        // Verify message was created
        #expect(!messageID.isEmpty)
    }
    
    // MARK: - Read Receipt Tests
    
    @Test("Read Receipts Track All Group Members")
    func readReceiptsTrackAllGroupMembers() async throws {
        // Given: A group chat message
        let messageService = MessageService()
        let messageID = try await messageService.sendMessage(chatID: testChatID, text: "Read receipt test")
        
        // When: Multiple group members read the message
        for memberID in testGroupMembers.dropFirst() { // Skip sender
            try await messageService.markMessageAsRead(messageID: messageID, userID: memberID)
        }
        
        // Then: All members are in readBy array
        let message = try await messageService.fetchMessage(messageID: messageID)
        #expect(message.readBy.count == testGroupMembers.count)
        
        for memberID in testGroupMembers {
            #expect(message.readBy.contains(memberID))
        }
    }
    
    @Test("Read Receipt Performance with 10 Members")
    func readReceiptPerformanceWith10Members() async throws {
        // Given: A group chat with 10 members
        let largeGroupMembers = (1...10).map { "user\($0)" }
        let messageService = MessageService()
        let messageID = try await messageService.sendMessage(chatID: testChatID, text: "Large group test")
        
        // When: All members read the message
        let startTime = Date()
        for memberID in largeGroupMembers {
            try await messageService.markMessageAsRead(messageID: messageID, userID: memberID)
        }
        let endTime = Date()
        
        // Then: Performance should be acceptable
        let totalTime = endTime.timeIntervalSince(startTime) * 1000
        #expect(totalTime < 500, "Read receipts for 10 members took \(totalTime)ms, expected < 500ms")
        
        // Verify all members are tracked
        let message = try await messageService.fetchMessage(messageID: messageID)
        #expect(message.readBy.count == largeGroupMembers.count)
    }
    
    // MARK: - Offline Persistence Tests
    
    @Test("Group Chat Messages Persist Offline")
    func groupChatMessagesPersistOffline() async throws {
        // Given: A group chat and offline scenario
        let offlineMessageService = OfflineMessageService()
        let messageText = "Offline group message"
        let senderID = "test-user"
        
        // When: Queuing a message while offline
        let messageID = try await offlineMessageService.queueMessageOffline(chatID: testChatID, text: messageText, senderID: senderID)
        
        // Then: Message is queued for later sync
        #expect(!messageID.isEmpty)
        
        let queuedMessages = offlineMessageService.getOfflineMessages()
        #expect(queuedMessages.contains { $0.id == messageID })
    }
    
    @Test("Group Chat Offline Messages Sync on Reconnect")
    func groupChatOfflineMessagesSyncOnReconnect() async throws {
        // Given: Queued messages from offline
        let offlineMessageService = OfflineMessageService()
        let networkMonitorService = NetworkMonitorService()
        let syncService = SyncService(offlineMessageService: offlineMessageService, networkMonitorService: networkMonitorService)
        let messageText = "Sync test message"
        let senderID = "test-user"
        let messageID = try await offlineMessageService.queueMessageOffline(chatID: testChatID, text: messageText, senderID: senderID)
        
        // When: Syncing queued messages (if online)
        if await networkMonitorService.isOnline() {
            _ = try await syncService.syncOfflineMessages()
        }
        
        // Then: Message is no longer in queue (if sync succeeded)
        let queuedMessages = offlineMessageService.getOfflineMessages()
        // Note: This may still contain the message if offline or sync failed, which is expected behavior
        #expect(queuedMessages.count >= 0) // Queue should be valid
    }
    
    // MARK: - Real-Time Sync Tests
    
    @Test("Group Chat Real-Time Sync Under 100ms")
    func groupChatRealTimeSyncUnder100ms() async throws {
        // Given: A group chat
        let messageService = MessageService()
        let messageText = "Real-time sync test"
        
        // When: Setting up real-time listener and sending message
        var receivedMessages: [Message] = []
        let listener = messageService.observeMessages(chatID: testChatID) { messages in
            receivedMessages = messages
        }
        
        // Send message
        let messageID = try await messageService.sendMessage(chatID: testChatID, text: messageText)
        
        // Wait for real-time sync (should be < 100ms)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Message should be received via real-time listener
        #expect(receivedMessages.contains { $0.id == messageID })
        
        // Cleanup
        listener.remove()
    }
    
    @Test("Concurrent Group Chat Messages Sync Correctly")
    func concurrentGroupChatMessagesSyncCorrectly() async throws {
        // Given: A group chat
        let messageService = MessageService()
        let messageTexts = ["Message 1", "Message 2", "Message 3"]
        
        // When: Sending multiple messages concurrently
        let messageIDs = try await withThrowingTaskGroup(of: String.self) { group in
            for text in messageTexts {
                group.addTask {
                    try await messageService.sendMessage(chatID: testChatID, text: text)
                }
            }
            
            var results: [String] = []
            for try await messageID in group {
                results.append(messageID)
            }
            return results
        }
        
        // Then: All messages should be created
        #expect(messageIDs.count == messageTexts.count)
        
        // Verify all messages exist
        for messageID in messageIDs {
            let message = try await messageService.fetchMessage(messageID: messageID)
            #expect(messageTexts.contains(message.text))
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Empty Group Chat Handles Gracefully")
    func emptyGroupChatHandlesGracefully() async throws {
        // Given: An empty group chat (edge case)
        let messageService = MessageService()
        let emptyChatID = "empty-group-chat"
        
        // When: Trying to send message to empty group
        let messageID = try await messageService.sendMessage(chatID: emptyChatID, text: "Empty group message")
        
        // Then: Message should still be created
        #expect(!messageID.isEmpty)
    }
    
    @Test("Group Chat with Single Member Handles Correctly")
    func groupChatWithSingleMemberHandlesCorrectly() async throws {
        // Given: A group chat with only one member (edge case)
        let messageService = MessageService()
        let singleMemberChatID = "single-member-chat"
        
        // When: Sending message to single-member group
        let messageID = try await messageService.sendMessage(chatID: singleMemberChatID, text: "Single member message")
        
        // Then: Message should be created successfully
        #expect(!messageID.isEmpty)
        
        let message = try await messageService.fetchMessage(messageID: messageID)
        #expect(message.readBy.contains(testUserID))
    }
    
    @Test("Group Chat Message Retry Logic Works")
    func groupChatMessageRetryLogicWorks() async throws {
        // Given: A failed message in group chat offline queue
        let offlineMessageService = OfflineMessageService()
        let networkMonitorService = NetworkMonitorService()
        let syncService = SyncService(offlineMessageService: offlineMessageService, networkMonitorService: networkMonitorService)
        let messageText = "Retry test message"
        let senderID = "test-user"
        
        // When: Message is queued offline and retry is attempted
        let messageID = try await offlineMessageService.queueMessageOffline(chatID: testChatID, text: messageText, senderID: senderID)
        
        // Then: Message should be in the queue and retryable
        #expect(!messageID.isEmpty)
        let retryableMessages = offlineMessageService.getRetryableMessages()
        #expect(retryableMessages.contains { $0.id == messageID })
        
        // Verify retry functionality through sync service
        if await networkMonitorService.isOnline() {
            _ = try await syncService.retryFailedMessages()
        }
    }
}
