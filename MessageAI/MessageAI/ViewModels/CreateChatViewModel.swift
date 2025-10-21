//
//  CreateChatViewModel.swift
//  MessageAI
//
//  ViewModel for managing chat creation flow
//

import Foundation
import SwiftUI

/// ViewModel for managing chat creation flow
/// - Note: Handles contact selection, search, and chat creation
@MainActor
class CreateChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// All available contacts
    @Published var contacts: [User] = []
    
    /// Filtered contacts based on search query
    @Published var filteredContacts: [User] = []
    
    /// Selected contacts for the new chat
    @Published var selectedContacts: Set<String> = []
    
    /// Search query for filtering contacts
    @Published var searchQuery: String = ""
    
    /// Loading state for various operations
    @Published var isLoading: Bool = false
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    /// Success state after chat creation
    @Published var isChatCreated: Bool = false
    
    /// Created chat ID for navigation
    @Published var createdChatID: String?
    
    // MARK: - Private Properties
    
    private let chatService: ChatService
    private var authService: AuthService
    
    // MARK: - Computed Properties
    
    /// Whether the create chat button should be enabled
    var canCreateChat: Bool {
        !selectedContacts.isEmpty && !isLoading
    }
    
    /// Number of selected contacts
    var selectedCount: Int {
        selectedContacts.count
    }
    
    /// Whether this will be a group chat
    var isGroupChat: Bool {
        selectedContacts.count >= 2
    }
    
    // MARK: - Initialization
    
    init(chatService: ChatService = ChatService(), authService: AuthService) {
        self.chatService = chatService
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Updates the AuthService instance
    /// - Parameter authService: The AuthService to use
    func updateAuthService(_ authService: AuthService) {
        self.authService = authService
    }
    
    /// Loads all contacts for the current user
    func loadContacts() async {
        guard let currentUserID = authService.currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            let fetchedContacts = try await chatService.fetchContacts(currentUserID: currentUserID)
            
            await MainActor.run {
                self.contacts = fetchedContacts
                self.filteredContacts = fetchedContacts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load contacts: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Searches contacts based on the current search query
    func searchContacts() async {
        guard let currentUserID = authService.currentUser?.uid else {
            await MainActor.run {
                self.errorMessage = "User not authenticated"
            }
            return
        }
        
        if searchQuery.isEmpty {
            await MainActor.run {
                self.filteredContacts = self.contacts
            }
            return
        }
        
        do {
            let searchResults = try await chatService.searchContacts(
                query: searchQuery,
                currentUserID: currentUserID
            )
            
            await MainActor.run {
                self.filteredContacts = searchResults
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Search failed: \(error.localizedDescription)"
            }
        }
    }
    
    /// Toggles selection of a contact
    /// - Parameter userID: The user ID to toggle
    func toggleContactSelection(userID: String) {
        if selectedContacts.contains(userID) {
            selectedContacts.remove(userID)
        } else {
            selectedContacts.insert(userID)
        }
    }
    
    /// Creates a new chat with selected contacts
    func createChat() async {
        print("🔄 CreateChatViewModel.createChat() called")
        
        guard let currentUserID = authService.currentUser?.uid else {
            print("❌ User not authenticated")
            await MainActor.run {
                self.errorMessage = "User not authenticated"
            }
            return
        }
        
        guard !selectedContacts.isEmpty else {
            print("❌ No contacts selected")
            await MainActor.run {
                self.errorMessage = "Please select at least one contact"
            }
            return
        }
        
        print("✅ Starting chat creation with \(selectedContacts.count) contacts: \(selectedContacts)")
        
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        do {
            // Include current user in members array
            var members = Array(selectedContacts)
            members.append(currentUserID)
            
            // Determine if this is a group chat
            let isGroup = members.count > 2
            
            // Create the chat
            print("🔄 Calling chatService.createChat with members: \(members)")
            let chatID = try await chatService.createChat(
                members: members,
                isGroup: isGroup,
                createdBy: currentUserID
            )
            
            print("✅ Chat created successfully with ID: \(chatID)")
            
            await MainActor.run {
                self.createdChatID = chatID
                self.isChatCreated = true
                self.isLoading = false
                print("✅ ViewModel state updated - isChatCreated: \(self.isChatCreated), createdChatID: \(self.createdChatID ?? "nil")")
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to create chat: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Clears the error message
    func clearError() {
        errorMessage = nil
    }
    
    /// Fetches the created chat object
    func fetchCreatedChat() async -> Chat? {
        guard let chatID = createdChatID else { return nil }
        
        do {
            return try await chatService.fetchChat(chatID: chatID)
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load created chat: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    /// Gets the current user ID
    func getCurrentUserID() -> String {
        return authService.currentUser?.uid ?? ""
    }
    
    /// Resets the view model state
    func reset() {
        selectedContacts.removeAll()
        searchQuery = ""
        filteredContacts = contacts
        errorMessage = nil
        isChatCreated = false
        createdChatID = nil
        isLoading = false
    }
}
