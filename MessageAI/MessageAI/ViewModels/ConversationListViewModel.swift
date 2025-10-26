//
//  ConversationListViewModel.swift
//  MessageAI
//
//  ViewModel for conversation list functionality
//

import Foundation
import FirebaseFirestore
import FirebaseDatabase

/// ViewModel for managing conversation list state and real-time updates
/// - Note: Handles chat loading, real-time updates, and user data management
@MainActor
class ConversationListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of chats sorted by most recent message
    @Published var chats: [Chat] = []
    
    /// Dictionary mapping user IDs to User objects for display
    @Published var chatUsers: [String: User] = [:]
    
    /// Loading state for initial data fetch
    @Published var isLoading: Bool = false
    
    /// Error message for display
    @Published var errorMessage: String?
    
    /// Dictionary mapping user IDs to presence status
    @Published var userPresence: [String: PresenceState] = [:]
    
    /// AI Classification Service for observing classification status changes
    @Published var aiClassificationService: AIClassificationService
    
    // MARK: - Computed Properties
    
    /// Total unread count across all chats for the current user
    var totalUnreadCount: Int {
        guard let currentUserID = currentUserID else { return 0 }
        return chats.reduce(0) { total, chat in
            total + (chat.unreadCount[currentUserID] ?? 0)
        }
    }
    
    // MARK: - Private Properties
    
    private var listener: ListenerRegistration?
    private let chatService = ChatService()
    private let userService = UserService()
    private let presenceService = PresenceService()
    private let messageService = MessageService()
    private var currentUserID: String?
    private var presenceHandles: [String: DatabaseHandle] = [:]
    private var isClassificationListeningStarted: Bool = false
    private var isInitialized: Bool = false
    
    // MARK: - Initialization
    
    init() {
        self.aiClassificationService = AIClassificationService()
    }
    
    // MARK: - Public Methods
    
    /// Initializes the view model with proper lifecycle management
    /// - Parameter userID: The current user's ID
    func initialize(userID: String) async {
        guard !isInitialized else { return }
        
        currentUserID = userID
        isInitialized = true
        
        // Load chats from Firestore
        await loadChats(userID: userID)
        observeChatsRealTime(userID: userID)
        observePresence()
        
        // Start AI classification listening
        await startClassificationListening()
    }
    
    /// Loads chats for the current user
    /// - Parameter userID: The current user's ID
    func loadChats(userID: String) async {
        currentUserID = userID
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedChats = try await chatService.fetchUserChats(userID: userID)
            chats = fetchedChats
            
            // Load user data for each chat
            await loadUserDataForChats(fetchedChats)
            
            // Populate AI classification service with existing message data
            await populateClassificationDataForChats(fetchedChats)
            
        } catch {
            errorMessage = error.localizedDescription
            print("⚠️ Failed to load chats: \(error)")
        }
        
        isLoading = false
    }
    
    /// Sets up real-time listener for chat updates
    /// - Parameter userID: The current user's ID
    func observeChatsRealTime(userID: String) {
        currentUserID = userID
        
        // Remove existing listener if any
        stopObserving()
        
        listener = chatService.observeUserChats(userID: userID) { [weak self] updatedChats in
            Task { @MainActor in
                self?.chats = updatedChats
                
                // Load user data for new chats
                await self?.loadUserDataForChats(updatedChats)
                
                // Populate AI classification service with existing message data
                await self?.populateClassificationDataForChats(updatedChats)
            }
        }
    }
    
    /// Stops the real-time listener and cleans up resources
    func stopObserving() {
        listener?.remove()
        listener = nil
    }
    
    /// Observes presence for all chat participants
    /// - Note: Updates userPresence dictionary in real-time
    func observePresence() {
        // Stop any existing presence observers
        stopObservingPresence()
        
        // Get all unique user IDs from chats
        var userIDs = Set<String>()
        for chat in chats {
            if let currentUserID = currentUserID,
               let otherUserID = chat.getOtherUserID(currentUserID: currentUserID) {
                userIDs.insert(otherUserID)
            }
        }
        
        // Only observe if we have users to observe
        guard !userIDs.isEmpty else {
            print("⚠️ No users to observe presence for")
            return
        }
        
        // Observe presence for each user
        for userID in userIDs {
            let handle = presenceService.observeUserPresence(userID: userID) { [weak self] presence in
                Task { @MainActor in
                    self?.userPresence[userID] = presence.status
                }
            }
            presenceHandles[userID] = handle
        }
        
        print("✅ Observing presence for \(userIDs.count) chat participants")
    }
    
    /// Stops observing presence for all users
    func stopObservingPresence() {
        for (userID, handle) in presenceHandles {
            presenceService.removeObserver(userID: userID, handle: handle)
        }
        presenceHandles.removeAll()
        userPresence.removeAll()
    }
    
    /// Gets the other user in a 1-on-1 chat
    /// - Parameter chat: The chat to get the other user for
    /// - Returns: User object for the other user, or nil if not found
    func getOtherUser(chat: Chat) -> User? {
        guard let currentUserID = currentUserID,
              let otherUserID = chat.getOtherUserID(currentUserID: currentUserID) else {
            return nil
        }
        
        return chatUsers[otherUserID]
    }
    
    /// Formats a timestamp into a user-friendly string
    /// - Parameter date: The date to format
    /// - Returns: Formatted timestamp string
    func formatTimestamp(date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        // Less than 1 minute
        if timeInterval < 60 {
            return "now"
        }
        
        // Less than 1 hour
        if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        }
        
        // Less than 24 hours
        if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        }
        
        // Less than 48 hours (yesterday)
        if timeInterval < 172800 {
            return "Yesterday"
        }
        
        // More than 48 hours - show date
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    /// Deletes a chat from the user's chat list
    /// - Parameter chatID: The ID of the chat to delete
    func deleteChat(chatID: String) async {
        do {
            try await chatService.deleteChat(chatID: chatID)
            // Remove from local array
            chats.removeAll { $0.id == chatID }
        } catch {
            errorMessage = "Failed to delete chat: \(error.localizedDescription)"
            print("❌ Failed to delete chat \(chatID): \(error)")
        }
    }
    
    // MARK: - AI Classification Methods
    
    /// Gets the AI classification service instance
    /// - Returns: The AIClassificationService instance
    func getAIClassificationService() -> AIClassificationService {
        return aiClassificationService
    }
    
    /// Starts listening for AI classification updates for all chats
    func startClassificationListening() async {
        guard currentUserID != nil, !isClassificationListeningStarted else { return }
        
        isClassificationListeningStarted = true
        
        for chat in chats {
            do {
                try await aiClassificationService.listenForClassificationUpdates(chatID: chat.id)
            } catch {
                print("❌ Failed to start classification listening for chat \(chat.id): \(error)")
            }
        }
    }
    
    /// Stops listening for AI classification updates for all chats
    func stopClassificationListening() {
        guard isClassificationListeningStarted else { return }
        
        aiClassificationService.stopAllListeners()
        isClassificationListeningStarted = false
    }
    
    /// Submits classification feedback for a message
    /// - Parameters:
    ///   - messageId: The message ID
    ///   - suggestedPriority: The user's suggested priority
    ///   - reason: Optional reason for the feedback
    func submitClassificationFeedback(messageId: String, suggestedPriority: String, reason: String? = nil) async {
        do {
            try await aiClassificationService.submitClassificationFeedback(
                messageId: messageId,
                suggestedPriority: suggestedPriority,
                reason: reason
            )
        } catch {
            errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
            print("❌ Failed to submit classification feedback: \(error)")
        }
    }
    
    /// Retries classification for a message
    /// - Parameter messageId: The message ID to retry classification for
    func retryClassification(messageId: String) async {
        do {
            try await aiClassificationService.retryClassification(messageId: messageId)
        } catch {
            errorMessage = "Failed to retry classification: \(error.localizedDescription)"
            print("❌ Failed to retry classification: \(error)")
        }
    }
    
    /// Gets the classification status for a message
    /// - Parameter messageId: The message ID
    /// - Returns: The current classification status
    func getClassificationStatus(messageId: String) -> ClassificationStatus {
        return aiClassificationService.getClassificationStatus(messageId: messageId)
    }
    
    // MARK: - Private Methods
    
    /// Populates AI classification service with existing message data for all chats
    /// - Parameter chats: Array of chats to populate classification data for
    private func populateClassificationDataForChats(_ chats: [Chat]) async {
        for chat in chats {
            do {
                // Fetch recent messages for this chat to populate classification data
                let messages = try await messageService.fetchMessages(chatID: chat.id, limit: 50)
                
                // Populate AI classification service with message metadata
                aiClassificationService.populateMessageMetadata(from: messages)
                
                print("✅ Populated classification data for chat: \(chat.id) with \(messages.count) messages")
            } catch {
                print("⚠️ Failed to populate classification data for chat \(chat.id): \(error)")
            }
        }
    }
    
    /// Loads user data for all chats
    /// - Parameter chats: Array of chats to load user data for
    private func loadUserDataForChats(_ chats: [Chat]) async {
        guard let currentUserID = currentUserID else { return }
        
        var usersToLoad: Set<String> = []
        
        // Collect all user IDs we need to load
        for chat in chats {
            if let otherUserID = chat.getOtherUserID(currentUserID: currentUserID) {
                usersToLoad.insert(otherUserID)
            }
        }
        
        // Load user data for each user
        for userID in usersToLoad {
            if chatUsers[userID] == nil {
                do {
                    let user = try await userService.fetchUser(userID: userID)
                    chatUsers[userID] = user
                } catch {
                    print("⚠️ Failed to load user \(userID): \(error)")
                }
            }
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        print("🧹 ConversationListViewModel deinit - cleaning up observers")
        
        // Clean up Firestore listener
        listener?.remove()
        listener = nil
        
        // Clean up presence observers - must be done synchronously in deinit
        for (userID, handle) in presenceHandles {
            presenceService.removeObserver(userID: userID, handle: handle)
        }
        presenceHandles.removeAll()
        
        // Clean up AI classification listeners
        // We can't access main actor isolated properties in deinit, so we'll use a different approach
        // The AIClassificationService will clean up its own listeners in its deinit
        
        print("✅ ConversationListViewModel cleanup completed")
    }
}
