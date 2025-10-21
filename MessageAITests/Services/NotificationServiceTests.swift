//
//  NotificationServiceTests.swift
//  MessageAITests
//
//  Unit tests for NotificationService using Swift Testing framework
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for NotificationService
/// - Note: Uses Swift Testing framework with @Test annotations
struct NotificationServiceTests {
    
    // MARK: - Test Data
    
    private let testUserID = "test-user-123"
    private let testChatID = "test-chat-456"
    private let testSenderID = "test-sender-789"
    private let testSenderName = "Test User"
    private let testMessageText = "Hello, this is a test message"
    
    // MARK: - Notification Payload Tests
    
    @Test("Parse valid notification payload returns NotificationPayload")
    func parseValidNotificationPayloadReturnsNotificationPayload() {
        // Given: Valid userInfo dictionary with all required fields
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": testMessageText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns NotificationPayload with correct values
        #expect(payload != nil)
        #expect(payload?.chatID == testChatID)
        #expect(payload?.senderID == testSenderID)
        #expect(payload?.senderName == testSenderName)
        #expect(payload?.messageText == testMessageText)
    }
    
    @Test("Parse invalid notification payload returns nil")
    func parseInvalidNotificationPayloadReturnsNil() {
        // Given: userInfo missing required chatID field
        let userInfo: [AnyHashable: Any] = [
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": testMessageText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns nil
        #expect(payload == nil)
    }
    
    @Test("Parse notification payload with missing senderID returns nil")
    func parseNotificationPayloadWithMissingSenderIDReturnsNil() {
        // Given: userInfo missing senderID field
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderName": testSenderName,
            "messageText": testMessageText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns nil
        #expect(payload == nil)
    }
    
    @Test("Parse notification payload with missing senderName returns nil")
    func parseNotificationPayloadWithMissingSenderNameReturnsNil() {
        // Given: userInfo missing senderName field
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "messageText": testMessageText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns nil
        #expect(payload == nil)
    }
    
    @Test("Parse notification payload with missing messageText returns nil")
    func parseNotificationPayloadWithMissingMessageTextReturnsNil() {
        // Given: userInfo missing messageText field
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns nil
        #expect(payload == nil)
    }
    
    @Test("Parse notification payload with empty userInfo returns nil")
    func parseNotificationPayloadWithEmptyUserInfoReturnsNil() {
        // Given: Empty userInfo dictionary
        let userInfo: [AnyHashable: Any] = [:]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns nil
        #expect(payload == nil)
    }
    
    // MARK: - NotificationService Tests
    
    @Test("NotificationService initializes correctly")
    func notificationServiceInitializesCorrectly() async {
        // When: Create NotificationService
        let service = NotificationService()
        
        // Then: Service is created successfully
        #expect(service != nil)
    }
    
    @Test("Parse notification payload with valid data returns correct chatID")
    func parseNotificationPayloadWithValidDataReturnsCorrectChatID() async {
        // Given: NotificationService and valid userInfo
        let service = NotificationService()
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": testMessageText
        ]
        
        // When: Parse notification payload
        let payload = service.parseNotificationPayload(userInfo)
        
        // Then: Returns correct chatID
        #expect(payload != nil)
        #expect(payload?.chatID == testChatID)
    }
    
    @Test("Parse notification payload with invalid data returns nil")
    func parseNotificationPayloadWithInvalidDataReturnsNil() async {
        // Given: NotificationService and invalid userInfo
        let service = NotificationService()
        let userInfo: [AnyHashable: Any] = [
            "invalidField": "invalidValue"
        ]
        
        // When: Parse notification payload
        let payload = service.parseNotificationPayload(userInfo)
        
        // Then: Returns nil
        #expect(payload == nil)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("NotificationError permissionDenied has correct description")
    func notificationErrorPermissionDeniedHasCorrectDescription() {
        // Given: NotificationError.permissionDenied
        let error = NotificationError.permissionDenied
        
        // When: Get error description
        let description = error.errorDescription
        
        // Then: Returns correct description
        #expect(description == "Notification permission was denied")
    }
    
    @Test("NotificationError tokenRegistrationFailed has correct description")
    func notificationErrorTokenRegistrationFailedHasCorrectDescription() {
        // Given: NotificationError.tokenRegistrationFailed
        let error = NotificationError.tokenRegistrationFailed
        
        // When: Get error description
        let description = error.errorDescription
        
        // Then: Returns correct description
        #expect(description == "Failed to register device token")
    }
    
    @Test("NotificationError firestoreUpdateFailed has correct description")
    func notificationErrorFirestoreUpdateFailedHasCorrectDescription() {
        // Given: NotificationError.firestoreUpdateFailed
        let error = NotificationError.firestoreUpdateFailed
        
        // When: Get error description
        let description = error.errorDescription
        
        // Then: Returns correct description
        #expect(description == "Failed to update token in database")
    }
    
    @Test("NotificationError invalidPayload has correct description")
    func notificationErrorInvalidPayloadHasCorrectDescription() {
        // Given: NotificationError.invalidPayload
        let error = NotificationError.invalidPayload
        
        // When: Get error description
        let description = error.errorDescription
        
        // Then: Returns correct description
        #expect(description == "Notification payload is invalid or malformed")
    }
}
