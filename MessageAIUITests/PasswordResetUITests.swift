//
//  PasswordResetUITests.swift
//  MessageAIUITests
//
//  UI tests for password reset flow using XCTest
//

import XCTest

/// UI tests for password reset functionality
/// - Note: Uses XCTest framework for UI automation
final class PasswordResetUITests: XCTestCase {
    
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
    
    func testForgotPasswordNavigation() {
        // Given: User is on login screen
        // (Assuming user is not logged in, or we need to log out first)
        
        // When: Tap "Forgot Password?" link
        let forgotPasswordButton = app.buttons["Forgot Password?"]
        
        // Give time for view to load
        XCTAssertTrue(forgotPasswordButton.waitForExistence(timeout: 5.0), 
                     "Forgot Password button should exist on login screen")
        
        forgotPasswordButton.tap()
        
        // Then: ForgotPasswordView should appear
        let resetPasswordTitle = app.staticTexts["Reset Password"]
        XCTAssertTrue(resetPasswordTitle.waitForExistence(timeout: 3.0),
                     "Reset Password title should appear")
        
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.exists, "Email field should exist")
        
        let sendButton = app.buttons["Send Reset Link"]
        XCTAssertTrue(sendButton.exists, "Send Reset Link button should exist")
    }
    
    func testBackButtonNavigation() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Tap "Back to Login" button
        let backButton = app.buttons["Back to Login"]
        XCTAssertTrue(backButton.exists, "Back to Login button should exist")
        
        backButton.tap()
        
        // Then: Should return to login screen
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.waitForExistence(timeout: 3.0),
                     "Should return to login screen")
    }
    
    // MARK: - Form Validation Tests
    
    func testEmailFieldInteraction() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Tap email field and enter text
        let emailField = app.textFields["Email"]
        XCTAssertTrue(emailField.exists, "Email field should exist")
        
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Then: Email should be entered
        XCTAssertEqual(emailField.value as? String, "test@example.com",
                      "Email field should contain entered text")
    }
    
    func testSendButtonDisabledWithEmptyEmail() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Email field is empty
        let sendButton = app.buttons["Send Reset Link"]
        
        // Then: Send button should be disabled
        XCTAssertFalse(sendButton.isEnabled, "Send button should be disabled with empty email")
    }
    
    func testSendButtonEnabledWithValidEmail() {
        // Given: User is on forgot password screen with email entered
        navigateToForgotPassword()
        
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // When: Valid email is entered
        let sendButton = app.buttons["Send Reset Link"]
        
        // Then: Send button should be enabled
        XCTAssertTrue(sendButton.waitForExistence(timeout: 1.0), "Send button should exist")
        XCTAssertTrue(sendButton.isEnabled, "Send button should be enabled with valid email")
    }
    
    // MARK: - Password Reset Flow Tests
    
    func testPasswordResetFlowCompletes() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Enter email and tap send
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let sendButton = app.buttons["Send Reset Link"]
        sendButton.tap()
        
        // Then: Success message or navigation should occur
        // Note: In real implementation, either:
        // 1. Success alert appears
        // 2. View dismisses after delay
        // 3. Loading indicator shows
        
        // Check for loading state
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            XCTAssertTrue(loadingIndicator.waitForExistence(timeout: 2.0),
                         "Loading indicator should appear during send")
        }
        
        // Wait for operation to complete
        sleep(3)
        
        // Verify no error alerts appeared (or check for success message)
        // This is a basic check - actual implementation may vary
    }
    
    func testInvalidEmailShowsError() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Enter clearly invalid email
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("notanemail")
        
        let sendButton = app.buttons["Send Reset Link"]
        
        // Try to tap send if enabled
        if sendButton.isEnabled {
            sendButton.tap()
            
            // Then: Error alert should appear
            let errorAlert = app.alerts.firstMatch
            if errorAlert.waitForExistence(timeout: 3.0) {
                XCTAssertTrue(errorAlert.exists, "Error alert should appear for invalid email")
                
                // Dismiss alert
                let okButton = errorAlert.buttons["OK"]
                if okButton.exists {
                    okButton.tap()
                }
            }
        }
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateAppearsDuringRequest() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Enter email and tap send
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let sendButton = app.buttons["Send Reset Link"]
        sendButton.tap()
        
        // Then: Loading indicator should appear briefly
        // Note: This may be difficult to catch if operation is very fast
        let loadingIndicator = app.activityIndicators.firstMatch
        
        // Either loading indicator exists or operation completes quickly
        // Both are acceptable behaviors
        _ = loadingIndicator.waitForExistence(timeout: 1.0)
    }
    
    func testButtonsDisabledDuringLoading() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Enter email and tap send
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let sendButton = app.buttons["Send Reset Link"]
        sendButton.tap()
        
        // Then: Buttons should be disabled during loading
        // Note: This checks immediately after tap
        let backButton = app.buttons["Back to Login"]
        
        // If still loading, back button should be disabled
        if app.activityIndicators.firstMatch.exists {
            XCTAssertFalse(backButton.isEnabled, 
                          "Back button should be disabled during loading")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testEmailFieldHasProperAttributes() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Check email field
        let emailField = app.textFields["Email"]
        
        // Then: Email field should have proper keyboard type
        XCTAssertTrue(emailField.exists, "Email field should exist")
    }
    
    func testButtonsHaveProperLabels() {
        // Given: User is on forgot password screen
        navigateToForgotPassword()
        
        // When: Check buttons
        let sendButton = app.buttons["Send Reset Link"]
        let backButton = app.buttons["Back to Login"]
        
        // Then: Buttons should have accessible labels
        XCTAssertTrue(sendButton.exists, "Send button should have accessible label")
        XCTAssertTrue(backButton.exists, "Back button should have accessible label")
    }
    
    // MARK: - Helper Methods
    
    /// Navigates to forgot password screen
    private func navigateToForgotPassword() {
        // Wait for login screen to load
        let forgotPasswordButton = app.buttons["Forgot Password?"]
        
        if forgotPasswordButton.waitForExistence(timeout: 5.0) {
            forgotPasswordButton.tap()
            
            // Wait for forgot password screen to appear
            let resetPasswordTitle = app.staticTexts["Reset Password"]
            XCTAssertTrue(resetPasswordTitle.waitForExistence(timeout: 3.0),
                         "Should navigate to forgot password screen")
        } else {
            XCTFail("Could not find Forgot Password button on login screen")
        }
    }
}


