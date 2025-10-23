//
//  UserService.swift
//  MessageAI
//
//  Service for managing user documents in Firestore
//

import Foundation
import FirebaseFirestore

/// Service for user CRUD operations in Firestore
class UserService {
    
    // MARK: - Properties
    
    private let db: Firestore
    private var usersCollection: CollectionReference {
        db.collection(Constants.Collections.users)
    }
    
    // MARK: - Caching for PR-3 Group Chat Enhancement
    
    /// Local cache for user profiles to reduce Firebase reads
    /// - Note: Improves performance for group chat attribution
    private var userCache: [String: User] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheExpirationSeconds: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    init(firestore: Firestore? = nil) {
        self.db = firestore ?? FirebaseService.shared.getFirestore()
    }
    
    // MARK: - Public Methods
    
    // MARK: User Creation & Fetching
    
    /// Creates a new user document in Firestore
    /// - Parameters:
    ///   - userID: Firebase Auth UID
    ///   - displayName: User's display name (1-50 characters)
    ///   - email: User's email address
    /// - Throws: UserServiceError for validation or Firestore errors
    /// - Performance: Should complete in < 1 second (see shared-standards.md)
    /// - Note: Uses server timestamp for date fields
    func createUser(userID: String, displayName: String, email: String) async throws {
        // Validate display name
        try validateDisplayName(displayName)
        
        // Prepare user data with server timestamps
        let userData: [String: Any] = [
            "id": userID,
            "displayName": displayName,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "lastActiveAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await usersCollection.document(userID).setData(userData)
            
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    /// Fetches a user document from Firestore
    /// - Parameter userID: Firebase Auth UID
    /// - Returns: User object
    /// - Throws: UserServiceError.notFound if user doesn't exist, or other Firestore errors
    /// - Performance: Should complete in < 1 second (see shared-standards.md)
    func fetchUser(userID: String) async throws -> User {
        do {
            let document = try await usersCollection.document(userID).getDocument()
            
            guard document.exists else {
                throw UserServiceError.notFound
            }
            
            // Decode document data to User model
            let data = document.data() ?? [:]
            let user = try decodeUser(from: data, id: userID)
            
            return user
            
        } catch let error as UserServiceError {
            throw error
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    /// Updates user document fields in Firestore
    /// - Parameters:
    ///   - userID: Firebase Auth UID
    ///   - displayName: Optional new display name
    ///   - profilePhotoURL: Optional new profile photo URL
    /// - Throws: UserServiceError for validation or Firestore errors
    /// - Note: Only updates provided fields, updates lastActiveAt automatically
    func updateUser(userID: String, displayName: String? = nil, profilePhotoURL: String? = nil) async throws {
        // Validate display name if provided
        if let displayName = displayName {
            try validateDisplayName(displayName)
        }
        
        // Build update data for only provided fields
        var updateData: [String: Any] = [
            "lastActiveAt": FieldValue.serverTimestamp()
        ]
        
        if let displayName = displayName {
            updateData["displayName"] = displayName
        }
        
        if let profilePhotoURL = profilePhotoURL {
            updateData["profilePhotoURL"] = profilePhotoURL
        }
        
        do {
            try await usersCollection.document(userID).updateData(updateData)
            
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: Profile Management
    
    /// Updates user's display name
    /// - Parameters:
    ///   - userID: Firebase Auth UID
    ///   - displayName: New display name (1-50 characters)
    /// - Throws: UserServiceError for validation or Firestore errors
    /// - Performance: Should complete in < 2 seconds
    func updateDisplayName(userID: String, displayName: String) async throws {
        try validateDisplayName(displayName)
        try await updateUser(userID: userID, displayName: displayName)
    }
    
    /// Updates user's profile photo URL
    /// - Parameters:
    ///   - userID: Firebase Auth UID
    ///   - photoURL: New profile photo URL from Firebase Storage
    /// - Throws: UserServiceError for Firestore errors
    /// - Performance: Should complete in < 2 seconds
    func updateProfilePhoto(userID: String, photoURL: String) async throws {
        try await updateUser(userID: userID, profilePhotoURL: photoURL)
    }
    
    /// Fetches current user's profile
    /// - Parameter authService: AuthService to get current user ID
    /// - Returns: Current user's User object
    /// - Throws: UserServiceError.notFound if user doesn't exist
    func fetchCurrentUserProfile(authService: AuthService) async throws -> User {
        guard let currentUserID = authService.currentUser?.uid else {
            throw UserServiceError.notFound
        }
        return try await fetchUser(userID: currentUserID)
    }
    
    // MARK: Contact Discovery
    
    /// Fetches all users from Firestore
    /// - Parameter currentUserID: Current user ID to exclude from results
    /// - Returns: Array of User objects (excluding current user)
    /// - Throws: UserServiceError for Firestore errors
    /// - Performance: Should complete in < 1 second
    func fetchAllUsers(excludingUserID currentUserID: String) async throws -> [User] {
        do {
            let snapshot = try await usersCollection.getDocuments()
            
            let users = snapshot.documents.compactMap { document -> User? in
                // Exclude current user
                guard document.documentID != currentUserID else { return nil }
                
                let data = document.data()
                return try? decodeUser(from: data, id: document.documentID)
            }
            
            return users
            
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    /// Searches users by display name or email (case-insensitive)
    /// - Parameters:
    ///   - query: Search query string
    ///   - currentUserID: Current user ID to exclude from results
    /// - Returns: Array of matching User objects
    /// - Throws: UserServiceError.searchQueryTooShort if query is empty
    /// - Note: Client-side filtering for now, server-side search in future
    func searchUsers(query: String, excludingUserID currentUserID: String) async throws -> [User] {
        guard !query.isEmpty else {
            throw UserServiceError.searchQueryTooShort
        }
        
        // Fetch all users first
        let allUsers = try await fetchAllUsers(excludingUserID: currentUserID)
        
        // Filter by query (case-insensitive)
        let lowercaseQuery = query.lowercased()
        let matchingUsers = allUsers.filter { user in
            user.displayName.lowercased().contains(lowercaseQuery) ||
            user.email.lowercased().contains(lowercaseQuery)
        }
        
        return matchingUsers
    }
    
    /// Observes a single user's profile in real-time
    /// - Parameters:
    ///   - userID: User ID to observe
    ///   - completion: Closure called with updated user
    /// - Returns: ListenerRegistration to remove listener when done
    /// - Note: Updates sync < 100ms (shared-standards.md target)
    func observeUser(userID: String, completion: @escaping (User?) -> Void) -> ListenerRegistration {
        return usersCollection.document(userID).addSnapshotListener(includeMetadataChanges: false) { snapshot, error in
            guard error == nil else {
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            
            let data = snapshot.data() ?? [:]
            let user = try? self.decodeUser(from: data, id: userID)
            completion(user)
        }
    }
    
    /// Sets up real-time listener for all users
    /// - Parameters:
    ///   - currentUserID: Current user ID to exclude from results
    ///   - completion: Closure called with updated user list
    /// - Returns: ListenerRegistration to remove listener when done
    func observeUsers(excludingUserID currentUserID: String, completion: @escaping ([User]) -> Void) -> ListenerRegistration {
        return usersCollection.addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                completion([])
                return
            }
            
            let users = snapshot.documents.compactMap { document -> User? in
                // Exclude current user
                guard document.documentID != currentUserID else { return nil }
                
                let data = document.data()
                return try? self.decodeUser(from: data, id: document.documentID)
            }
            
            completion(users)
        }
    }
    
    // MARK: - Group Chat Support Methods (PR-3)
    
    /// Fetches user profile with local caching for performance
    /// - Parameter userID: The user's ID
    /// - Returns: User object from cache or Firestore
    /// - Throws: UserServiceError for authentication or network errors
    /// - Note: Uses 5-minute cache to reduce Firebase reads for group chat attribution
    /// - Performance: < 50ms from cache, < 200ms from network
    func fetchUserProfile(userID: String) async throws -> User {
        // Check cache first
        if let cachedUser = getCachedUser(userID: userID) {
            return cachedUser
        }
        
        // Fetch from Firestore if not in cache
        let user = try await fetchUser(userID: userID)
        
        // Update cache
        cacheUser(user)
        
        return user
    }
    
    /// Fetches multiple user profiles with batch optimization
    /// - Parameter userIDs: Array of user IDs to fetch
    /// - Returns: Dictionary mapping userID to User object
    /// - Throws: UserServiceError for network errors
    /// - Note: Uses caching and batch fetching for optimal performance
    /// - Performance: Target < 400ms for 10 users (PR-3 requirement)
    func fetchMultipleUserProfiles(userIDs: [String]) async throws -> [String: User] {
        var result: [String: User] = [:]
        var idsToFetch: [String] = []
        
        // First, check cache for existing profiles
        for userID in userIDs {
            if let cachedUser = getCachedUser(userID: userID) {
                result[userID] = cachedUser
            } else {
                idsToFetch.append(userID)
            }
        }
        
        // If all users are cached, return immediately
        if idsToFetch.isEmpty {
            return result
        }
        
        // Fetch missing users from Firestore
        do {
            // Use whereField with 'in' operator for batch fetch (max 10 at a time)
            let batchSize = 10
            let batches = stride(from: 0, to: idsToFetch.count, by: batchSize).map {
                Array(idsToFetch[$0..<min($0 + batchSize, idsToFetch.count)])
            }
            
            for batch in batches {
                let snapshot = try await usersCollection
                    .whereField("id", in: batch)
                    .getDocuments()
                
                for document in snapshot.documents {
                    let user = try decodeUser(from: document.data(), id: document.documentID)
                    result[user.id] = user
                    cacheUser(user)
                }
            }
            
            return result
            
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    /// Observes a user profile for real-time updates
    /// - Parameters:
    ///   - userID: The user's ID to observe
    ///   - completion: Callback with updated user profile
    /// - Returns: ListenerRegistration for cleanup
    /// - Note: Updates local cache automatically on changes
    func observeUserProfile(userID: String, completion: @escaping (User) -> Void) -> ListenerRegistration {
        return usersCollection.document(userID).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot,
                  snapshot.exists,
                  error == nil,
                  let data = snapshot.data() else {
                completion(User(
                    id: userID,
                    displayName: "Unknown User",
                    email: "",
                    profilePhotoURL: nil,
                    createdAt: Date(),
                    lastActiveAt: Date()
                ))
                return
            }
            
            // Decode user and update cache
            guard let user = try? self.decodeUser(from: data, id: userID) else {
                return
            }
            
            self.cacheUser(user)
            completion(user)
        }
    }
    
    // MARK: - Cache Management
    
    /// Retrieves user from cache if available and not expired
    /// - Parameter userID: The user's ID
    /// - Returns: Cached User object or nil if not found/expired
    private func getCachedUser(userID: String) -> User? {
        guard let user = userCache[userID],
              let timestamp = cacheTimestamps[userID] else {
            return nil
        }
        
        // Check if cache is expired (5 minutes)
        let now = Date()
        if now.timeIntervalSince(timestamp) > cacheExpirationSeconds {
            // Cache expired, remove from cache
            userCache.removeValue(forKey: userID)
            cacheTimestamps.removeValue(forKey: userID)
            return nil
        }
        
        return user
    }
    
    /// Stores user in local cache
    /// - Parameter user: The User object to cache
    private func cacheUser(_ user: User) {
        userCache[user.id] = user
        cacheTimestamps[user.id] = Date()
    }
    
    /// Clears all cached user profiles
    /// - Note: Call this on logout or when cache needs to be refreshed
    func clearCache() {
        userCache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    /// Clears cached user for specific user ID
    /// - Parameter userID: The user ID to remove from cache
    func clearCachedUser(userID: String) {
        userCache.removeValue(forKey: userID)
        cacheTimestamps.removeValue(forKey: userID)
    }
    
    // MARK: - Validation Helpers
    
    /// Validates display name length
    /// - Parameter displayName: Display name to validate
    /// - Throws: UserServiceError.invalidDisplayName if invalid
    private func validateDisplayName(_ displayName: String) throws {
        let length = displayName.count
        guard length >= Constants.Validation.displayNameMinLength &&
              length <= Constants.Validation.displayNameMaxLength else {
            throw UserServiceError.invalidDisplayName
        }
    }
    
    // MARK: - Decoding Helpers
    
    /// Decodes Firestore document data into User model
    /// - Parameters:
    ///   - data: Firestore document data
    ///   - id: User ID
    /// - Returns: User object
    /// - Throws: UserServiceError.unknown if decoding fails
    private func decodeUser(from data: [String: Any], id: String) throws -> User {
        // Extract fields with defaults for optional values
        guard let displayName = data["displayName"] as? String,
              let email = data["email"] as? String else {
            throw UserServiceError.unknown(NSError(domain: "UserService", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Missing required user fields"]))
        }
        
        let profilePhotoURL = data["profilePhotoURL"] as? String
        
        // Handle Firestore Timestamps
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date() // Fallback for missing timestamp
        }
        
        let lastActiveAt: Date
        if let timestamp = data["lastActiveAt"] as? Timestamp {
            lastActiveAt = timestamp.dateValue()
        } else {
            lastActiveAt = Date() // Fallback for missing timestamp
        }
        
        return User(
            id: id,
            displayName: displayName,
            email: email,
            profilePhotoURL: profilePhotoURL,
            createdAt: createdAt,
            lastActiveAt: lastActiveAt
        )
    }
    
    // MARK: - Error Mapping
    
    /// Maps Firestore errors to UserServiceError
    /// - Parameter error: The error to map
    /// - Returns: Mapped UserServiceError
    private func mapFirestoreError(_ error: Error) -> UserServiceError {
        let nsError = error as NSError
        
        // Check for Firestore error codes
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 7: // Permission denied
                return .permissionDenied
            case 14: // Unavailable (network error)
                return .networkError
            default:
                return .unknown(error)
            }
        }
        
        return .unknown(error)
    }
}

