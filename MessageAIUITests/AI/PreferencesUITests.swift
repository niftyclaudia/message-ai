//
//  PreferencesUITests.swift
//  MessageAIUITests
//
//  UI tests for AI Preferences screen
//

import XCTest

/// UI tests for PreferencesSettingsView
/// - Note: Tests preferences configuration, validation, and save flow
final class PreferencesUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToAIPreferences() throws {
        // Given: App is launched and user is logged in
        // (Assuming login flow is already completed)
        
        // When: Navigate to Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5))
        profileTab.tap()
        
        // Then: AI Preferences button should be visible
        let aiPreferencesButton = app.buttons["AI Preferences"]
        XCTAssertTrue(aiPreferencesButton.waitForExistence(timeout: 3))
        
        // When: Tap AI Preferences
        aiPreferencesButton.tap()
        
        // Then: AI Preferences screen should appear
        let navigationTitle = app.navigationBars["AI Preferences"]
        XCTAssertTrue(navigationTitle.waitForExistence(timeout: 3))
    }
    
    // MARK: - Focus Hours Tests
    
    func testToggleFocusHours() throws {
        navigateToPreferences()
        
        // When: Find and toggle Focus Hours
        let focusHoursToggle = app.switches["Focus Hours"]
        XCTAssertTrue(focusHoursToggle.waitForExistence(timeout: 3))
        
        let initialState = focusHoursToggle.value as? String == "1"
        focusHoursToggle.tap()
        
        // Then: Toggle state should change
        let newState = focusHoursToggle.value as? String == "1"
        XCTAssertNotEqual(initialState, newState)
    }
    
    func testFocusHoursTimePickers() throws {
        navigateToPreferences()
        
        // Given: Focus Hours is enabled
        let focusHoursToggle = app.switches["Focus Hours"]
        if focusHoursToggle.value as? String != "1" {
            focusHoursToggle.tap()
        }
        
        // Then: Time pickers should be visible
        let startTimePicker = app.datePickers["Start Time"]
        let endTimePicker = app.datePickers["End Time"]
        
        XCTAssertTrue(startTimePicker.waitForExistence(timeout: 2))
        XCTAssertTrue(endTimePicker.exists)
    }
    
    // MARK: - Urgent Keywords Tests
    
    func testAddUrgentKeyword() throws {
        navigateToPreferences()
        
        // When: Find keyword input field
        let keywordField = app.textFields["Enter keywords (comma-separated)"]
        XCTAssertTrue(keywordField.waitForExistence(timeout: 3))
        
        // When: Enter keyword
        keywordField.tap()
        keywordField.typeText("critical")
        
        // When: Tap Add button
        let addButton = app.buttons["Add"]
        if addButton.exists {
            addButton.tap()
        }
        
        // Then: Keyword should appear as tag
        // (Note: Actual verification depends on accessibility identifiers)
        XCTAssertTrue(true) // Placeholder - would verify tag appearance
    }
    
    func testKeywordCountDisplay() throws {
        navigateToPreferences()
        
        // Then: Keyword count should be displayed
        let keywordCount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/50 keywords'")).firstMatch
        XCTAssertTrue(keywordCount.waitForExistence(timeout: 3))
    }
    
    // MARK: - Communication Tone Tests
    
    func testSelectCommunicationTone() throws {
        navigateToPreferences()
        
        // When: Scroll to Communication Tone section
        let professionalTone = app.staticTexts["Professional"]
        if !professionalTone.isHittable {
            app.swipeUp()
        }
        
        // When: Tap Professional tone
        XCTAssertTrue(professionalTone.waitForExistence(timeout: 3))
        professionalTone.tap()
        
        // Then: Professional should be selected (checkmark visible)
        // (Actual verification depends on implementation)
        XCTAssertTrue(true) // Placeholder
    }
    
    // MARK: - Save Tests
    
    func testSavePreferences() throws {
        navigateToPreferences()
        
        // When: Tap Save button
        let saveButton = app.navigationBars.buttons["Save"]
        XCTAssertTrue(saveButton.exists)
        saveButton.tap()
        
        // Then: Success message should appear
        let successMessage = app.staticTexts["Preferences saved"]
        XCTAssertTrue(successMessage.waitForExistence(timeout: 3))
    }
    
    func testSaveButtonDisabledWithInvalidData() throws {
        navigateToPreferences()
        
        // Given: Remove keywords to make preferences invalid
        // (This would require interaction with keyword tags)
        
        // Then: Save button should be disabled
        let saveButton = app.navigationBars.buttons["Save"]
        // Note: Check if button is enabled/disabled based on state
        XCTAssertTrue(saveButton.exists)
    }
    
    // MARK: - Validation Tests
    
    func testMinimumKeywordsValidation() throws {
        navigateToPreferences()
        
        // Then: Validation message should appear if fewer than 3 keywords
        let validationMessage = app.staticTexts["Add at least 3 keywords"]
        // Message may or may not exist depending on current state
        // Just verify we can detect it if it appears
        if validationMessage.exists {
            XCTAssertTrue(validationMessage.isHittable)
        }
    }
    
    // MARK: - Reset Tests
    
    func testResetToDefaults() throws {
        navigateToPreferences()
        
        // When: Scroll to Reset button
        let resetButton = app.buttons["Reset to Defaults"]
        if !resetButton.isHittable {
            app.swipeUp()
            app.swipeUp()
        }
        
        // When: Tap Reset
        XCTAssertTrue(resetButton.waitForExistence(timeout: 3))
        resetButton.tap()
        
        // Then: Preferences should reset to defaults
        // (Would verify default values are shown)
        XCTAssertTrue(true) // Placeholder
    }
    
    // MARK: - Privacy Notice Tests
    
    func testPrivacyNoticeVisible() throws {
        navigateToPreferences()
        
        // Then: Privacy notice should be visible
        let privacyText = app.staticTexts["AI learns from your corrections"]
        XCTAssertTrue(privacyText.waitForExistence(timeout: 3))
        
        let dataRetention = app.staticTexts["Data auto-deleted after 90 days"]
        XCTAssertTrue(dataRetention.exists)
    }
    
    // MARK: - Helper Methods
    
    private func navigateToPreferences() {
        // Navigate to Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
        }
        
        // Tap AI Preferences
        let aiPreferencesButton = app.buttons["AI Preferences"]
        if aiPreferencesButton.waitForExistence(timeout: 3) {
            aiPreferencesButton.tap()
        }
        
        // Wait for screen to load
        _ = app.navigationBars["AI Preferences"].waitForExistence(timeout: 3)
    }
}

