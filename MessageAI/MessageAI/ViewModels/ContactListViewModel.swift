//
//  ContactListViewModel.swift
//  MessageAI
//
//  View model for contact discovery and search
//

import Foundation
import FirebaseFirestore
import FirebaseDatabase

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
    @Published var userPresence: [String: PresenceState] = [:]
    
    // MARK: - Services
    
    private let userService: UserService
    private let authService: AuthService
    private let presenceService: PresenceService
    
    // MARK: - Private Properties
    
    private var listener: ListenerRegistration?
    private var presenceHandles: [String: DatabaseHandle] = [:]
    
    // MARK: - Initialization
    
    init(
        userService: UserService = UserService(),
        authService: AuthService = AuthService(),
        presenceService: PresenceService = PresenceService()
    ) {
        self.userService = userService
        self.authService = authService
        self.presenceService = presenceService
    }
    
    // MARK: - Deinitialization
    
    deinit {
        listener?.remove()
        stopObservingPresence()
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
    
    /// Observes presence for all users in the contact list
    /// - Note: Updates userPresence dictionary in real-time
    func observePresence() {
        // Stop any existing presence observers
        stopObservingPresence()
        
        // Observe presence for all users
        for user in allUsers {
            let handle = presenceService.observeUserPresence(userID: user.id) { [weak self] presence in
                Task { @MainActor in
                    self?.userPresence[user.id] = presence.status
                }
            }
            presenceHandles[user.id] = handle
        }
        
        print("✅ Observing presence for \(allUsers.count) users")
    }
    
    /// Stops observing presence for all users
    nonisolated func stopObservingPresence() {
        for (userID, handle) in presenceHandles {
            presenceService.removeObserver(userID: userID, handle: handle)
        }
        presenceHandles.removeAll()
        userPresence.removeAll()
    }
}

