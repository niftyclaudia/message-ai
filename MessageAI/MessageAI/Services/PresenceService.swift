//
//  PresenceService.swift
//  MessageAI
//
//  Service for managing user presence using Firebase Realtime Database
//

import Foundation
import UIKit
import FirebaseDatabase
import FirebaseAuth

/// Service for managing real-time user presence
/// - Note: Uses Firebase Realtime Database for superior onDisconnect hooks
/// - Performance: Presence updates should sync in < 100ms (shared-standards.md)
class PresenceService {
    
    // MARK: - Properties
    
    private let database: DatabaseReference
    private let presencePath = "presence"
    private var currentUserPresenceRef: DatabaseReference?
    private var retryAttempts = 0
    private let maxRetryAttempts = 3
    
    // MARK: - Initialization
    
    init() {
        self.database = Database.database().reference()
    }
    
    // MARK: - Public Methods
    
    /// Sets user as online in Firebase Realtime Database
    /// - Parameter userID: The user's ID
    /// - Throws: PresenceServiceError for authentication or network errors
    /// - Note: Automatically sets up onDisconnect hook to mark offline
    /// - Performance: Should complete in < 100ms (shared-standards.md)
    func setUserOnline(userID: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw PresenceServiceError.notAuthenticated
        }
        
        let presenceRef = database.child(presencePath).child(userID)
        currentUserPresenceRef = presenceRef
        
        // Create online presence status
        let deviceInfo = PresenceStatus.DeviceInfo(
            platform: "iOS",
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            model: UIDevice.current.model
        )
        
        let onlineStatus = PresenceStatus(
            status: .online,
            lastSeen: Date(),
            deviceInfo: deviceInfo
        )
        
        // Set up onDisconnect hook first (critical for reliability)
        let offlineStatus = PresenceStatus(status: .offline, lastSeen: Date())
        try await presenceRef.onDisconnectSetValue(offlineStatus.toFirebaseDict())
        
        // Now set user as online
        do {
            try await presenceRef.setValue(onlineStatus.toFirebaseDict())
            
            
            // Reset retry attempts on success
            retryAttempts = 0
            
        } catch {
            try await handleRetry(operation: { [weak self] in try await self?.setUserOnline(userID: userID) }, error: error)
        }
    }
    
    /// Sets user as offline in Firebase Realtime Database
    /// - Parameter userID: The user's ID
    /// - Throws: PresenceServiceError for authentication or network errors
    /// - Performance: Should complete in < 100ms (shared-standards.md)
    func setUserOffline(userID: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw PresenceServiceError.notAuthenticated
        }
        
        let presenceRef = database.child(presencePath).child(userID)
        
        let offlineStatus = PresenceStatus(status: .offline, lastSeen: Date())
        
        // Cancel onDisconnect hooks
        try await presenceRef.onDisconnectRemoveValue()
        
        // Set user as offline
        do {
            try await presenceRef.setValue(offlineStatus.toFirebaseDict())
            
            
            // Reset retry attempts on success
            retryAttempts = 0
            
        } catch {
            try await handleRetry(operation: { [weak self] in try await self?.setUserOffline(userID: userID) }, error: error)
        }
    }
    
    /// Observes presence status for a single user
    /// - Parameters:
    ///   - userID: The user's ID to observe
    ///   - completion: Callback with updated presence status
    /// - Returns: DatabaseHandle for cleanup (use removeObserver)
    /// - Note: Use removeObserver(withHandle:) on the presenceRef to cleanup
    func observeUserPresence(userID: String, completion: @escaping (PresenceStatus) -> Void) -> DatabaseHandle {
        let presenceRef = database.child(presencePath).child(userID)
        
        let handle = presenceRef.observe(.value) { snapshot in
            // Handle case where user has no presence data yet (default to offline)
            guard snapshot.exists(),
                  let dict = snapshot.value as? [String: Any],
                  let presence = PresenceStatus.from(firebaseDict: dict) else {
                // Default to offline if no data
                completion(.offline)
                return
            }
            
            completion(presence)
        }
        
        return handle
    }
    
    /// Observes presence status for multiple users
    /// - Parameters:
    ///   - userIDs: Array of user IDs to observe
    ///   - completion: Callback with dictionary mapping userID to presence status
    /// - Returns: Array of DatabaseHandles for cleanup
    /// - Note: Returns handles for each observer; cleanup with removeObserver
    func observeMultipleUsersPresence(userIDs: [String], completion: @escaping ([String: PresenceStatus]) -> Void) -> [String: DatabaseHandle] {
        var presenceDict: [String: PresenceStatus] = [:]
        var handles: [String: DatabaseHandle] = [:]
        
        for userID in userIDs {
            let handle = observeUserPresence(userID: userID) { presence in
                presenceDict[userID] = presence
                
                // Call completion with updated dictionary
                completion(presenceDict)
            }
            
            handles[userID] = handle
        }
        
        return handles
    }
    
    /// Cleans up presence data for a user
    /// - Parameter userID: The user's ID
    /// - Throws: PresenceServiceError for authentication or network errors
    /// - Note: Should be called on account deletion or similar cleanup operations
    func cleanupPresenceData(userID: String) async throws {
        let presenceRef = database.child(presencePath).child(userID)
        
        // Cancel any onDisconnect hooks
        try await presenceRef.onDisconnectRemoveValue()
        
        // Remove presence data
        do {
            try await presenceRef.removeValue()
            
            
        } catch {
            throw PresenceServiceError.networkError(error)
        }
    }
    
    /// Removes observer for a specific user
    /// - Parameters:
    ///   - userID: The user's ID
    ///   - handle: The DatabaseHandle returned from observeUserPresence
    func removeObserver(userID: String, handle: DatabaseHandle) {
        let presenceRef = database.child(presencePath).child(userID)
        presenceRef.removeObserver(withHandle: handle)
    }
    
    /// Removes all observers for multiple users
    /// - Parameters:
    ///   - handles: Dictionary mapping userID to DatabaseHandle
    func removeObservers(handles: [String: DatabaseHandle]) {
        for (userID, handle) in handles {
            removeObserver(userID: userID, handle: handle)
        }
    }
    
    // MARK: - Private Helpers
    
    /// Handles retry logic for network errors
    /// - Parameters:
    ///   - operation: The async operation to retry
    ///   - error: The error that occurred
    /// - Throws: PresenceServiceError if max retries exceeded
    private func handleRetry(operation: @escaping () async throws -> Void, error: Error) async throws {
        retryAttempts += 1
        
        if retryAttempts >= maxRetryAttempts {
            retryAttempts = 0
            throw PresenceServiceError.networkError(error)
        }
        
        // Exponential backoff
        let delaySeconds = pow(2.0, Double(retryAttempts))
        try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        
        // Retry operation
        try await operation()
    }
}

// MARK: - PresenceServiceError

/// Errors that can occur in PresenceService operations
enum PresenceServiceError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    case observerSetupFailed
    case cleanupFailed
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .observerSetupFailed:
            return "Failed to set up presence observer"
        case .cleanupFailed:
            return "Failed to cleanup presence data"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

