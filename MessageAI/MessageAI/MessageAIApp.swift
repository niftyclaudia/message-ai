//
//  MessageAIApp.swift
//  MessageAI
//
//  Created by Claudia Lucia Alban on 10/20/25.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// MARK: - Notification Delegate Class

/// Handles notification delegates since structs cannot conform to class protocols
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    private let notificationService: NotificationService
    private let authService: AuthService
    
    init(notificationService: NotificationService, authService: AuthService) {
        self.notificationService = notificationService
        self.authService = authService
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Handle notification received while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Task { @MainActor in
            let options = notificationService.handleForegroundNotification(notification)
            completionHandler(options)
        }
    }
    
    /// Handle notification tap (background or terminated)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task { @MainActor in
            if let chatID = notificationService.handleNotificationTap(response) {
                // Navigate to conversation with chatID
                navigateToChat(chatID: chatID)
            }
            completionHandler()
        }
    }
    
    // MARK: - MessagingDelegate
    
    /// Handle FCM token refresh
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Update token in Firestore if user is authenticated
        if let userID = authService.currentUser?.uid {
            Task {
                do {
                    try await notificationService.updateToken(userID: userID)
                } catch {
                    // Token update failed - will retry on next launch
                }
            }
        }
    }
    
    // MARK: - Navigation Helpers
    
    /// Navigate to specific chat from notification
    /// - Parameter chatID: Chat ID to navigate to
    private func navigateToChat(chatID: String) {
        // TODO: Implement navigation to specific chat
        // This would require passing the chatID to the root view
        // The actual navigation will be handled by the ConversationListView
    }
}

@main
struct MessageAIApp: App {
    
    // MARK: - State Objects
    
    /// Authentication service - single source of truth for auth state
    @StateObject private var authService = AuthService()
    
    /// App lifecycle manager - handles presence status based on app state
    @StateObject private var lifecycleManager = AppLifecycleManager()
    
    /// Notification service - handles push notifications and device tokens
    @StateObject private var notificationService = NotificationService()
    
    /// Notification delegate for handling push notifications
    @State private var notificationDelegate: NotificationDelegate?
    
    // MARK: - Initialization
    
    init() {
        // Configure Firebase on app launch
        do {
            try FirebaseService.shared.configure()
        } catch {
            // Firebase configuration failed - app features won't work
            // Consider implementing proper error handling/user notification
        }
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(notificationService)
                .environmentObject(lifecycleManager)
                .onAppear {
                    configureNotificationDelegates()
                }
        }
    }
    
    // MARK: - Notification Configuration
    
    /// Configure notification delegates and register for remote notifications
    private func configureNotificationDelegates() {
        // Create notification delegate
        notificationDelegate = NotificationDelegate(
            notificationService: notificationService,
            authService: authService
        )
        
        // Set notification center delegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        // Set FCM messaging delegate
        Messaging.messaging().delegate = notificationDelegate
        
        // Register for remote notifications
        UIApplication.shared.registerForRemoteNotifications()
    }
}
