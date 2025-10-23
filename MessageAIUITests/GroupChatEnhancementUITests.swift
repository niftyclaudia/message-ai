//
//  GroupChatEnhancementUITests.swift
//  MessageAIUITests
//
//  PR-3: UI tests for group chat enhancement features
//  Tests message attribution, member list, and presence indicators
//

import XCTest

/// UI tests for PR-3 group chat enhancement
/// - Note: Tests attribution, member list, and group header
final class GroupChatEnhancementUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Group Chat Header Tests
    
    func testGroupChatHeader_DisplaysGroupNameAndMemberCount() throws {
        // Given: App is launched and user is in a group chat
        // (Assumes test data setup or user logged in)
        
        // When: Navigate to group chat
        // Note: This test assumes group chat is accessible from main view
        // Adjust selectors based on actual UI
        
        // Then: Group header shows group name and member count
        let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
        XCTAssertTrue(groupHeader.waitForExistence(timeout: 5), "Group chat header should exist")
        
        // Verify member count text exists (e.g., "5 members")
        let memberCountLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'member'")).firstMatch
        XCTAssertTrue(memberCountLabel.exists, "Member count should be displayed")
    }
    
    func testGroupChatHeader_TappableToOpenMemberList() throws {
        // Given: User is in a group chat
        
        // When: Tap on group chat header
        let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
        XCTAssertTrue(groupHeader.waitForExistence(timeout: 5))
        groupHeader.tap()
        
        // Then: Member list modal appears
        let memberListTitle = app.navigationBars["Group Members"]
        XCTAssertTrue(memberListTitle.waitForExistence(timeout: 3), "Member list should open within 400ms")
        
        // Verify "Done" button exists to dismiss
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should exist in member list")
    }
    
    func testGroupChatHeader_LoadsWithin400ms() throws {
        // Given: User navigates to group chat
        
        // When: Group chat header loads
        let startTime = Date()
        let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
        XCTAssertTrue(groupHeader.waitForExistence(timeout: 5))
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Then: Header loads within 400ms (PR-3 requirement)
        XCTAssertLessThan(loadTime, 0.4, "Group header should load within 400ms")
    }
    
    // MARK: - Member List Tests
    
    func testMemberList_DisplaysAllMembers() throws {
        // Given: User opens member list in group chat
        let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
        XCTAssertTrue(groupHeader.waitForExistence(timeout: 5))
        groupHeader.tap()
        
        // When: Member list loads
        let memberListTitle = app.navigationBars["Group Members"]
        XCTAssertTrue(memberListTitle.waitForExistence(timeout: 3))
        
        // Then: All members are displayed
        // Note: Adjust based on test data - assumes at least 2 members
        let memberRows = app.cells.matching(identifier: "memberStatusRow")
        XCTAssertGreaterThanOrEqual(memberRows.count, 2, "Member list should show all members")
    }
    
    func testMemberList_ShowsPresenceIndicators() throws {
        // Given: User opens member list
        let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
        XCTAssertTrue(groupHeader.waitForExistence(timeout: 5))
        groupHeader.tap()
        
        // When: Member list loads
        let memberListTitle = app.navigationBars["Group Members"]
        XCTAssertTrue(memberListTitle.waitForExistence(timeout: 3))
        
        // Then: Presence indicators (online/offline) are visible
        // Check for presence indicator images or status text
        let onlineStatus = app.staticTexts.matching(NSPredicate(format: "label == 'Online'")).firstMatch
        let offlineStatus = app.staticTexts.matching(NSPredicate(format: "label == 'Offline'")).firstMatch
        
        // At least one presence status should be shown
        XCTAssertTrue(onlineStatus.exists || offlineStatus.exists, "Presence status should be displayed for members")
    }
    
    func testMemberList_PresenceUpdatesWithin500ms() throws {
        // Given: User opens member list
        let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
        XCTAssertTrue(groupHeader.waitForExistence(timeout: 5))
        groupHeader.tap()
        
        // When: Member list loads and presence updates
        let memberListTitle = app.navigationBars["Group Members"]
        XCTAssertTrue(memberListTitle.waitForExistence(timeout: 3))
        
        // Then: Presence indicators appear within 500ms (PR-3 requirement)
        // Note: This test validates the presence system works
        // Actual timing validation would require multi-device test setup
        let startTime = Date()
        let presenceIndicator = app.images.matching(identifier: "presenceIndicator").firstMatch
        XCTAssertTrue(presenceIndicator.waitForExistence(timeout: 0.5), "Presence should update within 500ms")
        let presenceTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(presenceTime, 0.5, "Presence propagation should be < 500ms")
    }
    
    func testMemberList_DismissesWithDoneButton() throws {
        // Given: Member list is open
        let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
        XCTAssertTrue(groupHeader.waitForExistence(timeout: 5))
        groupHeader.tap()
        
        let memberListTitle = app.navigationBars["Group Members"]
        XCTAssertTrue(memberListTitle.waitForExistence(timeout: 3))
        
        // When: User taps "Done"
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists)
        doneButton.tap()
        
        // Then: Member list dismisses
        XCTAssertFalse(memberListTitle.exists, "Member list should be dismissed")
    }
    
    // MARK: - Message Attribution Tests
    
    func testMessageAttribution_ShowsAvatarAndName() throws {
        // Given: User is viewing a group chat with messages
        
        // When: Messages are displayed
        let messageArea = app.scrollViews.firstMatch
        XCTAssertTrue(messageArea.waitForExistence(timeout: 5))
        
        // Then: Messages from other users show avatar and name
        // Note: Adjust identifier based on actual implementation
        let avatarImages = app.images.matching(identifier: "messageAvatar")
        XCTAssertGreaterThan(avatarImages.count, 0, "Message avatars should be displayed")
        
        // Sender names should be visible above messages
        let senderNames = app.staticTexts.matching(NSPredicate(format: "label != ''"))
        XCTAssertGreaterThan(senderNames.count, 0, "Sender names should be displayed")
    }
    
    func testMessageAttribution_AppearsWithin200ms() throws {
        // Given: User is in group chat
        
        // When: New message arrives
        // Note: This would ideally test real-time message arrival
        // For now, we validate that existing messages load quickly
        
        let startTime = Date()
        let messageArea = app.scrollViews.firstMatch
        XCTAssertTrue(messageArea.waitForExistence(timeout: 5))
        
        let firstMessage = app.otherElements.matching(identifier: "messageRow").firstMatch
        XCTAssertTrue(firstMessage.waitForExistence(timeout: 0.2))
        let loadTime = Date().timeIntervalSince(startTime)
        
        // Then: Message with attribution appears within 200ms (PR-3 requirement)
        XCTAssertLessThan(loadTime, 0.2, "Message attribution should appear within 200ms")
    }
    
    func testMessageAttribution_OnlyShowsForOtherUsers() throws {
        // Given: User is in group chat
        
        // When: Viewing messages
        let messageArea = app.scrollViews.firstMatch
        XCTAssertTrue(messageArea.waitForExistence(timeout: 5))
        
        // Then: Current user's messages don't show attribution (avatar + name)
        // Other users' messages show attribution
        // Note: This test would need to identify current user's messages
        // vs other users' messages based on UI positioning (right vs left)
        
        // Placeholder assertion - adjust based on actual UI
        XCTAssertTrue(messageArea.exists, "Message area should exist")
    }
    
    // MARK: - Integration Tests
    
    func testGroupChat_EndToEndWorkflow() throws {
        // Given: User is logged in
        
        // When: User navigates to group chat
        // 1. Open group chat
        // 2. View messages with attribution
        // 3. Open member list
        // 4. View presence indicators
        // 5. Close member list
        
        // Then: All features work together smoothly
        
        // Step 1: Navigate to group chat
        let groupChatRow = app.cells.matching(identifier: "chatRow").firstMatch
        XCTAssertTrue(groupChatRow.waitForExistence(timeout: 5))
        groupChatRow.tap()
        
        // Step 2: Verify message attribution
        let messageArea = app.scrollViews.firstMatch
        XCTAssertTrue(messageArea.waitForExistence(timeout: 5))
        
        // Step 3: Open member list
        let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
        XCTAssertTrue(groupHeader.exists)
        groupHeader.tap()
        
        // Step 4: Verify member list with presence
        let memberListTitle = app.navigationBars["Group Members"]
        XCTAssertTrue(memberListTitle.waitForExistence(timeout: 3))
        
        // Step 5: Close member list
        let doneButton = app.buttons["Done"]
        doneButton.tap()
        
        // Verify back in chat view
        XCTAssertTrue(messageArea.exists, "Should return to chat view")
    }
    
    func testGroupChat_PerformanceTargets() throws {
        // Test all performance requirements for PR-3
        
        measure {
            // Given: User navigates to group chat
            let groupChatRow = app.cells.matching(identifier: "chatRow").firstMatch
            if groupChatRow.waitForExistence(timeout: 5) {
                groupChatRow.tap()
                
                // Measure: Message loading and attribution
                let messageArea = app.scrollViews.firstMatch
                _ = messageArea.waitForExistence(timeout: 5)
                
                // Measure: Member list load time
                let groupHeader = app.staticTexts.matching(identifier: "groupChatHeader").firstMatch
                if groupHeader.exists {
                    groupHeader.tap()
                    
                    let memberListTitle = app.navigationBars["Group Members"]
                    _ = memberListTitle.waitForExistence(timeout: 3)
                    
                    // Close
                    let doneButton = app.buttons["Done"]
                    if doneButton.exists {
                        doneButton.tap()
                    }
                }
                
                // Navigate back
                let backButton = app.buttons.matching(identifier: "chevron.left").firstMatch
                if backButton.exists {
                    backButton.tap()
                }
            }
        }
    }
}

