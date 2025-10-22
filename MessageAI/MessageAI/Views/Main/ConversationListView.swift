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
    
    // MARK: - Navigation State
    
    /// Chat ID to navigate to from notification tap
    @State private var selectedChatID: String?
    
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
                conversationList
            }
        }
        .task {
            // Create test data in Firestore for development
            do {
                try await testDataService.createTestChatData(currentUserID: currentUserID)
            } catch {
            }
            
            // Load chats from Firestore
            await viewModel.loadChats(userID: currentUserID)
            viewModel.observeChatsRealTime(userID: currentUserID)
            viewModel.observePresence()
        }
        .onDisappear {
            viewModel.stopObserving()
            viewModel.stopObservingPresence()
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
        .onAppear {
            // Check for pending notification navigation
            checkForNotificationNavigation()
        }
        .background(
            // Hidden navigation for notification deep linking
            NavigationLink(
                destination: notificationDestination,
                isActive: .constant(selectedChatID != nil)
            ) {
                EmptyView()
            }
        )
    }
    
    // MARK: - Private Views
    
    /// List of conversations using LazyVStack for performance
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.chats) { chat in
                    NavigationLink(destination: ChatView(chat: chat, currentUserID: currentUserID, otherUser: viewModel.getOtherUser(chat: chat))) {
                        ConversationRowView(
                            chat: chat,
                            otherUser: viewModel.getOtherUser(chat: chat),
                            currentUserID: currentUserID,
                            timestamp: viewModel.formatTimestamp(date: chat.lastMessageTimestamp),
                            presenceStatus: {
                                if let otherUser = viewModel.getOtherUser(chat: chat) {
                                    return viewModel.userPresence[otherUser.id]
                                }
                                return nil
                            }()
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Delete", role: .destructive) {
                            Task {
                                await viewModel.deleteChat(chatID: chat.id)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
        }
    }
    
    /// Empty state when no conversations exist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            EmptyStateView(
                icon: "bubble.left.and.bubble.right",
                message: "No conversations yet"
            )
        }
    }
    
    // MARK: - Notification Navigation
    
    /// Check for pending notification navigation
    func checkForNotificationNavigation() {
        // TODO: This would be called from MessageAIApp when notification is tapped
        // For now, this is a placeholder for the navigation logic
    }
    
    /// Navigation destination for notification deep linking
    var notificationDestination: some View {
        Group {
            if let chatID = selectedChatID,
               let chat = viewModel.chats.first(where: { $0.id == chatID }) {
                ChatView(
                    chat: chat,
                    currentUserID: currentUserID,
                    otherUser: viewModel.getOtherUser(chat: chat)
                )
            } else {
                // Fallback to conversation list if chat not found
                ConversationListView(currentUserID: currentUserID)
            }
        }
    }
    
    /// Navigate to specific chat from notification
    /// - Parameter chatID: Chat ID to navigate to
    func navigateToChat(chatID: String) {
        selectedChatID = chatID
    }
    
    /// Clear notification navigation
    func clearNotificationNavigation() {
        selectedChatID = nil
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
