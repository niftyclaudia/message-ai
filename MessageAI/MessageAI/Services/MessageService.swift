//
//  MessageService.swift
//  MessageAI
//
//  Message service for chat functionality
//

import Foundation
import FirebaseFirestore

/// Service for managing message operations and real-time updates
/// - Note: Handles Firestore queries for message display and status updates
class MessageService {
    
    // MARK: - Properties
    
    private let firestore: Firestore
    
    // MARK: - Initialization
    
    init() {
        self.firestore = FirebaseService.shared.getFirestore()
    }
    
    // MARK: - Public Methods
    
    /// Fetches messages for a specific chat with pagination
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - limit: Maximum number of messages to fetch (default: 50)
    /// - Returns: Array of Message objects sorted by timestamp ascending
    /// - Throws: MessageServiceError for various failure scenarios
    func fetchMessages(chatID: String, limit: Int = 50) async throws -> [Message] {
        do {
            let query = firestore.collection("chats")
                .document(chatID)
                .collection(Message.collectionName)
                .order(by: "timestamp", descending: false)
                .limit(to: limit)
            
            let snapshot = try await query.getDocuments()
            
            var messages: [Message] = []
            for document in snapshot.documents {
                do {
                    var message = try document.data(as: Message.self)
                    message.id = document.documentID
                    messages.append(message)
                } catch {
                    print("⚠️ Failed to decode message document \(document.documentID): \(error)")
                    // Continue with other documents
                }
            }
            
            return messages
        } catch {
            throw MessageServiceError.networkError(error)
        }
    }
    
    /// Sets up real-time listener for messages in a chat
    /// - Parameters:
    ///   - chatID: The chat's ID
    ///   - completion: Callback with updated messages array
    /// - Returns: ListenerRegistration for cleanup
    func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration {
        let query = firestore.collection("chats")
            .document(chatID)
            .collection(Message.collectionName)
            .order(by: "timestamp", descending: false)
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                print("⚠️ Message listener error: \(error)")
                completion([])
                return
            }
            
            guard let snapshot = snapshot else {
                print("⚠️ Message listener: no snapshot")
                completion([])
                return
            }
            
            var messages: [Message] = []
            for document in snapshot.documents {
                do {
                    var message = try document.data(as: Message.self)
                    message.id = document.documentID
                    messages.append(message)
                } catch {
                    print("⚠️ Failed to decode message document \(document.documentID): \(error)")
                    // Continue with other documents
                }
            }
            
            completion(messages)
        }
    }
    
    /// Fetches a specific message by ID
    /// - Parameter messageID: The message's ID
    /// - Returns: Message object
    /// - Throws: MessageServiceError for various failure scenarios
    func fetchMessage(messageID: String) async throws -> Message {
        do {
            // Note: This is a simplified implementation
            // In a real app, you'd need to know the chatID to construct the path
            // For now, we'll search across all chats (not efficient for production)
            let query = firestore.collectionGroup(Message.collectionName)
                .whereField("id", isEqualTo: messageID)
                .limit(to: 1)
            
            let snapshot = try await query.getDocuments()
            
            guard let document = snapshot.documents.first else {
                throw MessageServiceError.messageNotFound
            }
            
            var message = try document.data(as: Message.self)
            message.id = document.documentID
            return message
        } catch let error as MessageServiceError {
            throw error
        } catch {
            throw MessageServiceError.networkError(error)
        }
    }
    
    /// Marks a message as read by a specific user
    /// - Parameters:
    ///   - messageID: The message's ID
    ///   - userID: The user's ID who read the message
    /// - Throws: MessageServiceError for various failure scenarios
    func markMessageAsRead(messageID: String, userID: String) async throws {
        do {
            // Note: This is a simplified implementation
            // In a real app, you'd need to know the chatID to construct the path
            // For now, we'll search across all chats (not efficient for production)
            let query = firestore.collectionGroup(Message.collectionName)
                .whereField("id", isEqualTo: messageID)
                .limit(to: 1)
            
            let snapshot = try await query.getDocuments()
            
            guard let document = snapshot.documents.first else {
                throw MessageServiceError.messageNotFound
            }
            
            var message = try document.data(as: Message.self)
            
            // Add user to readBy array if not already present
            if !message.readBy.contains(userID) {
                message.readBy.append(userID)
                
                // Update the message in Firestore
                try document.reference.setData(from: message, merge: true)
            }
        } catch let error as MessageServiceError {
            throw error
        } catch {
            throw MessageServiceError.networkError(error)
        }
    }
}

// MARK: - MessageServiceError

/// Errors that can occur in MessageService operations
enum MessageServiceError: LocalizedError {
    case messageNotFound
    case permissionDenied
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .messageNotFound:
            return "Message not found"
        case .permissionDenied:
            return "Permission denied to access message"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
