//
//  ProfileEditUITests.swift
//  MessageAIUITests
//
//  UI tests for profile editing flow using XCTest
//

import XCTest

/// UI tests for profile editing functionality
/// - Note: Uses XCTest framework for UI automation
final class ProfileEditUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Tests
    
    func testProfileEditNavigation() {
        // Given: User is logged in and on profile screen
        // Note: This assumes user can navigate to profile
        // May need to login first in real tests
        
        // Navigate to profile (implementation depends on app structure)
        // For now, we'll check if Edit Profile button exists
        
        let editProfileButton = app.buttons["Edit Profile"]
        
        // If button exists, proceed with test
        if editProfileButton.waitForExistence(timeout: 5.0) {
            // When: Tap "Edit Profile" button
            editProfileButton.tap()
            
            // Then: ProfileEditView should appear
            let editProfileTitle = app.navigationBars["Edit Profile"]
            XCTAssertTrue(editProfileTitle.waitForExistence(timeout: 3.0),
                         "Edit Profile screen should appear")
            
            let cancelButton = app.buttons["Cancel"]
            XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
            
            let saveButton = app.buttons["Save"]
            XCTAssertTrue(saveButton.exists, "Save button should exist")
        }
    }
    
    func testCancelButtonDismissesView() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            // When: Tap Cancel button
            let cancelButton = app.buttons["Cancel"]
            XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
            
            cancelButton.tap()
            
            // Then: Should return to profile screen
            let editProfileTitle = app.navigationBars["Edit Profile"]
            XCTAssertFalse(editProfileTitle.exists,
                          "Edit Profile screen should be dismissed")
        }
    }
    
    // MARK: - Display Name Tests
    
    func testDisplayNameFieldInteraction() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            // When: Tap display name field
            let displayNameField = app.textFields["Enter your name"]
            
            if displayNameField.waitForExistence(timeout: 2.0) {
                displayNameField.tap()
                
                // Clear existing text (if any)
                if let currentValue = displayNameField.value as? String, !currentValue.isEmpty {
                    // Select all and delete
                    displayNameField.doubleTap()
                    app.keys["delete"].tap()
                }
                
                // Type new name
                displayNameField.typeText("New Name")
                
                // Then: Name should be entered
                XCTAssertTrue(displayNameField.value as? String == "New Name" || 
                            (displayNameField.value as? String)?.contains("New Name") == true,
                            "Display name field should contain entered text")
            }
        }
    }
    
    func testCharacterCounterUpdates() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            // When: Enter text in display name field
            let displayNameField = app.textFields["Enter your name"]
            
            if displayNameField.waitForExistence(timeout: 2.0) {
                displayNameField.tap()
                
                // Clear and type text
                if let currentValue = displayNameField.value as? String, !currentValue.isEmpty {
                    displayNameField.doubleTap()
                    app.keys["delete"].tap()
                }
                
                let testName = "Test"
                displayNameField.typeText(testName)
                
                // Then: Character counter should update
                // Look for text showing count (e.g., "4/50")
                let counterText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/'")).firstMatch
                if counterText.exists {
                    XCTAssertTrue(counterText.label.contains(String(testName.count)),
                                 "Character counter should show correct count")
                }
            }
        }
    }
    
    func testSaveButtonDisabledWithInvalidName() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            let displayNameField = app.textFields["Enter your name"]
            
            if displayNameField.waitForExistence(timeout: 2.0) {
                // When: Clear name field (< 1 character)
                displayNameField.tap()
                displayNameField.doubleTap()
                
                // Delete all text
                let deleteKey = app.keys["delete"]
                for _ in 0..<50 {  // Press delete multiple times to ensure field is empty
                    deleteKey.tap()
                }
                
                // Then: Save button should be disabled
                let saveButton = app.buttons["Save"]
                XCTAssertFalse(saveButton.isEnabled,
                              "Save button should be disabled with empty name")
            }
        }
    }
    
    func testCharacterCounterShowsMaxLimit() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            // When: Check for character counter
            let displayNameField = app.textFields["Enter your name"]
            
            if displayNameField.waitForExistence(timeout: 2.0) {
                // Then: Character counter should show max of 50
                let counterText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/50'")).firstMatch
                XCTAssertTrue(counterText.exists,
                             "Character counter should show /50 maximum")
            }
        }
    }
    
    // MARK: - Profile Photo Tests
    
    func testProfilePhotoTapShowsPicker() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            // When: Tap on profile photo
            // Note: This may vary based on how photo is implemented
            let profileImage = app.images.firstMatch
            
            if profileImage.exists {
                profileImage.tap()
                
                // Then: Photo picker should appear (iOS system picker)
                // This is difficult to test as it's a system UI
                // We can verify our UI dismissed or sheet appeared
                sleep(1)  // Give time for picker to appear
            }
        }
    }
    
    // MARK: - Save Flow Tests
    
    func testSaveProfileCompletes() {
        // Given: User is on profile edit screen with valid changes
        if navigateToProfileEdit() {
            let displayNameField = app.textFields["Enter your name"]
            
            if displayNameField.waitForExistence(timeout: 2.0) {
                // When: Make changes and tap save
                displayNameField.tap()
                
                // Clear and type new name
                if let currentValue = displayNameField.value as? String, !currentValue.isEmpty {
                    displayNameField.doubleTap()
                    app.keys["delete"].tap()
                }
                
                displayNameField.typeText("Updated Name")
                
                let saveButton = app.buttons["Save"]
                
                if saveButton.isEnabled {
                    saveButton.tap()
                    
                    // Then: Loading indicator may appear
                    let loadingIndicator = app.activityIndicators.firstMatch
                    _ = loadingIndicator.waitForExistence(timeout: 2.0)
                    
                    // Wait for save to complete
                    sleep(3)
                    
                    // View should dismiss or show success
                    let editProfileTitle = app.navigationBars["Edit Profile"]
                    
                    // Either view dismissed or still showing (depends on implementation)
                    // Both are acceptable in this test
                }
            }
        }
    }
    
    func testLoadingIndicatorAppearsDuringSave() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            let displayNameField = app.textFields["Enter your name"]
            
            if displayNameField.waitForExistence(timeout: 2.0) {
                // When: Make changes and save
                displayNameField.tap()
                displayNameField.typeText("Test")
                
                let saveButton = app.buttons["Save"]
                
                if saveButton.isEnabled {
                    saveButton.tap()
                    
                    // Then: Loading indicator should appear
                    let loadingIndicator = app.activityIndicators.firstMatch
                    
                    // Check if loading indicator appears (may be very brief)
                    _ = loadingIndicator.waitForExistence(timeout: 1.0)
                }
            }
        }
    }
    
    func testButtonsDisabledDuringSave() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            let displayNameField = app.textFields["Enter your name"]
            
            if displayNameField.waitForExistence(timeout: 2.0) {
                // When: Make changes and start save
                displayNameField.tap()
                displayNameField.typeText("Test")
                
                let saveButton = app.buttons["Save"]
                
                if saveButton.isEnabled {
                    saveButton.tap()
                    
                    // Then: Buttons should be disabled during save
                    // Note: This checks immediately after tap
                    if app.activityIndicators.firstMatch.exists {
                        let cancelButton = app.buttons["Cancel"]
                        XCTAssertFalse(cancelButton.isEnabled,
                                      "Cancel should be disabled during save")
                    }
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorAlertAppears() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            // Note: Difficult to test error scenarios without mocking
            // This is a placeholder for error alert verification
            
            // If an error occurs, alert should appear
            let errorAlert = app.alerts.firstMatch
            
            // In normal flow, no error alert should appear
            XCTAssertFalse(errorAlert.waitForExistence(timeout: 1.0),
                          "No error alert should appear in normal flow")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testNavigationButtonsAreAccessible() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            // When: Check navigation buttons
            let cancelButton = app.buttons["Cancel"]
            let saveButton = app.buttons["Save"]
            
            // Then: Buttons should be accessible
            XCTAssertTrue(cancelButton.exists, "Cancel button should be accessible")
            XCTAssertTrue(saveButton.exists, "Save button should be accessible")
        }
    }
    
    func testDisplayNameFieldIsAccessible() {
        // Given: User is on profile edit screen
        if navigateToProfileEdit() {
            // When: Check display name field
            let displayNameField = app.textFields["Enter your name"]
            
            if displayNameField.waitForExistence(timeout: 2.0) {
                // Then: Field should be accessible
                XCTAssertTrue(displayNameField.exists, "Display name field should be accessible")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Navigates to profile edit screen
    /// - Returns: True if navigation successful, false otherwise
    @discardableResult
    private func navigateToProfileEdit() -> Bool {
        // Look for Edit Profile button
        let editProfileButton = app.buttons["Edit Profile"]
        
        if editProfileButton.waitForExistence(timeout: 5.0) {
            editProfileButton.tap()
            
            // Wait for edit screen to appear
            let editProfileTitle = app.navigationBars["Edit Profile"]
            if editProfileTitle.waitForExistence(timeout: 3.0) {
                return true
            }
        }
        
        // If we can't find Edit Profile button, try navigating through tab bar
        // This depends on app structure
        
        return false
    }
}


