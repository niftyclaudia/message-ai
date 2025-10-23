//
//  PerformanceUITests.swift
//  MessageAIUITests
//
//  Essential UI tests for performance optimization
//

import XCTest

/// Essential UI tests for performance optimization
/// - Note: Streamlined tests focusing on core performance validation
final class PerformanceUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Core Performance Tests
    
    func testAppLaunchTimeUnderTwoSeconds() throws {
        let startTime = Date()
        
        app.launch()
        
        let chatListExists = app.navigationBars["Conversations"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(chatListExists, "Chat list should be visible within 2 seconds")
        
        let launchTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(launchTime, 2.0, "App launch time should be under 2 seconds")
    }
    
    func testNavigationTimeUnderFourHundredMilliseconds() throws {
        let startTime = Date()
        
        let chatListExists = app.navigationBars["Conversations"].waitForExistence(timeout: 2.0)
        XCTAssertTrue(chatListExists, "Chat list should be visible")
        
        let firstChat = app.cells.firstMatch
        XCTAssertTrue(firstChat.exists, "First chat should exist")
        firstChat.tap()
        
        let chatViewExists = app.navigationBars.firstMatch.waitForExistence(timeout: 0.5)
        XCTAssertTrue(chatViewExists, "Chat view should be visible")
        
        let navigationTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(navigationTime, 0.4, "Navigation time should be under 400ms")
    }
    
    func testScrollPerformanceIsSmooth() throws {
        let firstChat = app.cells.firstMatch
        firstChat.tap()
        
        let chatViewExists = app.navigationBars.firstMatch.waitForExistence(timeout: 2.0)
        XCTAssertTrue(chatViewExists, "Chat view should be visible")
        
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Scroll view should exist")
        
        let startTime = Date()
        
        // Perform scroll gestures
        for _ in 0..<5 {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }
        
        let scrollTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(scrollTime, 2.0, "Scrolling should be smooth and fast")
    }
    
    func testKeyboardTransitionIsSmooth() throws {
        let firstChat = app.cells.firstMatch
        firstChat.tap()
        
        let chatViewExists = app.navigationBars.firstMatch.waitForExistence(timeout: 2.0)
        XCTAssertTrue(chatViewExists, "Chat view should be visible")
        
        let startTime = Date()
        
        let messageInput = app.textFields.firstMatch
        messageInput.tap()
        
        let keyboardExists = app.keyboards.firstMatch.waitForExistence(timeout: 0.5)
        XCTAssertTrue(keyboardExists, "Keyboard should appear")
        
        let showTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(showTime, 0.3, "Keyboard show transition should be under 300ms")
    }
    
    func testOptimisticUIFeedbackIsInstant() throws {
        let firstChat = app.cells.firstMatch
        firstChat.tap()
        
        let chatViewExists = app.navigationBars.firstMatch.waitForExistence(timeout: 2.0)
        XCTAssertTrue(chatViewExists, "Chat view should be visible")
        
        let startTime = Date()
        
        let messageInput = app.textFields.firstMatch
        messageInput.tap()
        messageInput.typeText("Test message")
        
        let sendButton = app.buttons["Send"]
        sendButton.tap()
        
        let messageExists = app.staticTexts["Test message"].waitForExistence(timeout: 0.1)
        XCTAssertTrue(messageExists, "Message should appear instantly with optimistic UI")
        
        let optimisticTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(optimisticTime, 0.1, "Optimistic UI feedback should be under 100ms")
    }
}
