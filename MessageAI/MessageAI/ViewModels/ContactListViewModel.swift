//
//  ContactListViewModel.swift
//  MessageAI
//
//  View model for contact discovery and search
//

import Foundation
import FirebaseFirestore

/// View model managing contact list and search
@MainActor
class ContactListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var allUsers: [User] = []
    @Published var filteredUsers: [User] = []
    @Published var searchQuery: String = "" {
        didSet {
            filterUsers()
        }
    }
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Services
    
    private let userService: UserService
    private let authService: AuthService
    
    // MARK: - Private Properties
    
    private var listener: ListenerRegistration?
    
    // MARK: - Initialization
    
    init(
        userService: UserService = UserService(),
        authService: AuthService = AuthService()
    ) {
        self.userService = userService
        self.authService = authService
    }
    
    // MARK: - Deinitialization
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Public Methods
    
    /// Loads all users from Firestore
    func loadUsers() async {
        guard let currentUserID = authService.currentUser?.uid else {
            errorMessage = "Not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            allUsers = try await userService.fetchAllUsers(excludingUserID: currentUserID)
            filteredUsers = allUsers
            print("✅ Loaded \(allUsers.count) users")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load users: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Filters users based on search query
    func filterUsers() {
        if searchQuery.isEmpty {
            filteredUsers = allUsers
        } else {
            let lowercaseQuery = searchQuery.lowercased()
            filteredUsers = allUsers.filter { user in
                user.displayName.lowercased().contains(lowercaseQuery) ||
                user.email.lowercased().contains(lowercaseQuery)
            }
        }
        
        print("✅ Filtered to \(filteredUsers.count) users for query: '\(searchQuery)'")
    }
    
    /// Sets up real-time listener for user updates
    func observeUsersRealTime() {
        guard let currentUserID = authService.currentUser?.uid else {
            errorMessage = "Not authenticated"
            return
        }
        
        listener?.remove()
        
        listener = userService.observeUsers(excludingUserID: currentUserID) { [weak self] users in
            Task { @MainActor in
                self?.allUsers = users
                self?.filterUsers()
                print("✅ Real-time update: \(users.count) users")
            }
        }
    }
    
    /// Stops observing user updates
    func stopObserving() {
        listener?.remove()
        listener = nil
    }
}

