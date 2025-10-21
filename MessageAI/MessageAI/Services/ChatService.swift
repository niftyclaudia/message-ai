//
//  ChatService.swift
//  MessageAI
//
//  Chat service for conversation list functionality
//

import Foundation
import FirebaseFirestore

/// Service for managing chat operations and real-time updates
/// - Note: Handles Firestore queries for conversation list
class ChatService {
    
    // MARK: - Properties
    
    private let firestore: Firestore
    
    // MARK: - Initialization
    
    init() {
        self.firestore = FirebaseService.shared.getFirestore()
    }
    
    // MARK: - Public Methods
    
    /// Fetches all chats for a specific user
    /// - Parameter userID: The user's ID
    /// - Returns: Array of Chat objects sorted by lastMessageTimestamp descending
    /// - Throws: ChatServiceError for various failure scenarios
    func fetchUserChats(userID: String) async throws -> [Chat] {
        do {
            let query = firestore.collection(Chat.collectionName)
                .whereField("members", arrayContains: userID)
            
            let snapshot = try await query.getDocuments()
            
            var chats: [Chat] = []
            for document in snapshot.documents {
                do {
                    var chat = try document.data(as: Chat.self)
                    chat.id = document.documentID
                    chats.append(chat)
                } catch {
                    print("⚠️ Failed to decode chat document \(document.documentID): \(error)")
                    // Continue with other documents
                }
            }
            
            // Sort by lastMessageTimestamp descending
            return chats.sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
    
    /// Sets up real-time listener for user's chats
    /// - Parameters:
    ///   - userID: The user's ID
    ///   - completion: Callback with updated chats array
    /// - Returns: ListenerRegistration for cleanup
    /// - Throws: ChatServiceError if listener setup fails
    func observeUserChats(userID: String, completion: @escaping ([Chat]) -> Void) -> ListenerRegistration {
        let query = firestore.collection(Chat.collectionName)
            .whereField("members", arrayContains: userID)
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("⚠️ Chat listener error: \(error)")
                completion([])
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ Chat listener: no snapshot")
                completion([])
                return
            }
            
            var chats: [Chat] = []
            for document in snapshot.documents {
                do {
                    var chat = try document.data(as: Chat.self)
                    chat.id = document.documentID
                    chats.append(chat)
                } catch {
                    print("⚠️ Failed to decode chat document \(document.documentID): \(error)")
                    // Continue with other documents
                }
            }
            
            // Sort by lastMessageTimestamp descending
            let sortedChats = chats.sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
            completion(sortedChats)
        }
    }
    
