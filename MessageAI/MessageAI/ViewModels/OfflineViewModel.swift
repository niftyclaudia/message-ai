//
//  OfflineViewModel.swift
//  MessageAI
//
//  View model for offline persistence and sync management
//

import Foundation
import SwiftUI

/// View model for managing offline state and UI updates
/// - Note: Coordinates between offline message service, network monitoring, and sync service
@MainActor
class OfflineViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var connectionState: ConnectionState = .online
    @Published var queuedMessageCount: Int = 0
    @Published var isQueueFull: Bool = false
    @Published var isSyncing: Bool = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncTime: Date?
    
    // MARK: - Private Properties
    
    private let offlineMessageService: OfflineMessageService
    private let networkMonitorService: NetworkMonitorService
    private let syncService: SyncService
    
    // MARK: - Initialization
    
    init() {
        self.offlineMessageService = OfflineMessageService()
        self.networkMonitorService = NetworkMonitorService()
        self.syncService = SyncService(
            offlineMessageService: offlineMessageService,
            networkMonitorService: networkMonitorService
        )
        
        setupObservers()
        loadInitialState()
    }
    
    // MARK: - Public Methods
    
    /// Queues a message for offline delivery
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - text: The message text
    ///   - senderID: The sender's user ID
    /// - Returns: Message ID
    /// - Throws: OfflineMessageServiceError for various failure scenarios
    func queueMessageOffline(chatID: String, text: String, senderID: String) async throws -> String {
        let messageID = try await offlineMessageService.queueMessageOffline(
            chatID: chatID,
            text: text,
            senderID: senderID
        )
        
        // Update UI state
        updateQueueState()
        
        return messageID
    }
    
    /// Gets all offline messages
    /// - Returns: Array of offline messages
    func getOfflineMessages() -> [OfflineMessage] {
        return offlineMessageService.getOfflineMessages()
    }
    
    /// Clears all offline messages
    func clearOfflineMessages() {
        offlineMessageService.clearOfflineMessages()
        updateQueueState()
    }
    
    /// Retries failed messages
    func retryFailedMessages() async {
        do {
            _ = try await syncService.retryFailedMessages()
            updateQueueState()
        } catch {
            // Silently fail - retry is not critical
        }
    }
    
    /// Starts automatic sync when network becomes available
    func startAutoSync() {
        syncService.startAutoSync()
    }
    
    /// Checks if the device is currently online
    /// - Returns: True if online, false if offline
    func isOnline() -> Bool {
        return networkMonitorService.isOnline()
    }
    
    /// Gets the current connection state
    /// - Returns: Current connection state
    func getConnectionState() -> ConnectionState {
        return connectionState
    }
    
    /// Gets sync statistics
    /// - Returns: Dictionary with sync statistics
    func getSyncStatistics() -> [String: Any] {
        return syncService.getSyncStatistics()
    }
    
    /// Checks if there are messages that need syncing
    /// - Returns: True if there are messages to sync
    func hasMessagesToSync() -> Bool {
        return syncService.hasMessagesToSync()
    }
    
    /// Gets the maximum queue size
    /// - Returns: Maximum number of messages allowed in queue
    func getMaxQueueSize() -> Int {
        return offlineMessageService.getMaxQueueSize()
    }
    
    /// Checks if the queue has space for new messages
    /// - Returns: True if queue has space
    func hasQueueSpace() -> Bool {
        return offlineMessageService.hasQueueSpace()
    }
    
    /// Gets messages for a specific chat
    /// - Parameter chatID: The chat ID to filter by
    /// - Returns: Array of offline messages for that chat
    func getMessagesForChat(chatID: String) -> [OfflineMessage] {
        return offlineMessageService.getMessagesForChat(chatID: chatID)
    }
    
    /// Simulates network state for testing
    /// - Parameter state: The state to simulate
    func simulateNetworkState(_ state: ConnectionState) {
        networkMonitorService.simulateNetworkState(state)
        connectionState = state
    }
    
    // MARK: - Private Methods
    
    /// Sets up observers for state changes
    private func setupObservers() {
        // Observe network state changes
        Task {
            for await state in networkMonitorService.observeNetworkState() {
                // State change already logged by NetworkMonitorService
                connectionState = state
                
                // Start auto-sync when coming back online
                if state.isOnline && hasMessagesToSync() {
                    startAutoSync()
                }
            }
        }
        
        // Observe offline message service changes
        offlineMessageService.$queuedMessages
            .sink { [weak self] _ in
                self?.updateQueueState()
            }
            .store(in: &cancellables)
        
        // Observe sync service changes
        syncService.$isSyncing
            .sink { [weak self] isSyncing in
                self?.isSyncing = isSyncing
            }
            .store(in: &cancellables)
        
        syncService.$syncProgress
            .sink { [weak self] progress in
                self?.syncProgress = progress
            }
            .store(in: &cancellables)
        
        syncService.$lastSyncTime
            .sink { [weak self] lastSync in
                self?.lastSyncTime = lastSync
            }
            .store(in: &cancellables)
    }
    
    /// Loads initial state from services
    private func loadInitialState() {
        connectionState = networkMonitorService.connectionState
        updateQueueState()
    }
    
    /// Updates queue-related UI state
    private func updateQueueState() {
        queuedMessageCount = offlineMessageService.getQueuedMessageCount()
        isQueueFull = offlineMessageService.isQueueFull
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Combine Import

import Combine
