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
    @StateObject private var testDataService = TestDataService()
    let currentUserID: String
    
    // MARK: - Body
    
    var body: some View {
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
                            createdAt: Date(),
                            createdBy: currentUserID
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
        .task {
            // Create test data in Firestore for development
            do {
                try await testDataService.createTestChatData(currentUserID: currentUserID)
            } catch {
                print("⚠️ Failed to create test data: \(error)")
            }
            
            // Load chats from Firestore
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Delete", role: .destructive) {
                            Task {
                                await viewModel.deleteChat(chatID: chat.id)
                            }
                        }
                        .tint(.red)
                    }
                    
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
                    createdAt: Date(),
                    createdBy: currentUserID
                )
                
                // Add to view model
                viewModel.chats = [testChat]
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
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
