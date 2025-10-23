//
//  OfflinePersistenceIntegrationTests.swift
//  MessageAITests
//
//  Integration tests for offline persistence system
//

import Testing
import Foundation
@testable import MessageAI

/// Integration tests for offline persistence system
/// - Note: Tests end-to-end offline functionality with real components
struct OfflinePersistenceIntegrationTests {
    
    // MARK: - Test Properties
    
    private var offlineViewModel: OfflineViewModel!
    private var chatViewModel: ChatViewModel!
    
    // MARK: - Setup
    
    init() {
        offlineViewModel = OfflineViewModel()
        chatViewModel = ChatViewModel(currentUserID: "test-user")
        
        // Ensure clean state
        offlineViewModel.clearOfflineMessages()
    }
    
    // MARK: - End-to-End Tests
    
    @Test("Offline Message Flow Complete")
    func offlineMessageFlowComplete() async throws {
        // Given
        let chatID = "test-chat"
        let text = "Test offline message"
        let senderID = "test-user"
        
        // When - Queue message offline
        let messageID = try await offlineViewModel.queueMessageOffline(
            chatID: chatID,
            text: text,
            senderID: senderID
        )
        
        // Then - Message should be queued
        #expect(!messageID.isEmpty)
        #expect(offlineViewModel.getQueuedMessageCount() == 1)
        #expect(offlineViewModel.hasMessagesToSync() == true)
        
        let offlineMessages = offlineViewModel.getOfflineMessages()
        #expect(offlineMessages.count == 1)
        
        let queuedMessage = offlineMessages.first!
        #expect(queuedMessage.id == messageID)
        #expect(queuedMessage.chatID == chatID)
        #expect(queuedMessage.text == text)
        #expect(queuedMessage.senderID == senderID)
        #expect(queuedMessage.status == .queued)
    }
    
    @Test("3-Message Queue Limit Enforced")
    func threeMessageQueueLimitEnforced() async throws {
        // Given
        let chatID = "test-chat"
        let senderID = "test-user"
        
        // When - Add 4 messages (exceeds 3-message limit)
        var messageIDs: [String] = []
        for i in 1...4 {
            let messageID = try await offlineViewModel.queueMessageOffline(
                chatID: chatID,
                text: "Message \(i)",
                senderID: senderID
            )
            messageIDs.append(messageID)
        }
        
        // Then - Should only have 3 messages (oldest removed)
        #expect(offlineViewModel.getQueuedMessageCount() == 3)
        #expect(offlineViewModel.getMaxQueueSize() == 3)
        
        let offlineMessages = offlineViewModel.getOfflineMessages()
        #expect(offlineMessages.count == 3)
        
        // First message should be removed (oldest)
        let messageTexts = offlineMessages.map { $0.text }
        #expect(!messageTexts.contains("Message 1"))
        #expect(messageTexts.contains("Message 2"))
        #expect(messageTexts.contains("Message 3"))
        #expect(messageTexts.contains("Message 4"))
    }
    
    @Test("Network State Integration")
    func networkStateIntegration() async throws {
        // Given
        #expect(offlineViewModel.isOnline() == true)
        #expect(offlineViewModel.getConnectionState() == .online)
        
        // When - Simulate offline state
        offlineViewModel.simulateNetworkState(.offline)
        
        // Then
        #expect(offlineViewModel.isOnline() == false)
        #expect(offlineViewModel.getConnectionState() == .offline)
        
        // When - Simulate connecting state
        offlineViewModel.simulateNetworkState(.connecting)
        
        // Then
        #expect(offlineViewModel.isOnline() == false)
        #expect(offlineViewModel.getConnectionState() == .connecting)
        
        // When - Simulate syncing state
        offlineViewModel.simulateNetworkState(.syncing(3))
        
        // Then
        #expect(offlineViewModel.isOnline() == false)
        #expect(offlineViewModel.getConnectionState() == .syncing(3))
        #expect(offlineViewModel.getConnectionState().syncingCount == 3)
    }
    
    @Test("Message Persistence Across Operations")
    func messagePersistenceAcrossOperations() async throws {
        // Given - Add some messages
        let chatID = "test-chat"
        let senderID = "test-user"
        
        let messageID1 = try await offlineViewModel.queueMessageOffline(
            chatID: chatID,
            text: "Message 1",
            senderID: senderID
        )
        let messageID2 = try await offlineViewModel.queueMessageOffline(
            chatID: chatID,
            text: "Message 2",
            senderID: senderID
        )
        
        #expect(offlineViewModel.getQueuedMessageCount() == 2)
        
        // When - Update message status
        offlineViewModel.updateOfflineState()
        
        // Then - Messages should persist
        #expect(offlineViewModel.getQueuedMessageCount() == 2)
        
        let messages = offlineViewModel.getOfflineMessages()
        #expect(messages.count == 2)
        #expect(messages.contains { $0.id == messageID1 })
        #expect(messages.contains { $0.id == messageID2 })
    }
    
