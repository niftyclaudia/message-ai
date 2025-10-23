//
//  OptimisticMessageRowView.swift
//  MessageAI
//
//  Optimistic message row component for immediate UI display
//

import SwiftUI

/// Optimistic message row component that displays messages before server confirmation
/// - Note: Handles optimistic updates with smooth animations and status indicators
struct OptimisticMessageRowView: View {
    
    // MARK: - Properties
    
    let message: Message
    let previousMessage: Message?
    let isFromCurrentUser: Bool
    let shouldShowSenderName: Bool
    let shouldShowTimestamp: Bool
    let senderDisplayName: String
    let timestamp: String
    let chat: Chat?
    let currentUserID: String
    let onRetry: (() -> Void)?
    
    // MARK: - Animation Properties
    
    @State private var isAnimating: Bool = false
    @State private var opacity: Double = 0.0
    @State private var scale: Double = 0.8
    @State private var offsetY: Double = 20
    
    // MARK: - Initialization
    
    init(message: Message, previousMessage: Message?, viewModel: ChatViewModel, onRetry: (() -> Void)? = nil) {
        self.message = message
        self.previousMessage = previousMessage
        self.isFromCurrentUser = viewModel.isMessageFromCurrentUser(message: message)
        self.shouldShowSenderName = viewModel.shouldShowSenderName(message: message)
        self.shouldShowTimestamp = viewModel.shouldShowTimestamp(message: message, previousMessage: previousMessage)
        self.senderDisplayName = viewModel.getSenderDisplayName(message: message)
        self.timestamp = viewModel.formatTimestamp(date: message.timestamp)
        self.chat = viewModel.chat
        self.currentUserID = viewModel.currentUserID
        self.onRetry = onRetry
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
            
            // Optimistic message bubble with animation
            OptimisticMessageBubbleView(
                message: message,
                isFromCurrentUser: isFromCurrentUser,
                status: message.status,
                onRetry: onRetry
            )
            .opacity(opacity)
            .scaleEffect(scale)
            .offset(y: offsetY)
            .animation(.easeOut(duration: 0.3), value: opacity)
            .animation(.easeOut(duration: 0.3), value: scale)
            .animation(.easeOut(duration: 0.3), value: offsetY)
            
            // Timestamp and status
            if shouldShowTimestamp {
                HStack {
                    if isFromCurrentUser {
                        Spacer()
                        
                        // Use ReadReceiptView for group chats, OptimisticMessageStatusView for 1-on-1
                        if let chat = chat, chat.isGroupChat {
                            ReadReceiptView(
                                message: message,
                                chat: chat,
                                chatMembers: chat.members,
                                currentUserID: currentUserID
                            )
                        } else {
                            OptimisticMessageStatusView(
                                status: message.status,
                                isOptimistic: message.isOptimistic,
                                onRetry: message.status == .failed ? onRetry : nil
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
                    
                    // Use ReadReceiptView for group chats, OptimisticMessageStatusView for 1-on-1
                    if let chat = chat, chat.isGroupChat {
                        ReadReceiptView(
                            message: message,
                            chat: chat,
                            chatMembers: chat.members,
                            currentUserID: currentUserID
                        )
                    } else {
                        OptimisticMessageStatusView(
                            status: message.status,
                            isOptimistic: message.isOptimistic,
                            onRetry: message.status == .failed ? onRetry : nil
                        )
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 2)
        .onAppear {
            // Animate message appearance
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 1.0
                scale = 1.0
                offsetY = 0
            }
        }
    }
}

// MARK: - Optimistic Message Bubble View

struct OptimisticMessageBubbleView: View {
    
    // MARK: - Properties
    
    let message: Message
    let isFromCurrentUser: Bool
    let status: MessageStatus
    let onRetry: (() -> Void)?
    
    // MARK: - Animation Properties
    
    @State private var isPulsing: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(bubbleColor)
                            .overlay(
                                // Optimistic indicator for sending messages
                                Group {
                                    if message.isOptimistic && status == .sending {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                            .scaleEffect(isPulsing ? 1.05 : 1.0)
                                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
                                    }
                                }
                            )
                    )
                    .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)
                
                // Status indicator for sent messages
                if isFromCurrentUser {
                    HStack(spacing: 4) {
                        OptimisticStatusIcon(
                            status: status,
                            isOptimistic: message.isOptimistic
                        )
                        
                        Text(formatStatusText(status, isOptimistic: message.isOptimistic))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
        .onAppear {
            if message.isOptimistic && status == .sending {
                isPulsing = true
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var bubbleColor: Color {
        if isFromCurrentUser {
            switch status {
            case .sending, .sent, .delivered, .read:
                return .blue
            case .failed:
                return .red.opacity(0.8)
            case .queued:
                return .orange.opacity(0.8)
            }
        } else {
            return Color.gray.opacity(0.2)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatStatusText(_ status: MessageStatus, isOptimistic: Bool) -> String {
        switch status {
        case .sending:
            return isOptimistic ? "Sending..." : "Sending"
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

// MARK: - Optimistic Status Icon

struct OptimisticStatusIcon: View {
    
    // MARK: - Properties
    
    let status: MessageStatus
    let isOptimistic: Bool
    
    // MARK: - Animation Properties
    
    @State private var isRotating: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch status {
            case .sending:
                if isOptimistic {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.blue)
                        .rotationEffect(.degrees(isRotating ? 360 : 0))
                        .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isRotating)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                }
                
            case .sent:
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                
            case .delivered:
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.blue)
                
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(.red)
                
            case .queued:
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.orange)
            }
        }
        .onAppear {
            if isOptimistic && status == .sending {
                isRotating = true
            }
        }
    }
}

// MARK: - Optimistic Message Status View

struct OptimisticMessageStatusView: View {
    
    // MARK: - Properties
    
    let status: MessageStatus
    let isOptimistic: Bool
    let onRetry: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            OptimisticStatusIcon(
                status: status,
                isOptimistic: isOptimistic
            )
            
            if let onRetry = onRetry, status == .failed {
                Button(action: onRetry) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Optimistic sending message
        OptimisticMessageRowView(
            message: Message(
                id: "1",
                chatID: "chat1",
                senderID: "user1",
                text: "This is an optimistic message being sent...",
                timestamp: Date(),
                status: .sending,
                isOptimistic: true
            ),
            previousMessage: nil,
            viewModel: ChatViewModel(currentUserID: "user1")
        )
        
        // Optimistic failed message with retry
        OptimisticMessageRowView(
            message: Message(
                id: "2",
                chatID: "chat1",
                senderID: "user1",
                text: "This message failed to send",
                timestamp: Date(),
                status: .failed,
                isOptimistic: true
            ),
            previousMessage: nil,
            viewModel: ChatViewModel(currentUserID: "user1"),
            onRetry: {
            }
        )
        
        // Regular message
        OptimisticMessageRowView(
            message: Message(
                id: "3",
                chatID: "chat1",
                senderID: "user2",
                text: "This is a regular received message",
                timestamp: Date(),
                status: .delivered,
                senderName: "John Doe"
            ),
            previousMessage: nil,
            viewModel: ChatViewModel(currentUserID: "user1")
        )
    }
    .padding()
}
