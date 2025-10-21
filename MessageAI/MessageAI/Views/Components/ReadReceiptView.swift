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
    let chat: Chat?
    let chatMembers: [String]
    let currentUserID: String
    
    // MARK: - Computed Properties
    
    /// Number of group members who have read the message (excluding sender)
    private var readCount: Int {
        message.readBy.filter { $0 != currentUserID }.count
    }
    
    /// Total number of group members (excluding sender)
    private var totalMembers: Int {
        if let chat = chat {
            return chat.members.count - 1
        } else {
            return chatMembers.count - 1
        }
    }
    
    /// Whether this is a group chat and message is from current user
    private var shouldShow: Bool {
        let isGroupChat = chat?.isGroupChat ?? (chatMembers.count > 2)
        return isGroupChat && message.senderID == currentUserID
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

/// Detailed read receipt view showing individual member read status
struct DetailedReadReceiptView: View {
    
    // MARK: - Properties
    
    let message: Message
    let chatMembers: [String]
    let currentUserID: String
    @State private var isExpanded: Bool = false
    
    // MARK: - Computed Properties
    
    private var readMembers: [String] {
        message.readBy.filter { $0 != currentUserID }
    }
    
    private var unreadMembers: [String] {
        chatMembers.filter { !message.readBy.contains($0) && $0 != currentUserID }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Summary view
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(message.readBy.count) of \(chatMembers.count) read")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded view
            if isExpanded {
                VStack(alignment: .trailing, spacing: 2) {
                    if !readMembers.isEmpty {
                        Text("Read by:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        ForEach(readMembers, id: \.self) { memberID in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                
                                Text(getMemberDisplayName(memberID))
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    if !unreadMembers.isEmpty {
                        Text("Not read by:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        ForEach(unreadMembers, id: \.self) { memberID in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 6, height: 6)
                                
                                Text(getMemberDisplayName(memberID))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMemberDisplayName(_ memberID: String) -> String {
        // In a real app, you'd fetch this from a user service
        // For now, return a simplified display name
        if memberID == currentUserID {
            return "You"
        } else {
            return "User \(memberID.prefix(4))"
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
        chatMembers: ["user1", "user2", "user3", "user4"],
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
        chatMembers: ["user1", "user2", "user3", "user4"],
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
        chatMembers: ["user1", "user2", "user3", "user4"],
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
        chatMembers: ["user1", "user2"],
        currentUserID: "user1"
    )
    .padding()
}