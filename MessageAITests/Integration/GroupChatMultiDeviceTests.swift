//
//  GroupChatMultiDeviceTests.swift
//  MessageAITests
//
//  Multi-device integration tests for group chat functionality
//

import Testing
import Foundation
@testable import MessageAI

/// Multi-device integration tests for group chat functionality
/// - Note: Tests real-time sync across multiple devices in group chats
struct GroupChatMultiDeviceTests {
    
    // MARK: - Test Data
    
    private let testChatID = "test-group-chat-multi"
    private let testGroupMembers = ["user1", "user2", "user3", "user4", "user5"]
    
    // MARK: - Multi-Device Sync Tests
    
    @Test("Group Chat Message Sync Across 3 Devices Completes Within 100ms")
    func groupChatMessageSyncAcross3DevicesCompletesWithin100ms() async throws {
        // Given: Three devices in the same group chat
        let device1Service = MessageService()
        let device2Service = MessageService()
        let device3Service = MessageService()
        
        // When: Device 1 sends a message
        let messageText = "Hello from device 1"
        let startTime = Date()
        let messageID = try await device1Service.sendMessage(chatID: testChatID, text: messageText)
        let sendTime = Date()
        
        // Wait for Firebase sync (should be <100ms)
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Device 2 and 3 should receive the message
        let device2Messages = try await device2Service.fetchMessages(chatID: testChatID)
        let device3Messages = try await device3Service.fetchMessages(chatID: testChatID)
        
        // Verify message sync
        #expect(device2Messages.contains { $0.id == messageID })
        #expect(device3Messages.contains { $0.id == messageID })
        
        // Verify sync time
        let syncTime = sendTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        #expect(syncTime < 100, "Message sync took \(syncTime)ms, expected < 100ms")
    }
    
    @Test("Group Chat Concurrent Messages Sync Correctly")
    func groupChatConcurrentMessagesSyncCorrectly() async throws {
        // Given: Three devices in the same group chat
        let device1Service = MessageService()
        let device2Service = MessageService()
        let device3Service = MessageService()
        
        // When: All devices send messages concurrently
        let messageTexts = ["Message from device 1", "Message from device 2", "Message from device 3"]
        
        let messageIDs = try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await device1Service.sendMessage(chatID: testChatID, text: messageTexts[0])
            }
            group.addTask {
                try await device2Service.sendMessage(chatID: testChatID, text: messageTexts[1])
            }
            group.addTask {
                try await device3Service.sendMessage(chatID: testChatID, text: messageTexts[2])
            }
            
