//
//  TestDataService.swift
//  MessageAI
//
//  Service for creating test data in Firestore for development and testing
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for creating test data in Firestore
/// - Note: Only use in development/testing environments
class TestDataService: ObservableObject {
    
    // MARK: - Properties
    
    private let firestore: Firestore
    
    // MARK: - Initialization
    
    init() {
        self.firestore = FirebaseService.shared.getFirestore()
    }
    
    // MARK: - Public Methods
    
    /// Creates test chat data in Firestore
    /// - Parameter currentUserID: The current user's ID
    /// - Throws: Error if creation fails
    func createTestChatData(currentUserID: String) async throws {
        print("🧪 Creating test chat data for user: \(currentUserID)")
        
        // Create test users first
        try await createTestUsers()
        
        // Create test chats
        try await createTestChats(currentUserID: currentUserID)
        
        // Create test messages
        try await createTestMessages(currentUserID: currentUserID)
        
        print("✅ Test data created successfully")
    }
    
    /// Creates test users in Firestore
    /// - Throws: Error if creation fails
    private func createTestUsers() async throws {
        let testUsers = [
            User(
                id: "user-2",
                displayName: "John Doe",
                email: "john@example.com",
                profilePhotoURL: nil,
                createdAt: Date().addingTimeInterval(-86400), // 1 day ago
                lastActiveAt: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            User(
                id: "user-3",
                displayName: "Jane Smith",
                email: "jane@example.com",
                profilePhotoURL: nil,
                createdAt: Date().addingTimeInterval(-172800), // 2 days ago
                lastActiveAt: Date().addingTimeInterval(-7200) // 2 hours ago
            ),
            User(
                id: "user-4",
                displayName: "Mike Johnson",
                email: "mike@example.com",
                profilePhotoURL: nil,
                createdAt: Date().addingTimeInterval(-259200), // 3 days ago
                lastActiveAt: Date().addingTimeInterval(-1800) // 30 minutes ago
            ),
            User(
                id: "user-5",
                displayName: "Sarah Wilson",
                email: "sarah@example.com",
                profilePhotoURL: nil,
                createdAt: Date().addingTimeInterval(-345600), // 4 days ago
                lastActiveAt: Date().addingTimeInterval(-900) // 15 minutes ago
            )
        ]
        
        for user in testUsers {
            do {
                try firestore.collection("users")
                    .document(user.id)
                    .setData(from: user)
                print("✅ Created test user: \(user.displayName)")
            } catch {
                print("⚠️ Failed to create test user \(user.displayName): \(error)")
                // Continue with other users
            }
        }
    }
    
    /// Creates test chats in Firestore
    /// - Parameter currentUserID: The current user's ID
    /// - Throws: Error if creation fails
    private func createTestChats(currentUserID: String) async throws {
        let now = Date()
        
        let testChats = [
            Chat(
                id: "test-chat-1",
                members: [currentUserID, "user-2"],
                lastMessage: "Hey! How are you doing?",
                lastMessageTimestamp: now.addingTimeInterval(-300), // 5 minutes ago
                lastMessageSenderID: "user-2",
                isGroupChat: false,
                createdAt: now.addingTimeInterval(-3600) // 1 hour ago
            ),
            Chat(
                id: "test-chat-2",
                members: [currentUserID, "user-3"],
                lastMessage: "Thanks for the help earlier!",
                lastMessageTimestamp: now.addingTimeInterval(-1800), // 30 minutes ago
                lastMessageSenderID: currentUserID,
                isGroupChat: false,
                createdAt: now.addingTimeInterval(-7200) // 2 hours ago
            ),
            Chat(
                id: "test-chat-3",
                members: [currentUserID, "user-4", "user-5"],
                lastMessage: "Meeting at 3pm today",
                lastMessageTimestamp: now.addingTimeInterval(-600), // 10 minutes ago
                lastMessageSenderID: "user-4",
                isGroupChat: true,
                groupName: "Team Chat",
                createdAt: now.addingTimeInterval(-10800) // 3 hours ago
            )
        ]
        
        for chat in testChats {
            do {
                try firestore.collection("chats")
                    .document(chat.id)
                    .setData(from: chat)
                print("✅ Created test chat: \(chat.id)")
            } catch {
                print("⚠️ Failed to create test chat \(chat.id): \(error)")
                // Continue with other chats
            }
        }
    }
    
    /// Creates test messages in Firestore
    /// - Parameter currentUserID: The current user's ID
    /// - Throws: Error if creation fails
    private func createTestMessages(currentUserID: String) async throws {
        let now = Date()
        
        // Messages for test-chat-1
        let chat1Messages = [
            Message(
                id: "msg-1-1",
                chatID: "test-chat-1",
                senderID: "user-2",
                text: "Hey! How are you doing?",
                timestamp: now.addingTimeInterval(-300),
                readBy: ["user-2", currentUserID],
                status: .read,
                senderName: "John Doe"
            ),
            Message(
                id: "msg-1-2",
                chatID: "test-chat-1",
                senderID: currentUserID,
                text: "I'm doing great! Thanks for asking. How about you?",
                timestamp: now.addingTimeInterval(-240),
                readBy: [currentUserID, "user-2"],
                status: .read
            ),
            Message(
                id: "msg-1-3",
                chatID: "test-chat-1",
                senderID: "user-2",
                text: "Pretty good! Just working on some new projects. What's new with you?",
                timestamp: now.addingTimeInterval(-180),
                readBy: ["user-2", currentUserID],
                status: .read,
                senderName: "John Doe"
            )
        ]
        
        // Messages for test-chat-2
        let chat2Messages = [
            Message(
                id: "msg-2-1",
                chatID: "test-chat-2",
                senderID: "user-3",
                text: "Hey! Can you help me with the project?",
                timestamp: now.addingTimeInterval(-2400),
                readBy: ["user-3", currentUserID],
                status: .read,
                senderName: "Jane Smith"
            ),
            Message(
                id: "msg-2-2",
                chatID: "test-chat-2",
                senderID: currentUserID,
                text: "Of course! What do you need help with?",
                timestamp: now.addingTimeInterval(-2100),
                readBy: [currentUserID, "user-3"],
                status: .read
            ),
            Message(
                id: "msg-2-3",
                chatID: "test-chat-2",
                senderID: "user-3",
                text: "Thanks for the help earlier!",
                timestamp: now.addingTimeInterval(-1800),
                readBy: ["user-3", currentUserID],
                status: .read,
                senderName: "Jane Smith"
            )
        ]
        
        // Messages for test-chat-3 (group chat)
        let chat3Messages = [
            Message(
                id: "msg-3-1",
                chatID: "test-chat-3",
                senderID: "user-4",
                text: "Hey team! How's everyone doing?",
                timestamp: now.addingTimeInterval(-3600),
                readBy: ["user-4", currentUserID, "user-5"],
                status: .read,
                senderName: "Mike Johnson"
            ),
            Message(
                id: "msg-3-2",
                chatID: "test-chat-3",
                senderID: currentUserID,
                text: "Doing well! Just finished the new feature.",
                timestamp: now.addingTimeInterval(-3300),
                readBy: [currentUserID, "user-4", "user-5"],
                status: .read
            ),
            Message(
                id: "msg-3-3",
                chatID: "test-chat-3",
                senderID: "user-5",
                text: "Great work! I'll review it later.",
                timestamp: now.addingTimeInterval(-3000),
                readBy: ["user-5", currentUserID, "user-4"],
                status: .read,
                senderName: "Sarah Wilson"
            ),
            Message(
                id: "msg-3-4",
                chatID: "test-chat-3",
                senderID: "user-4",
                text: "Meeting at 3pm today",
                timestamp: now.addingTimeInterval(-600),
                readBy: ["user-4", currentUserID],
                status: .delivered,
                senderName: "Mike Johnson"
            )
        ]
        
        // Save all messages
        let allMessages = chat1Messages + chat2Messages + chat3Messages
        
        for message in allMessages {
            do {
                try firestore.collection("chats")
                    .document(message.chatID)
                    .collection("messages")
                    .document(message.id)
                    .setData(from: message)
                print("✅ Created test message: \(message.id)")
            } catch {
                print("⚠️ Failed to create test message \(message.id): \(error)")
                // Continue with other messages
            }
        }
    }
    
    /// Clears all test data from Firestore
    /// - Warning: This will delete all data in the database
    /// - Throws: Error if deletion fails
    func clearAllTestData() async throws {
        print("🧹 Clearing all test data...")
        
        // Delete all messages
        let messagesQuery = firestore.collectionGroup("messages")
        let messagesSnapshot = try await messagesQuery.getDocuments()
        for document in messagesSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete all chats
        let chatsSnapshot = try await firestore.collection("chats").getDocuments()
        for document in chatsSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete all users (except current user)
        let usersSnapshot = try await firestore.collection("users").getDocuments()
        for document in usersSnapshot.documents {
            // Don't delete the current user
            if let currentUser = Auth.auth().currentUser,
               document.documentID != currentUser.uid {
                try await document.reference.delete()
            }
        }
        
        print("✅ All test data cleared")
    }
}
