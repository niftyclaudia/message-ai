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
}

// MARK: - ChatServiceError

/// Errors that can occur in ChatService operations
enum ChatServiceError: LocalizedError {
    case chatNotFound
    case permissionDenied
    case networkError(Error)
    case unknown(Error)
    
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
        }
    }
}
