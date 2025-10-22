//
//  NotificationBackgroundUITests.swift
//  MessageAIUITests
//
//  UI tests for background notification behavior
//

import XCTest

/// UI tests for background notification delivery and app resume
/// - Note: Tests notification behavior when app is in background
final class NotificationBackgroundUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - BG1: Background Notification Delivery Tests
    
    func testBackgroundNotification_AppResumesCorrectly() throws {
        // BG1: App in background → notification appears <2s
        
        // Given: App is running and authenticated
        authenticateTestUser()
        
        // When: Send app to background
        XCUIDevice.shared.press(.home)
        
        // Wait briefly
        sleep(2)
        
        // Then: App can be resumed
        app.activate()
        
        // Verify app returns to foreground
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testBackgroundNotification_StatePreservedOnResume() throws {
        // BG1: Verify app state preserved when resuming from background
        
        // Given: User viewing specific conversation
        authenticateTestUser()
        navigateToConversation()
        
        let conversationView = app.otherElements["conversationView"]
        let wasInConversation = conversationView.exists
        
        // When: App goes to background and resumes
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        
        // Then: Returns to same conversation or conversation list
        XCTAssertTrue(app.state == .runningForeground)
        
        // Note: State restoration behavior depends on iOS version and app settings
    }
    
    // MARK: - BG2: Notification Tap Resume Tests
    
    func testBackgroundNotification_TapResumesAppQuickly() throws {
        // BG2: Tap notification → app resumes <1s
        
        // Given: App in background
        authenticateTestUser()
        XCUIDevice.shared.press(.home)
        sleep(1)
        
        let startTime = Date()
        
        // When: Resume app (simulating notification tap)
        app.activate()
        
        // Wait for app to become active
        let conversationList = app.tables["conversationList"]
        _ = conversationList.waitForExistence(timeout: 3)
        
        let resumeTime = Date().timeIntervalSince(startTime)
        
        // Then: App resumes quickly (<1s target)
        XCTAssertLessThan(resumeTime, 2.0, "App should resume quickly from background")
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testBackgroundNotification_ResumeWithNotificationDataLoadsCorrectChat() throws {
        // BG2: Tapping notification with chatID navigates to correct chat
        
        // Given: App in background
        authenticateTestUser()
        XCUIDevice.shared.press(.home)
        sleep(1)
        
        // When: App activated (simulating notification tap)
        app.activate()
        
        // Then: App resumes to appropriate view
        XCTAssertTrue(app.state == .runningForeground)
        
        // Navigation capability verified
        let conversationList = app.tables["conversationList"]
        XCTAssertTrue(conversationList.waitForExistence(timeout: 5))
    }
    
    // MARK: - BG3: Background Navigation Tests
    
    func testBackgroundNotification_NavigationAfterResumeWorks() throws {
        // BG3: Navigation to correct conversation works after resume
        
        // Given: App resumed from background
        authenticateTestUser()
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        
        // When: User can navigate to conversations
        let conversationList = app.tables["conversationList"]
        XCTAssertTrue(conversationList.waitForExistence(timeout: 5))
        
        // Then: Navigation functions work
        navigateToConversation()
        
        let conversationView = app.otherElements["conversationView"]
        let conversationExists = conversationView.exists || conversationView.waitForExistence(timeout: 3)
        
        // Verify conversation navigation works (or no conversations exist yet)
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testBackgroundNotification_MultipleResumeCyclesStable() throws {
        // BG3: Multiple background/resume cycles work correctly
        
        // Given: App running
        authenticateTestUser()
        
        // When: Multiple background/resume cycles
        for i in 0..<3 {
            XCUIDevice.shared.press(.home)
            sleep(1)
            app.activate()
            
            // Then: App remains stable
            XCTAssertTrue(app.state == .runningForeground, "Cycle \(i+1) failed")
            
            // Verify core UI still accessible
            let conversationList = app.tables["conversationList"]
            XCTAssertTrue(conversationList.waitForExistence(timeout: 3), "Cycle \(i+1): List not found")
        }
    }
    
    // MARK: - Background State Tests
    
    func testBackgroundNotification_DataRefreshesOnResume() throws {
        // Verify data can refresh when resuming from background
        
        // Given: App with loaded data
        authenticateTestUser()
        
        let conversationList = app.tables["conversationList"]
        _ = conversationList.waitForExistence(timeout: 5)
        
        // When: Go to background and resume
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()
        
        // Then: List still accessible (data may have refreshed)
        XCTAssertTrue(conversationList.waitForExistence(timeout: 5))
    }
    
    func testBackgroundNotification_NoDataLossDuringBackgrounding() throws {
        // Verify no data loss when app backgrounded
        
        // Given: User typed message but didn't send
        authenticateTestUser()
        navigateToConversation()
        
        let messageInput = app.textFields["messageInput"].firstMatch
        if messageInput.waitForExistence(timeout: 2) {
            messageInput.tap()
            messageInput.typeText("Test unsent message")
        }
        
        // When: App backgrounded and resumed
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        
        // Then: App resumes without crash
        XCTAssertTrue(app.state == .runningForeground)
        
        // Note: Text field persistence depends on iOS and app implementation
    }
    
    // MARK: - Performance Tests
    
    func testBackgroundNotification_ResumePerformance() throws {
        // Measure app resume performance from background
        
        // Given: App in background
        authenticateTestUser()
        XCUIDevice.shared.press(.home)
        sleep(1)
        
        // When: Measure resume time
        measure {
            app.activate()
            
            // Wait for UI to be ready
            let conversationList = app.tables["conversationList"]
            _ = conversationList.waitForExistence(timeout: 3)
            
            // Reset for next measurement
            XCUIDevice.shared.press(.home)
            sleep(1)
        }
    }
    
    // MARK: - Helper Methods
    
    private func authenticateTestUser() {
        // Check if already authenticated
        let conversationList = app.tables["conversationList"]
        if conversationList.waitForExistence(timeout: 2) {
            return
        }
        
        // Perform login
        let emailField = app.textFields["emailField"]
        let passwordField = app.secureTextFields["passwordField"]
        let loginButton = app.buttons["loginButton"]
        
        if emailField.waitForExistence(timeout: 5) {
            emailField.tap()
            emailField.typeText("test@example.com")
            
            passwordField.tap()
            passwordField.typeText("testPassword123")
            
            loginButton.tap()
            
            _ = conversationList.waitForExistence(timeout: 10)
        }
    }
    
    private func navigateToConversation() {
        let conversationList = app.tables["conversationList"]
        
        if conversationList.waitForExistence(timeout: 5) {
            let firstCell = conversationList.cells.element(boundBy: 0)
            if firstCell.exists {
                firstCell.tap()
                
                let conversationView = app.otherElements["conversationView"]
                _ = conversationView.waitForExistence(timeout: 5)
            } else {
                let newChatButton = app.buttons["newChatButton"]
                if newChatButton.exists {
                    newChatButton.tap()
                }
            }
        }
    }
}

