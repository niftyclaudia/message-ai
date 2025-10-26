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
    @StateObject private var focusModeService = FocusModeService()
    let currentUserID: String
    
    // MARK: - Navigation State
    
    /// Chat ID to navigate to from notification tap
    @State private var selectedChatID: String?
    @State private var navigateToNotification = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppTheme.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with Focus Mode toggle
                    headerView
                    
                    // Content based on state
                    if viewModel.isLoading {
                        LoadingView(message: "Loading conversations...")
                    } else if viewModel.chats.isEmpty {
                        emptyStateView
                    } else {
                        conversationList
                    }
                }
            }
            .task {
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
            .navigationDestination(isPresented: $navigateToNotification) {
                if let chatID = selectedChatID,
                   let chat = viewModel.chats.first(where: { $0.id == chatID }) {
                    ChatView(
                        chat: chat,
                        currentUserID: currentUserID,
                        otherUser: viewModel.getOtherUser(chat: chat)
                    )
                }
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Header with Focus Mode toggle
    private var headerView: some View {
        HStack(spacing: 12) {
            Spacer()
            
            // Flow Mode label
            HStack(spacing: 6) {
                if focusModeService.isActive {
                    Circle()
                        .fill(Color(red: 0.2, green: 0.7, blue: 0.7))
                        .frame(width: 6, height: 6)
                }
                Text("Flow Mode")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(focusModeService.isActive ? Color(red: 0.2, green: 0.7, blue: 0.7) : .secondary)
            
            // Toggle switch
            Toggle("", isOn: Binding(
                get: { focusModeService.isActive },
                set: { _ in
                    Task {
                        await focusModeService.toggleFocusMode()
                    }
                }
            ))
            .toggleStyle(CustomToggleStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    /// List of conversations using LazyVStack for performance
    private var conversationList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                if focusModeService.isActive {
                    // Two-section layout when Focus Mode is active
                    focusModeSections
                } else {
                    // Single section layout when Focus Mode is inactive
                    allConversationsList
                }
            }
        }
    }
    
    /// All conversations in a single list (Focus Mode OFF)
    private var allConversationsList: some View {
        ForEach(viewModel.chats) { chat in
            conversationRow(for: chat)
        }
        .background(Color(.systemBackground))
    }
    
    /// Two sections for Priority and HOLDING (Focus Mode ON)
    private var focusModeSections: some View {
        let filtered = focusModeService.filterChats(viewModel.chats)
        
        return Group {
            // Priority Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("PRIORITY")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text("(\(filtered.priority.count))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                if filtered.priority.isEmpty {
                    // Empty priority state
                    VStack(spacing: 12) {
                        Text("All caught up!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("No urgent messages. Focus on you.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(filtered.priority) { chat in
                        conversationRow(for: chat)
                    }
                }
            }
            
            // HOLDING Section - Only show placeholder, no messages
            if !filtered.holding.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("HOLDING")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        Text("(\(filtered.holding.count))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    // Show placeholder for held messages (but don't show the actual messages)
                    HoldingPlaceholderView()
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    /// Individual conversation row
    private func conversationRow(for chat: Chat) -> some View {
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
    
    /// Navigate to specific chat from notification
    /// - Parameter chatID: Chat ID to navigate to
    func navigateToChat(chatID: String) {
        selectedChatID = chatID
        navigateToNotification = true
    }
    
    /// Clear notification navigation
    func clearNotificationNavigation() {
        selectedChatID = nil
        navigateToNotification = false
    }
}

// MARK: - Custom Toggle Style

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? Color(red: 0.2, green: 0.7, blue: 0.7) : Color(.systemGray4))
                    .frame(width: 50, height: 30)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .padding(3)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    configuration.isOn.toggle()
                }
            }
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
