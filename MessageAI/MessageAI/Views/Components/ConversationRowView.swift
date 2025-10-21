//
//  ConversationRowView.swift
//  MessageAI
//
//  Individual conversation row component for conversation list
//

import SwiftUI

/// Individual conversation row showing chat preview
/// - Note: Displays avatar, name, message preview, and timestamp
struct ConversationRowView: View {
    
    // MARK: - Properties
    
    let chat: Chat
    let otherUser: User?
    let currentUserID: String
    let timestamp: String
    
    // MARK: - Private Computed Properties
    
    /// Display name for the other user or "Unknown User"
    private var displayName: String {
        otherUser?.displayName ?? "Unknown User"
    }
    
    /// Profile photo URL for the other user
    private var profilePhotoURL: String? {
        otherUser?.profilePhotoURL
    }
    
    /// Message preview with "You: " prefix if current user sent it
    private var messagePreview: String {
        if chat.lastMessageSenderID == currentUserID {
            return "You: \(chat.lastMessage)"
        } else {
            return chat.lastMessage
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            AvatarView(
                photoURL: profilePhotoURL,
                displayName: displayName,
                size: 40
            )
            
            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                // Name and timestamp
                HStack {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                // Message preview
                Text(messagePreview)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview("With Other User") {
    ConversationRowView(
        chat: Chat(
            id: "chat1",
            members: ["user1", "user2"],
            lastMessage: "Hey, how are you doing?",
            lastMessageTimestamp: Date().addingTimeInterval(-300),
            lastMessageSenderID: "user2",
            isGroupChat: false,
            createdAt: Date()
        ),
        otherUser: User(
            id: "user2",
            displayName: "John Doe",
            email: "john@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        ),
        currentUserID: "user1",
        timestamp: "5m"
    )
}

#Preview("Current User Message") {
    ConversationRowView(
        chat: Chat(
            id: "chat2",
            members: ["user1", "user2"],
            lastMessage: "Thanks for the update!",
            lastMessageTimestamp: Date().addingTimeInterval(-600),
            lastMessageSenderID: "user1",
            isGroupChat: false,
            createdAt: Date()
        ),
        otherUser: User(
            id: "user2",
            displayName: "Jane Smith",
            email: "jane@example.com",
            profilePhotoURL: "https://example.com/photo.jpg",
            createdAt: Date(),
            lastActiveAt: Date()
        ),
        currentUserID: "user1",
        timestamp: "10m"
    )
}

#Preview("Long Message") {
    ConversationRowView(
        chat: Chat(
            id: "chat3",
            members: ["user1", "user2"],
            lastMessage: "This is a very long message that should be truncated when displayed in the conversation list to prevent the UI from becoming cluttered.",
            lastMessageTimestamp: Date().addingTimeInterval(-3600),
            lastMessageSenderID: "user2",
            isGroupChat: false,
            createdAt: Date()
        ),
        otherUser: User(
            id: "user2",
            displayName: "Alice Wonder",
            email: "alice@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        ),
        currentUserID: "user1",
        timestamp: "1h"
    )
}
