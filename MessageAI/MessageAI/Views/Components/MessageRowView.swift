//
//  MessageRowView.swift
//  MessageAI
//
//  Message row component for chat display
//

import SwiftUI

/// Message row component that displays individual messages with sender info and timestamps
/// - Note: Handles group chat sender names and message layout
struct MessageRowView: View {
    
    // MARK: - Properties
    
    let message: Message
    let previousMessage: Message?
    let isFromCurrentUser: Bool
    let shouldShowSenderName: Bool
    let shouldShowTimestamp: Bool
    let senderDisplayName: String
    let timestamp: String
    let chat: Chat?
    let isGroupChat: Bool
    let groupMembers: [String]
    let currentUserID: String
    
    // MARK: - Initialization
    
    init(message: Message, previousMessage: Message?, viewModel: ChatViewModel) {
        self.message = message
        self.previousMessage = previousMessage
        self.isFromCurrentUser = viewModel.isMessageFromCurrentUser(message: message)
        self.shouldShowSenderName = viewModel.shouldShowSenderName(message: message)
        self.shouldShowTimestamp = viewModel.shouldShowTimestamp(message: message, previousMessage: previousMessage)
        self.senderDisplayName = viewModel.getSenderDisplayName(message: message)
        self.timestamp = viewModel.formatTimestamp(date: message.timestamp)
        self.chat = viewModel.chat
        self.isGroupChat = viewModel.chat?.isGroupChat ?? false
        self.groupMembers = viewModel.groupMembers
        self.currentUserID = viewModel.currentUserID
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            
            // PR-3: Show attribution with avatar for group chat messages from others
            if isGroupChat && !isFromCurrentUser && shouldShowSenderName {
                HStack(alignment: .top, spacing: 8) {
                    // Avatar and name
                    AvatarView(
                        photoURL: nil, // Will be fetched from UserService cache
                        displayName: senderDisplayName,
                        size: 28
                    )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(senderDisplayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.leading, 12)
            }
            
            // Message bubble
            HStack {
                if !isFromCurrentUser && isGroupChat {
                    // Spacer for avatar alignment in groups
                    Spacer()
                        .frame(width: 36)
                }
                
                MessageBubbleView(
                    message: message,
                    isFromCurrentUser: isFromCurrentUser,
                    status: message.status,
                    showSenderName: false, // PR-3: Attribution shown above, not in bubble
                    senderName: nil
                )
                
                if isFromCurrentUser || !isGroupChat {
                    Spacer()
                }
            }
            
            // Timestamp and status
            if shouldShowTimestamp {
                HStack {
                    if isFromCurrentUser {
                        Spacer()
                        
                        // Use ReadReceiptView for group chats, MessageStatusView for 1-on-1
                        if let chat = chat, chat.isGroupChat {
                            ReadReceiptView(
                                message: message,
                                chat: chat,
                                chatMembers: chat.members,
                                currentUserID: currentUserID
                            )
                        } else {
                            MessageStatusView(
                                status: message.status,
                                isOptimistic: message.isOptimistic,
                                retryCount: message.retryCount
                            )
                        }
                        
                        Text(timestamp)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text(timestamp)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
            } else if isFromCurrentUser {
                // Show status even without timestamp
                HStack {
                    Spacer()
                    
                    // Use ReadReceiptView for group chats, MessageStatusView for 1-on-1
                    if let chat = chat, chat.isGroupChat {
                        ReadReceiptView(
                            message: message,
                            chat: chat,
                            chatMembers: chat.members,
                            currentUserID: currentUserID
                        )
                    } else {
                        MessageStatusView(
                            status: message.status,
                            isOptimistic: message.isOptimistic,
                            retryCount: message.retryCount
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
            
            // Read receipt for group chats
            if isGroupChat && isFromCurrentUser && !groupMembers.isEmpty {
                HStack {
                    Spacer()
                    
                    ReadReceiptView(
                        message: message,
                        chat: chat,
                        chatMembers: groupMembers,
                        currentUserID: currentUserID
                    )
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Group chat message with sender name
        MessageRowView(
            message: Message(
                id: "1",
                chatID: "chat1",
                senderID: "user2",
                text: "Hey everyone! How's it going?",
                timestamp: Date().addingTimeInterval(-300),
                senderName: "John Doe"
            ),
            previousMessage: nil,
            viewModel: ChatViewModel(currentUserID: "user1")
        )
        
        // Current user message
        MessageRowView(
            message: Message(
                id: "2",
                chatID: "chat1",
                senderID: "user1",
                text: "I'm doing great, thanks!",
                timestamp: Date().addingTimeInterval(-200),
                status: .delivered
            ),
            previousMessage: Message(
                id: "1",
                chatID: "chat1",
                senderID: "user2",
                text: "Hey everyone! How's it going?",
                timestamp: Date().addingTimeInterval(-300),
                senderName: "John Doe"
            ),
            viewModel: ChatViewModel(currentUserID: "user1")
        )
        
        // Another user message (no sender name shown due to time proximity)
        MessageRowView(
            message: Message(
                id: "3",
                chatID: "chat1",
                senderID: "user3",
                text: "Same here!",
                timestamp: Date().addingTimeInterval(-100),
                senderName: "Jane Smith"
            ),
            previousMessage: Message(
                id: "2",
                chatID: "chat1",
                senderID: "user1",
                text: "I'm doing great, thanks!",
                timestamp: Date().addingTimeInterval(-200),
                status: .delivered
            ),
            viewModel: ChatViewModel(currentUserID: "user1")
        )
    }
    .padding()
}