            var results: [String] = []
            for try await messageID in group {
                results.append(messageID)
            }
            return results
        }
        
        // Wait for sync
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then: All devices should see all messages
        let device1Messages = try await device1Service.fetchMessages(chatID: testChatID)
        let device2Messages = try await device2Service.fetchMessages(chatID: testChatID)
        let device3Messages = try await device3Service.fetchMessages(chatID: testChatID)
        
        // Verify all messages are synced
        for messageID in messageIDs {
            #expect(device1Messages.contains { $0.id == messageID })
            #expect(device2Messages.contains { $0.id == messageID })
            #expect(device3Messages.contains { $0.id == messageID })
        }
    }
    
    @Test("Group Chat Read Receipts Sync Across Devices")
    func groupChatReadReceiptsSyncAcrossDevices() async throws {
        // Given: Three devices in the same group chat
        let device1Service = MessageService()
        let device2Service = MessageService()
        let device3Service = MessageService()
        
        // When: Device 1 sends a message
        let messageID = try await device1Service.sendMessage(chatID: testChatID, text: "Read receipt test")
        
        // And: Device 2 and 3 mark it as read
        try await device2Service.markMessageAsRead(messageID: messageID, userID: "user2")
        try await device3Service.markMessageAsRead(messageID: messageID, userID: "user3")
        
        // Wait for sync
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: All devices should see updated read receipts
        let device1Message = try await device1Service.fetchMessage(messageID: messageID)
        let device2Message = try await device2Service.fetchMessage(messageID: messageID)
        let device3Message = try await device3Service.fetchMessage(messageID: messageID)
        
        // Verify read receipts are synced
        #expect(device1Message.readBy.contains("user2"))
        #expect(device1Message.readBy.contains("user3"))
        #expect(device2Message.readBy.contains("user2"))
        #expect(device2Message.readBy.contains("user3"))
        #expect(device3Message.readBy.contains("user2"))
        #expect(device3Message.readBy.contains("user3"))
    }
    
    @Test("Group Chat Real-Time Listeners Work Across Devices")
    func groupChatRealTimeListenersWorkAcrossDevices() async throws {
        // Given: Three devices with real-time listeners
        let device1Service = MessageService()
        let device2Service = MessageService()
        let device3Service = MessageService()
        
        var device1Messages: [Message] = []
        var device2Messages: [Message] = []
        var device3Messages: [Message] = []
        
        // Set up real-time listeners
        let listener1 = device1Service.observeMessages(chatID: testChatID) { messages in
            device1Messages = messages
        }
        let listener2 = device2Service.observeMessages(chatID: testChatID) { messages in
            device2Messages = messages
        }
        let listener3 = device3Service.observeMessages(chatID: testChatID) { messages in
            device3Messages = messages
        }
        
        // When: Device 1 sends a message
        let messageID = try await device1Service.sendMessage(chatID: testChatID, text: "Real-time test")
        
        // Wait for real-time sync
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: All devices should receive the message via real-time listeners
        #expect(device1Messages.contains { $0.id == messageID })
        #expect(device2Messages.contains { $0.id == messageID })
        #expect(device3Messages.contains { $0.id == messageID })
        
        // Cleanup
        listener1.remove()
        listener2.remove()
        listener3.remove()
    }
    
    @Test("Group Chat Offline Messages Sync When Reconnecting")
    func groupChatOfflineMessagesSyncWhenReconnecting() async throws {
        // Given: A device that goes offline
        let device1Service = MessageService()
        let device2Service = MessageService()
        
        // When: Device 1 goes offline and queues a message
        let queuedMessageID = try await device1Service.queueMessage(chatID: testChatID, text: "Offline message")
        
        // And: Device 2 sends a message while device 1 is offline
        let onlineMessageID = try await device2Service.sendMessage(chatID: testChatID, text: "Online message")
        
        // And: Device 1 comes back online and syncs
        try await device1Service.syncQueuedMessages()
        
        // Wait for sync
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then: Device 1 should see both messages
        let device1Messages = try await device1Service.fetchMessages(chatID: testChatID)
        #expect(device1Messages.contains { $0.id == onlineMessageID })
        
        // And: Device 2 should see the queued message
        let device2Messages = try await device2Service.fetchMessages(chatID: testChatID)
        #expect(device2Messages.contains { $0.id == queuedMessageID })
    }
    
    @Test("Group Chat Performance with 5 Concurrent Devices")
    func groupChatPerformanceWith5ConcurrentDevices() async throws {
        // Given: 5 devices in the same group chat
        let devices = (1...5).map { _ in MessageService() }
        
        // When: All devices send messages concurrently
        let startTime = Date()
        let messageIDs = try await withThrowingTaskGroup(of: String.self) { group in
            for (index, device) in devices.enumerated() {
                group.addTask {
                    try await device.sendMessage(chatID: testChatID, text: "Message from device \(index + 1)")
                }
            }
            
            var results: [String] = []
            for try await messageID in group {
                results.append(messageID)
            }
            return results
        }
        let endTime = Date()
        
        // Wait for sync
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
        
        // Then: All devices should see all messages
        for device in devices {
            let messages = try await device.fetchMessages(chatID: testChatID)
            #expect(messages.count >= 5)
        }
        
        // Verify performance
        let totalTime = endTime.timeIntervalSince(startTime)
        #expect(totalTime < 1.0, "5 concurrent devices took \(totalTime)s, expected < 1s")
    }
    
    @Test("Group Chat Message Ordering Is Consistent Across Devices")
    func groupChatMessageOrderingIsConsistentAcrossDevices() async throws {
        // Given: Three devices in the same group chat
        let device1Service = MessageService()
        let device2Service = MessageService()
        let device3Service = MessageService()
        
        // When: Devices send messages in sequence
        let message1ID = try await device1Service.sendMessage(chatID: testChatID, text: "Message 1")
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        
        let message2ID = try await device2Service.sendMessage(chatID: testChatID, text: "Message 2")
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        
        let message3ID = try await device3Service.sendMessage(chatID: testChatID, text: "Message 3")
        
        // Wait for sync
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then: All devices should see messages in the same order
        let device1Messages = try await device1Service.fetchMessages(chatID: testChatID)
        let device2Messages = try await device2Service.fetchMessages(chatID: testChatID)
        let device3Messages = try await device3Service.fetchMessages(chatID: testChatID)
        
        // Verify message order is consistent
        let device1Order = device1Messages.map { $0.id }
        let device2Order = device2Messages.map { $0.id }
        let device3Order = device3Messages.map { $0.id }
        
        #expect(device1Order == device2Order)
        #expect(device2Order == device3Order)
    }
}
