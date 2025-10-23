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
    
    // MARK: - Services
    
    private let presenceService = PresenceService()
    
    // MARK: - State
    
    @State private var showingCreateChat: Bool = false
    @State private var createdChat: Chat?
    @State private var navigateToChat: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            // Chat List (PR #4)
            NavigationStack {
                ConversationListView(currentUserID: authService.currentUser?.uid ?? "")
                    .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
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
                            }
                    } else {
                        EmptyView()
                            .onAppear {
                            }
                    }
                }
            }
            .tabItem {
                Label("Chats", systemImage: "bubble.left.and.bubble.right")
            }
            
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
        .sheet(isPresented: $showingCreateChat) {
            CreateNewChatView { chat in
                // Handle chat creation completion
                createdChat = chat
                navigateToChat = true
            }
        }
        .task {
            // Set current user online when main view appears
            if let userID = authService.currentUser?.uid {
                try? await presenceService.setUserOnline(userID: userID)
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}

