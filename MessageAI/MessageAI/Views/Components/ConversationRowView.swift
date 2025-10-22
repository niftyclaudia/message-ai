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
    let presenceStatus: PresenceState?
    
    // MARK: - Private Computed Properties
    
    /// Display name for the other user, group name, or "Unknown User"
    private var displayName: String {
        if chat.isGroupChat {
            return chat.groupName ?? "Group Chat"
        }
        return otherUser?.displayName ?? "Unknown User"
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
            // Avatar with presence indicator
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    photoURL: profilePhotoURL,
                    displayName: displayName,
                    size: 40
                )
                
                // Presence indicator
                if let presenceStatus = presenceStatus {
                    PresenceIndicator(status: presenceStatus, size: 12)
                        .offset(x: 2, y: 2)
                }
            }
            
            // Chat info
            VStack(alignment: .leading, spacing: 4) {
                // Name and timestamp
                HStack {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Group indicator
                    if chat.isGroupChat {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(timestamp)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                // Message preview with member count for groups
                HStack(spacing: 4) {
                    Text(messagePreview)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if chat.isGroupChat {
                        Text("• \(chat.members.count) members")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    
                    Spacer()
                }
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
            createdAt: Date(),
            createdBy: "user1"
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
        timestamp: "5m",
        presenceStatus: .online
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
            createdAt: Date(),
            createdBy: "user1"
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
        timestamp: "10m",
        presenceStatus: .offline
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
            createdAt: Date(),
            createdBy: "user1"
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
        timestamp: "1h",
        presenceStatus: nil
    )
}
