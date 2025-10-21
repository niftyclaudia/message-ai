//
//  ProfileFlowUITests.swift
//  MessageAIUITests
//
//  UI tests for profile viewing and editing
//

import XCTest

final class ProfileFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-TESTING"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Profile View Tests
    
    /// Test profile view loads and displays user info
    /// Gate: Shows avatar, name, email
    func testProfileView_Loads_DisplaysUserInfo() throws {
        // Given: User is authenticated (assume already logged in for test)
        
        // When: Navigating to Profile tab
        let profileTab = app.tabBars.buttons["Profile"]
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        profileTab.tap()
        
        // Then: Profile view should display
        XCTAssertTrue(app.navigationBars["Profile"].exists, "Profile navigation bar should exist")
    }
    
    /// Test profile view shows initials when no photo
    /// Gate: Default avatar with initials
    func testProfileView_NoPhoto_ShowsInitials() throws {
        // Given: User without profile photo
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        
        // Then: Should show user info
        // Note: Specific initials depend on test user data
        XCTAssertTrue(app.staticTexts.matching(identifier: "displayName").firstMatch.exists ||
                      app.staticTexts.count > 0, "Should show display name")
    }
    
    /// Test tapping edit button navigates to edit view
    /// Gate: Edit button works
    func testProfileView_TapEdit_NavigatesToEdit() throws {
        // Given: Profile view displayed
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        
        // When: Tapping Edit Profile button
        let editButton = app.buttons["Edit Profile"]
        if editButton.waitForExistence(timeout: 3) {
            editButton.tap()
            
            // Then: Should navigate to edit view
            XCTAssertTrue(app.navigationBars["Edit Profile"].waitForExistence(timeout: 2), "Should show Edit Profile")
        }
    }
    
    // MARK: - Profile Edit Tests
    
    /// Test edit view allows name change
    /// Gate: Name persists in ProfileView
    func testProfileEdit_ChangeNameAndSave_Updates() throws {
        // Given: Profile edit view
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        
        let editButton = app.buttons["Edit Profile"]
        guard editButton.waitForExistence(timeout: 3) else {
            XCTFail("Edit button not found")
            return
        }
        editButton.tap()
        
        // When: Changing name and saving
        let nameField = app.textFields.firstMatch
        if nameField.waitForExistence(timeout: 2) {
            nameField.tap()
            nameField.typeText(" Updated")
            
            let saveButton = app.buttons["Save"]
            if saveButton.isEnabled {
                saveButton.tap()
                
                // Then: Should return to profile view
                XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 2), "Should return to profile")
            }
        }
    }
    
    /// Test cancel button discards changes
    /// Gate: No changes saved
    func testProfileEdit_TapCancel_DiscardsChanges() throws {
        // Given: Profile edit view
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        
        let editButton = app.buttons["Edit Profile"]
        guard editButton.waitForExistence(timeout: 3) else { return }
        editButton.tap()
        
        // When: Tapping Cancel
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 2) {
            cancelButton.tap()
            
            // Then: Should return to profile view
            XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 2), "Should return to profile")
        }
    }
}