    @Test("Chat-Specific Message Filtering")
    func chatSpecificMessageFiltering() async throws {
        // Given - Messages for different chats
        let chatID1 = "chat-1"
        let chatID2 = "chat-2"
        let senderID = "test-user"
        
        _ = try await offlineViewModel.queueMessageOffline(
            chatID: chatID1,
            text: "Message for chat 1",
            senderID: senderID
        )
        _ = try await offlineViewModel.queueMessageOffline(
            chatID: chatID2,
            text: "Message for chat 2",
            senderID: senderID
        )
        _ = try await offlineViewModel.queueMessageOffline(
            chatID: chatID1,
            text: "Another message for chat 1",
            senderID: senderID
        )
        
        #expect(offlineViewModel.getQueuedMessageCount() == 3)
        
        // When - Get messages for specific chat
        let chat1Messages = offlineViewModel.getMessagesForChat(chatID: chatID1)
        let chat2Messages = offlineViewModel.getMessagesForChat(chatID: chatID2)
        
        // Then - Should filter correctly
        #expect(chat1Messages.count == 2)
        #expect(chat2Messages.count == 1)
        #expect(chat1Messages.allSatisfy { $0.chatID == chatID1 })
        #expect(chat2Messages.allSatisfy { $0.chatID == chatID2 })
    }
    
    @Test("Sync Statistics Integration")
    func syncStatisticsIntegration() async throws {
        // Given - Add some messages
        let chatID = "test-chat"
        let senderID = "test-user"
        
        for i in 1...3 {
            _ = try await offlineViewModel.queueMessageOffline(
                chatID: chatID,
                text: "Message \(i)",
                senderID: senderID
            )
        }
        
        // When - Get sync statistics
        let stats = offlineViewModel.getSyncStatistics()
        
        // Then - Statistics should be accurate
        #expect(stats["queuedMessages"] as? Int == 3)
        #expect(stats["isSyncing"] as? Bool == false)
        #expect(stats["syncProgress"] as? Double == 0.0)
    }
    
    @Test("Queue Space Management")
    func queueSpaceManagement() async throws {
        // Given - Empty queue
        #expect(offlineViewModel.hasQueueSpace() == true)
        #expect(offlineViewModel.getMaxQueueSize() == 3)
        
        // When - Add 2 messages
        for i in 1...2 {
            _ = try await offlineViewModel.queueMessageOffline(
                chatID: "test-chat",
                text: "Message \(i)",
                senderID: "test-user"
            )
        }
        
        // Then - Should have space
        #expect(offlineViewModel.hasQueueSpace() == true)
        #expect(offlineViewModel.getQueuedMessageCount() == 2)
        
        // When - Add one more message (queue full)
        _ = try await offlineViewModel.queueMessageOffline(
            chatID: "test-chat",
            text: "Message 3",
            senderID: "test-user"
        )
        
        // Then - Queue should be full
        #expect(offlineViewModel.hasQueueSpace() == false)
        #expect(offlineViewModel.getQueuedMessageCount() == 3)
    }
    
    @Test("Clear Messages Integration")
    func clearMessagesIntegration() async throws {
        // Given - Add some messages
        for i in 1...3 {
            _ = try await offlineViewModel.queueMessageOffline(
                chatID: "test-chat",
                text: "Message \(i)",
                senderID: "test-user"
            )
        }
        #expect(offlineViewModel.getQueuedMessageCount() == 3)
        
        // When - Clear all messages
        offlineViewModel.clearOfflineMessages()
        
        // Then - Queue should be empty
        #expect(offlineViewModel.getQueuedMessageCount() == 0)
        #expect(offlineViewModel.getOfflineMessages().isEmpty)
        #expect(offlineViewModel.hasMessagesToSync() == false)
    }
    
    @Test("Connection State Transitions")
    func connectionStateTransitions() async throws {
        // Given - Start online
        #expect(offlineViewModel.getConnectionState() == .online)
        
        // When - Transition to offline
        offlineViewModel.simulateNetworkState(.offline)
        
        // Then
        #expect(offlineViewModel.getConnectionState() == .offline)
        #expect(offlineViewModel.isOnline() == false)
        
        // When - Transition to connecting
        offlineViewModel.simulateNetworkState(.connecting)
        
        // Then
        #expect(offlineViewModel.getConnectionState() == .connecting)
        #expect(offlineViewModel.isOnline() == false)
        
        // When - Transition to syncing
        offlineViewModel.simulateNetworkState(.syncing(2))
        
        // Then
        #expect(offlineViewModel.getConnectionState() == .syncing(2))
        #expect(offlineViewModel.getConnectionState().syncingCount == 2)
        #expect(offlineViewModel.isOnline() == false)
        
        // When - Transition back to online
        offlineViewModel.simulateNetworkState(.online)
        
        // Then
        #expect(offlineViewModel.getConnectionState() == .online)
        #expect(offlineViewModel.isOnline() == true)
    }
}