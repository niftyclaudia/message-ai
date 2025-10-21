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
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    
    // MARK: - Mock Testing Properties
    @State private var showMockPanel = false
    @State private var mockMessages: [Message] = []
    @State private var mockConnectionStatus = "Connected"
    @State private var mockMessageCount = 0
    
    // MARK: - Initialization
    
    init(chat: Chat, currentUserID: String) {
        self.chat = chat
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
                onRetry: {
                    viewModel.syncQueuedMessages()
                }
            )
            
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
            .onTapGesture {
                // This helps ensure the text field can be tapped
            }
            
            // Mock Testing Panel
            if showMockPanel {
                mockTestingPanel
            }
            
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.chat = chat
            Task {
                await viewModel.loadMessages(chatID: chat.id)
                viewModel.observeMessagesRealTime(chatID: chat.id)
            }
        }
        .onDisappear {
            viewModel.stopObserving()
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
            
            Button(action: {}) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            // Mock Testing Button
            Button(action: { showMockPanel.toggle() }) {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.title2)
                    .foregroundColor(.orange)
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
    }
    
    // MARK: - Messages List
    
    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                    let previousMessage = index > 0 ? viewModel.messages[index - 1] : nil
                    
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
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
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
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
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
    
    // MARK: - Mock Testing Panel
    
    private var mockTestingPanel: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🧪 Mock Testing Panel")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Button("Close") {
                    showMockPanel = false
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Connection Status
            HStack {
                Text("Connection:")
                Text(mockConnectionStatus)
                    .foregroundColor(mockConnectionStatus == "Connected" ? .green : .red)
                Spacer()
            }
            .font(.caption)
            
            // Mock Message Controls
            VStack(spacing: 8) {
                HStack {
                    Button("📤 Send Mock Message") {
                        addMockMessage(isFromCurrentUser: true)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Button("📥 Receive Mock Message") {
                        addMockMessage(isFromCurrentUser: false)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                
                HStack {
                    Button("🔄 Simulate Real-time") {
                        simulateRealTimeUpdate()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Button("📱 Simulate Offline") {
                        simulateOfflineMode()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                
                HStack {
                    Button("❌ Simulate Send Failure") {
                        simulateSendFailure()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    
                    Button("🧹 Clear Mock Data") {
                        clearMockData()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
                
                // New PR-6 Real-time Messaging Tests
                VStack(spacing: 8) {
                    Text("🚀 PR-6 Real-time Tests")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Button("📤 Test Send Message") {
                            testRealMessageSend()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("📥 Test Receive Message") {
                            testRealMessageReceive()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                    
                    HStack {
                        Button("🔄 Test Status Updates") {
                            testStatusUpdates()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                        
                        Button("📱 Test Offline Queue") {
                            testOfflineQueue()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }
            }
            
            // Mock Message Status
            if !mockMessages.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mock Messages: \(mockMessages.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(mockMessages.prefix(3)) { message in
                        HStack {
                            Text("• \(message.text)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(message.status.rawValue)
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Mock Testing Functions
    
    private func addMockMessage(isFromCurrentUser: Bool) {
        mockMessageCount += 1
        let message = Message(
            id: "mock_\(mockMessageCount)",
            chatID: chat.id,
            senderID: isFromCurrentUser ? viewModel.currentUserID : "other_user",
            text: isFromCurrentUser ? "Mock sent message \(mockMessageCount)" : "Mock received message \(mockMessageCount)",
            timestamp: Date(),
            readBy: isFromCurrentUser ? [viewModel.currentUserID] : [],
            status: isFromCurrentUser ? .sending : .delivered,
            senderName: isFromCurrentUser ? nil : "Other User",
            isOffline: false,
            retryCount: 0
        )
        
        mockMessages.append(message)
        
        // Add to viewModel for display
        viewModel.messages.append(message)
        
        // Simulate status update after delay
        if isFromCurrentUser {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let index = viewModel.messages.firstIndex(where: { $0.id == message.id }) {
                    viewModel.messages[index].status = .sent
                }
            }
        }
    }
    
    private func simulateRealTimeUpdate() {
        // Simulate receiving a message from another user
        addMockMessage(isFromCurrentUser: false)
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // This would trigger the real-time listener in the actual implementation
        }
    }
    
    private func simulateOfflineMode() {
        mockConnectionStatus = "Offline"
        // In real implementation, this would disable sending and show offline indicator
    }
    
    private func simulateSendFailure() {
        mockMessageCount += 1
        let message = Message(
            id: "mock_failed_\(mockMessageCount)",
            chatID: chat.id,
            senderID: viewModel.currentUserID,
            text: "This message failed to send",
            timestamp: Date(),
            readBy: [viewModel.currentUserID],
            status: .failed,
            senderName: nil,
            isOffline: false,
            retryCount: 1
        )
        
        mockMessages.append(message)
        viewModel.messages.append(message)
    }
    
    private func clearMockData() {
        mockMessages.removeAll()
        mockMessageCount = 0
        mockConnectionStatus = "Connected"
        // Clear mock messages from viewModel
        viewModel.messages.removeAll { message in
            message.id.hasPrefix("mock_")
        }
    }
    
    // MARK: - PR-6 Real-time Messaging Test Functions
    
    private func testRealMessageSend() {
        // Test the actual message sending functionality
        let testMessage = "Test real-time send: \(Date().timeIntervalSince1970)"
        viewModel.sendMessage(text: testMessage)
    }
    
    private func testRealMessageReceive() {
        // Simulate receiving a real-time message
        let testMessage = Message(
            id: "realtime_\(Date().timeIntervalSince1970)",
            chatID: chat.id,
            senderID: "other_user",
            text: "Real-time test message received!",
            timestamp: Date(),
            readBy: [],
            status: .delivered,
            senderName: "Test User",
            isOffline: false,
            retryCount: 0
        )
        
        viewModel.messages.append(testMessage)
    }
    
    private func testStatusUpdates() {
        // Test message status updates
        if let lastMessage = viewModel.messages.last {
            // Simulate status progression: sending -> sent -> delivered
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let index = self.viewModel.messages.firstIndex(where: { $0.id == lastMessage.id }) {
                    self.viewModel.messages[index].status = .sent
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let index = self.viewModel.messages.firstIndex(where: { $0.id == lastMessage.id }) {
                    self.viewModel.messages[index].status = .delivered
                }
            }
        }
    }
    
    private func testOfflineQueue() {
        // Test offline message queuing
        viewModel.isOffline = true
        let testMessage = "Offline test message: \(Date().timeIntervalSince1970)"
        viewModel.sendMessage(text: testMessage)
        
        // Show queued message count
        viewModel.updateQueuedMessageCount()
    }
    
    // MARK: - Helper Properties
    
    private var chatTitle: String {
        if chat.isGroupChat {
            return chat.groupName ?? "Group Chat"
        } else {
            // For 1-on-1 chats, we'd need to get the other user's name
            // This is a simplified implementation
            return "Chat"
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
                createdAt: Date()
            ),
            currentUserID: "user1"
        )
    }
}
