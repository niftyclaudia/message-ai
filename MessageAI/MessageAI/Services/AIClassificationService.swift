//
//  AIClassificationService.swift
//  MessageAI
//
//  Service for managing AI classification and real-time updates
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

/// Metadata for tracking message classification
struct MessageMetadata {
    let chatID: String
    let senderID: String
}

/// Service for managing AI classification operations and real-time updates
/// - Note: Handles real-time classification updates, feedback submission, and retry logic
@MainActor
class AIClassificationService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current classification status for each message
    @Published var classificationStatus: [String: ClassificationStatus] = [:]
    
    /// Message metadata including chat ID and read status
    @Published var messageMetadata: [String: MessageMetadata] = [:]
    
    /// Whether the service is currently listening for updates
    @Published var isListening: Bool = false
    
    /// Offline feedback queue for when network is unavailable
    @Published var offlineFeedbackQueue: [ClassificationFeedback] = []
    
    // MARK: - Private Properties
    
    private let firestore: Firestore
    private let userDefaults = UserDefaults.standard
    private var listeners: [String: ListenerRegistration] = [:]
    private var cancellables = Set<AnyCancellable>()
    
    /// UserDefaults keys
    private let offlineQueueKey = "offline_classification_feedback"
    private let maxOfflineQueueSize = 50
    
    /// Rate limiting
    private var lastFeedbackSubmission: Date?
    private let feedbackRateLimit: TimeInterval = 1.0 // 1 second between submissions
    
    // MARK: - Initialization
    
    init() {
        self.firestore = FirebaseService.shared.getFirestore()
        loadOfflineQueue()
        setupNetworkMonitoring()
    }
    
    deinit {
        // Clean up listeners synchronously in deinit
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
    }
    
    // MARK: - Public Methods
    
    /// Starts listening for classification updates for a specific chat
    /// - Parameter chatID: The chat ID to listen for updates
    func listenForClassificationUpdates(chatID: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw ClassificationError.userNotAuthenticated
        }
        
        // Check if already listening for this chat
        if listeners[chatID] != nil {
            return
        }
        
        // Stop existing listener for this chat if any
        listeners[chatID]?.remove()
        
        let messagesRef = firestore.collection("chats")
            .document(chatID)
            .collection(Message.collectionName)
            // Listen to ALL messages to detect classification updates for both sent and received messages
        
        let listener = messagesRef.addSnapshotListener { [weak self] snapshot, error in
            Task { @MainActor in
                if let error = error {
                    return
                }
                
                guard let snapshot = snapshot else { return }
                
                for documentChange in snapshot.documentChanges {
                    switch documentChange.type {
                    case .added, .modified:
                        if let message = try? documentChange.document.data(as: Message.self) {
                            await self?.handleMessageUpdate(message)
                        }
                    case .removed:
                        // Handle message removal if needed
                        break
                    }
                }
            }
        }
        
        listeners[chatID] = listener
        isListening = true
        
    }
    
    /// Stops listening for classification updates for a specific chat
    /// - Parameter chatID: The chat ID to stop listening for
    func stopListeningForChat(chatID: String) {
        listeners[chatID]?.remove()
        listeners.removeValue(forKey: chatID)
        
        if listeners.isEmpty {
            isListening = false
        }
        
    }
    
    /// Stops all active listeners
    func stopAllListeners() {
        guard !listeners.isEmpty else {
            return
        }
        
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
        isListening = false
        
    }
    
    /// Manually clean up all resources (for testing or explicit cleanup)
    func cleanup() {
        stopAllListeners()
        cancellables.removeAll()
        classificationStatus.removeAll()
        offlineFeedbackQueue.removeAll()
    }
    
    /// Submits feedback for a classification
    /// - Parameters:
    ///   - messageId: The message ID
    ///   - suggestedPriority: The user's suggested priority
    ///   - reason: Optional reason for the feedback
    func submitClassificationFeedback(messageId: String, suggestedPriority: String, reason: String? = nil) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw ClassificationError.userNotAuthenticated
        }
        
        // Rate limiting check
        if let lastSubmission = lastFeedbackSubmission,
           Date().timeIntervalSince(lastSubmission) < feedbackRateLimit {
            throw ClassificationError.rateLimitExceeded
        }
        
        // Validate priority
        guard MessagePriority.isValid(suggestedPriority) else {
            throw ClassificationError.invalidPriority(suggestedPriority)
        }
        
        // Get current classification status
        let currentStatus = classificationStatus[messageId]
        let originalPriority: String
        
        switch currentStatus {
        case .classified(let priority, _):
            originalPriority = priority
        case .pending, .failed, .feedbackSubmitted, .none:
            originalPriority = "normal" // Default fallback
        }
        
        let feedback = ClassificationFeedback(
            messageId: messageId,
            userId: currentUser.uid,
            originalPriority: originalPriority,
            suggestedPriority: suggestedPriority,
            feedbackReason: reason
        )
        
        do {
            // Submit to Cloud Function
            try await submitFeedbackToCloudFunction(feedback)
            
            // Update local status
            classificationStatus[messageId] = .feedbackSubmitted
            lastFeedbackSubmission = Date()
            
            
        } catch {
            // If submission fails, add to offline queue
            addToOfflineQueue(feedback)
            throw ClassificationError.feedbackSubmissionFailed
        }
    }
    
    /// Retries classification for a specific message
    /// - Parameter messageId: The message ID to retry classification for
    func retryClassification(messageId: String) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw ClassificationError.userNotAuthenticated
        }
        
        let retryRequest = ClassificationRetryRequest(
            messageId: messageId,
            userId: currentUser.uid,
            reason: "User requested retry"
        )
        
        do {
            // Call Cloud Function to retry classification
            try await retryClassificationViaCloudFunction(retryRequest)
            
            // Update local status to pending
            classificationStatus[messageId] = .pending
            
            
        } catch {
            throw ClassificationError.retryFailed
        }
    }
    
    /// Gets the current classification status for a message
    /// - Parameter messageId: The message ID
    /// - Returns: Current classification status
    func getClassificationStatus(messageId: String) -> ClassificationStatus {
        return classificationStatus[messageId] ?? .pending
    }
    
    
    /// Populates message metadata from a list of messages
    /// - Parameter messages: Array of messages to populate metadata for
    func populateMessageMetadata(from messages: [Message]) {
        
        var urgentCount = 0
        var normalCount = 0
        
        for message in messages {
            
            messageMetadata[message.id] = MessageMetadata(
                chatID: message.chatID,
                senderID: message.senderID
            )
            
            // Also update classification status if message has priority
            if let priority = message.priority,
               let confidence = message.classificationConfidence {
                classificationStatus[message.id] = .classified(priority: priority, confidence: Float(confidence))
                
                if priority == "urgent" {
                    urgentCount += 1
                    let name = message.senderName ?? message.senderID
                } else {
                    normalCount += 1
                }
            } else {
            }
        }
        
    }
    
    /// Checks if a chat has any urgent messages (regardless of read status)
    /// - Parameter chatID: The chat ID to check
    /// - Returns: True if any urgent messages exist in the chat
    func hasUrgentMessagesInChat(chatID: String) -> Bool {
        // Get all urgent message IDs in this specific chat
        let urgentMessageIds = getUrgentMessageIdsInChat(chatID: chatID)
        
        print("🔍 [AI CLASSIFICATION] hasUrgentMessagesInChat for chat \(chatID): \(urgentMessageIds.count) urgent messages")
        
        return !urgentMessageIds.isEmpty
    }
    
    /// Gets all urgent message IDs in a specific chat
    /// - Parameter chatID: The chat ID to check
    /// - Returns: Array of message IDs that are classified as urgent in this chat
    func getUrgentMessageIdsInChat(chatID: String) -> [String] {
        var urgentMessageIds: [String] = []
        
        
        for (messageId, status) in classificationStatus {
            // Check if message is urgent and belongs to the specified chat
            if case .classified(let priority, _) = status, priority == "urgent" {
                if let metadata = messageMetadata[messageId] {
                    if metadata.chatID == chatID {
                        urgentMessageIds.append(messageId)
                    }
                } else {
                }
            }
        }
        
        return urgentMessageIds
    }
    
    /// Processes offline feedback queue when network becomes available
    func processOfflineQueue() async {
        guard !offlineFeedbackQueue.isEmpty else { return }
        
        
        let queueCopy = offlineFeedbackQueue
        offlineFeedbackQueue.removeAll()
        saveOfflineQueue()
        
        for feedback in queueCopy {
            do {
                try await submitFeedbackToCloudFunction(feedback)
            } catch {
                // Re-add to queue if still failing
                addToOfflineQueue(feedback)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles message updates from Firestore listeners
    private func handleMessageUpdate(_ message: Message) async {
        // Debug log: Print classification update details
        let username = message.senderName ?? message.senderID
        
        // Update classification status based on message priority
        if let priority = message.priority,
           let confidence = message.classificationConfidence {
            classificationStatus[message.id] = .classified(priority: priority, confidence: Float(confidence))
        } else if message.classificationTimestamp != nil {
            // Message was processed but no priority set (likely failed)
            classificationStatus[message.id] = .failed(error: "Classification failed")
        } else {
            // Message hasn't been classified yet
            classificationStatus[message.id] = .pending
        }
        
        // Update message metadata
        messageMetadata[message.id] = MessageMetadata(
            chatID: message.chatID,
            senderID: message.senderID
        )
    }
    
    /// Submits feedback to Cloud Function
    private func submitFeedbackToCloudFunction(_ feedback: ClassificationFeedback) async throws {
        // This would call the Cloud Function endpoint
        // For now, we'll simulate the call
        let _ = try JSONEncoder().encode(feedback)
        
        // TODO: Replace with actual Cloud Function call
        // let url = URL(string: "https://your-region-your-project.cloudfunctions.net/submitClassificationFeedback")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // request.httpBody = data
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
    }
    
    /// Retries classification via Cloud Function
    private func retryClassificationViaCloudFunction(_ request: ClassificationRetryRequest) async throws {
        // This would call the Cloud Function endpoint
        // For now, we'll simulate the call
        let _ = try JSONEncoder().encode(request)
        
        // TODO: Replace with actual Cloud Function call
        // let url = URL(string: "https://your-region-your-project.cloudfunctions.net/retryClassification")!
        // var request = URLRequest(url: url)
        // request.httpMethod = "POST"
        // request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // request.httpBody = data
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
    }
    
    /// Adds feedback to offline queue
    private func addToOfflineQueue(_ feedback: ClassificationFeedback) {
        // Remove oldest items if queue is full
        if offlineFeedbackQueue.count >= maxOfflineQueueSize {
            offlineFeedbackQueue.removeFirst()
        }
        
        offlineFeedbackQueue.append(feedback)
        saveOfflineQueue()
        
    }
    
    /// Loads offline queue from UserDefaults
    private func loadOfflineQueue() {
        guard let data = userDefaults.data(forKey: offlineQueueKey),
              let queue = try? JSONDecoder().decode([ClassificationFeedback].self, from: data) else {
            return
        }
        
        offlineFeedbackQueue = queue
    }
    
    /// Saves offline queue to UserDefaults
    private func saveOfflineQueue() {
        guard let data = try? JSONEncoder().encode(offlineFeedbackQueue) else {
            return
        }
        
        userDefaults.set(data, forKey: offlineQueueKey)
    }
    
    /// Sets up network monitoring for offline queue processing
    private func setupNetworkMonitoring() {
        // Monitor network status changes
        NotificationCenter.default.publisher(for: .networkStatusChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.processOfflineQueue()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Network Status Notification

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}
