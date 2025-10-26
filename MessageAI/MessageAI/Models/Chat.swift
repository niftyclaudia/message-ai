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
    
    /// ID of the most recent message
    var lastMessageID: String?
    
    /// Whether this is a group chat (false for 1-on-1 chats)
    var isGroupChat: Bool
    
    /// Group name for group chats (nil for 1-on-1 chats)
    var groupName: String?
    
    /// When this chat was created
    var createdAt: Date
    
    /// User ID of who created this chat
    var createdBy: String
    
    /// Unread message count per user (userID -> count)
    var unreadCount: [String: Int]
    
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
    
    // MARK: - Private Helper Methods
    
    /// Decodes a timestamp from Firestore with fallback for null values
    /// - Parameters:
    ///   - container: The decoder container
    ///   - key: The coding key for the timestamp
    /// - Returns: Decoded Date or current date as fallback
    private static func decodeTimestamp(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Date {
        if let timestamp = try? container.decode(Timestamp.self, forKey: key) {
            return timestamp.dateValue()
        } else if let date = try? container.decode(Date.self, forKey: key) {
            return date
        } else {
            // Fallback to current date if timestamp is null or missing
            return Date()
        }
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case members
        case lastMessage
        case lastMessageTimestamp
        case lastMessageSenderID
        case lastMessageID
        case isGroupChat
        case groupName
        case createdAt
        case createdBy
        case unreadCount
    }
    
    // MARK: - Initialization
    
    init(id: String, members: [String], lastMessage: String, lastMessageTimestamp: Date, lastMessageSenderID: String, lastMessageID: String? = nil, isGroupChat: Bool, groupName: String? = nil, createdAt: Date, createdBy: String, unreadCount: [String: Int] = [:]) {
        self.id = id
        self.members = members
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderID = lastMessageSenderID
        self.lastMessageID = lastMessageID
        self.isGroupChat = isGroupChat
        self.groupName = groupName
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.unreadCount = unreadCount
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        members = try container.decode([String].self, forKey: .members)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        lastMessageSenderID = try container.decode(String.self, forKey: .lastMessageSenderID)
        lastMessageID = try container.decodeIfPresent(String.self, forKey: .lastMessageID)
        isGroupChat = try container.decode(Bool.self, forKey: .isGroupChat)
        groupName = try container.decodeIfPresent(String.self, forKey: .groupName)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        unreadCount = try container.decodeIfPresent([String: Int].self, forKey: .unreadCount) ?? [:]
        
        // Handle timestamps with fallback for null values
        lastMessageTimestamp = Self.decodeTimestamp(from: container, forKey: .lastMessageTimestamp)
        createdAt = Self.decodeTimestamp(from: container, forKey: .createdAt)
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(members, forKey: .members)
        try container.encode(lastMessage, forKey: .lastMessage)
        try container.encode(lastMessageSenderID, forKey: .lastMessageSenderID)
        try container.encodeIfPresent(lastMessageID, forKey: .lastMessageID)
        try container.encode(isGroupChat, forKey: .isGroupChat)
        try container.encodeIfPresent(groupName, forKey: .groupName)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(unreadCount, forKey: .unreadCount)
        
        // Convert dates to Firestore Timestamps
        try container.encode(Timestamp(date: lastMessageTimestamp), forKey: .lastMessageTimestamp)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}
