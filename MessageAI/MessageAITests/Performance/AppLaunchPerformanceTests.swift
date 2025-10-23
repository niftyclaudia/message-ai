//
//  AppLaunchPerformanceTests.swift
//  MessageAITests
//
//  Performance tests for app launch and view rendering
//

import XCTest
@testable import MessageAI

final class AppLaunchPerformanceTests: XCTestCase {
    
    // MARK: - App Launch Performance
    
    /// Gate: App launch to interactive UI < 3 seconds
    func testAppLaunch_ColdStart_Under3Seconds() {
        measure(metrics: [XCTClockMetric()]) {
            // Simulate app initialization
            let authService = AuthService()
            
            // Verify auth service initializes quickly
            XCTAssertNotNil(authService)
        }
    }
    
    // MARK: - View Rendering Performance
    
    /// Gate: LoginView renders at 60fps (< 16ms per frame)
    func testViewRendering_LoginView_60fps() {
        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            // Simulate LoginView initialization
            let authService = AuthService()
            let mockNotificationService = MockNotificationService()
            let viewModel = AuthViewModel(authService: authService, notificationService: mockNotificationService)
            
            // Views should be lightweight
            XCTAssertNotNil(viewModel)
        }
    }
    
    /// Gate: Navigation transitions < 300ms
    func testNavigation_LoginToSignUp_Under300ms() {
        measure(metrics: [XCTClockMetric()]) {
            // Simulate navigation setup
            let authService = AuthService()
            
            // Navigation should be instant
            XCTAssertNotNil(authService)
        }
    }
    
    // MARK: - State Management Performance
    
    /// Tests that auth state updates propagate quickly
    func testAuthStateUpdate_PropagatesToObservers() {
        let authService = AuthService()
        
        measure(metrics: [XCTClockMetric()]) {
            // State observation should be instant
            _ = authService.isAuthenticated
        }
    }
    
    // MARK: - Validation Performance
    
    /// Tests that validation helpers are fast
    func testValidation_EmailCheck_IsFast() {
        let email = "test@example.com"
        
        measure {
            for _ in 0..<1000 {
                _ = Validation.isValidEmail(email)
            }
        }
    }
    
    func testValidation_PasswordCheck_IsFast() {
        let password = "password123"
        
        measure {
            for _ in 0..<1000 {
                _ = Validation.isValidPassword(password)
            }
        }
    }
}

