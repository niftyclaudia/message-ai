//
//  NotificationService.swift
//  MessageAI
//
//  Core notification management service for push notifications
//

import Foundation
import UserNotifications
import FirebaseMessaging
import FirebaseFirestore

/// Service for managing push notifications and device tokens
/// - Note: Handles permission requests, token registration, and notification processing
@MainActor
class NotificationService: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    /// Firestore database reference
    private let db = Firestore.firestore()
    
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
            print("❌ Failed to request notification permission: \(error)")
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
            print("❌ Failed to remove FCM token: \(error)")
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
    /// - Parameter response: UNNotificationResponse object
    /// - Returns: ChatID to navigate to, or nil if invalid
    func handleNotificationTap(_ response: UNNotificationResponse) -> String? {
        let userInfo = response.notification.request.content.userInfo
        return parseNotificationPayload(userInfo)?.chatID
    }
    
    /// Parse notification payload into structured data
    /// - Parameter userInfo: Notification dictionary
    /// - Returns: NotificationPayload if valid, nil otherwise
    func parseNotificationPayload(_ userInfo: [AnyHashable: Any]) -> NotificationPayload? {
        return NotificationPayload(userInfo: userInfo)
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
            print("❌ Failed to store FCM token: \(error)")
            throw NotificationError.firestoreUpdateFailed
        }
    }
}
