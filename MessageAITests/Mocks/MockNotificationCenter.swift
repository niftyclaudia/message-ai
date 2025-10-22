//
//  MockNotificationCenter.swift
//  MessageAITests
//
//  Mock UNUserNotificationCenter for testing without actual notifications
//

import Foundation
import UserNotifications
@testable import MessageAI

/// Mock notification center for testing notification behavior
/// - Note: Allows testing without requiring actual notification permissions or device
@MainActor
class MockNotificationCenter {
    
    // MARK: - Properties
    
    /// Mock authorization status
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// Mock notification settings
    var mockSettings: UNNotificationSettings?
    
    /// Notifications that have been scheduled
    var scheduledNotifications: [UNNotificationRequest] = []
    
    /// Notifications that have been delivered
    var deliveredNotifications: [UNNotification] = []
    
    /// Whether permission request was called
    var requestPermissionCalled = false
    
    /// Whether permission was granted
    var permissionGranted = false
    
    /// Closure to simulate permission request result
    var permissionRequestResult: ((Bool, Error?) -> Void)?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Permission Methods
    
    /// Mock request authorization
    /// - Parameters:
    ///   - options: Authorization options
    ///   - completion: Completion handler with result
    func requestAuthorization(
        options: UNAuthorizationOptions,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        requestPermissionCalled = true
        
        // Simulate async permission request
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            
            if let customResult = self.permissionRequestResult {
                customResult(self.permissionGranted, nil)
            } else {
                completion(self.permissionGranted, nil)
            }
            
            // Update authorization status based on result
            self.authorizationStatus = self.permissionGranted ? .authorized : .denied
        }
    }
    
    /// Mock get notification settings
    /// - Parameter completion: Completion handler with settings
    func getNotificationSettings(completion: @escaping (UNNotificationSettings) -> Void) {
        DispatchQueue.main.async { [weak self] in
            if let settings = self?.mockSettings {
                completion(settings)
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    /// Mock add notification request
    /// - Parameters:
    ///   - request: Notification request to add
    ///   - completion: Completion handler
    func add(
        _ request: UNNotificationRequest,
        withCompletionHandler completion: ((Error?) -> Void)? = nil
    ) {
        scheduledNotifications.append(request)
        
        DispatchQueue.main.async {
            completion?(nil)
        }
    }
    
    /// Mock remove pending notification requests
    /// - Parameter identifiers: Notification identifiers to remove
    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        scheduledNotifications.removeAll { request in
            identifiers.contains(request.identifier)
        }
    }
    
    /// Mock remove all pending notification requests
    func removeAllPendingNotificationRequests() {
        scheduledNotifications.removeAll()
    }
    
    /// Mock get pending notification requests
    /// - Parameter completion: Completion handler with requests
    func getPendingNotificationRequests(
        completionHandler: @escaping ([UNNotificationRequest]) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            completionHandler(self?.scheduledNotifications ?? [])
        }
    }
    
    // MARK: - Delivered Notifications
    
    /// Mock get delivered notifications
    /// - Parameter completion: Completion handler with notifications
    func getDeliveredNotifications(
        completionHandler: @escaping ([UNNotification]) -> Void
    ) {
        DispatchQueue.main.async { [weak self] in
            completionHandler(self?.deliveredNotifications ?? [])
        }
    }
    
    /// Mock remove delivered notifications
    /// - Parameter identifiers: Notification identifiers to remove
    func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {
        deliveredNotifications.removeAll { notification in
            identifiers.contains(notification.request.identifier)
        }
    }
    
    /// Mock remove all delivered notifications
    func removeAllDeliveredNotifications() {
        deliveredNotifications.removeAll()
    }
    
    // MARK: - Test Helpers
    
    /// Simulate notification delivery
    /// - Parameter payload: Notification payload to deliver
    func simulateNotificationDelivery(userInfo: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        content.userInfo = userInfo
        content.title = userInfo["senderName"] as? String ?? "New Message"
        content.body = userInfo["messageText"] as? String ?? ""
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        // Note: Creating UNNotification requires private APIs in tests
        // This is a simplified mock for testing purposes
        scheduledNotifications.append(request)
    }
    
    /// Reset mock state
    func reset() {
        authorizationStatus = .notDetermined
        mockSettings = nil
        scheduledNotifications.removeAll()
        deliveredNotifications.removeAll()
        requestPermissionCalled = false
        permissionGranted = false
        permissionRequestResult = nil
    }
    
    /// Set mock to grant permission
    func grantPermission() {
        permissionGranted = true
        authorizationStatus = .authorized
    }
    
    /// Set mock to deny permission
    func denyPermission() {
        permissionGranted = false
        authorizationStatus = .denied
    }
}

