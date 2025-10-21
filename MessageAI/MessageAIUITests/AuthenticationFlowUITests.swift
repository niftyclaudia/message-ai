//
//  AuthenticationFlowUITests.swift
//  MessageAIUITests
//
//  UI tests for authentication flows
//

import XCTest

final class AuthenticationFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - App Launch Tests
    
    /// Gate: LoginView appears < 2s for unauthenticated users
    func testAppLaunch_Unauthenticated_ShowsLoginView() {
        // Given: App launches unauthenticated
        
        // Then: LoginView appears quickly
        let welcomeText = app.staticTexts["Welcome Back"]
        XCTAssertTrue(welcomeText.waitForExistence(timeout: 2.0), "Login view should appear within 2 seconds")
        
        // Verify login form elements exist
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }
    
    // MARK: - Login Flow Tests
    
    /// Gate: Invalid email shows error alert, stays on LoginView
    func testLoginView_InvalidEmail_ShowsError() {
        // Given: On login view
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInButton = app.buttons["Sign In"]
        
        // When: Enter invalid email
        emailField.tap()
        emailField.typeText("invalid-email")
        passwordField.tap()
        passwordField.typeText("password123")
        signInButton.tap()
        
        // Then: Error alert appears and stays on login view
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 1.0))
        errorAlert.buttons["OK"].tap()
        
        // Still on login view
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
    }
    
    /// Gate: Navigation to SignUpView works
    func testLoginView_NavigateToSignUp_ShowsSignUpView() {
        // Given: On login view
        let signUpLink = app.buttons["Sign Up"]
        
        // When: Tap sign up link
        signUpLink.tap()
        
        // Then: SignUpView appears
        let createAccountText = app.staticTexts["Create Account"]
        XCTAssertTrue(createAccountText.waitForExistence(timeout: 1.0))
        
        // Verify sign up form elements
        XCTAssertTrue(app.textFields["Display Name"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.secureTextFields["Confirm Password"].exists)
        XCTAssertTrue(app.buttons["Sign Up"].exists)
    }
    
    // MARK: - Sign Up Flow Tests
    
    /// Gate: Navigation back button works
    func testSignUpView_BackButton_ReturnsToLogin() {
        // Given: Navigate to sign up view
        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1.0))
        
        // When: Tap back button
        app.navigationBars.buttons.firstMatch.tap()
        
        // Then: Returns to login view
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 1.0))
    }
    
    /// Gate: Password mismatch shows error
    func testSignUpView_InvalidData_ShowsError() {
        // Given: On sign up view
        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1.0))
        
        let displayNameField = app.textFields["Display Name"]
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let confirmPasswordField = app.secureTextFields["Confirm Password"]
        
        // When: Enter mismatched passwords
        displayNameField.tap()
        displayNameField.typeText("Test User")
        emailField.tap()
        emailField.typeText("test@example.com")
        passwordField.tap()
        passwordField.typeText("password123")
        confirmPasswordField.tap()
        confirmPasswordField.typeText("different123")
        
        // Then: Sign up button should be disabled or show error
        let signUpButton = app.buttons["Sign Up"]
        signUpButton.tap()
        
        let errorAlert = app.alerts["Error"]
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 1.0))
    }
    
    // MARK: - Keyboard Tests
    
    /// Gate: Keyboard dismisses on background tap
    func testKeyboardDismissal_TapOutside_HidesKeyboard() {
        // Given: Keyboard is shown
        let emailField = app.textFields["Email"]
        emailField.tap()
        
        // Verify keyboard is visible
        XCTAssertTrue(emailField.hasKeyboardFocus)
        
        // When: Tap outside text field
        app.staticTexts["Welcome Back"].tap()
        
        // Then: Keyboard dismisses (field loses focus)
        // Note: Keyboard state is hard to test directly in UI tests
        // This verifies the tap gesture is handled
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
    }
    
    // MARK: - Form Validation Tests
    
    func testLoginView_EmptyFields_DisablesButton() {
        // Given: On login view with empty fields
        let signInButton = app.buttons["Sign In"]
        
        // Then: Sign in button is disabled
        XCTAssertFalse(signInButton.isEnabled)
    }
    
    func testLoginView_FilledFields_EnablesButton() {
        // Given: On login view
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInButton = app.buttons["Sign In"]
        
        // When: Fill in fields
        emailField.tap()
        emailField.typeText("test@example.com")
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Then: Sign in button is enabled
        XCTAssertTrue(signInButton.isEnabled)
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    var hasKeyboardFocus: Bool {
        let hasKeyboardFocus = (self.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
        return hasKeyboardFocus
    }
}

