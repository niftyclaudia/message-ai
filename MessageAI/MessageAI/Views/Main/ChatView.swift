//
//  ChatView.swift
//  MessageAI
//
//  Main chat view screen for message display
//

import SwiftUI

/// Main chat view screen that displays messages in a conversation
/// - Note: Handles scrolling, loading states, and real-time updates
struct ChatView: View {
    
    // MARK: - Properties
    
    let chat: Chat
    let otherUser: User?
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    
    
    // MARK: - Initialization
    
    init(chat: Chat, currentUserID: String, otherUser: User? = nil) {
        self.chat = chat
        self.otherUser = otherUser
        self._viewModel = StateObject(wrappedValue: ChatViewModel(currentUserID: currentUserID))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Navigation header
            navigationHeader
            
            // Messages area
            messagesArea
            
            // Offline indicator
            OfflineIndicatorView(
                isOffline: viewModel.isOffline,
                queuedMessageCount: viewModel.queuedMessageCount,
                connectionType: viewModel.connectionType,
                onRetry: {
                    viewModel.syncQueuedMessages()
                }
            )
            
            // Optimistic update indicator
            if viewModel.isOptimisticUpdate && !viewModel.optimisticMessages.isEmpty {
                OptimisticUpdateSummary(
                    optimisticService: viewModel.optimisticService,
                    chatID: chat.id
                )
                .padding(.horizontal)
            }
            
            // Message input
            MessageInputView(
                messageText: $messageText,
                isSending: $viewModel.isSending,
                isOffline: $viewModel.isOffline,
                onSend: {
                    viewModel.sendMessage(text: messageText)
                    messageText = ""
                }
            )
            
        }
        .navigationBarHidden(true)
        .onTapGesture {
            // Dismiss keyboard when tapping outside text field
        }
        .onAppear {
            viewModel.chat = chat
            Task {
                await viewModel.loadMessages(chatID: chat.id)
                // Reset unread count when user opens chat
                print("🔄 [CHAT VIEW] About to reset unread count for chat \(chat.id)")
                await viewModel.resetUnreadCount(chatID: chat.id, userID: viewModel.currentUserID)
                viewModel.observeMessagesRealTime(chatID: chat.id)
                
                // Mark all messages in chat as read when opening (PR-12)
                viewModel.markChatAsRead()
                
                // Set up group member presence for group chats
                if chat.isGroupChat {
                    viewModel.setupGroupMemberPresence(chat: chat)
                }
            }
        }
        .onDisappear {
            viewModel.stopObserving()
            viewModel.stopGroupMemberPresence()
        }
    }
    
    // MARK: - Navigation Header
    
    private var navigationHeader: some View {
        HStack {
            Button(action: { 
                dismiss() 
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(chatTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if chat.isGroupChat {
                    Text("\(chat.members.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: { 
                // TODO: Implement info action
            }) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Messages Area
    
    private var messagesArea: some View {
        Group {
            if viewModel.isLoading {
                loadingState
            } else if viewModel.messages.isEmpty {
                emptyState
            } else if let errorMessage = viewModel.errorMessage {
                errorState(errorMessage)
            } else {
                messagesList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Messages List
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(viewModel.allMessages.enumerated()), id: \.element.id) { index, message in
                        let previousMessage = index > 0 ? viewModel.allMessages[index - 1] : nil
                        
                        // Use optimistic message row for optimistic messages
                        if message.isOptimistic {
                            OptimisticMessageRowView(
                                message: message,
                                previousMessage: previousMessage,
                                viewModel: viewModel,
                                onRetry: {
                                    viewModel.retryMessage(messageID: message.id)
                                }
                            )
                            .onAppear {
                                // Mark message as read when it appears
                                if !viewModel.isMessageFromCurrentUser(message: message) {
                                    viewModel.markMessageAsRead(messageID: message.id)
                                }
                            }
                        } else {
                            MessageRowView(
                                message: message,
                                previousMessage: previousMessage,
                                viewModel: viewModel
                            )
                            .onAppear {
                                // Mark message as read when it appears
                                if !viewModel.isMessageFromCurrentUser(message: message) {
                                    viewModel.markMessageAsRead(messageID: message.id)
                                }
                            }
                        }
                    }
                    
                    // Bottom anchor for positioning
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onAppear {
                    // Scroll to bottom immediately when messages first appear
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
                .onChange(of: viewModel.allMessages.count) { _ in
                    // Scroll to bottom when new messages arrive
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        // Dismiss keyboard when tapping on messages
                    }
            )
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading messages...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No messages yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Start the conversation by sending a message")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Error State
    
    private func errorState(_ errorMessage: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Unable to load messages")
                .font(.headline)
                .foregroundColor(.primary)
            
            // Show user-friendly error message
            if errorMessage.contains("permissions") {
                VStack(spacing: 8) {
                    Text("Permission Error")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Please make sure you're signed in and have access to this chat.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry") {
                Task {
                    await viewModel.loadMessages(chatID: chat.id)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Helper Properties
    
    private var chatTitle: String {
        if chat.isGroupChat {
            return chat.groupName ?? "Group Chat"
        } else {
            // For 1-on-1 chats, show the other user's name
            return otherUser?.displayName ?? "Chat"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        ChatView(
            chat: Chat(
                id: "chat1",
                members: ["user1", "user2"],
                lastMessage: "Hello there!",
                lastMessageTimestamp: Date(),
                lastMessageSenderID: "user2",
                isGroupChat: false,
                createdAt: Date(),
                createdBy: "user1"
            ),
            currentUserID: "user1"
        )
    }
}
