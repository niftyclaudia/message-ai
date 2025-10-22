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
    
    /// Group name for group chats (nil for 1-on-1 chats)
    var groupName: String?
    
    /// When this chat was created
    var createdAt: Date
    
    /// User ID of who created this chat
    var createdBy: String
    
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
        case groupName
        case createdAt
        case createdBy
    }
    
    // MARK: - Initialization
    
    init(id: String, members: [String], lastMessage: String, lastMessageTimestamp: Date, lastMessageSenderID: String, isGroupChat: Bool, groupName: String? = nil, createdAt: Date, createdBy: String) {
        self.id = id
        self.members = members
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderID = lastMessageSenderID
        self.isGroupChat = isGroupChat
        self.groupName = groupName
        self.createdAt = createdAt
        self.createdBy = createdBy
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
        groupName = try container.decodeIfPresent(String.self, forKey: .groupName)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        
        // Handle lastMessageTimestamp with fallback for null values
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastMessageTimestamp) {
            lastMessageTimestamp = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .lastMessageTimestamp) {
            lastMessageTimestamp = date
        } else {
            // Fallback to current date if lastMessageTimestamp is null or missing
            lastMessageTimestamp = Date()
        }
        
        // Handle createdAt with fallback for null values
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            // Fallback to current date if createdAt is null or missing
            createdAt = Date()
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
        try container.encodeIfPresent(groupName, forKey: .groupName)
        try container.encode(createdBy, forKey: .createdBy)
        
        // Convert dates to Firestore Timestamps
        try container.encode(Timestamp(date: lastMessageTimestamp), forKey: .lastMessageTimestamp)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}
