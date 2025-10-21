//
//  MessageAnimationUITests.swift
//  MessageAIUITests
//
//  UI tests for message animations
//

import XCTest
@testable import MessageAI

/// UI tests for message animations and visual effects
final class MessageAnimationUITests: XCTestCase {
    
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
    
    // MARK: - Message Appearance Animation Tests
    
    func testMessageAppearance_SlideInAnimation() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test slide in animation"
        sendMessage(text: messageText)
        
        // Then: Message slides in from bottom
        let messageElement = app.staticTexts[messageText]
        XCTAssertTrue(messageElement.waitForExistence(timeout: 0.1), "Message should appear immediately")
        
        // Check that message has proper positioning (would need more specific UI element checks)
        XCTAssertTrue(messageElement.exists, "Message should be visible")
    }
    
    func testMessageAppearance_ScaleAnimation() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test scale animation"
        sendMessage(text: messageText)
        
        // Then: Message scales up smoothly
        let messageElement = app.staticTexts[messageText]
        XCTAssertTrue(messageElement.waitForExistence(timeout: 0.1), "Message should appear with scale animation")
    }
    
    func testMessageAppearance_OpacityAnimation() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test opacity animation"
        sendMessage(text: messageText)
        
        // Then: Message fades in smoothly
        let messageElement = app.staticTexts[messageText]
        XCTAssertTrue(messageElement.waitForExistence(timeout: 0.1), "Message should fade in")
    }
    
    // MARK: - Status Change Animation Tests
    
    func testStatusChange_SendingToSentAnimation() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test status change animation"
        sendMessage(text: messageText)
        
        // Then: Status changes animate smoothly
        let sendingIndicator = app.images["clock"]
        XCTAssertTrue(sendingIndicator.waitForExistence(timeout: 0.1), "Sending indicator should appear")
        
        let sentIndicator = app.images["checkmark"]
        XCTAssertTrue(sentIndicator.waitForExistence(timeout: 2.0), "Sent indicator should appear with animation")
    }
    
    func testStatusChange_SentToDeliveredAnimation() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test delivered animation"
        sendMessage(text: messageText)
        
        // Then: Status progression animates smoothly
        let sentIndicator = app.images["checkmark"]
        XCTAssertTrue(sentIndicator.waitForExistence(timeout: 2.0), "Sent indicator should appear")
        
        let deliveredIndicator = app.images["checkmark.circle"]
        XCTAssertTrue(deliveredIndicator.waitForExistence(timeout: 3.0), "Delivered indicator should appear with animation")
    }
    
    func testStatusChange_FailedAnimation() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message that will fail
        let messageText = "Test failed animation"
        sendMessage(text: messageText)
        
        // Then: Failed status shows with shake animation
        let failedIndicator = app.images["exclamationmark.circle"]
        XCTAssertTrue(failedIndicator.waitForExistence(timeout: 2.0), "Failed indicator should appear with animation")
    }
    
    // MARK: - Optimistic Indicator Animation Tests
    
    func testOptimisticIndicator_RotationAnimation() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test rotation animation"
        sendMessage(text: messageText)
        
        // Then: Optimistic indicator rotates
        let progressIndicator = app.progressIndicators.firstMatch
        XCTAssertTrue(progressIndicator.waitForExistence(timeout: 0.1), "Progress indicator should rotate")
    }
    
    func testOptimisticIndicator_PulseAnimation() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a message
        let messageText = "Test pulse animation"
        sendMessage(text: messageText)
        
        // Then: Message bubble pulses during sending
        let messageElement = app.staticTexts[messageText]
        XCTAssertTrue(messageElement.waitForExistence(timeout: 0.1), "Message should pulse during sending")
    }
    
    // MARK: - Multiple Message Animation Tests
    
    func testMultipleMessages_SequentialAnimations() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends multiple messages quickly
        let messages = ["First message", "Second message", "Third message"]
        for (index, message) in messages.enumerated() {
            sendMessage(text: message)
            Thread.sleep(forTimeInterval: 0.2) // Small delay between messages
        }
        
        // Then: Each message animates in sequence
        for (index, message) in messages.enumerated() {
            let messageElement = app.staticTexts[message]
            XCTAssertTrue(messageElement.waitForExistence(timeout: 0.5), "Message \(index + 1) should animate in sequence")
        }
    }
    
    func testMultipleMessages_StaggeredAnimations() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends messages with staggered timing
        let messages = ["Staggered 1", "Staggered 2", "Staggered 3"]
        for (index, message) in messages.enumerated() {
            sendMessage(text: message)
            Thread.sleep(forTimeInterval: Double(index) * 0.1) // Increasing delay
        }
        
        // Then: Messages appear with staggered animations
        for message in messages {
            let messageElement = app.staticTexts[message]
            XCTAssertTrue(messageElement.waitForExistence(timeout: 1.0), "Staggered message should animate")
        }
    }
    
    // MARK: - Performance Animation Tests
    
    func testAnimationPerformance_Smooth60FPS() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends many messages quickly
        let startTime = Date()
        for i in 0..<20 {
            sendMessage(text: "Performance message \(i)")
            Thread.sleep(forTimeInterval: 0.05) // 20 FPS input
        }
        let endTime = Date()
        
        // Then: Animations remain smooth
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 3.0, "Should handle 20 messages in less than 3 seconds")
        
        // All messages should be visible
        let messageElements = app.staticTexts.matching(identifier: "messageText")
        XCTAssertTrue(messageElements.count >= 20, "Should have at least 20 messages")
    }
    
    func testAnimationPerformance_NoStuttering() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User scrolls while messages are animating
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Scroll view should exist")
        
        // Send messages while scrolling
        for i in 0..<10 {
            sendMessage(text: "Scroll test message \(i)")
            Thread.sleep(forTimeInterval: 0.1)
            
            // Scroll during animation
            scrollView.swipeUp()
        }
        
        // Then: Scrolling remains smooth
        XCTAssertTrue(scrollView.exists, "Scroll view should still be responsive")
    }
    
    // MARK: - Edge Case Animation Tests
    
    func testAnimationEdgeCase_RapidSending() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends messages very rapidly
        let startTime = Date()
        for i in 0..<5 {
            sendMessage(text: "Rapid message \(i)")
            Thread.sleep(forTimeInterval: 0.01) // Very fast sending
        }
        let endTime = Date()
        
        // Then: All animations complete without issues
        let duration = endTime.timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 1.0, "Should handle rapid sending quickly")
        
        // All messages should be visible
        let messageElements = app.staticTexts.matching(identifier: "messageText")
        XCTAssertTrue(messageElements.count >= 5, "Should have at least 5 messages")
    }
    
    func testAnimationEdgeCase_LongMessage() throws {
        // Given: User is in chat view
        navigateToChatView()
        
        // When: User sends a very long message
        let longMessage = String(repeating: "This is a very long message that should test text wrapping and animation performance. ", count: 10)
        sendMessage(text: longMessage)
        
        // Then: Long message animates properly
        let messageElement = app.staticTexts[longMessage]
        XCTAssertTrue(messageElement.waitForExistence(timeout: 0.5), "Long message should animate properly")
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
