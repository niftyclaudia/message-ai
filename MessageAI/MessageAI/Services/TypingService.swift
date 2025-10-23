//
//  TypingService.swift
//  MessageAI
//
//  Service for managing typing indicators using Firebase Realtime Database
//

import Foundation
import FirebaseDatabase
import FirebaseAuth

/// Service for managing real-time typing indicators
/// - Note: Uses Firebase Realtime Database for sub-200ms updates
/// - Performance: Typing updates should sync in < 200ms (shared-standards.md)
class TypingService {
    
    // MARK: - Properties
    
    private let database: DatabaseReference
    private let typingPath = "typing"
    private var typingTimer: Timer?
    private let typingTimeout: TimeInterval = 3.0 // Auto-clear after 3 seconds of inactivity
    
    // MARK: - Initialization
    
    init() {
        self.database = Database.database().reference()
    }
    
    // MARK: - Public Methods
    
    /// Sets user as typing in a specific chat
    /// - Parameters:
    ///   - userID: The user's ID
    ///   - chatID: The chat ID where user is typing
    ///   - userName: The user's display name
    /// - Throws: TypingServiceError for authentication or network errors
    /// - Performance: Should complete in < 200ms (shared-standards.md)
    func setUserTyping(userID: String, chatID: String, userName: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TypingServiceError.notAuthenticated
        }
        
        let typingRef = database.child(typingPath).child(chatID).child(userID)
        
        let typingData: [String: Any] = [
            "isTyping": true,
            "userName": userName,
            "timestamp": ServerValue.timestamp()
        ]
        
        do {
            // Set user as typing
            try await typingRef.setValue(typingData)
            
            // Set up auto-removal after timeout (onDisconnect)
            try await typingRef.onDisconnectRemoveValue()
            
        } catch {
            throw TypingServiceError.networkError(error)
        }
    }
    
    /// Clears user's typing status in a specific chat
    /// - Parameters:
    ///   - userID: The user's ID
    ///   - chatID: The chat ID where user stopped typing
    /// - Throws: TypingServiceError for authentication or network errors
    /// - Performance: Should complete in < 500ms (shared-standards.md)
    func clearUserTyping(userID: String, chatID: String) async throws {
        guard Auth.auth().currentUser != nil else {
            throw TypingServiceError.notAuthenticated
        }
        
        let typingRef = database.child(typingPath).child(chatID).child(userID)
        
        do {
            // Remove typing indicator
            try await typingRef.removeValue()
            
            // Cancel onDisconnect
            try await typingRef.cancelDisconnectOperations()
            
        } catch {
            throw TypingServiceError.networkError(error)
        }
    }
    
    /// Observes typing indicators for a specific chat
    /// - Parameters:
    ///   - chatID: The chat ID to observe
    ///   - currentUserID: Current user's ID to exclude from results
    ///   - completion: Callback with array of users currently typing
    /// - Returns: DatabaseHandle for cleanup (use removeObserver)
    func observeTyping(chatID: String, currentUserID: String, completion: @escaping ([TypingUser]) -> Void) -> DatabaseHandle {
        let chatTypingRef = database.child(typingPath).child(chatID)
        
        let handle = chatTypingRef.observe(.value) { snapshot in
            guard snapshot.exists(),
                  let typingDict = snapshot.value as? [String: Any] else {
                // No one is typing
                completion([])
                return
            }
            
            var typingUsers: [TypingUser] = []
            
            for (userID, value) in typingDict {
                // Exclude current user
                guard userID != currentUserID else { continue }
                
                guard let userData = value as? [String: Any],
                      let isTyping = userData["isTyping"] as? Bool,
                      let userName = userData["userName"] as? String,
                      isTyping else {
                    continue
                }
                
                // Optional timestamp for staleness check
                var timestamp: Date?
                if let timestampValue = userData["timestamp"] as? TimeInterval {
                    timestamp = Date(timeIntervalSince1970: timestampValue / 1000.0)
                }
                
                // Only include if typing is recent (within last 5 seconds)
                if let ts = timestamp {
                    let age = Date().timeIntervalSince(ts)
                    guard age < 5.0 else { continue }
                }
                
                typingUsers.append(TypingUser(userID: userID, userName: userName))
            }
            
            completion(typingUsers)
        }
        
        return handle
    }
    
    /// Removes typing observer
    /// - Parameters:
    ///   - chatID: The chat ID being observed
    ///   - handle: The database handle returned from observeTyping
    func removeObserver(chatID: String, handle: DatabaseHandle) {
        let chatTypingRef = database.child(typingPath).child(chatID)
        chatTypingRef.removeObserver(withHandle: handle)
    }
    
    /// Clears all typing indicators for a chat (admin/cleanup function)
    /// - Parameter chatID: The chat ID to clear
    func clearAllTyping(chatID: String) async throws {
        let chatTypingRef = database.child(typingPath).child(chatID)
        
        do {
            try await chatTypingRef.removeValue()
        } catch {
            throw TypingServiceError.networkError(error)
        }
    }
}

// MARK: - TypingUser Model

/// Model representing a user who is currently typing
struct TypingUser: Identifiable, Equatable {
    let id: String
    let userID: String
    let userName: String
    
    init(userID: String, userName: String) {
        self.id = userID
        self.userID = userID
        self.userName = userName
    }
}

// MARK: - TypingServiceError

/// Errors specific to TypingService operations
enum TypingServiceError: LocalizedError {
    case notAuthenticated
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

