import Foundation
@testable import MessageAI

/// Mock implementation of NotificationService for testing
class MockNotificationService: NotificationService {
    
    var requestPermissionCalled = false
    var requestPermissionResult: Bool = true
    var sendNotificationCalled = false
    var sendNotificationTitle: String?
    var sendNotificationBody: String?
    
    override func requestPermission() async -> Bool {
        requestPermissionCalled = true
        return requestPermissionResult
    }
    
    func sendNotification(title: String, body: String) {
        sendNotificationCalled = true
        sendNotificationTitle = title
        sendNotificationBody = body
    }
    
    func reset() {
        requestPermissionCalled = false
        requestPermissionResult = true
        sendNotificationCalled = false
        sendNotificationTitle = nil
        sendNotificationBody = nil
    }
}
