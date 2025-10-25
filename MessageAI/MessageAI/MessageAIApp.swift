//
//  MessageAIApp.swift
//  MessageAI
//
//  Created by Claudia Lucia Alban on 10/20/25.
//

import SwiftUI
import FirebaseCore

// MARK: - Notification Delegate Class (DISABLED)
// Notification functionality has been temporarily disabled to prevent misleading errors
// TODO: Re-enable when APNS setup is complete

@main
struct MessageAIApp: App {
    
    // MARK: - State Objects
    
    /// Authentication service - single source of truth for auth state
    @StateObject private var authService = AuthService()
    
    /// App lifecycle manager - handles presence status based on app state
    @StateObject private var lifecycleManager = AppLifecycleManager()
    
    // MARK: - Notification Service (DISABLED)
    // Notification functionality has been temporarily disabled to prevent misleading errors
    // TODO: Re-enable when APNS setup is complete
    
    // MARK: - Initialization
    
    init() {
        // Configure Firebase on app launch
        do {
            try FirebaseService.shared.configure()
        } catch {
            print("❌ Firebase configuration error: \(error.localizedDescription)")
            // In production, might want to show user-facing error
            // For now, app can still launch but Firebase features won't work
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                // Notification service temporarily disabled
                // .environmentObject(notificationService)
                // .onAppear {
                //     configureNotificationDelegates()
                // }
        }
    }
    
    // MARK: - Notification Configuration (DISABLED)
    
    /// Configure notification delegates and register for remote notifications
    /// DISABLED: Notification functionality temporarily removed to prevent misleading errors
    /// TODO: Re-enable when APNS setup is complete
    private func configureNotificationDelegates() {
        // Notification setup has been disabled
        // TODO: Re-implement when APNS is properly configured
    }
}
