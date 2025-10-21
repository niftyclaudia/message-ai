//
//  Chat.swift
//  MessageAI
//
//  Chat data model for conversation list functionality
//

import Foundation
import FirebaseFirestore

/// Chat data model representing a conversation between users
/// - Note: Maps to Firestore collection 'chats' with document ID = chatID
struct Chat: Codable, Identifiable, Equatable {
    /// Unique chat identifier
    var id: String
    
    /// Array of user IDs who are members of this chat
    var members: [String]
    
    /// Preview of the most recent message in the chat
    var lastMessage: String
    
    /// Timestamp of the most recent message
    var lastMessageTimestamp: Date
    
    /// User ID of who sent the most recent message
    var lastMessageSenderID: String
    
    /// Whether this is a group chat (false for 1-on-1 chats)
    var isGroupChat: Bool
    
    /// When this chat was created
    var createdAt: Date
    
    /// Firestore collection name
    static let collectionName = "chats"
    
    // MARK: - Computed Properties
    
    /// Returns the other user's ID in a 1-on-1 chat
    /// - Parameter currentUserID: The current user's ID
    /// - Returns: The other user's ID, or nil if not a 1-on-1 chat or user not found
    func getOtherUserID(currentUserID: String) -> String? {
        guard !isGroupChat, members.count == 2 else { return nil }
        return members.first { $0 != currentUserID }
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case members
        case lastMessage
        case lastMessageTimestamp
        case lastMessageSenderID
        case isGroupChat
        case createdAt
    }
    
    // MARK: - Initialization
    
    init(id: String, members: [String], lastMessage: String, lastMessageTimestamp: Date, lastMessageSenderID: String, isGroupChat: Bool, createdAt: Date) {
        self.id = id
        self.members = members
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderID = lastMessageSenderID
        self.isGroupChat = isGroupChat
        self.createdAt = createdAt
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        members = try container.decode([String].self, forKey: .members)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        lastMessageSenderID = try container.decode(String.self, forKey: .lastMessageSenderID)
        isGroupChat = try container.decode(Bool.self, forKey: .isGroupChat)
        
        // Handle Firestore Timestamp conversion for dates
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastMessageTimestamp) {
            lastMessageTimestamp = timestamp.dateValue()
        } else {
            lastMessageTimestamp = try container.decode(Date.self, forKey: .lastMessageTimestamp)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(members, forKey: .members)
        try container.encode(lastMessage, forKey: .lastMessage)
        try container.encode(lastMessageSenderID, forKey: .lastMessageSenderID)
        try container.encode(isGroupChat, forKey: .isGroupChat)
        
        // Convert dates to Firestore Timestamps
        try container.encode(Timestamp(date: lastMessageTimestamp), forKey: .lastMessageTimestamp)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}
