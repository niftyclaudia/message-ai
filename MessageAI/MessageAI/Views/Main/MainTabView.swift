//
//  MainTabView.swift
//  MessageAI
//
//  Main tab-based container for authenticated users
//

import SwiftUI

/// Main tab view container for authenticated users
/// - Note: Placeholder for future feature tabs (Chat List - PR #4+)
struct MainTabView: View {
    
    // MARK: - Environment Objects
    
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State
    
    @State private var showingCreateChat: Bool = false
    @State private var createdChat: Chat?
    @State private var navigateToChat: Bool = false
    @StateObject private var conversationListViewModel = ConversationListViewModel()
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            // Chat List (PR #4)
            NavigationStack {
                ConversationListView(currentUserID: authService.currentUser?.uid ?? "", aiClassificationService: conversationListViewModel.aiClassificationService)
                    .environmentObject(conversationListViewModel)
                    .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            print("🔄 Plus button tapped - showingCreateChat: \(showingCreateChat)")
                            showingCreateChat = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .foregroundColor(AppTheme.primaryColor)
                    }
                }
                .navigationDestination(isPresented: $navigateToChat) {
                    if let chat = createdChat {
                        ChatView(chat: chat, currentUserID: authService.currentUser?.uid ?? "", otherUser: nil)
                            .onAppear {
                                print("🔄 MainTabView: Navigating to ChatView with chat: \(chat.id)")
                            }
                    } else {
                        EmptyView()
                            .onAppear {
                                print("❌ MainTabView: No chat available for navigation")
                            }
                    }
                }
            }
            .tabItem {
                Label("Chats", systemImage: "bubble.left.and.bubble.right")
            }
            .badge(conversationListViewModel.totalUnreadCount)
            
            // Contacts tab (PR #3)
            ContactListView()
                .environmentObject(authService)
                .tabItem {
                    Label("Contacts", systemImage: "person.2")
                }
            
            // Profile tab (PR #3)
            ProfileView()
                .environmentObject(authService)
                .tabItem {
                    Label("Profile", systemImage: "person.circle")
                }
            
        }
        .onAppear {
            // Initialize the conversation list view model
            Task {
                await conversationListViewModel.initialize(userID: authService.currentUser?.uid ?? "")
            }
        }
        .sheet(isPresented: $showingCreateChat) {
            CreateNewChatView { chat in
                // Handle chat creation completion
                print("🔄 MainTabView: Chat creation callback received - chat: \(chat.id)")
                createdChat = chat
                navigateToChat = true
                print("🔄 MainTabView: Navigation state set - navigateToChat: \(navigateToChat)")
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}

