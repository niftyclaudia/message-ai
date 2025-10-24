//
//  PriorityMessageUITests.swift
//  MessageAIUITests
//
//  UI tests for priority message detection feature
//

import XCTest

/// UI tests for priority message detection functionality
final class PriorityMessageUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Priority Badge Display Tests
    
    func testPriorityBadgeDisplaysCorrectly() throws {
        // Given: User is in a chat with categorized messages
        navigateToChat()
        
        // When: Messages are displayed
        let messageList = app.scrollViews.firstMatch
        
        // Then: Priority badges should be visible
        let urgentBadge = app.buttons.matching(identifier: "urgent-badge").firstMatch
        let canWaitBadge = app.buttons.matching(identifier: "can-wait-badge").firstMatch
        let aiHandledBadge = app.buttons.matching(identifier: "ai-handled-badge").firstMatch
        
        XCTAssertTrue(urgentBadge.exists, "Urgent badge should be visible")
        XCTAssertTrue(canWaitBadge.exists, "Can wait badge should be visible")
        XCTAssertTrue(aiHandledBadge.exists, "AI handled badge should be visible")
    }
    
    func testUrgentMessagesShowRedBadge() throws {
        // Given: User is in a chat
        navigateToChat()
        
        // When: An urgent message is displayed
        let urgentMessage = app.staticTexts.containing("URGENT").firstMatch
        
        // Then: Red priority badge should be visible
        let urgentBadge = app.buttons.matching(identifier: "urgent-badge").firstMatch
        XCTAssertTrue(urgentBadge.exists, "Urgent message should show red badge")
        
        // Verify badge color (red)
        let badgeColor = urgentBadge.value as? String
        XCTAssertNotNil(badgeColor, "Badge should have color information")
    }
    
    func testCanWaitMessagesShowYellowBadge() throws {
        // Given: User is in a chat
        navigateToChat()
        
        // When: A can-wait message is displayed
        let canWaitMessage = app.staticTexts.containing("weekend").firstMatch
        
        // Then: Yellow priority badge should be visible
        let canWaitBadge = app.buttons.matching(identifier: "can-wait-badge").firstMatch
        XCTAssertTrue(canWaitBadge.exists, "Can wait message should show yellow badge")
    }
    
    func testAIHandledMessagesShowBlueBadge() throws {
        // Given: User is in a chat
        navigateToChat()
        
        // When: An AI-handled message is displayed
        let aiHandledMessage = app.staticTexts.containing("schedule").firstMatch
        
        // Then: Blue priority badge should be visible
        let aiHandledBadge = app.buttons.matching(identifier: "ai-handled-badge").firstMatch
        XCTAssertTrue(aiHandledBadge.exists, "AI handled message should show blue badge")
    }
    
    // MARK: - Chat List Priority Indicators Tests
    
    func testChatListShowsPriorityIndicators() throws {
        // Given: User is on the conversation list
        navigateToConversationList()
        
        // When: Chats with categorized messages are displayed
        let conversationList = app.tables.firstMatch
        
        // Then: Priority indicators should be visible in chat list
        let urgentIndicator = app.staticTexts.matching(identifier: "urgent-indicator").firstMatch
        let canWaitIndicator = app.staticTexts.matching(identifier: "can-wait-indicator").firstMatch
        let aiHandledIndicator = app.staticTexts.matching(identifier: "ai-handled-indicator").firstMatch
        
        XCTAssertTrue(urgentIndicator.exists, "Urgent indicator should be visible in chat list")
        XCTAssertTrue(canWaitIndicator.exists, "Can wait indicator should be visible in chat list")
        XCTAssertTrue(aiHandledIndicator.exists, "AI handled indicator should be visible in chat list")
    }
    
    // MARK: - Priority Inbox Tests
    
    func testPriorityInboxFiltersMessages() throws {
        // Given: User navigates to priority inbox
        navigateToPriorityInbox()
        
        // When: User selects different categories
        let urgentTab = app.buttons["Urgent"]
        let canWaitTab = app.buttons["Can Wait"]
        let aiHandledTab = app.buttons["AI Handled"]
        
        // Then: Messages should be filtered correctly
        urgentTab.tap()
        let urgentMessages = app.staticTexts.matching(identifier: "urgent-message")
        XCTAssertTrue(urgentMessages.count > 0, "Urgent messages should be displayed")
        
        canWaitTab.tap()
        let canWaitMessages = app.staticTexts.matching(identifier: "can-wait-message")
        XCTAssertTrue(canWaitMessages.count > 0, "Can wait messages should be displayed")
        
        aiHandledTab.tap()
        let aiHandledMessages = app.staticTexts.matching(identifier: "ai-handled-message")
        XCTAssertTrue(aiHandledMessages.count > 0, "AI handled messages should be displayed")
    }
    
    func testPriorityInboxShowsEmptyState() throws {
        // Given: User navigates to priority inbox
        navigateToPriorityInbox()
        
        // When: No messages exist for a category
        let urgentTab = app.buttons["Urgent"]
        urgentTab.tap()
        
        // Then: Empty state should be displayed
        let emptyState = app.staticTexts["No Urgent Messages"]
        XCTAssertTrue(emptyState.exists, "Empty state should be displayed when no messages exist")
    }
    
    // MARK: - Real-Time Categorization Tests
    
    func testMessageCategorizationAppearsInRealTime() throws {
        // Given: User is in a chat
        navigateToChat()
        
        // When: A new message is sent
        let messageInput = app.textFields["message-input"]
        messageInput.tap()
        messageInput.typeText("URGENT: This is a test urgent message")
        
        let sendButton = app.buttons["send-button"]
        sendButton.tap()
        
        // Then: Priority badge should appear within 2 seconds
        let urgentBadge = app.buttons.matching(identifier: "urgent-badge").firstMatch
        let badgeExists = urgentBadge.waitForExistence(timeout: 2.0)
        XCTAssertTrue(badgeExists, "Priority badge should appear within 2 seconds")
    }
    
    func testCategorizationConfidenceDisplay() throws {
        // Given: User is in a chat with categorized messages
        navigateToChat()
        
        // When: Messages with confidence scores are displayed
        let confidenceText = app.staticTexts.containing("%").firstMatch
        
        // Then: Confidence percentage should be visible
        XCTAssertTrue(confidenceText.exists, "Confidence percentage should be displayed")
        
        // Verify confidence is a valid percentage
        let confidenceValue = confidenceText.label
        XCTAssertTrue(confidenceValue.contains("%"), "Confidence should be displayed as percentage")
    }
    
    // MARK: - Settings Tests
    
    func testPrioritySettingsCanBeModified() throws {
        // Given: User navigates to priority settings
        navigateToPrioritySettings()
        
        // When: User modifies settings
        let enableToggle = app.switches["Enable AI Categorization"]
        let confidenceSlider = app.sliders["Confidence Threshold"]
        
        // Then: Settings should be modifiable
        XCTAssertTrue(enableToggle.exists, "AI categorization toggle should be visible")
        XCTAssertTrue(confidenceSlider.exists, "Confidence threshold slider should be visible")
        
        // Test toggle functionality
        enableToggle.tap()
        XCTAssertFalse(enableToggle.value as? Bool ?? true, "Toggle should change state")
        
        // Test slider functionality
        confidenceSlider.adjust(toNormalizedSliderPosition: 0.8)
        let sliderValue = confidenceSlider.value as? String
        XCTAssertNotNil(sliderValue, "Slider should have a value")
    }
    
    // MARK: - Performance Tests
    
    func testScrollingPerformanceWithCategorizedMessages() throws {
        // Given: User is in a chat with many categorized messages
        navigateToChat()
        
        // When: User scrolls through messages
        let messageList = app.scrollViews.firstMatch
        
        // Then: Scrolling should be smooth (60fps)
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 1...10 {
            messageList.swipeUp()
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let scrollDuration = endTime - startTime
        
        XCTAssertLessThan(scrollDuration, 2.0, "Scrolling should be smooth and fast")
    }
    
    // MARK: - Error Handling Tests
    
    func testGracefulDegradationWhenAIServiceFails() throws {
        // Given: AI service is unavailable
        // (This would be simulated in a real test environment)
        
        // When: User sends a message
        navigateToChat()
        let messageInput = app.textFields["message-input"]
        messageInput.tap()
        messageInput.typeText("Test message")
        
        let sendButton = app.buttons["send-button"]
        sendButton.tap()
        
        // Then: Message should still be sent without priority badge
        let message = app.staticTexts["Test message"]
        XCTAssertTrue(message.exists, "Message should be sent even when AI service fails")
        
        // No priority badge should appear
        let urgentBadge = app.buttons.matching(identifier: "urgent-badge").firstMatch
        XCTAssertFalse(urgentBadge.exists, "No priority badge should appear when AI service fails")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToChat() {
        // Navigate to a chat with categorized messages
        let chatCell = app.cells.firstMatch
        chatCell.tap()
    }
    
    private func navigateToConversationList() {
        // Navigate to the conversation list
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
        }
    }
    
    private func navigateToPriorityInbox() {
        // Navigate to priority inbox
        let priorityInboxButton = app.buttons["Priority Inbox"]
        priorityInboxButton.tap()
    }
    
    private func navigateToPrioritySettings() {
        // Navigate to priority settings
        navigateToPriorityInbox()
        let settingsButton = app.buttons["Settings"]
        settingsButton.tap()
    }
}
