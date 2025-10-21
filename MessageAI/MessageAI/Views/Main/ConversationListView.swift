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
                    conversationList
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
                    ConversationRowView(
                        chat: chat,
                        otherUser: viewModel.getOtherUser(chat: chat),
                        currentUserID: currentUserID,
                        timestamp: viewModel.formatTimestamp(date: chat.lastMessageTimestamp)
                    )
                    .onTapGesture {
                        // TODO: Navigate to ChatView (placeholder for PR #5)
                        print("Tapped chat: \(chat.id)")
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
        EmptyStateView(
            icon: "bubble.left.and.bubble.right",
            message: "No conversations yet"
        )
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
