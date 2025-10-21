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
    
    // MARK: - Initialization
    
    init(message: Message, previousMessage: Message?, viewModel: ChatViewModel) {
        self.message = message
        self.previousMessage = previousMessage
        self.isFromCurrentUser = viewModel.isMessageFromCurrentUser(message: message)
        self.shouldShowSenderName = viewModel.shouldShowSenderName(message: message)
        self.shouldShowTimestamp = viewModel.shouldShowTimestamp(message: message, previousMessage: previousMessage)
        self.senderDisplayName = viewModel.getSenderDisplayName(message: message)
        self.timestamp = viewModel.formatTimestamp(date: message.timestamp)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
            
            // Sender name (for group chats)
            if shouldShowSenderName {
                HStack {
                    if isFromCurrentUser {
                        Spacer()
                    }
                    
                    Text(senderDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    
                    if !isFromCurrentUser {
                        Spacer()
                    }
                }
            }
            
            // Message bubble
            MessageBubbleView(
                message: message,
                isFromCurrentUser: isFromCurrentUser,
                status: message.status
            )
            
            // Timestamp
            if shouldShowTimestamp {
                HStack {
                    if isFromCurrentUser {
                        Spacer()
                    }
                    
                    Text(timestamp)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    
                    if !isFromCurrentUser {
                        Spacer()
                    }
                }
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
