//
//  TestNotificationPayload.swift
//  MessageAITests
//
//  Test data structures for notification testing
//

import Foundation
@testable import MessageAI

/// Test notification payload structure for testing
/// - Note: Extends NotificationPayload with test-specific functionality
struct TestNotificationPayload {
    let chatID: String
    let senderID: String
    let senderName: String
    let messageText: String
    let testID: String  // For tracking in tests
    let expectedRecipients: [String]
    let timestamp: Date
    
    /// Initialize test notification payload
    /// - Parameters:
    ///   - chatID: Chat ID for navigation
    ///   - senderID: ID of message sender
    ///   - senderName: Display name of sender
    ///   - messageText: Message content
    ///   - testID: Unique identifier for test tracking
    ///   - expectedRecipients: List of user IDs who should receive notification
    init(
        chatID: String,
        senderID: String,
        senderName: String,
        messageText: String,
        testID: String = UUID().uuidString,
        expectedRecipients: [String] = []
    ) {
        self.chatID = chatID
        self.senderID = senderID
        self.senderName = senderName
        self.messageText = messageText
        self.testID = testID
        self.expectedRecipients = expectedRecipients
        self.timestamp = Date()
    }
    
    /// Convert to userInfo dictionary for notification testing
    /// - Returns: Dictionary matching notification payload format
    func toUserInfo() -> [AnyHashable: Any] {
        return [
            "chatID": chatID,
            "senderID": senderID,
            "senderName": senderName,
            "messageText": messageText,
            "testID": testID
        ]
    }
    
    /// Create a test payload for 1-on-1 chat
    /// - Parameters:
    ///   - chatID: Chat ID
    ///   - senderID: Sender ID
    ///   - recipientID: Recipient ID
    /// - Returns: TestNotificationPayload
    static func oneOnOne(chatID: String, senderID: String, recipientID: String) -> TestNotificationPayload {
        return TestNotificationPayload(
            chatID: chatID,
            senderID: senderID,
            senderName: "Test Sender",
            messageText: "Test message for 1-on-1 chat",
            expectedRecipients: [recipientID]
        )
    }
    
    /// Create a test payload for group chat
    /// - Parameters:
    ///   - chatID: Chat ID
    ///   - senderID: Sender ID
    ///   - recipientIDs: List of recipient IDs (sender should be excluded)
    /// - Returns: TestNotificationPayload
    static func groupChat(chatID: String, senderID: String, recipientIDs: [String]) -> TestNotificationPayload {
        return TestNotificationPayload(
            chatID: chatID,
            senderID: senderID,
            senderName: "Test Sender",
            messageText: "Test message for group chat",
            expectedRecipients: recipientIDs
        )
    }
}

/// Test result structure for notification tests
/// - Note: Captures test execution results and metrics
struct NotificationTestResult {
    let testID: String
    let testName: String
    let appState: AppState
    let passed: Bool
    let actualLatency: TimeInterval?
    let error: String?
    let timestamp: Date
    
    init(
        testID: String,
        testName: String,
        appState: AppState,
        passed: Bool,
        actualLatency: TimeInterval? = nil,
        error: String? = nil
    ) {
        self.testID = testID
        self.testName = testName
        self.appState = appState
        self.passed = passed
        self.actualLatency = actualLatency
        self.error = error
        self.timestamp = Date()
    }
}

/// App states for notification testing
enum AppState {
    case foreground
    case background
    case terminated
}

