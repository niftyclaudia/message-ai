//
//  SyncService.swift
//  MessageAI
//
//  Message synchronization service for offline persistence
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for synchronizing offline messages with Firebase
/// - Note: Handles message sync, conflict resolution, and retry logic
class SyncService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isSyncing: Bool = false
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncTime: Date?
    
    // MARK: - Private Properties
    
    private let firestore: Firestore
    private let offlineMessageService: OfflineMessageService
    private let networkMonitorService: NetworkMonitorService
    private let maxRetryCount = 3
    private let syncTimeout: TimeInterval = 30.0 // 30 seconds timeout
    
    // MARK: - Initialization
    
    init(offlineMessageService: OfflineMessageService, networkMonitorService: NetworkMonitorService) {
        self.firestore = FirebaseService.shared.getFirestore()
        self.offlineMessageService = offlineMessageService
        self.networkMonitorService = networkMonitorService
    }
    
    // MARK: - Public Methods
    
    /// Syncs all offline messages to Firebase
    /// - Returns: Number of messages successfully synced
    /// - Throws: SyncServiceError for various failure scenarios
    func syncOfflineMessages() async throws -> Int {
        guard await networkMonitorService.isOnline() else {
            throw SyncServiceError.offline
        }
        
        let offlineMessages = offlineMessageService.getOfflineMessages()
        guard !offlineMessages.isEmpty else {
            return 0
        }
        
        isSyncing = true
        syncProgress = 0.0
        
        var syncedCount = 0
        let totalMessages = offlineMessages.count
        
        do {
            // Update UI to show syncing state
            await await networkMonitorService.updateToSyncing(messageCount: totalMessages)
            
            for (index, offlineMessage) in offlineMessages.enumerated() {
                do {
                    // Convert offline message to Firebase message
                    let message = offlineMessage.toMessage()
                    
                    // Save to Firestore
                    try firestore.collection("chats")
                        .document(offlineMessage.chatID)
                        .collection(Message.collectionName)
                        .document(offlineMessage.id)
                        .setData(from: message)
                    
                    // Update chat's last message info
                    try await updateChatLastMessage(
                        chatID: offlineMessage.chatID,
                        message: message
                    )
                    
                    // Remove from offline queue
                    offlineMessageService.removeOfflineMessage(messageID: offlineMessage.id)
                    
                    syncedCount += 1
                    
                    // Update progress
                    syncProgress = Double(index + 1) / Double(totalMessages)
                    
                } catch {
                    // Handle individual message failure
                    offlineMessageService.incrementRetryCount(messageID: offlineMessage.id)
                    
                    // If retry limit exceeded, remove from queue
                    if !offlineMessage.canRetry(maxRetries: maxRetryCount) {
                        offlineMessageService.removeOfflineMessage(messageID: offlineMessage.id)
                    }
                }
            }
            
            // Update UI to show online state
            await networkMonitorService.updateToOnline()
            lastSyncTime = Date()
            
        } catch {
            // Reset syncing state on error
            isSyncing = false
            syncProgress = 0.0
            await networkMonitorService.updateToOnline()
            throw SyncServiceError.syncFailed(error)
        }
        
        isSyncing = false
        syncProgress = 1.0
        
        return syncedCount
    }
    
    /// Retries failed messages with exponential backoff
    /// - Returns: Number of messages successfully retried
    /// - Throws: SyncServiceError for various failure scenarios
    func retryFailedMessages() async throws -> Int {
        guard await networkMonitorService.isOnline() else {
            throw SyncServiceError.offline
        }
        
        let retryableMessages = offlineMessageService.getRetryableMessages()
        guard !retryableMessages.isEmpty else {
            return 0
        }
        
        isSyncing = true
        syncProgress = 0.0
        
        var retriedCount = 0
        let totalMessages = retryableMessages.count
        
        do {
            // Update UI to show syncing state
            await networkMonitorService.updateToSyncing(messageCount: totalMessages)
            
            for (index, offlineMessage) in retryableMessages.enumerated() {
                do {
                    // Apply exponential backoff
                    let backoffDelay = min(pow(2.0, Double(offlineMessage.retryCount)), 30.0)
                    try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                    
                    // Convert offline message to Firebase message
                    let message = offlineMessage.toMessage()
                    
                    // Save to Firestore
                    try firestore.collection("chats")
                        .document(offlineMessage.chatID)
                        .collection(Message.collectionName)
                        .document(offlineMessage.id)
                        .setData(from: message)
                    
                    // Update chat's last message info
                    try await updateChatLastMessage(
                        chatID: offlineMessage.chatID,
                        message: message
                    )
                    
                    // Remove from offline queue
                    offlineMessageService.removeOfflineMessage(messageID: offlineMessage.id)
                    
                    retriedCount += 1
                    
                    // Update progress
                    syncProgress = Double(index + 1) / Double(totalMessages)
                    
                } catch {
                    // Handle individual message failure
                    offlineMessageService.incrementRetryCount(messageID: offlineMessage.id)
                    
                    // If retry limit exceeded, remove from queue
                    if !offlineMessage.canRetry(maxRetries: maxRetryCount) {
                        offlineMessageService.removeOfflineMessage(messageID: offlineMessage.id)
                    }
                }
            }
            
            // Update UI to show online state
            await networkMonitorService.updateToOnline()
            lastSyncTime = Date()
            
        } catch {
            // Reset syncing state on error
            isSyncing = false
            syncProgress = 0.0
            await networkMonitorService.updateToOnline()
            throw SyncServiceError.syncFailed(error)
        }
        
        isSyncing = false
        syncProgress = 1.0
        
        return retriedCount
    }
    
    /// Starts automatic sync when network becomes available
    func startAutoSync() {
        Task {
            // Wait for network connection
            let connected = await networkMonitorService.waitForConnection(timeout: syncTimeout)
            
            if connected {
                do {
                    _ = try await syncOfflineMessages()
                } catch {
                    // Silently fail - auto-sync is not critical
                }
            }
        }
    }
    
    /// Gets sync statistics
    /// - Returns: Dictionary with sync statistics
    func getSyncStatistics() -> [String: Any] {
        let queuedCount = offlineMessageService.getQueuedMessageCount()
        let retryableCount = offlineMessageService.getRetryableMessages().count
        
        return [
            "queuedMessages": queuedCount,
            "retryableMessages": retryableCount,
            "isSyncing": isSyncing,
            "lastSyncTime": lastSyncTime ?? Date.distantPast,
            "syncProgress": syncProgress
        ]
    }
    
    /// Clears all failed messages from the queue
    func clearFailedMessages() {
        offlineMessageService.removeExpiredMessages()
    }
    
    /// Checks if there are messages that need syncing
    /// - Returns: True if there are messages to sync
    func hasMessagesToSync() -> Bool {
        return !offlineMessageService.getOfflineMessages().isEmpty
    }
    
    // MARK: - Private Methods
    
    /// Updates chat's last message information
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - message: The message that was sent
    private func updateChatLastMessage(chatID: String, message: Message) async throws {
        let chatRef = firestore.collection("chats").document(chatID)
        
        try await chatRef.updateData([
            "lastMessage": message.text,
            "lastMessageTimestamp": message.timestamp,
            "lastMessageSenderID": message.senderID
        ])
    }
}

// MARK: - SyncServiceError

/// Errors that can occur in SyncService operations
enum SyncServiceError: LocalizedError {
    case offline
    case syncFailed(Error)
    case timeout
    case permissionDenied
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "Device is offline, cannot sync messages"
        case .syncFailed(let error):
            return "Sync failed: \(error.localizedDescription)"
        case .timeout:
            return "Sync operation timed out"
        case .permissionDenied:
            return "Permission denied to sync messages"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
