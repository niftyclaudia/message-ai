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
    
    @EnvironmentObject private var viewModel: ConversationListViewModel
    @StateObject private var focusModeService = FocusModeService()
    let currentUserID: String
    
    // MARK: - Navigation State
    
    /// Chat ID to navigate to from notification tap
    @State private var selectedChatID: String?
    @State private var navigateToNotification = false
    
    // MARK: - Lifecycle State
    
    /// Tracks if the view has been initialized to prevent multiple setups
    @State private var hasInitialized = false
    
    // MARK: - Initialization
    
    init(currentUserID: String, aiClassificationService: AIClassificationService) {
        self.currentUserID = currentUserID
        // aiClassificationService is now accessed via viewModel
    }
    
    
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
            .onAppear {
                // View model is initialized by MainTabView
                // Just check for pending notification navigation
                checkForNotificationNavigation()
            }
            .onDisappear {
                // Only clean up if we're actually leaving the view (not just tab switching)
                // In TabView, onDisappear can be called when switching tabs
                // We'll let the deinit handle cleanup instead
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
            .sheet(isPresented: $focusModeService.shouldShowSummary) {
                if let sessionID = focusModeService.currentSessionID {
                    FocusSummaryView(sessionID: sessionID)
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
                        .onAppear {
                            print("🔍 [CONVERSATION LIST] Rendering Focus Mode sections")
                        }
                } else {
                    // Single section layout when Focus Mode is inactive
                    allConversationsList
                        .onAppear {
                            print("🔍 [CONVERSATION LIST] Rendering single section (Focus Mode OFF)")
                        }
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
        // Create a computed property that forces SwiftUI to observe changes
        let filtered = focusModeService.filterChats(
            viewModel.chats, 
            aiClassificationService: viewModel.aiClassificationService, 
            currentUserID: currentUserID
        )
        
        // Use the filtered results
        return createFocusModeSections(priority: filtered.priority, holding: filtered.holding)
            .onAppear {
                print("🔍 [CONVERSATION LIST] Focus Mode sections being computed - Focus Mode active: \(focusModeService.isActive)")
                print("🔍 [CONVERSATION LIST] Total chats: \(viewModel.chats.count)")
                print("🔍 [CONVERSATION LIST] Filtering result: \(filtered.priority.count) priority, \(filtered.holding.count) holding")
            }
    }
    
    @ViewBuilder
    private func createFocusModeSections(priority: [Chat], holding: [Chat]) -> some View {
        VStack(spacing: 0) {
            // Priority Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("PRIORITY")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text("(\(priority.count))")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                if priority.isEmpty {
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
                    ForEach(priority) { chat in
                        conversationRow(for: chat)
                    }
                }
            }
            
            // HOLDING Section - Always show when Focus Mode is active
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("HOLDING")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    Text("(\(holding.count))")
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
        .background(Color(.systemBackground))
        .id(viewModel.aiClassificationService.classificationStatus.count) // Force SwiftUI to recreate when classification changes
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
                }(),
                classificationStatus: getLastMessageClassificationStatus(for: chat),
                onFeedbackSubmitted: { priority, reason in
                    Task {
                        await viewModel.submitClassificationFeedback(
                            messageId: chat.lastMessageID ?? "",
                            suggestedPriority: priority,
                            reason: reason
                        )
                    }
                },
                onRetryRequested: {
                    Task {
                        await viewModel.retryClassification(messageId: chat.lastMessageID ?? "")
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .id("\(chat.id)-\(getLastMessageClassificationStatus(for: chat))")
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteChat(chatID: chat.id)
                }
            }
        }
    }
    
    /// Gets the classification status for the last message in a chat
    private func getLastMessageClassificationStatus(for chat: Chat) -> ClassificationStatus {
        guard let lastMessageID = chat.lastMessageID else {
            return .pending
        }
        return viewModel.getClassificationStatus(messageId: lastMessageID)
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
    ConversationListView(currentUserID: "user1", aiClassificationService: AIClassificationService())
        .onAppear {
            // Mock data for preview
        }
}

#Preview("Empty State") {
    ConversationListView(currentUserID: "user1", aiClassificationService: AIClassificationService())
        .onAppear {
            // Empty state will show by default
        }
}

#Preview("Loading State") {
    ConversationListView(currentUserID: "user1", aiClassificationService: AIClassificationService())
        .onAppear {
            // Loading state would be shown during initial load
        }
}
