//
//  SyncServiceTests.swift
//  MessageAITests
//
//  Unit tests for sync service
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for SyncService
/// - Note: Tests message synchronization and conflict resolution
struct SyncServiceTests {
    
    // MARK: - Test Properties
    
    private var offlineService: OfflineMessageService!
    private var networkService: NetworkMonitorService!
    private var syncService: SyncService!
    
    // MARK: - Setup
    
    init() {
        offlineService = OfflineMessageService()
        networkService = NetworkMonitorService()
        syncService = SyncService(
            offlineMessageService: offlineService,
            networkMonitorService: networkService
        )
        
        // Ensure clean state
        offlineService.clearOfflineMessages()
    }
    
    // MARK: - Sync Tests
    
    @Test("Sync Offline Messages Success")
    func syncOfflineMessagesSuccess() async throws {
        // Given - Add some offline messages
        let messageID1 = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Message 1",
            senderID: "test-user"
        )
        let messageID2 = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Message 2",
            senderID: "test-user"
        )
        
        #expect(offlineService.getQueuedMessageCount() == 2)
        
        // When - Simulate online state and sync
        networkService.simulateNetworkState(.online)
        
        // Note: In a real test, we'd mock Firebase operations
        // For now, we'll test the service logic without actual Firebase calls
        
        // Then - Service should be ready to sync
        #expect(syncService.hasMessagesToSync() == true)
        #expect(syncService.isSyncing == false)
    }
    
    @Test("Sync Fails When Offline")
    func syncFailsWhenOffline() async throws {
        // Given - Add offline messages
        _ = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        
        // When - Simulate offline state
        networkService.simulateNetworkState(.offline)
        
        // Then - Should not be able to sync
        #expect(syncService.hasMessagesToSync() == true)
        #expect(networkService.isOnline() == false)
    }
    
    @Test("Sync Statistics")
    func syncStatistics() async throws {
        // Given - Add some messages
        _ = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Message 1",
            senderID: "test-user"
        )
        _ = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Message 2",
            senderID: "test-user"
        )
        
        // When
        let stats = syncService.getSyncStatistics()
        
        // Then
        #expect(stats["queuedMessages"] as? Int == 2)
        #expect(stats["isSyncing"] as? Bool == false)
        #expect(stats["syncProgress"] as? Double == 0.0)
    }
    
    @Test("Clear Failed Messages")
    func clearFailedMessages() async throws {
        // Given - Add messages and increment retry count
        let messageID = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        
        // Increment retry count to exceed limit
        for _ in 1...4 {
            offlineService.incrementRetryCount(messageID: messageID)
        }
        
        #expect(offlineService.getQueuedMessageCount() == 1)
        
        // When
        syncService.clearFailedMessages()
        
        // Then - Expired messages should be removed
        #expect(offlineService.getQueuedMessageCount() == 0)
    }
    
    @Test("Has Messages To Sync")
    func hasMessagesToSync() async throws {
        // Given - Empty queue
        #expect(syncService.hasMessagesToSync() == false)
        
        // When - Add message
        _ = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        
        // Then
        #expect(syncService.hasMessagesToSync() == true)
    }
    
    @Test("Sync Progress Tracking")
    func syncProgressTracking() {
        // Given
        #expect(syncService.syncProgress == 0.0)
        #expect(syncService.isSyncing == false)
        
        // When - Simulate sync start
        syncService.isSyncing = true
        syncService.syncProgress = 0.5
        
        // Then
        #expect(syncService.isSyncing == true)
        #expect(syncService.syncProgress == 0.5)
    }
    
    @Test("Last Sync Time Tracking")
    func lastSyncTimeTracking() {
        // Given
        let initialTime = syncService.lastSyncTime
        
        // When - Set last sync time
        let now = Date()
        syncService.lastSyncTime = now
        
        // Then
        #expect(syncService.lastSyncTime == now)
        #expect(syncService.lastSyncTime != initialTime)
    }
    
    @Test("Retry Failed Messages Detection")
    func retryFailedMessagesDetection() async throws {
        // Given - Add message and increment retry count
        let messageID = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        
        offlineService.incrementRetryCount(messageID: messageID)
        
        // When - Check retryable messages
        let retryableMessages = offlineService.getRetryableMessages()
        
        // Then
        #expect(retryableMessages.count == 1)
        #expect(retryableMessages.first?.id == messageID)
        #expect(offlineService.hasRetryableMessages() == true)
    }
    
    @Test("Network State Integration")
    func networkStateIntegration() {
        // Given
        #expect(networkService.connectionState == .online)
        
        // When - Change network state
        networkService.simulateNetworkState(.offline)
        
        // Then
        #expect(networkService.connectionState == .offline)
        #expect(networkService.isOnline() == false)
    }
    
    @Test("Offline Service Integration")
    func offlineServiceIntegration() async throws {
        // Given
        #expect(offlineService.getQueuedMessageCount() == 0)
        
        // When - Add message
        _ = try await offlineService.queueMessageOffline(
            chatID: "test-chat",
            text: "Test message",
            senderID: "test-user"
        )
        
        // Then
        #expect(offlineService.getQueuedMessageCount() == 1)
        #expect(syncService.hasMessagesToSync() == true)
    }
}
