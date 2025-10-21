//
//  ConversationListViewModel.swift
//  MessageAI
//
//  ViewModel for conversation list functionality
//

import Foundation
import FirebaseFirestore

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
    
    // MARK: - Private Properties
    
    private var listener: ListenerRegistration?
    private let chatService = ChatService()
    private let userService = UserService()
    private var currentUserID: String?
    
    // MARK: - Public Methods
    
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
            }
        }
    }
    
    /// Stops the real-time listener and cleans up resources
    func stopObserving() {
        listener?.remove()
        listener = nil
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
    
    // MARK: - Private Methods
    
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
        // Clean up listener without main actor isolation
        listener?.remove()
        listener = nil
    }
}
