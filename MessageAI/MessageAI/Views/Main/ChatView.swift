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
    @StateObject private var performanceViewModel: PerformanceViewModel
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @State private var showChatInfo: Bool = false
    @State private var showMemberList: Bool = false // PR-3: Show group member list
    @State private var currentUserName: String = ""
    @State private var listWindowing: ListWindowing<Message>?
    
    
    // MARK: - Initialization
    
    init(chat: Chat, currentUserID: String, otherUser: User? = nil) {
        self.chat = chat
        self.otherUser = otherUser
        self._viewModel = StateObject(wrappedValue: ChatViewModel(currentUserID: currentUserID))
        self._performanceViewModel = StateObject(wrappedValue: PerformanceViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Navigation header
            navigationHeader
            
            // Messages area
            messagesArea
            
            // PR-2: Clean, unified connection status banner (Apple HIG compliant)
            // Only shows when NOT online - follows Apple best practices
            ConnectionStatusBanner(
                connectionState: viewModel.connectionState,
                queuedMessageCount: viewModel.queuedMessageCount,
                onRetry: {
                    viewModel.syncQueuedMessages()
                }
            )
            
            // Typing indicator (shown below status for context)
            if !viewModel.typingUsers.isEmpty {
                TypingIndicatorView(typingUsers: viewModel.typingUsers)
            }
            
            // Message input with keyboard optimization
            MessageInputView(
                messageText: $messageText,
                isSending: $viewModel.isSending,
                isOffline: $viewModel.isOffline,
                onSend: {
                    // Add haptic feedback for send action
                    performanceViewModel.addHapticFeedback(for: .send)
                    
                    viewModel.userStoppedTyping() // Clear typing indicator before sending
                    viewModel.sendMessage(text: messageText)
                    messageText = ""
                }
            )
            .keyboardOptimized(optimizer: KeyboardOptimizer())
            .onChange(of: messageText) { oldValue, newValue in
                // Trigger typing indicator when user types
                if !newValue.isEmpty && oldValue != newValue {
                    viewModel.userStartedTyping(userName: currentUserName)
                } else if newValue.isEmpty {
                    viewModel.userStoppedTyping()
                }
            }
            .onTapGesture {
                // This helps ensure the text field can be tapped
            }
            
        }
        .navigationBarHidden(true)
        .task {
            // Start performance monitoring
            performanceViewModel.startPerformanceMonitoring()
            
            // Optimize chat view for performance
            performanceViewModel.optimizeChatView(
                messageCount: viewModel.allMessages.count,
                isGroupChat: chat.isGroupChat
            )
            
            viewModel.chat = chat
            await viewModel.loadMessages(chatID: chat.id)
            viewModel.observeMessagesRealTime(chatID: chat.id)
            
            // Initialize list windowing for large message counts
            if viewModel.allMessages.count > 100 {
                listWindowing = ListWindowing<Message>()
                await initializeListWindowing()
            }
            
            // Mark all messages in chat as read when opening (PR-12)
            viewModel.markChatAsRead()
            
            // Set up presence monitoring for all chats
            viewModel.setupGroupMemberPresence(chat: chat)
            
            // Set up typing indicators
            viewModel.observeTyping(chatID: chat.id)
            
            // Fetch current user's display name
            if let userID = authService.currentUser?.uid {
                do {
                    let userService = UserService()
                    let user = try await userService.fetchUser(userID: userID)
                    currentUserName = user.displayName
                } catch {
                    // Fallback to email or default
                    currentUserName = authService.currentUser?.email ?? "User"
                }
            }
        }
        .onDisappear {
            viewModel.stopObserving()
            viewModel.stopGroupMemberPresence()
            viewModel.userStoppedTyping() // Clear typing status when leaving chat
        }
    }
    
    // MARK: - Navigation Header
    
    private var navigationHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            // PR-3: Use GroupChatHeaderView for group chats, standard header for 1-on-1
            if chat.isGroupChat {
                GroupChatHeaderView(chat: chat) {
                    showMemberList = true
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(chatTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            Button(action: { showChatInfo = true }) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
        .sheet(isPresented: $showChatInfo) {
            ChatInfoView(chat: chat, otherUser: otherUser)
        }
        .sheet(isPresented: $showMemberList) {
            // PR-3: Group member list with live presence
            GroupMemberListView(chat: chat)
        }
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
                    // Use list windowing for performance with 1000+ messages
                    if let windowing = listWindowing, viewModel.allMessages.count > 100 {
                        ForEach(Array(windowing.getCurrentWindow().enumerated()), id: \.element.id) { index, message in
                            let previousMessage = index > 0 ? windowing.getCurrentWindow()[index - 1] : nil
                            
                            messageRowView(message: message, previousMessage: previousMessage)
                                .id(message.id)
                                .onAppear {
                                    // Mark message as read when it appears
                                    if !viewModel.isMessageFromCurrentUser(message: message) {
                                        viewModel.markMessageAsRead(messageID: message.id)
                                    }
                                    
                                    // Prefetch more messages if near end
                                    if index >= windowing.getCurrentWindow().count - 10 {
                                        Task {
                                            await windowing.prefetchMessages(
                                                chatID: chat.id,
                                                currentIndex: index,
                                                messageService: MessageService()
                                            )
                                        }
                                    }
                                }
                        }
                    } else {
                        // Fallback to regular list for smaller message counts
                        ForEach(Array(viewModel.allMessages.enumerated()), id: \.element.id) { index, message in
                            let previousMessage = index > 0 ? viewModel.allMessages[index - 1] : nil
                            
                            messageRowView(message: message, previousMessage: previousMessage)
                                .id(message.id)
                                .onAppear {
                                    // Mark message as read when it appears
                                    if !viewModel.isMessageFromCurrentUser(message: message) {
                                        viewModel.markMessageAsRead(messageID: message.id)
                                    }
                                }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: viewModel.allMessages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }
        }
    }
    
    // MARK: - Message Row View Helper
    
    private func messageRowView(message: Message, previousMessage: Message?) -> some View {
        Group {
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
            } else {
                MessageRowView(
                    message: message,
                    previousMessage: previousMessage,
                    viewModel: viewModel
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Scrolls to the bottom (latest message)
    private func scrollToBottom(proxy: ScrollViewProxy) {
        guard let lastMessage = viewModel.allMessages.last else { return }
        withAnimation {
            proxy.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
    
    /// Initializes list windowing for performance optimization
    private func initializeListWindowing() async {
        guard let windowing = listWindowing else { return }
        
        do {
            let messageService = MessageService()
            // Use viewModel's message count as the source of truth
            let totalCount = viewModel.allMessages.count
            
            // Load initial window around the latest messages
            let startIndex = max(0, totalCount - 50)
            _ = try await windowing.loadWindow(
                around: totalCount - 1,
                totalCount: totalCount,
                itemLoader: { _, count in
                    // Fetch messages using the existing API with limit parameter
                    try await messageService.fetchMessages(
                        chatID: chat.id,
                        limit: count
                )
            }
        )
    } catch {
        // Silently fail - list windowing is not critical
    }
}
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        MessageListSkeletonView(count: 5)
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
