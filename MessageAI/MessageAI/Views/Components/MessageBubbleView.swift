//
//  MessageBubbleView.swift
//  MessageAI
//
//  Message bubble component for chat display
//

import SwiftUI

/// Reusable message bubble component with sent/received styling
/// - Note: Handles text wrapping, padding, and status indicators
struct MessageBubbleView: View {
    
    // MARK: - Properties
    
    let message: Message
    let isFromCurrentUser: Bool
    let status: MessageStatus
    let showSenderName: Bool
    let senderName: String?
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Sender name for group chats
                if showSenderName, let senderName = senderName {
                    Text(senderName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
                
                Text(message.text)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    )
                    .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)
                
                // Status indicator for sent messages
                if isFromCurrentUser {
                    HStack(spacing: 4) {
                        statusIcon
                        Text(formatStatusText(status))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    // MARK: - Status Icon
    
    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .sending:
            Image(systemName: "clock")
                .foregroundColor(.secondary)
        case .sent:
            Image(systemName: "checkmark")
                .foregroundColor(.secondary)
        case .delivered:
            Image(systemName: "checkmark.circle")
                .foregroundColor(.secondary)
        case .read:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
        case .failed:
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.red)
        case .queued:
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatStatusText(_ status: MessageStatus) -> String {
        switch status {
        case .sending:
            return "Sending..."
        case .sent:
            return "Sent"
        case .delivered:
            return "Delivered"
        case .read:
            return "Read"
        case .failed:
            return "Failed"
        case .queued:
            return "Queued"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Sent message
        MessageBubbleView(
            message: Message(
                id: "1",
                chatID: "chat1",
                senderID: "user1",
                text: "Hello there! How are you doing today?",
                timestamp: Date(),
                status: .delivered
            ),
            isFromCurrentUser: true,
            status: .delivered,
            showSenderName: false,
            senderName: nil
        )
        
        // Received message
        MessageBubbleView(
            message: Message(
                id: "2",
                chatID: "chat1",
                senderID: "user2",
                text: "I'm doing great, thanks for asking!",
                timestamp: Date(),
                status: .sent
            ),
            isFromCurrentUser: false,
            status: .sent,
            showSenderName: false,
            senderName: nil
        )
        
        // Group chat message with sender name
        MessageBubbleView(
            message: Message(
                id: "3",
                chatID: "chat1",
                senderID: "user2",
                text: "This is a group message",
                timestamp: Date(),
                status: .sent
            ),
            isFromCurrentUser: false,
            status: .sent,
            showSenderName: true,
            senderName: "John Doe"
        )
        
        // Failed message
        MessageBubbleView(
            message: Message(
                id: "4",
                chatID: "chat1",
                senderID: "user1",
                text: "This message failed to send",
                timestamp: Date(),
                status: .failed
            ),
            isFromCurrentUser: true,
            status: .failed,
            showSenderName: false,
            senderName: nil
        )
    }
    .padding()
}
