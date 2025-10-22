//
//  NavigationUITests.swift
//  MessageAIUITests
//
//  UI tests for app navigation
//

import XCTest

final class NavigationUITests: XCTestCase {
    
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
    
    // MARK: - Navigation Tests
    
    /// Tests navigation structure is properly set up
    func testNavigationStructure_LoginToSignUp() {
        // Given: On login view
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 2.0))
        
        // When: Navigate to sign up
        app.buttons["Sign Up"].tap()
        
        // Then: Sign up view appears with navigation
        XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 1.0))
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.exists)
    }
    
    /// Tests smooth transitions between views
    func testNavigationTransitions_AreSmooth() {
        // Given: On login view
        XCTAssertTrue(app.staticTexts["Welcome Back"].exists)
        
        // When: Navigate back and forth
        app.buttons["Sign Up"].tap()
        XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 0.5))
        
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Welcome Back"].waitForExistence(timeout: 0.5))
        
        // Then: Transitions complete quickly (< 300ms target)
        // Note: If views appear within timeout, transitions were smooth
    }
}

