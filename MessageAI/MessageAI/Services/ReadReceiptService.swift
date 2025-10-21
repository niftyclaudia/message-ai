//
//  ReadReceiptService.swift
//  MessageAI
//
//  Service for managing message read receipts with Firebase integration
//

import Foundation
import FirebaseFirestore
import Combine

/// Service responsible for tracking and syncing message read receipts
class ReadReceiptService: ObservableObject {
    // MARK: - Properties
    
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    // MARK: - Public Methods
    
    /// Mark a single message as read by a user
    /// - Parameters:
    ///   - messageID: The ID of the message to mark as read
    ///   - userID: The ID of the user who read the message
    ///   - chatID: The ID of the chat containing the message
    /// - Throws: FirebaseError if update fails
    func markMessageAsRead(messageID: String, userID: String, chatID: String) async throws {
        // Validate inputs
        guard !messageID.isEmpty, !userID.isEmpty, !chatID.isEmpty else {
            throw NSError(domain: "ReadReceiptService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid message, user, or chat ID"])
        }
        
        let messageRef = db.collection("chats").document(chatID).collection("messages").document(messageID)
        
        // Update message with read receipt using Firestore transaction for atomicity
        _ = try await db.runTransaction { transaction, errorPointer in
            let messageDoc: DocumentSnapshot
            do {
                messageDoc = try transaction.getDocument(messageRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard messageDoc.exists else {
                let error = NSError(domain: "ReadReceiptService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Message not found"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Add user to readBy array if not already present
            var readBy = messageDoc.data()?["readBy"] as? [String] ?? []
            if !readBy.contains(userID) {
                readBy.append(userID)
            }
            
            // Update readAt timestamp for this user
            var readAt = messageDoc.data()?["readAt"] as? [String: Timestamp] ?? [:]
            readAt[userID] = Timestamp(date: Date())
            
            // Update the message document
            transaction.updateData([
                "readBy": readBy,
                "readAt": readAt,
                "status": MessageStatus.read.rawValue
            ], forDocument: messageRef)
            
            return nil
        }
    }
    
    /// Mark all messages in a chat as read by a user
    /// - Parameters:
    ///   - chatID: The ID of the chat
    ///   - userID: The ID of the user who read the messages
    /// - Throws: FirebaseError if update fails
    func markChatAsRead(chatID: String, userID: String) async throws {
        // Validate inputs
        guard !chatID.isEmpty, !userID.isEmpty else {
            throw NSError(domain: "ReadReceiptService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid chat or user ID"])
        }
        
        let messagesRef = db.collection("chats").document(chatID).collection("messages")
        
        // Query for all unread messages in the chat (messages not in readBy array for this user)
        let snapshot = try await messagesRef
            .whereField("readBy", notIn: [[userID]]) // Messages where user hasn't read yet
            .getDocuments()
        
        // Batch update all unread messages
        let batch = db.batch()
        let readTimestamp = Timestamp(date: Date())
        
        for document in snapshot.documents {
            var readBy = document.data()["readBy"] as? [String] ?? []
            if !readBy.contains(userID) {
                readBy.append(userID)
            }
            
            var readAt = document.data()["readAt"] as? [String: Timestamp] ?? [:]
            readAt[userID] = readTimestamp
            
            batch.updateData([
                "readBy": readBy,
                "readAt": readAt,
                "status": MessageStatus.read.rawValue
            ], forDocument: document.reference)
        }
        
        try await batch.commit()
    }
    
    /// Observe read receipt updates for messages in a chat
    /// - Parameters:
    ///   - chatID: The ID of the chat to observe
    ///   - completion: Callback invoked with updated read receipts (messageID -> readAt map)
    /// - Returns: ListenerRegistration to remove the listener when done
    func observeReadReceipts(chatID: String, completion: @escaping ([String: [String: Date]]) -> Void) -> ListenerRegistration {
        let messagesRef = db.collection("chats").document(chatID).collection("messages")
        
        let listener = messagesRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ ReadReceiptService: Error observing read receipts: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([:])
                return
            }
            
            var readReceiptsMap: [String: [String: Date]] = [:]
            
            for document in documents {
                let messageID = document.documentID
                if let readAtTimestamps = document.data()["readAt"] as? [String: Timestamp] {
                    let readAtDates = readAtTimestamps.mapValues { $0.dateValue() }
                    readReceiptsMap[messageID] = readAtDates
                }
            }
            
            completion(readReceiptsMap)
        }
        
        // Store listener with chatID as key
        listeners[chatID] = listener
        
        return listener
    }
    
    /// Get read status for a specific message
    /// - Parameter messageID: The ID of the message
    /// - Parameter chatID: The ID of the chat containing the message
    /// - Returns: Dictionary mapping user IDs to when they read the message
    /// - Throws: FirebaseError if fetch fails
    func getReadStatus(messageID: String, chatID: String) async throws -> [String: Date] {
        guard !messageID.isEmpty, !chatID.isEmpty else {
            throw NSError(domain: "ReadReceiptService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid message or chat ID"])
        }
        
        let messageRef = db.collection("chats").document(chatID).collection("messages").document(messageID)
        let document = try await messageRef.getDocument()
        
        guard document.exists else {
            throw NSError(domain: "ReadReceiptService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Message not found"])
        }
        
        guard let readAtTimestamps = document.data()?["readAt"] as? [String: Timestamp] else {
            return [:]
        }
        
        return readAtTimestamps.mapValues { $0.dateValue() }
    }
    
    /// Remove listener for a specific chat
    /// - Parameter chatID: The ID of the chat
    func removeListener(forChat chatID: String) {
        listeners[chatID]?.remove()
        listeners.removeValue(forKey: chatID)
    }
    
    /// Remove all active listeners
    func removeAllListeners() {
        listeners.values.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Cleanup
    
    deinit {
        removeAllListeners()
    }
}

