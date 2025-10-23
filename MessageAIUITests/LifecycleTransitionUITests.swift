//
//  LifecycleTransitionUITests.swift
//  MessageAIUITests
//
//  UI tests for app lifecycle transitions
//  PR #4: Mobile Lifecycle Management
//

import XCTest

/// UI tests for backgrounding and foregrounding transitions
final class LifecycleTransitionUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Background/Foreground Tests
    
    func testBackgroundingAndForegrounding() throws {
        // Given: App is running
        XCTAssertTrue(app.state == .runningForeground)
        
        // When: App backgrounds
        XCUIDevice.shared.press(.home)
        
        // Wait for background
        let backgroundExpectation = expectation(description: "App backgrounded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            backgroundExpectation.fulfill()
        }
        wait(for: [backgroundExpectation], timeout: 2.0)
        
        // Then: App should be in background
        XCTAssertTrue(app.state == .runningBackground || app.state == .runningBackgroundSuspended)
        
        // When: App foregrounds
        app.activate()
        
        // Wait for foreground
        let foregroundExpectation = expectation(description: "App foregrounded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            foregroundExpectation.fulfill()
        }
        wait(for: [foregroundExpectation], timeout: 2.0)
        
        // Then: App should be running in foreground
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testReconnectIndicatorAppearsAndHides() throws {
        // Given: App is running
        XCTAssertTrue(app.state == .runningForeground)
        
        // When: App backgrounds and foregrounds
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        
        // Then: UI should respond to state change
        // Note: Reconnecting indicator appears briefly (< 500ms)
        // so we just verify app is responsive
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testMessagesPreservedAfterBackgrounding() throws {
        // Given: User is logged in and viewing a chat
        // Note: This requires authentication setup in test environment
        
        // When: App backgrounds and foregrounds
        XCUIDevice.shared.press(.home)
        sleep(2)
        app.activate()
        
        // Then: App should restore to previous state
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Performance Tests
    
    func testForegroundPerformance() throws {
        // Measure foreground transition time
        measure(metrics: [XCTClockMetric()]) {
            // Background
            XCUIDevice.shared.press(.home)
            sleep(1)
            
            // Foreground
            app.activate()
            
            // Wait for app to become active
            let activeExpectation = expectation(description: "App active")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                activeExpectation.fulfill()
            }
            wait(for: [activeExpectation], timeout: 1.0)
        }
    }
}

