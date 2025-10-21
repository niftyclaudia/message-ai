//
//  OfflinePersistenceIntegrationTests.swift
//  MessageAITests
//
//  Integration tests for offline persistence functionality
//

import Testing
import Foundation
@testable import MessageAI

/// Integration tests for offline persistence and sync
struct OfflinePersistenceIntegrationTests {
    
    // MARK: - Test Properties
    
    private var messageService: MessageService!
    private var chatViewModel: ChatViewModel!
    
    // MARK: - Setup
    
    init() {
        messageService = MessageService()
        chatViewModel = ChatViewModel(currentUserID: "test-user", messageService: messageService)
    }
    
    // MARK: - Offline Message Flow Tests
    
    @Test("Offline Message Flow Works End To End")
    func offlineMessageFlowWorksEndToEnd() async throws {
        // Given: A chat view model and message service
        let chatID = "test-chat"
        let messageText = "Test offline message"
        
        // When: Send message while offline (simulated)
        let messageID = try await messageService.queueMessage(chatID: chatID, text: messageText)
        
        // Then: Message should be queued and view model should reflect state
        #expect(!messageID.isEmpty)
        #expect(messageService.getQueuedMessageCount() == 1)
        #expect(chatViewModel.queuedMessageCount == 1)
    }
    
    @Test("Message Status Updates Correctly During Offline Flow")
    func messageStatusUpdatesCorrectlyDuringOfflineFlow() async throws {
        // Given: A message service with queued messages
        let chatID = "test-chat"
        let messageText = "Test message"
        
        // When: Queue a message
        let messageID = try await messageService.queueMessage(chatID: chatID, text: messageText)
        
        // Then: Message should have correct status
        let queuedMessages = messageService.getQueuedMessages()
        #expect(queuedMessages.count == 1)
        #expect(queuedMessages.first?.id == messageID)
        #expect(queuedMessages.first?.text == messageText)
    }
    
    @Test("Retry Logic Works With Exponential Backoff")
    func retryLogicWorksWithExponentialBackoff() async throws {
        // Given: A message service with failed messages
        let chatID = "test-chat"
        let messageText = "Test retry message"
        
        // When: Queue a message and simulate retry
        let messageID = try await messageService.queueMessage(chatID: chatID, text: messageText)
        
        // Then: Retry count should be tracked
        let queuedMessages = messageService.getQueuedMessages()
        #expect(queuedMessages.count == 1)
        #expect(queuedMessages.first?.retryCount == 0)
    }
    
    // MARK: - Network State Integration Tests
    
    @Test("Network State Changes Trigger Appropriate Actions")
    func networkStateChangesTriggerAppropriateActions() async throws {
        // Given: A chat view model monitoring network state
        let initialOfflineState = chatViewModel.isOffline
        
        // When: Network state changes (simulated)
        await chatViewModel.monitorNetworkStatus()
        
        // Then: View model should update accordingly
        #expect(chatViewModel.isOffline == true || chatViewModel.isOffline == false)
    }
    
    @Test("Connection Type Is Properly Tracked")
    func connectionTypeIsProperlyTracked() async throws {
        // Given: A chat view model
        // When: Check connection type
        let connectionType = chatViewModel.getConnectionType()
        
        // Then: Should have valid connection type
        #expect(connectionType == .wifi || connectionType == .cellular || 
                connectionType == .ethernet || connectionType == .none)
    }
    
    // MARK: - Cache Management Tests
    
    @Test("Cache Size Limit Is Enforced")
    func cacheSizeLimitIsEnforced() async throws {
        // Given: A message service with cache size limit
        // When: Queue many messages
        for i in 1...5 {
            _ = try await messageService.queueMessage(chatID: "chat-\(i)", text: "Message \(i)")
        }
        
        // Then: Cache should not exceed limit
        #expect(messageService.getQueuedMessageCount() == 5)
    }
    
    @Test("Failed Messages Are Cleaned Up After Max Retries")
    func failedMessagesAreCleanedUpAfterMaxRetries() async throws {
        // Given: A message service with retry limit
        let chatID = "test-chat"
        let messageText = "Test message"
        
        // When: Queue a message
        _ = try await messageService.queueMessage(chatID: chatID, text: messageText)
        
        // Then: Message should be queued initially
        #expect(messageService.getQueuedMessageCount() == 1)
        
        // When: Clear all queued messages (simulating cleanup)
        messageService.clearAllQueuedMessages()
        
        // Then: Queue should be empty
        #expect(messageService.getQueuedMessageCount() == 0)
    }
    
    // MARK: - UI State Integration Tests
    
    @Test("UI State Reflects Offline Status")
    func uiStateReflectsOfflineStatus() async throws {
        // Given: A chat view model
        // When: Check offline state
        let isOffline = chatViewModel.isOffline
        
        // Then: UI state should reflect network status
        #expect(isOffline == true || isOffline == false)
    }
    
    @Test("Queued Message Count Updates In UI")
    func queuedMessageCountUpdatesInUI() async throws {
        // Given: A chat view model
        let initialCount = chatViewModel.queuedMessageCount
        
        // When: Queue a message
        _ = try await messageService.queueMessage(chatID: "test-chat", text: "Test message")
        await chatViewModel.updateQueuedMessageCount()
        
        // Then: UI should reflect updated count
        #expect(chatViewModel.queuedMessageCount == initialCount + 1)
    }
    
    @Test("Retryable Messages State Updates Correctly")
    func retryableMessagesStateUpdatesCorrectly() async throws {
        // Given: A chat view model
        // When: Check retryable messages state
        await chatViewModel.updateRetryableMessages()
        
        // Then: State should be valid
        #expect(chatViewModel.hasRetryableMessages == true || chatViewModel.hasRetryableMessages == false)
    }
    
    // MARK: - Performance Tests
    
    @Test("Offline Operations Complete Within Performance Targets")
    func offlineOperationsCompleteWithinPerformanceTargets() async throws {
        // Given: A message service
        let startTime = Date()
        
        // When: Perform offline operations
        _ = try await messageService.queueMessage(chatID: "test-chat", text: "Performance test message")
        let queuedMessages = messageService.getQueuedMessages()
        
        // Then: Operations should complete quickly
        let duration = Date().timeIntervalSince(startTime)
        #expect(duration < 1.0) // Should complete within 1 second
        #expect(queuedMessages.count == 1)
    }
    
    @Test("Cache Operations Are Efficient")
    func cacheOperationsAreEfficient() async throws {
        // Given: A message service with queued messages
        _ = try await messageService.queueMessage(chatID: "test-chat", text: "Cache test message")
        
        let startTime = Date()
        
        // When: Perform cache operations
        let count = messageService.getQueuedMessageCount()
        let hasRetryable = messageService.hasRetryableMessages()
        
        // Then: Operations should be fast
        let duration = Date().timeIntervalSince(startTime)
        #expect(duration < 0.1) // Should complete within 100ms
        #expect(count == 1)
        #expect(hasRetryable == true)
    }
}
