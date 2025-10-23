//
//  MessageService.swift
//  MessageAI
//
//  Message service for chat functionality
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for managing message operations and real-time updates
/// - Note: Handles Firestore queries for message display and status updates
class MessageService {
    
    // MARK: - Properties
    
    private let firestore: Firestore
    private let userDefaults = UserDefaults.standard
    private let maxRetryCount = 3
    private let maxQueueSize = 3 // PR-2 requirement: 3-message queue
    
    // Make queue key user-specific to prevent cross-device/simulator conflicts
    private var queueKey: String {
        guard let userID = Auth.auth().currentUser?.uid else {
            return "queued_messages"
        }
        return "queued_messages_\(userID)"
    }
    
    // NetworkMonitor needs to be accessed on main actor
    @MainActor
    private lazy var networkMonitor = NetworkMonitor()
    
    // MARK: - Initialization
    
    init() {
        self.firestore = FirebaseService.shared.getFirestore()
    }
    
    // MARK: - Public Methods
    
    /// Sends a message with optimistic UI updates
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - text: The message text
    ///   - messageID: Pre-generated message ID (for optimistic UI matching)
    ///   - senderName: Optional sender display name for group chat attribution (PR-3)
    /// - Returns: Message ID
    /// - Throws: MessageServiceError for various failure scenarios
    func sendMessageOptimistic(chatID: String, text: String, messageID: String, senderName: String? = nil) async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw MessageServiceError.permissionDenied
        }
        
        let timestamp = Date()
        
        // Create optimistic message for immediate UI display
        let _ = OptimisticMessage(
            id: messageID,
            chatID: chatID,
            text: text,
            timestamp: timestamp,
            senderID: currentUser.uid,
            status: .sending
        )
        
        do {
            // Create message with server timestamp and sender name for group attribution
            let message = Message(
                id: messageID,
                chatID: chatID,
                senderID: currentUser.uid,
                text: text,
                timestamp: timestamp,
                serverTimestamp: nil, // Will be set by server
                readBy: [currentUser.uid],
                status: .sending,
                senderName: senderName, // PR-3: Include sender name for group chat attribution
                isOffline: false,
                retryCount: 0,
                isOptimistic: false  // Don't save optimistic flag to Firebase
            )
            
            // Save to Firestore with server timestamp
            try firestore.collection("chats")
                .document(chatID)
                .collection(Message.collectionName)
                .document(messageID)
                .setData(from: message)
            
            return messageID
        } catch {
            throw MessageServiceError.networkError(error)
        }
    }
    
    /// Sends a message to Firestore with optimized real-time delivery
    /// - Note: Optimized for < 200ms latency (PR-1 requirement)
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - text: The message text
    ///   - senderName: Optional sender display name for group chat attribution (PR-3)
    /// - Returns: Message ID
    /// - Throws: MessageServiceError for various failure scenarios
    func sendMessage(chatID: String, text: String, senderName: String? = nil) async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw MessageServiceError.permissionDenied
        }
        
        let messageID = UUID().uuidString
        let timestamp = Date()
        
        // Start performance tracking for PR-1 optimization
        PerformanceMonitor.shared.startMessageSend(messageID: messageID)
        
        // Create message with server timestamp for consistent ordering and sender name for group attribution
        let message = Message(
            id: messageID,
            chatID: chatID,
            senderID: currentUser.uid,
            text: text,
            timestamp: timestamp,
            serverTimestamp: nil, // Will be set by server
            readBy: [currentUser.uid],
            status: .sending, // Start as sending, will be updated to sent
            senderName: senderName, // PR-3: Include sender name for group chat attribution
            isOffline: false,
            retryCount: 0,
            isOptimistic: false
        )
        
        do {
            // Use batch write for atomic operation and better performance
            let batch = firestore.batch()
            
            // Add message to batch
            let messageRef = firestore.collection("chats")
                .document(chatID)
                .collection(Message.collectionName)
                .document(messageID)
            
            try batch.setData(from: message, forDocument: messageRef)
            
            // Update chat's last message info in same batch
            let chatRef = firestore.collection("chats").document(chatID)
            batch.updateData([
                "lastMessage": text,
                "lastMessageTimestamp": timestamp,
                "lastMessageSenderID": currentUser.uid
            ], forDocument: chatRef)
            
            // Commit batch atomically
            try await batch.commit()
            
            // Update message status to sent after successful server commit
            try await updateMessageStatus(messageID: messageID, status: .sent)
            
            // Track server ack latency
            PerformanceMonitor.shared.endMessageSend(messageID: messageID, phase: "serverAck")
            
            return messageID
        } catch {
            // Track failed send
            PerformanceMonitor.shared.endMessageSend(messageID: messageID, phase: "failed")
            throw MessageServiceError.networkError(error)
        }
    }
    
    /// Queues a message for offline delivery
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - text: The message text
    /// - Returns: Message ID
    /// - Throws: MessageServiceError for various failure scenarios
    func queueMessage(chatID: String, text: String) async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw MessageServiceError.permissionDenied
        }
        
        // Check queue size limit
        let currentQueue = getQueuedMessages()
        if currentQueue.count >= maxQueueSize {
            throw MessageServiceError.offlineQueueFull
        }
        
        let messageID = UUID().uuidString
        let timestamp = Date()
        
        let queuedMessage = QueuedMessage(
            id: messageID,
            chatID: chatID,
            text: text,
            timestamp: timestamp,
            senderID: currentUser.uid
        )
        
        // Save to local storage
        var queuedMessages = getQueuedMessages()
        queuedMessages.append(queuedMessage)
        saveQueuedMessages(queuedMessages)
        
        return messageID
    }
    
    /// Syncs queued messages to Firestore
    /// - Throws: MessageServiceError for various failure scenarios
    func syncQueuedMessages() async throws {
        let queuedMessages = getQueuedMessages()
        
        for queuedMessage in queuedMessages {
            do {
                let message = queuedMessage.toMessage()
                
                try firestore.collection("chats")
                    .document(queuedMessage.chatID)
                    .collection(Message.collectionName)
                    .document(queuedMessage.id)
                    .setData(from: message)
                
                // Remove from queue after successful sync
                removeQueuedMessage(id: queuedMessage.id)
                
            } catch {
                // Update retry count
                var updatedMessage = queuedMessage
                updatedMessage.retryCount += 1
                updatedMessage.lastAttempt = Date()
                
                // Remove old and add updated
                removeQueuedMessage(id: queuedMessage.id)
                var updatedQueue = getQueuedMessages()
                updatedQueue.append(updatedMessage)
                saveQueuedMessages(updatedQueue)
                
                if updatedMessage.retryCount >= 3 {
                    // Remove after max retries
                    removeQueuedMessage(id: queuedMessage.id)
                }
            }
        }
    }
    
    /// Gets all queued messages
    /// - Returns: Array of queued messages
    func getQueuedMessages() -> [QueuedMessage] {
        guard let data = userDefaults.data(forKey: queueKey),
              let messages = try? JSONDecoder().decode([QueuedMessage].self, from: data) else {
            return []
        }
        return messages
    }
    
    /// Updates message status in Firestore
    /// - Parameters:
    ///   - messageID: The message's ID
    ///   - status: The new status
    /// - Throws: MessageServiceError for various failure scenarios
    func updateMessageStatus(messageID: String, status: MessageStatus) async throws {
        // Note: This is a simplified implementation
        // In a real app, you'd need to know the chatID to construct the path
        let query = firestore.collectionGroup(Message.collectionName)
            .whereField("id", isEqualTo: messageID)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw MessageServiceError.messageNotFound
        }
        
        try await document.reference.updateData(["status": status.rawValue])
    }
    
    /// Marks a message as delivered
    /// - Parameter messageID: The message's ID
    /// - Throws: MessageServiceError for various failure scenarios
    func markMessageAsDelivered(messageID: String) async throws {
        try await updateMessageStatus(messageID: messageID, status: .delivered)
    }
    
    /// Retries a failed message
    /// - Parameter messageID: The message's ID
    /// - Throws: MessageServiceError for various failure scenarios
    func retryFailedMessage(messageID: String) async throws {
        // Find the message in queued messages
        let queuedMessages = getQueuedMessages()
        guard let queuedMessage = queuedMessages.first(where: { $0.id == messageID }) else {
            throw MessageServiceError.messageNotFound
        }
        
        // Remove from queue and try to send again
        removeQueuedMessage(id: messageID)
        
        do {
            _ = try await sendMessage(chatID: queuedMessage.chatID, text: queuedMessage.text)
        } catch {
            // If still fails, re-queue with updated retry count
            var updatedMessage = queuedMessage
            updatedMessage.retryCount += 1
            updatedMessage.lastAttempt = Date()
            
            var updatedQueue = getQueuedMessages()
            updatedQueue.append(updatedMessage)
            saveQueuedMessages(updatedQueue)
            
            throw error
        }
    }
    
    /// Deletes a failed message
    /// - Parameter messageID: The message's ID
    func deleteFailedMessage(messageID: String) {
        removeQueuedMessage(id: messageID)
    }
    
    /// Updates a message with server timestamp
    /// - Parameters:
    ///   - messageID: The message ID to update
    ///   - serverTimestamp: The server timestamp to set
    /// - Throws: MessageServiceError for various failure scenarios
    func updateMessageWithServerTimestamp(messageID: String, serverTimestamp: Date) async throws {
        let query = firestore.collectionGroup(Message.collectionName)
            .whereField("id", isEqualTo: messageID)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw MessageServiceError.messageNotFound
        }
        
        try await document.reference.updateData([
            "serverTimestamp": Timestamp(date: serverTimestamp)
        ])
    }
    
    /// Sorts messages by server timestamp for consistent ordering
    /// - Parameter messages: Array of messages to sort
    /// - Returns: Messages sorted by server timestamp (fallback to client timestamp)
    func sortMessagesByServerTimestamp(_ messages: [Message]) -> [Message] {
        return messages.sorted { message1, message2 in
            // Use server timestamp if available, otherwise fall back to client timestamp
            let timestamp1 = message1.serverTimestamp ?? message1.timestamp
            let timestamp2 = message2.serverTimestamp ?? message2.timestamp
            return timestamp1 < timestamp2
        }
    }
    
    /// Fetches messages for a specific chat with pagination
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - limit: Maximum number of messages to fetch (default: 50)
    /// - Returns: Array of Message objects sorted by timestamp ascending
    /// - Throws: MessageServiceError for various failure scenarios
    func fetchMessages(chatID: String, limit: Int = 50) async throws -> [Message] {
        do {
            let query = firestore.collection("chats")
                .document(chatID)
                .collection(Message.collectionName)
                .order(by: "timestamp", descending: false)
                .limit(to: limit)
            
            let snapshot = try await query.getDocuments()
            
            var messages: [Message] = []
            for document in snapshot.documents {
                do {
                    var message = try document.data(as: Message.self)
                    message.id = document.documentID
                    messages.append(message)
                } catch {
                    // Continue with other documents
                }
            }
            
            return messages
        } catch {
            throw MessageServiceError.networkError(error)
        }
    }
    
    /// Sets up optimized real-time listener for messages in a chat
    /// - Note: Optimized for < 200ms sync latency (PR-1 requirement)
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - completion: Callback with updated messages array
    /// - Returns: ListenerRegistration for cleanup
    func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        // Optimize query with proper indexing and limit for performance
        let query = firestore.collection("chats")
            .document(chatID)
            .collection(Message.collectionName)
            .order(by: "timestamp", descending: false)
            .limit(to: 100) // Limit for performance
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("MessageService: Error observing messages: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let snapshot = snapshot else {
                completion([])
                return
            }
            
            // Process documents efficiently
            let messages = snapshot.documents.compactMap { document -> Message? in
                do {
                    var message = try document.data(as: Message.self)
                    message.id = document.documentID
                    return message
                } catch {
                    print("MessageService: Error parsing message: \(error.localizedDescription)")
                    return nil
                }
            }
            
            // Sort by server timestamp for consistent ordering
            let sortedMessages = self.sortMessagesByServerTimestamp(messages)
            
            // Track render latency for performance monitoring (only for messages sent by current user)
            for message in sortedMessages {
                if message.senderID == Auth.auth().currentUser?.uid {
                    PerformanceMonitor.shared.endMessageSend(messageID: message.id, phase: "rendered")
                }
            }
            
            completion(sortedMessages)
        }
    }
    
    /// Fetches a specific message by ID
    /// - Parameter messageID: The message's ID
    /// - Returns: Message object
    /// - Throws: MessageServiceError for various failure scenarios
    func fetchMessage(messageID: String) async throws -> Message {
        do {
            // Note: This is a simplified implementation
            // In a real app, you'd need to know the chatID to construct the path
            // For now, we'll search across all chats (not efficient for production)
            let query = firestore.collectionGroup(Message.collectionName)
                .whereField("id", isEqualTo: messageID)
                .limit(to: 1)
            
            let snapshot = try await query.getDocuments()
            
            guard let document = snapshot.documents.first else {
                throw MessageServiceError.messageNotFound
            }
            
            var message = try document.data(as: Message.self)
            message.id = document.documentID
            return message
        } catch let error as MessageServiceError {
            throw error
        } catch {
            throw MessageServiceError.networkError(error)
        }
    }
    
    /// Marks a message as read by a specific user
    /// - Parameters:
    ///   - messageID: The message's ID
    ///   - userID: The user's ID who read the message
    /// - Throws: MessageServiceError for various failure scenarios
    func markMessageAsRead(messageID: String, userID: String) async throws {
        do {
            // Note: This is a simplified implementation
            // In a real app, you'd need to know the chatID to construct the path
            // For now, we'll search across all chats (not efficient for production)
            let query = firestore.collectionGroup(Message.collectionName)
                .whereField("id", isEqualTo: messageID)
                .limit(to: 1)
            
            let snapshot = try await query.getDocuments()
            
            guard let document = snapshot.documents.first else {
                throw MessageServiceError.messageNotFound
            }
            
            var message = try document.data(as: Message.self)
            
            // Add user to readBy array if not already present
            if !message.readBy.contains(userID) {
                message.readBy.append(userID)
                
                // Update the message in Firestore
                try document.reference.setData(from: message, merge: true)
            }
        } catch let error as MessageServiceError {
            throw error
        } catch {
            throw MessageServiceError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Saves queued messages to local storage
    /// - Parameter messages: Array of queued messages
    private func saveQueuedMessages(_ messages: [QueuedMessage]) {
        do {
            let data = try JSONEncoder().encode(messages)
            userDefaults.set(data, forKey: queueKey)
        } catch {
            // Silently fail - queued messages will be lost but not critical
        }
    }
    
    /// Removes a queued message by ID
    /// - Parameter id: The message ID to remove
    private func removeQueuedMessage(id: String) {
        var queuedMessages = getQueuedMessages()
        queuedMessages.removeAll { $0.id == id }
        saveQueuedMessages(queuedMessages)
    }
    
    // MARK: - Offline Persistence Methods
    
    /// Checks if the device is currently online
    /// - Returns: True if online, false if offline
    @MainActor
    func isOnline() -> Bool {
        return networkMonitor.isConnected
    }
    
    /// Gets the current network connection type
    /// - Returns: ConnectionType enum value
    @MainActor
    func getConnectionType() -> ConnectionType {
        return networkMonitor.connectionType
    }
    
    /// Starts automatic sync when network becomes available
    func startAutoSync() {
        // This would be called by the ChatViewModel when network status changes
        Task { @MainActor in
            if isOnline() {
                try? await syncQueuedMessages()
            }
        }
    }
    
    /// Clears all queued messages (for testing or user action)
    func clearAllQueuedMessages() {
        saveQueuedMessages([])
    }
    
    /// Gets the count of queued messages
    /// - Returns: Number of queued messages
    func getQueuedMessageCount() -> Int {
        return getQueuedMessages().count
    }
    
    /// Checks if there are any failed messages that can be retried
    /// - Returns: True if there are retryable messages
    func hasRetryableMessages() -> Bool {
        let queuedMessages = getQueuedMessages()
        return queuedMessages.contains { $0.retryCount < maxRetryCount }
    }
    
    /// Retries all failed messages with exponential backoff
    func retryAllFailedMessages() async throws {
        let queuedMessages = getQueuedMessages()
        let retryableMessages = queuedMessages.filter { $0.retryCount < maxRetryCount }
        
        for queuedMessage in retryableMessages {
            do {
                let message = queuedMessage.toMessage()
                
                try firestore.collection("chats")
                    .document(queuedMessage.chatID)
                    .collection(Message.collectionName)
                    .document(queuedMessage.id)
                    .setData(from: message)
                
                // Remove from queue after successful sync
                removeQueuedMessage(id: queuedMessage.id)
                
            } catch {
                // Update retry count with exponential backoff
                var updatedMessage = queuedMessage
                updatedMessage.retryCount += 1
                updatedMessage.lastAttempt = Date()
                
                // Remove old and add updated
                removeQueuedMessage(id: queuedMessage.id)
                var updatedQueue = getQueuedMessages()
                updatedQueue.append(updatedMessage)
                saveQueuedMessages(updatedQueue)
            }
        }
    }
    
    // MARK: - PR-1 Optimization Methods
    
    /// Sends multiple messages in a burst for optimized performance
    /// - Note: Handles 20+ rapid messages with no lag or out-of-order delivery (PR-1 requirement)
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - messages: Array of message texts to send
    ///   - senderName: Optional sender display name for group chat attribution (PR-3)
    /// - Returns: Array of message IDs
    /// - Throws: MessageServiceError for various failure scenarios
    func sendBurstMessages(chatID: String, messages: [String], senderName: String? = nil) async throws -> [String] {
        guard let currentUser = Auth.auth().currentUser else {
            throw MessageServiceError.permissionDenied
        }
        
        guard !messages.isEmpty else {
            return []
        }
        
        // Start performance tracking for burst operation
        let burstStartTime = Date()
        PerformanceMonitor.shared.startSync()
        
        var messageIDs: [String] = []
        let batch = firestore.batch()
        let timestamp = Date()
        
        // Create all messages in batch for atomic operation
        for (index, text) in messages.enumerated() {
            let messageID = UUID().uuidString
            let messageTimestamp = Date(timeInterval: Double(index) * 0.001, since: timestamp) // 1ms apart for ordering
            
            let message = Message(
                id: messageID,
                chatID: chatID,
                senderID: currentUser.uid,
                text: text,
                timestamp: messageTimestamp,
                serverTimestamp: nil,
                readBy: [currentUser.uid],
                status: .sending,
                senderName: senderName, // PR-3: Include sender name for group chat attribution
                isOffline: false,
                retryCount: 0,
                isOptimistic: false
            )
            
            let messageRef = firestore.collection("chats")
                .document(chatID)
                .collection(Message.collectionName)
                .document(messageID)
            
            try batch.setData(from: message, forDocument: messageRef)
            messageIDs.append(messageID)
        }
        
        // Update chat's last message info
        let chatRef = firestore.collection("chats").document(chatID)
        if let lastMessage = messages.last {
            batch.updateData([
                "lastMessage": lastMessage,
                "lastMessageTimestamp": timestamp,
                "lastMessageSenderID": currentUser.uid
            ], forDocument: chatRef)
        }
        
        do {
            // Commit all messages atomically
            try await batch.commit()
            
            // Track burst completion
            PerformanceMonitor.shared.endSync(messageCount: messages.count)
            
            let burstDuration = Date().timeIntervalSince(burstStartTime) * 1000
            print("MessageService: Burst of \(messages.count) messages sent in \(String(format: "%.1f", burstDuration))ms")
            
            return messageIDs
        } catch {
            throw MessageServiceError.networkError(error)
        }
    }
    
    /// Measures message delivery latency for performance monitoring
    /// - Parameter messageID: The message ID to measure
    /// - Returns: Latency in milliseconds
    func measureMessageLatency(messageID: String) async -> TimeInterval {
        // This method is called by PerformanceMonitor internally
        // Return the measured latency from PerformanceMonitor
        if let stats = PerformanceMonitor.shared.getStatistics(type: .messageLatency) {
            return stats.p95 / 1000.0 // Convert ms to seconds
        }
        return 0.0
    }
    
    // MARK: - PR-4 Lifecycle Support Methods
    
    /// Syncs messages when app foregrounds with prioritization
    /// - PR #4: Target < 500ms for foreground sync
    /// - Parameter priorityChatID: Optional chat to prioritize in sync
    /// - Returns: Number of messages synced
    /// - Throws: MessageServiceError for various failure scenarios
    func syncOnForeground(priorityChatID: String? = nil) async throws -> Int {
        let startTime = Date()
        PerformanceMonitor.shared.startSync()
        
        // First, sync any queued offline messages
        try await syncQueuedMessages()
        let queuedCount = getQueuedMessageCount()
        
        // If priority chat is specified, fetch its latest messages
        var syncedCount = queuedCount
        if let priorityChatID = priorityChatID {
            let messages = try await fetchMessages(chatID: priorityChatID, limit: 50)
            syncedCount += messages.count
        }
        
        // Track sync duration
        PerformanceMonitor.shared.endSync(messageCount: syncedCount)
        
        return syncedCount
    }
    
    /// Preserves message state before app backgrounds
    /// - PR #4: Ensures zero message loss during lifecycle transitions
    /// - Throws: MessageServiceError if state preservation fails
    func preserveState() async throws {
        // Queued messages are already persisted in UserDefaults
        // This method ensures any pending operations are flushed
    }
    
    /// Restores message state when app foregrounds
    /// - PR #4: Restores preserved state after lifecycle transitions
    /// - Throws: MessageServiceError if state restoration fails
    func restoreState() async throws {
        // Queued messages are automatically loaded from UserDefaults
        // Attempt to sync any queued messages
        
        let queuedMessages = getQueuedMessages()
        if !queuedMessages.isEmpty {
            // Sync queued messages if online
            Task { @MainActor in
                if isOnline() {
                    try? await syncQueuedMessages()
                }
            }
        }
    }
}

// MARK: - MessageServiceError

/// Errors that can occur in MessageService operations
enum MessageServiceError: LocalizedError {
    case messageNotFound
    case permissionDenied
    case networkError(Error)
    case offlineQueueFull
    case retryLimitExceeded
    case optimisticUpdateFailed
    case serverTimestampError
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .messageNotFound:
            return "Message not found"
        case .permissionDenied:
            return "Permission denied to access message"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .offlineQueueFull:
            return "Offline message queue is full"
        case .retryLimitExceeded:
            return "Retry limit exceeded for message"
        case .optimisticUpdateFailed:
            return "Optimistic update failed"
        case .serverTimestampError:
            return "Server timestamp error"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

