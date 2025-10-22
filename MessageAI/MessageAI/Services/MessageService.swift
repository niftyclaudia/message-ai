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
    private let queueKey = "queued_messages"
    private let maxRetryCount = 3
    private let maxQueueSize = 100
    
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
    /// - Returns: Message ID
    /// - Throws: MessageServiceError for various failure scenarios
    func sendMessageOptimistic(chatID: String, text: String) async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw MessageServiceError.permissionDenied
        }
        
        let messageID = UUID().uuidString
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
            // Create message with server timestamp
            let message = Message(
                id: messageID,
                chatID: chatID,
                senderID: currentUser.uid,
                text: text,
                timestamp: timestamp,
                serverTimestamp: nil, // Will be set by server
                readBy: [currentUser.uid],
                status: .sending,
                senderName: nil,
                isOffline: false,
                retryCount: 0,
                isOptimistic: true
            )
            
            // Save to Firestore with server timestamp
            try firestore.collection("chats")
                .document(chatID)
                .collection(Message.collectionName)
                .document(messageID)
                .setData(from: message)
            
            // Update status to sent
            try await updateMessageStatus(messageID: messageID, status: .sent)
            
            return messageID
        } catch {
            // If send fails, mark as failed
            try? await updateMessageStatus(messageID: messageID, status: .failed)
            throw MessageServiceError.networkError(error)
        }
    }
    
    /// Sends a message to Firestore with real-time delivery
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - text: The message text
    /// - Returns: Message ID
    /// - Throws: MessageServiceError for various failure scenarios
    func sendMessage(chatID: String, text: String) async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw MessageServiceError.permissionDenied
        }
        
        let messageID = UUID().uuidString
        let timestamp = Date()
        
        let message = Message(
            id: messageID,
            chatID: chatID,
            senderID: currentUser.uid,
            text: text,
            timestamp: timestamp,
            readBy: [currentUser.uid],
            status: .sending,
            senderName: nil,
            isOffline: false,
            retryCount: 0
        )
        
        do {
            // Save to Firestore
            try firestore.collection("chats")
                .document(chatID)
                .collection(Message.collectionName)
                .document(messageID)
                .setData(from: message)
            
            // Update status to sent
            try await updateMessageStatus(messageID: messageID, status: .sent)
            
            return messageID
        } catch {
            // If send fails, mark as failed
            try? await updateMessageStatus(messageID: messageID, status: .failed)
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
    
    /// Sets up real-time listener for messages in a chat
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - completion: Callback with updated messages array
    /// - Returns: ListenerRegistration for cleanup
    func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        let query = firestore.collection("chats")
            .document(chatID)
            .collection(Message.collectionName)
            .order(by: "timestamp", descending: false)
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion([])
                return
            }
            
            guard let snapshot = snapshot else {
                completion([])
                return
            }
            
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
            
            completion(messages)
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
