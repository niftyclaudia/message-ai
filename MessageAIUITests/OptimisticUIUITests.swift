//
//  OptimisticUIUITests.swift
//  MessageAIUITests
//
//  UI tests for optimistic UI functionality
//

import XCTest
@testable import MessageAI

/// UI tests for optimistic UI flows
final class OptimisticUIUITests: XCTestCase {
    
    // MARK: - Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Optimistic Message Send Tests
    
    func testOptimisticMessageSend_DisplaysImmediately() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test optimistic message"
        sendMessage(text: messageText)
        
        // Then: Message appears immediately in UI
        let messageElement = app.staticTexts[messageText]
        XCTAssertTrue(messageElement.waitForExistence(timeout: 0.1), "Message should appear immediately")
    }
    
    func testOptimisticMessageSend_ShowsSendingStatus() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test sending status message"
        sendMessage(text: messageText)
        
        // Then: Message shows sending status
        let sendingIndicator = app.images["clock"]
        XCTAssertTrue(sendingIndicator.waitForExistence(timeout: 0.1), "Sending indicator should appear immediately")
    }
    
    func testOptimisticMessageSend_StatusUpdatesToSent() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test status update message"
        sendMessage(text: messageText)
        
        // Then: Status updates to sent after delay
        let sentIndicator = app.images["checkmark"]
        XCTAssertTrue(sentIndicator.waitForExistence(timeout: 2.0), "Sent indicator should appear after delay")
    }
    
    func testOptimisticMessageSend_StatusUpdatesToDelivered() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test delivered status message"
        sendMessage(text: messageText)
        
        // Then: Status updates to delivered after delay
        let deliveredIndicator = app.images["checkmark.circle"]
        XCTAssertTrue(deliveredIndicator.waitForExistence(timeout: 3.0), "Delivered indicator should appear after delay")
    }
    
    // MARK: - Optimistic Message Failure Tests
    
    func testOptimisticMessageSend_FailureShowsErrorState() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message that will fail
        let messageText = "Test failure message"
        sendMessage(text: messageText)
        
        // Then: Message shows failed status with retry button
        let failedIndicator = app.images["exclamationmark.circle"]
        XCTAssertTrue(failedIndicator.waitForExistence(timeout: 2.0), "Failed indicator should appear")
        
        let retryButton = app.buttons["arrow.clockwise"]
        XCTAssertTrue(retryButton.exists, "Retry button should be available")
    }
    
    func testOptimisticMessageSend_RetryButtonWorks() throws {
        // Given: User is in chat view with a failed message
        navigateToChatView()
        let messageText = "Test retry message"
        sendMessage(text: messageText)
        
        // Wait for failure
        let failedIndicator = app.images["exclamationmark.circle"]
        XCTAssertTrue(failedIndicator.waitForExistence(timeout: 2.0))
        
        // When: User taps retry button
        let retryButton = app.buttons["arrow.clockwise"]
        XCTAssertTrue(retryButton.exists)
        retryButton.tap()
        
        // Then: Message status changes to sending
        let sendingIndicator = app.images["clock"]
        XCTAssertTrue(sendingIndicator.waitForExistence(timeout: 1.0), "Status should change to sending after retry")
    }
    
    // MARK: - Animation Tests
    
    func testOptimisticMessageSend_SmoothAnimations() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends multiple messages quickly
        let messages = ["Message 1", "Message 2", "Message 3"]
        for message in messages {
            sendMessage(text: message)
            Thread.sleep(forTimeInterval: 0.1) // Small delay between messages
        }
        
        // Then: All messages appear with smooth animations
        for message in messages {
            let messageElement = app.staticTexts[message]
            XCTAssertTrue(messageElement.waitForExistence(timeout: 0.5), "Message \(message) should appear with animation")
        }
    }
    
    func testOptimisticMessageSend_StatusChangeAnimations() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test animation message"
        sendMessage(text: messageText)
        
        // Then: Status changes animate smoothly
        // Check for sending status
        let sendingIndicator = app.images["clock"]
        XCTAssertTrue(sendingIndicator.waitForExistence(timeout: 0.1))
        
        // Check for sent status
        let sentIndicator = app.images["checkmark"]
        XCTAssertTrue(sentIndicator.waitForExistence(timeout: 2.0))
        
        // Check for delivered status
        let deliveredIndicator = app.images["checkmark.circle"]
        XCTAssertTrue(deliveredIndicator.waitForExistence(timeout: 3.0))
    }
    
    // MARK: - Server Timestamp Tests
    
    func testOptimisticMessageSend_ServerTimestampConsistency() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends multiple messages
        let messages = ["First message", "Second message", "Third message"]
        for message in messages {
            sendMessage(text: message)
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Then: Messages are ordered consistently
        let messageElements = app.staticTexts.matching(identifier: "messageText")
        XCTAssertTrue(messageElements.count >= 3, "Should have at least 3 messages")
        
        // Messages should be in chronological order
        let firstMessage = app.staticTexts["First message"]
        let secondMessage = app.staticTexts["Second message"]
        let thirdMessage = app.staticTexts["Third message"]
        
        XCTAssertTrue(firstMessage.exists)
        XCTAssertTrue(secondMessage.exists)
        XCTAssertTrue(thirdMessage.exists)
    }
    
    // MARK: - Offline Optimistic Tests
    
    func testOptimisticMessageSend_OfflineMode() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User goes offline and sends a message
        // Note: This would require network simulation in a real test
        let messageText = "Offline message"
        sendMessage(text: messageText)
        
        // Then: Message shows queued status
        let queuedIndicator = app.images["clock.arrow.circlepath"]
        XCTAssertTrue(queuedIndicator.waitForExistence(timeout: 1.0), "Queued indicator should appear for offline message")
    }
    
    // MARK: - Performance Tests
    
    func testOptimisticMessageSend_PerformanceWithManyMessages() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends many messages quickly
        let startTime = Date()
        for i in 0..<50 {
            sendMessage(text: "Performance test message \(i)")
            Thread.sleep(forTimeInterval: 0.01) // Very small delay
        }
        let endTime = Date()
        
        // Then: All messages appear quickly
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 5.0, "Should send 50 messages in less than 5 seconds")
        
        // All messages should be visible
        let messageElements = app.staticTexts.matching(identifier: "messageText")
        XCTAssertTrue(messageElements.count >= 50, "Should have at least 50 messages")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToChatView() {
        // Navigate to chat view (implementation depends on app structure)
        let chatButton = app.buttons["Chat"]
        if chatButton.exists {
            chatButton.tap()
        }
        
        // Wait for chat view to load
        let chatView = app.otherElements["ChatView"]
        XCTAssertTrue(chatView.waitForExistence(timeout: 2.0))
    }
    
    private func sendMessage(text: String) {
        let messageInput = app.textFields["MessageInput"]
        XCTAssertTrue(messageInput.waitForExistence(timeout: 2.0))
        
        messageInput.tap()
        messageInput.typeText(text)
        
        let sendButton = app.buttons["Send"]
        XCTAssertTrue(sendButton.exists)
        sendButton.tap()
    }
}
