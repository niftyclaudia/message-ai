//
//  ReadReceiptView.swift
//  MessageAI
//
//  Read receipt indicator for group chats showing member read status
//

import SwiftUI

/// View that displays read receipt information for group chats
/// - Note: Shows "Read by X of Y" format for group messages
struct ReadReceiptView: View {
    
    // MARK: - Properties
    
    let message: Message
    let chat: Chat
    let currentUserID: String
    
    // MARK: - Computed Properties
    
    /// Number of group members who have read the message (excluding sender)
    private var readCount: Int {
        message.readBy.filter { $0 != currentUserID }.count
    }
    
    /// Total number of group members (excluding sender)
    private var totalMembers: Int {
        chat.members.count - 1
    }
    
    /// Whether this is a group chat and message is from current user
    private var shouldShow: Bool {
        chat.isGroupChat && message.senderID == currentUserID
    }
    
    /// Read receipt color based on read status
    private var receiptColor: Color {
        if readCount == totalMembers {
            return .blue  // All read
        } else if readCount > 0 {
            return .green  // Some read
        } else {
            return .secondary  // None read yet
        }
    }
    
    /// Icon to display based on read status
    private var receiptIcon: String {
        if readCount == totalMembers {
            return "checkmark.circle.fill"  // All read
        } else if readCount > 0 {
            return "checkmark.circle"  // Some read
        } else {
            return "checkmark"  // None read yet
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        if shouldShow {
            HStack(spacing: 4) {
                Image(systemName: receiptIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(receiptColor)
                
                if totalMembers > 0 {
                    Text("Read by \(readCount) of \(totalMembers)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Sent")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("All Read") {
    ReadReceiptView(
        message: Message(
            id: "msg1",
            chatID: "chat1",
            senderID: "user1",
            text: "Hello everyone!",
            timestamp: Date(),
            readBy: ["user1", "user2", "user3", "user4"]
        ),
        chat: Chat(
            id: "chat1",
            members: ["user1", "user2", "user3", "user4"],
            lastMessage: "Hello everyone!",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: true,
            groupName: "Team Chat",
            createdAt: Date(),
            createdBy: "user1"
        ),
        currentUserID: "user1"
    )
    .padding()
}

#Preview("Partially Read") {
    ReadReceiptView(
        message: Message(
            id: "msg1",
            chatID: "chat1",
            senderID: "user1",
            text: "Hello everyone!",
            timestamp: Date(),
            readBy: ["user1", "user2"]
        ),
        chat: Chat(
            id: "chat1",
            members: ["user1", "user2", "user3", "user4"],
            lastMessage: "Hello everyone!",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: true,
            groupName: "Team Chat",
            createdAt: Date(),
            createdBy: "user1"
        ),
        currentUserID: "user1"
    )
    .padding()
}

#Preview("Not Read Yet") {
    ReadReceiptView(
        message: Message(
            id: "msg1",
            chatID: "chat1",
            senderID: "user1",
            text: "Hello everyone!",
            timestamp: Date(),
            readBy: ["user1"]
        ),
        chat: Chat(
            id: "chat1",
            members: ["user1", "user2", "user3", "user4"],
            lastMessage: "Hello everyone!",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: true,
            groupName: "Team Chat",
            createdAt: Date(),
            createdBy: "user1"
        ),
        currentUserID: "user1"
    )
    .padding()
}

#Preview("One-on-One Chat (Should Not Show)") {
    ReadReceiptView(
        message: Message(
            id: "msg1",
            chatID: "chat1",
            senderID: "user1",
            text: "Hello!",
            timestamp: Date(),
            readBy: ["user1", "user2"]
        ),
        chat: Chat(
            id: "chat1",
            members: ["user1", "user2"],
            lastMessage: "Hello!",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: false,
            createdAt: Date(),
            createdBy: "user1"
        ),
        currentUserID: "user1"
    )
    .padding()
}

