//
//  ConversationListView.swift
//  MessageAI
//
//  Main conversation list view with real-time updates
//

import SwiftUI

/// Main conversation list view showing all user's chats
/// - Note: Handles loading, empty, error states and real-time updates
struct ConversationListView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = ConversationListViewModel()
    let currentUserID: String
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.backgroundColor
                    .ignoresSafeArea()
                
                // Content based on state
                if viewModel.isLoading {
                    LoadingView(message: "Loading conversations...")
                } else if viewModel.chats.isEmpty {
                    emptyStateView
                } else {
                    VStack {
                        // Test button for PR-5 (always visible)
                        Button("🧪 Test Chat View") {
                            // Create a test chat and navigate to it
                            let testChat = Chat(
                                id: "test-chat-pr5",
                                members: [currentUserID, "user-2"],
                                lastMessage: "Test message",
                                lastMessageTimestamp: Date(),
                                lastMessageSenderID: "user-2",
                                isGroupChat: false,
                                createdAt: Date()
                            )
                            
                            // Add to view model
                            viewModel.chats = [testChat]
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                        
                        conversationList
                    }
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        // TODO: Implement logout functionality
                        print("Logout tapped")
                    }
                    .foregroundColor(AppTheme.primaryColor)
                }
            }
        }
        .task {
            // Add test data for PR-5 testing
            await addTestData()
            await viewModel.loadChats(userID: currentUserID)
            viewModel.observeChatsRealTime(userID: currentUserID)
        }
        .onDisappear {
            viewModel.stopObserving()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Private Views
    
    /// List of conversations using LazyVStack for performance
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.chats) { chat in
                    NavigationLink(destination: ChatView(chat: chat, currentUserID: currentUserID)) {
                        ConversationRowView(
                            chat: chat,
                            otherUser: viewModel.getOtherUser(chat: chat),
                            currentUserID: currentUserID,
                            timestamp: viewModel.formatTimestamp(date: chat.lastMessageTimestamp)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Divider between rows
                    if chat.id != viewModel.chats.last?.id {
                        Divider()
                            .padding(.leading, 68) // Align with text
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    /// Empty state when no conversations exist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                icon: "bubble.left.and.bubble.right",
                message: "No conversations yet"
            )
            
            // Test button for PR-5
            Button("Test Chat View") {
                // Create a test chat and navigate to it
                let testChat = Chat(
                    id: "test-chat-pr5",
                    members: [currentUserID, "user-2"],
                    lastMessage: "Test message",
                    lastMessageTimestamp: Date(),
                    lastMessageSenderID: "user-2",
                    isGroupChat: false,
                    createdAt: Date()
                )
                
                // Add to view model
                viewModel.chats = [testChat]
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
    
    // MARK: - Test Data Methods
    
    /// Adds test conversations for PR-5 testing
    private func addTestData() async {
        // Create test chats with mock data
        let testChats = [
            Chat(
                id: "test-chat-1",
                members: [currentUserID, "user-2"],
                lastMessage: "Hey! How are you doing?",
                lastMessageTimestamp: Date().addingTimeInterval(-300), // 5 minutes ago
                lastMessageSenderID: "user-2",
                isGroupChat: false,
                createdAt: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            Chat(
                id: "test-chat-2", 
                members: [currentUserID, "user-3"],
                lastMessage: "Thanks for the help earlier!",
                lastMessageTimestamp: Date().addingTimeInterval(-1800), // 30 minutes ago
                lastMessageSenderID: currentUserID,
                isGroupChat: false,
                createdAt: Date().addingTimeInterval(-7200) // 2 hours ago
            ),
            Chat(
                id: "test-chat-3",
                members: [currentUserID, "user-4", "user-5"],
                lastMessage: "Meeting at 3pm today",
                lastMessageTimestamp: Date().addingTimeInterval(-600), // 10 minutes ago
                lastMessageSenderID: "user-4",
                isGroupChat: true,
                groupName: "Team Chat",
                createdAt: Date().addingTimeInterval(-10800) // 3 hours ago
            )
        ]
        
        // Add test chats to the view model
        viewModel.chats = testChats
    }
    
    /// Navigates to ChatView for the selected chat
    private func navigateToChat(chat: Chat) {
        // For PR-5 testing, we'll use a simple navigation approach
        print("Navigating to chat: \(chat.id)")
        print("Chat details: \(chat.lastMessage)")
        
        // In a real app, this would use NavigationLink or programmatic navigation
        // For now, we'll just print the navigation intent
    }
}

// MARK: - Preview

#Preview("With Conversations") {
    ConversationListView(currentUserID: "user1")
        .onAppear {
            // Mock data for preview
        }
}

#Preview("Empty State") {
    ConversationListView(currentUserID: "user1")
        .onAppear {
            // Empty state will show by default
        }
}

#Preview("Loading State") {
    ConversationListView(currentUserID: "user1")
        .onAppear {
            // Loading state would be shown during initial load
        }
}
