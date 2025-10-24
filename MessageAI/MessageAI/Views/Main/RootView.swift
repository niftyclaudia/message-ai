//
//  RootView.swift
//  MessageAI
//
//  Root navigation router based on authentication state
//

import SwiftUI

/// Root view that routes between authentication and main app based on auth state
/// - Note: Observes AuthService.isAuthenticated for automatic navigation
struct RootView: View {
    
    // MARK: - Environment Objects
    
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State
    
    @State private var isInitializing: Bool = true
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isInitializing {
                // Brief loading screen during Firebase initialization
                LoadingView(message: "Loading...")
            } else {
                if authService.isAuthenticated {
                    // Authenticated - show main app
                    MainTabView()
                        .environmentObject(authService)
                        .transition(.opacity)
                } else {
                    // Not authenticated - show login
                    LoginView()
                        .environmentObject(authService)
                        .transition(.opacity)
                }
            }
        }
        .animation(AppTheme.springAnimation, value: authService.isAuthenticated)
        .onAppear {
            // Give Firebase a moment to check auth state (reduced delay for faster startup)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInitializing = false
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthService())
}

