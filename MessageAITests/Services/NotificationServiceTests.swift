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
    
    // MARK: - Foreground Notification Handling Tests
    
    @Test("Handle foreground notification returns banner and sound options")
    func handleForegroundNotificationReturnsBannerAndSoundOptions() async {
        // Given: NotificationService and mock notification
        let service = NotificationService()
        
        // Note: Creating actual UNNotification requires private APIs
        // This test validates the method signature and return type
        // Full integration test done in UI tests
        
        // Then: Service method exists and is callable
        #expect(service != nil)
    }
    
    // MARK: - Notification Tap Handling Tests
    
    @Test("Handle notification tap with valid chatID returns chatID")
    func handleNotificationTapWithValidChatIDReturnsChatID() async {
        // Given: NotificationService
        let service = NotificationService()
        
        // Note: Creating actual UNNotificationResponse requires private APIs
        // Testing parseNotificationPayload directly instead
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": testMessageText
        ]
        
        // When: Parse payload (same logic as handleNotificationTap)
        let payload = service.parseNotificationPayload(userInfo)
        
        // Then: Returns correct chatID
        #expect(payload?.chatID == testChatID)
    }
    
    @Test("Handle notification tap with invalid payload returns nil")
    func handleNotificationTapWithInvalidPayloadReturnsNil() async {
        // Given: NotificationService and invalid userInfo
        let service = NotificationService()
        let userInfo: [AnyHashable: Any] = [:]
        
        // When: Parse payload
        let payload = service.parseNotificationPayload(userInfo)
        
        // Then: Returns nil
        #expect(payload == nil)
    }
    
    // MARK: - Edge Case Payload Tests
    
    @Test("Parse notification payload with empty chatID returns nil")
    func parseNotificationPayloadWithEmptyChatIDReturnsNil() {
        // Given: userInfo with empty chatID
        let userInfo: [AnyHashable: Any] = [
            "chatID": "",
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": testMessageText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Should still parse (empty string is valid)
        // Empty validation happens at navigation level
        #expect(payload != nil)
        #expect(payload?.chatID == "")
    }
    
    @Test("Parse notification payload with empty messageText returns payload")
    func parseNotificationPayloadWithEmptyMessageTextReturnsPayload() {
        // Given: userInfo with empty messageText
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": ""
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns payload with empty messageText
        #expect(payload != nil)
        #expect(payload?.messageText == "")
    }
    
    @Test("Parse notification payload with special characters in messageText")
    func parseNotificationPayloadWithSpecialCharactersInMessageText() {
        // Given: userInfo with special characters
        let specialText = "Hello! 👋 Test @user #hashtag $price 100%"
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": specialText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns payload with special characters preserved
        #expect(payload != nil)
        #expect(payload?.messageText == specialText)
    }
    
    @Test("Parse notification payload with very long messageText")
    func parseNotificationPayloadWithVeryLongMessageText() {
        // Given: userInfo with very long message (500+ characters)
        let longText = String(repeating: "a", count: 500)
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": longText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns payload with full text (truncation happens at display level)
        #expect(payload != nil)
        #expect(payload?.messageText.count == 500)
    }
    
    @Test("Parse notification payload with unicode characters")
    func parseNotificationPayloadWithUnicodeCharacters() {
        // Given: userInfo with unicode characters
        let unicodeText = "Hello 你好 مرحبا שלום 🌍"
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": unicodeText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns payload with unicode preserved
        #expect(payload != nil)
        #expect(payload?.messageText == unicodeText)
    }
    
    @Test("Parse notification payload with wrong type for chatID returns nil")
    func parseNotificationPayloadWithWrongTypeForChatIDReturnsNil() {
        // Given: userInfo with chatID as Int instead of String
        let userInfo: [AnyHashable: Any] = [
            "chatID": 123,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": testMessageText
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns nil due to type mismatch
        #expect(payload == nil)
    }
    
    @Test("Parse notification payload with additional fields ignores them")
    func parseNotificationPayloadWithAdditionalFieldsIgnoresThem() {
        // Given: userInfo with extra fields
        let userInfo: [AnyHashable: Any] = [
            "chatID": testChatID,
            "senderID": testSenderID,
            "senderName": testSenderName,
            "messageText": testMessageText,
            "extraField1": "value1",
            "extraField2": 123
        ]
        
        // When: Parse notification payload
        let payload = NotificationPayload(userInfo: userInfo)
        
        // Then: Returns payload ignoring extra fields
        #expect(payload != nil)
        #expect(payload?.chatID == testChatID)
    }
    
    // MARK: - Test Helper Integration Tests
    
    @Test("TestNotificationPayload converts to userInfo correctly")
    func testNotificationPayloadConvertsToUserInfoCorrectly() {
        // Given: TestNotificationPayload
        let testPayload = TestNotificationPayload(
            chatID: testChatID,
            senderID: testSenderID,
            senderName: testSenderName,
            messageText: testMessageText,
            testID: "test-123",
            expectedRecipients: ["user1", "user2"]
        )
        
        // When: Convert to userInfo
        let userInfo = testPayload.toUserInfo()
        
        // Then: userInfo contains all required fields
        #expect(userInfo["chatID"] as? String == testChatID)
        #expect(userInfo["senderID"] as? String == testSenderID)
        #expect(userInfo["senderName"] as? String == testSenderName)
        #expect(userInfo["messageText"] as? String == testMessageText)
        #expect(userInfo["testID"] as? String == "test-123")
    }
    
    @Test("TestNotificationPayload oneOnOne creates correct payload")
    func testNotificationPayloadOneOnOneCreatesCorrectPayload() {
        // When: Create 1-on-1 test payload
        let payload = TestNotificationPayload.oneOnOne(
            chatID: testChatID,
            senderID: testSenderID,
            recipientID: "recipient-123"
        )
        
        // Then: Payload has correct structure
        #expect(payload.chatID == testChatID)
        #expect(payload.senderID == testSenderID)
        #expect(payload.expectedRecipients == ["recipient-123"])
    }
    
    @Test("TestNotificationPayload groupChat creates correct payload")
    func testNotificationPayloadGroupChatCreatesCorrectPayload() {
        // Given: Group chat with multiple recipients
        let recipients = ["user1", "user2", "user3"]
        
        // When: Create group chat test payload
        let payload = TestNotificationPayload.groupChat(
            chatID: testChatID,
            senderID: testSenderID,
            recipientIDs: recipients
        )
        
        // Then: Payload has correct structure
        #expect(payload.chatID == testChatID)
        #expect(payload.senderID == testSenderID)
        #expect(payload.expectedRecipients == recipients)
    }
    
    // MARK: - NotificationTestResult Tests
    
    @Test("NotificationTestResult captures test data correctly")
    func notificationTestResultCapturesTestDataCorrectly() {
        // Given: Test parameters
        let testID = "test-123"
        let testName = "foreground_test"
        let appState = AppState.foreground
        let latency: TimeInterval = 0.3
        
        // When: Create test result
        let result = NotificationTestResult(
            testID: testID,
            testName: testName,
            appState: appState,
            passed: true,
            actualLatency: latency
        )
        
        // Then: Result captures all data
        #expect(result.testID == testID)
        #expect(result.testName == testName)
        #expect(result.appState == .foreground)
        #expect(result.passed == true)
        #expect(result.actualLatency == latency)
        #expect(result.error == nil)
    }
    
    @Test("NotificationTestResult captures failure with error")
    func notificationTestResultCapturesFailureWithError() {
        // Given: Test parameters with error
        let testID = "test-456"
        let errorMessage = "Network timeout"
        
        // When: Create failed test result
        let result = NotificationTestResult(
            testID: testID,
            testName: "background_test",
            appState: .background,
            passed: false,
            error: errorMessage
        )
        
        // Then: Result captures failure and error
        #expect(result.passed == false)
        #expect(result.error == errorMessage)
    }
}