    /// Fetches a specific chat by ID
    /// - Parameter chatID: The chat's ID
    /// - Returns: Chat object
    /// - Throws: ChatServiceError for various failure scenarios
    func fetchChat(chatID: String) async throws -> Chat {
        do {
            let document = try await firestore.collection(Chat.collectionName).document(chatID).getDocument()
            
            guard document.exists else {
                throw ChatServiceError.chatNotFound
            }
            
            var chat = try document.data(as: Chat.self)
            chat.id = document.documentID
            return chat
        } catch let error as ChatServiceError {
            throw error
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
    
    // MARK: - Chat Creation Methods
    
    /// Creates a new chat with specified members
    /// - Parameters:
    ///   - members: Array of user IDs to include in the chat
    ///   - isGroup: Whether this is a group chat (true if 3+ members)
    ///   - createdBy: User ID of who created the chat
    /// - Returns: The created chat's ID
    /// - Throws: ChatServiceError for various failure scenarios
    /// - Performance: Should complete in < 2 seconds (see shared-standards.md)
    func createChat(members: [String], isGroup: Bool, createdBy: String) async throws -> String {
        print("🔄 ChatService.createChat called with members: \(members), isGroup: \(isGroup), createdBy: \(createdBy)")
        // Validate members array
        guard members.count >= 2 else {
            throw ChatServiceError.invalidMembers("Chat must have at least 2 members")
        }
        
        // Ensure creator is included in members
        guard members.contains(createdBy) else {
            throw ChatServiceError.invalidMembers("Creator must be included in members")
        }
        
        // Check for existing chat with same members
        print("🔄 Checking for existing chat with same members...")
        if let existingChatID = try await checkForExistingChat(members: members) {
            print("✅ Found existing chat: \(existingChatID)")
            return existingChatID
        }
        print("✅ No existing chat found, creating new one...")
        
        do {
            // Create new chat document
            let chatRef = firestore.collection(Chat.collectionName).document()
            let chatID = chatRef.documentID
            
            // Prepare chat data with server timestamps
            let now = Date()
            let chatData: [String: Any] = [
                "id": chatID,
                "members": members,
                "lastMessage": "",
                "lastMessageTimestamp": now,
                "lastMessageSenderID": "",
                "isGroupChat": isGroup,
                "groupName": isGroup ? NSNull() : NSNull(),
                "createdAt": FieldValue.serverTimestamp(),
                "createdBy": createdBy
            ]
            
            try await chatRef.setData(chatData)
            print("✅ Chat created successfully in Firestore: \(chatID)")
            return chatID
            
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
    
    /// Checks if a chat already exists with the same members
    /// - Parameter members: Array of user IDs
    /// - Returns: Existing chat ID if found, nil otherwise
    /// - Throws: ChatServiceError for network errors
    func checkForExistingChat(members: [String]) async throws -> String? {
        do {
            // Query for chats containing all members
            let query = firestore.collection(Chat.collectionName)
                .whereField("members", isEqualTo: members)
            
            let snapshot = try await query.getDocuments()
            
            // Return first match if found
            if let document = snapshot.documents.first {
                return document.documentID
            }
            
            return nil
            
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
    
    // MARK: - Contact Methods
    
    /// Fetches all users (contacts) excluding current user
    /// - Parameter currentUserID: Current user's ID to exclude
    /// - Returns: Array of User objects
    /// - Throws: ChatServiceError for network errors
    /// - Performance: Should complete in < 2 seconds (see shared-standards.md)
    func fetchContacts(currentUserID: String) async throws -> [User] {
        do {
            let usersCollection = firestore.collection(User.collectionName)
            let snapshot = try await usersCollection.getDocuments()
            
            let users = snapshot.documents.compactMap { document -> User? in
                // Exclude current user
                guard document.documentID != currentUserID else { return nil }
                
                do {
                    var user = try document.data(as: User.self)
                    user.id = document.documentID
                    return user
                } catch {
                    print("⚠️ Failed to decode user document \(document.documentID): \(error)")
                    return nil
                }
            }
            
            print("✅ Fetched \(users.count) contacts")
            return users
            
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
    
    /// Searches contacts by display name or email
    /// - Parameters:
    ///   - query: Search query string
    ///   - currentUserID: Current user's ID to exclude
    /// - Returns: Array of matching User objects
    /// - Throws: ChatServiceError for network errors
    func searchContacts(query: String, currentUserID: String) async throws -> [User] {
        guard !query.isEmpty else {
            throw ChatServiceError.invalidQuery("Search query cannot be empty")
        }
        
        // Fetch all contacts first
        let allContacts = try await fetchContacts(currentUserID: currentUserID)
        
        // Filter by query (case-insensitive)
        let lowercaseQuery = query.lowercased()
        let matchingContacts = allContacts.filter { user in
            user.displayName.lowercased().contains(lowercaseQuery) ||
            user.email.lowercased().contains(lowercaseQuery)
        }
        
        print("✅ Found \(matchingContacts.count) contacts matching '\(query)'")
        return matchingContacts
    }
    
    /// Deletes a chat from Firestore
    /// - Parameter chatID: The ID of the chat to delete
    /// - Throws: ChatServiceError for various failure scenarios
    func deleteChat(chatID: String) async throws {
        do {
            try await firestore.collection(Chat.collectionName).document(chatID).delete()
            print("✅ Chat deleted successfully: \(chatID)")
        } catch {
            throw ChatServiceError.networkError(error)
        }
    }
}

// MARK: - ChatServiceError

/// Errors that can occur in ChatService operations
enum ChatServiceError: LocalizedError {
    case chatNotFound
    case permissionDenied
    case networkError(Error)
    case unknown(Error)
    case invalidMembers(String)
    case invalidQuery(String)
    
    var errorDescription: String? {
        switch self {
        case .chatNotFound:
            return "Chat not found"
        case .permissionDenied:
            return "Permission denied to access chat"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        case .invalidMembers(let message):
            return "Invalid members: \(message)"
        case .invalidQuery(let message):
            return "Invalid query: \(message)"
        }
    }
}
