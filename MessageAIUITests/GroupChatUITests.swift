//
//  GroupChatUITests.swift
//  MessageAIUITests
//
//  UI tests for group chat functionality
//

import XCTest

/// UI tests for group chat functionality
/// - Note: Tests group chat user flows, sender name display, and read receipts
final class GroupChatUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Group Chat Navigation Tests
    
    func testGroupChatNavigation_DisplaysCorrectly() throws {
        // Given: User is on conversation list
        // When: Tapping on a group chat
        let groupChatCell = app.cells["Group Chat - 5 members"]
        XCTAssertTrue(groupChatCell.waitForExistence(timeout: 5))
        groupChatCell.tap()
        
        // Then: Group chat view should display
        let chatView = app.otherElements["ChatView"]
        XCTAssertTrue(chatView.waitForExistence(timeout: 3))
        
        // Verify group chat header shows member count
        let memberCountLabel = app.staticTexts["5 members"]
        XCTAssertTrue(memberCountLabel.exists)
    }
    
    func testGroupChatHeader_ShowsMemberCount() throws {
        // Given: User is in a group chat
        navigateToGroupChat()
        
        // Then: Header should show member count
        let memberCountLabel = app.staticTexts["5 members"]
        XCTAssertTrue(memberCountLabel.exists)
        
        // And: Group chat title should be displayed
        let groupTitle = app.staticTexts["Group Chat"]
        XCTAssertTrue(groupTitle.exists)
    }
    
    // MARK: - Group Chat Message Display Tests
    
    func testGroupChatMessages_ShowSenderNames() throws {
        // Given: User is in a group chat with messages
        navigateToGroupChat()
        
        // Then: Messages from other users should show sender names
        let senderNameLabel = app.staticTexts["John Doe"]
        XCTAssertTrue(senderNameLabel.waitForExistence(timeout: 3))
        
        // Verify sender name is displayed above message
        let messageBubble = app.otherElements["MessageBubbleView"]
        XCTAssertTrue(messageBubble.exists)
    }
    
    func testGroupChatMessages_DoNotShowOwnSenderName() throws {
        // Given: User is in a group chat
        navigateToGroupChat()
        
        // When: User sends a message
        let messageInput = app.textFields["Message input"]
        XCTAssertTrue(messageInput.waitForExistence(timeout: 3))
        messageInput.tap()
        messageInput.typeText("My message")
        
        let sendButton = app.buttons["Send"]
        sendButton.tap()
        
        // Then: Own messages should not show sender name
        let ownMessageBubble = app.otherElements["MessageBubbleView"].firstMatch
        XCTAssertTrue(ownMessageBubble.exists)
        
        // Verify no sender name is shown for own messages
        let ownSenderName = app.staticTexts["You"]
        XCTAssertFalse(ownSenderName.exists)
    }
    
    func testGroupChatMessages_ShowTimestampWhenNeeded() throws {
        // Given: User is in a group chat
        navigateToGroupChat()
        
        // Then: Timestamps should be displayed appropriately
        let timestampLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'ago'"))
        XCTAssertTrue(timestampLabel.firstMatch.exists)
    }
    
    // MARK: - Group Chat Read Receipt Tests
    
    func testGroupChatReadReceipts_DisplayCorrectly() throws {
        // Given: User is in a group chat
        navigateToGroupChat()
        
        // When: User sends a message
        sendMessage("Read receipt test")
        
        // Then: Read receipt should be displayed
        let readReceipt = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Read by'"))
        XCTAssertTrue(readReceipt.firstMatch.waitForExistence(timeout: 5))
    }
    
    func testGroupChatReadReceipts_ShowAllMembersRead() throws {
        // Given: User is in a group chat with all members having read the message
        navigateToGroupChat()
        sendMessage("All read test")
        
        // Then: Read receipt should show "Read by all"
        let allReadReceipt = app.staticTexts["Read by all"]
        XCTAssertTrue(allReadReceipt.waitForExistence(timeout: 5))
    }
    
    func testGroupChatReadReceipts_ShowPartialRead() throws {
        // Given: User is in a group chat with some members having read
        navigateToGroupChat()
        sendMessage("Partial read test")
        
        // Then: Read receipt should show "Read by X of Y"
        let partialReadReceipt = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Read by' AND label CONTAINS 'of'"))
        XCTAssertTrue(partialReadReceipt.firstMatch.waitForExistence(timeout: 5))
    }
    
    // MARK: - Group Chat Message Input Tests
    
    func testGroupChatMessageInput_WorksCorrectly() throws {
        // Given: User is in a group chat
        navigateToGroupChat()
        
        // When: User types and sends a message
        let messageText = "Hello group!"
        sendMessage(messageText)
        
        // Then: Message should appear in chat
        let messageBubble = app.otherElements["MessageBubbleView"]
        XCTAssertTrue(messageBubble.waitForExistence(timeout: 3))
        
        // Verify message text is displayed
        let messageTextElement = app.staticTexts[messageText]
        XCTAssertTrue(messageTextElement.exists)
    }
    
    func testGroupChatMessageInput_HandlesLongMessages() throws {
        // Given: User is in a group chat
        navigateToGroupChat()
        
        // When: User sends a long message
        let longMessage = "This is a very long message that should wrap properly in the group chat interface and display correctly for all group members to read and understand the content."
        sendMessage(longMessage)
        
        // Then: Long message should be displayed correctly
        let messageBubble = app.otherElements["MessageBubbleView"]
        XCTAssertTrue(messageBubble.waitForExistence(timeout: 3))
        
        // Verify message text is displayed
        let messageTextElement = app.staticTexts[longMessage]
        XCTAssertTrue(messageTextElement.exists)
    }
    
    // MARK: - Group Chat Performance Tests
    
    func testGroupChatScrolling_PerformsSmoothly() throws {
        // Given: User is in a group chat with many messages
        navigateToGroupChat()
        
        // When: User scrolls through messages
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
        
        // Perform scrolling gesture
        scrollView.swipeUp()
        scrollView.swipeUp()
        scrollView.swipeDown()
        
        // Then: Scrolling should be smooth (no crashes or freezes)
        // This is a basic performance test - in real testing, you'd measure frame rates
        XCTAssertTrue(scrollView.exists)
    }
    
    func testGroupChatMessageDelivery_Under100ms() throws {
        // Given: User is in a group chat
        navigateToGroupChat()
        
        // When: User sends a message
        let startTime = Date()
        sendMessage("Performance test")
        let endTime = Date()
        
        // Then: Message should appear quickly
        let deliveryTime = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        XCTAssertLessThan(deliveryTime, 100, "Message delivery took \(deliveryTime)ms, expected < 100ms")
    }
    
    // MARK: - Group Chat Edge Cases
    
    func testGroupChatWithSingleMember_HandlesCorrectly() throws {
        // Given: User is in a group chat with only one member (edge case)
        let singleMemberChat = app.cells["Single Member Group"]
        if singleMemberChat.waitForExistence(timeout: 3) {
            singleMemberChat.tap()
            
            // Then: Chat should still work
            let chatView = app.otherElements["ChatView"]
            XCTAssertTrue(chatView.waitForExistence(timeout: 3))
        }
    }
    
    func testGroupChatWithManyMembers_HandlesCorrectly() throws {
        // Given: User is in a group chat with many members
        let largeGroupChat = app.cells["Large Group - 10 members"]
        if largeGroupChat.waitForExistence(timeout: 3) {
            largeGroupChat.tap()
            
            // Then: Chat should still work efficiently
            let chatView = app.otherElements["ChatView"]
            XCTAssertTrue(chatView.waitForExistence(timeout: 3))
            
            // Verify member count is displayed
            let memberCountLabel = app.staticTexts["10 members"]
            XCTAssertTrue(memberCountLabel.exists)
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToGroupChat() {
        // Navigate to conversation list if not already there
        if app.navigationBars["Conversations"].exists {
            // Already on conversation list
        } else {
            // Navigate back to conversation list
            let backButton = app.buttons["Back"]
            if backButton.exists {
                backButton.tap()
            }
        }
        
        // Tap on group chat
        let groupChatCell = app.cells["Group Chat - 5 members"]
        XCTAssertTrue(groupChatCell.waitForExistence(timeout: 5))
        groupChatCell.tap()
    }
    
    private func sendMessage(_ text: String) {
        let messageInput = app.textFields["Message input"]
        XCTAssertTrue(messageInput.waitForExistence(timeout: 3))
        messageInput.tap()
        messageInput.typeText(text)
        
        let sendButton = app.buttons["Send"]
        sendButton.tap()
    }
}
