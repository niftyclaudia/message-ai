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
    
    @State private var showLogoutAlert: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            // Placeholder for Chat List (PR #4)
            NavigationStack {
                EmptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    message: "Chat list coming soon"
                )
                .navigationTitle("Chats")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showLogoutAlert = true
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
                .alert("Sign Out", isPresented: $showLogoutAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Sign Out", role: .destructive) {
                        handleLogout()
                    }
                } message: {
                    Text("Are you sure you want to sign out?")
                }
            }
            .tabItem {
                Label("Chats", systemImage: "bubble.left.and.bubble.right")
            }
            
            // Contacts tab (PR #3)
            ContactListView()
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
    }
    
    // MARK: - Private Methods
    
    /// Handles user logout
    private func handleLogout() {
        do {
            try authService.signOut()
        } catch {
            print("❌ Logout error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
}

