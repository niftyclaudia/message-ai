//
//  NotificationService.swift
//  MessageAI
//
//  Core notification management service for push notifications
//  Enhanced for PR #4: Mobile Lifecycle Management (deep-linking support)
//

import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

/// Service for managing push notifications and device tokens
/// - Note: Handles permission requests, token registration, and notification processing
/// - PR #4: Added deep-linking support with messageID
@MainActor
class NotificationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current deep link to navigate to (set by notification tap)
    @Published var activeDeepLink: DeepLink?
    
    // MARK: - Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
    /// Deep linking service for navigation
    private let deepLinkingService = DeepLinkingService()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from user
    /// - Returns: True if granted, false if denied
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            return false
        }
    }
    
    /// Check current notification permission status
    /// - Returns: UNAuthorizationStatus
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Token Management
    
    /// Register device for push notifications and store token in Firestore
    /// - Parameter userID: Current user's ID
    /// - Throws: NotificationError if registration fails
    func registerForNotifications(userID: String) async throws {
        // Get FCM token
        guard let token = try? await Messaging.messaging().token() else {
            throw NotificationError.tokenRegistrationFailed
        }
        
        // Store token in Firestore
        try await storeTokenInFirestore(userID: userID, token: token)
    }
    
    /// Refresh FCM token and update Firestore
    /// - Parameter userID: Current user's ID
    /// - Throws: NotificationError if update fails
    func updateToken(userID: String) async throws {
        // Get new FCM token
        guard let token = try? await Messaging.messaging().token() else {
            throw NotificationError.tokenRegistrationFailed
        }
        
        // Update Firestore with new token
        try await storeTokenInFirestore(userID: userID, token: token)
    }
    
    /// Remove FCM token from Firestore on logout
    /// - Parameter userID: User ID to remove token for
    /// - Throws: NotificationError if deletion fails
    func removeToken(userID: String) async throws {
        do {
            try await db.collection("users").document(userID).updateData([
                "fcmToken": FieldValue.delete(),
                "lastTokenUpdate": FieldValue.delete()
            ])
        } catch {
            throw NotificationError.firestoreUpdateFailed
        }
    }
    
    // MARK: - Notification Handling
    
    /// Handle notification received while app in foreground
    /// - Parameter notification: UNNotification object
    /// - Returns: Presentation options (banner, sound, badge)
    func handleForegroundNotification(_ notification: UNNotification) -> UNNotificationPresentationOptions {
        return [.banner, .sound]
    }
    
    /// Handle notification tap (background or terminated)
    /// - PR #4: Enhanced to create and publish deep link for navigation
    /// - Parameter response: UNNotificationResponse object
    /// - Returns: ChatID to navigate to, or nil if invalid
    func handleNotificationTap(_ response: UNNotificationResponse) -> String? {
        let userInfo = response.notification.request.content.userInfo
        
        // Start tracking navigation time for < 400ms target
        PerformanceMonitor.shared.startNavigation(from: "notification_tap")
        
        // Parse payload and create deep link
        if let payload = parseNotificationPayload(userInfo) {
            let deepLink = deepLinkingService.createDeepLink(from: payload)
            
            // Set active deep link for navigation
            activeDeepLink = deepLink
            
            return payload.chatID
        }
        
        return nil
    }
    
    /// Parse notification payload into structured data
    /// - Parameter userInfo: Notification dictionary
    /// - Returns: NotificationPayload if valid, nil otherwise
    func parseNotificationPayload(_ userInfo: [AnyHashable: Any]) -> NotificationPayload? {
        return NotificationPayload(userInfo: userInfo)
    }
    
    /// Clear the active deep link after navigation completes
    func clearDeepLink() {
        activeDeepLink = nil
    }
    
    /// Get the deep linking service for advanced operations
    /// - Returns: DeepLinkingService instance
    func getDeepLinkingService() -> DeepLinkingService {
        return deepLinkingService
    }
    
    // MARK: - Private Methods
    
    /// Store FCM token in Firestore
    /// - Parameters:
    ///   - userID: User ID
    ///   - token: FCM token to store
    /// - Throws: NotificationError if storage fails
    private func storeTokenInFirestore(userID: String, token: String) async throws {
        do {
            try await db.collection("users").document(userID).updateData([
                "fcmToken": token,
                "lastTokenUpdate": FieldValue.serverTimestamp()
            ])
        } catch {
            throw NotificationError.firestoreUpdateFailed
        }
    }
}
