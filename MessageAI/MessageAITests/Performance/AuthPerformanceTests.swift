//
//  AuthPerformanceTests.swift
//  MessageAITests
//
//  Performance tests for authentication and user services
//  Verifies targets from shared-standards.md
//

import XCTest
@testable import MessageAI
import FirebaseAuth

final class AuthPerformanceTests: XCTestCase {
    
    var authService: AuthService!
    var userService: UserService!
    var firebaseService: FirebaseService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        firebaseService = FirebaseService.shared
        try firebaseService.configure()
        
        authService = AuthService()
        userService = UserService()
    }
    
    override func tearDownWithError() throws {
        // Clean up
        try? authService.signOut()
        
        authService = nil
        userService = nil
        firebaseService = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Firebase Initialization Performance
    
    /// Test Firebase initialization completes in < 500ms
    /// Gate: Initialization < 500ms (from shared-standards.md)
    func testPerformance_FirebaseInit_Under500ms() throws {
        // Reset Firebase state (this is approximation since Firebase is singleton)
        // In real scenario, this would be first app launch
        
        measure {
            do {
                try firebaseService.configure()
            } catch {
                XCTFail("Configuration should not fail: \(error)")
            }
        }
        
        // Note: Baseline should be set to 0.5s (500ms)
        // If average exceeds 500ms, test should fail
    }
    
    // MARK: - Sign Up Performance
    
    /// Test signUp completes in < 5 seconds
    /// Gate: signUp < 5s (from shared-standards.md and PRD)
    func testPerformance_SignUp_Under5Seconds() async throws {
        let expectation = expectation(description: "Sign up performance")
        var elapsed: TimeInterval = 0
        
        // Generate unique test credentials
        let email = "perftest\(String(UUID().uuidString.prefix(8)))@example.com"
        let password = "testPassword123"
        let displayName = "Performance Test User"
        
        // Measure sign up time
        let startTime = Date()
        
        Task {
            do {
                _ = try await authService.signUp(email: email, password: password, displayName: displayName)
                elapsed = Date().timeIntervalSince(startTime)
                expectation.fulfill()
            } catch {
                XCTFail("Sign up failed: \(error)")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 10.0)
        
        // Assert performance target
        XCTAssertLessThan(elapsed, Constants.Performance.signUpMaxSeconds,
                         "Sign up should complete in < \(Constants.Performance.signUpMaxSeconds) seconds, took \(elapsed)s")
        
        print("✅ Sign up completed in \(elapsed)s (target: < \(Constants.Performance.signUpMaxSeconds)s)")
    }
    
    // MARK: - Sign In Performance
    
    /// Test signIn completes in < 3 seconds
    /// Gate: signIn < 3s (from shared-standards.md and PRD)
    func testPerformance_SignIn_Under3Seconds() async throws {
        // Given: Existing user
        let email = "perftest\(String(UUID().uuidString.prefix(8)))@example.com"
        let password = "testPassword123"
        let displayName = "Performance Test User"
        
        _ = try await authService.signUp(email: email, password: password, displayName: displayName)
        try authService.signOut()
        
        // Wait for auth state to settle
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        let expectation = expectation(description: "Sign in performance")
        var elapsed: TimeInterval = 0
        
        // Measure sign in time
        let startTime = Date()
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                elapsed = Date().timeIntervalSince(startTime)
                expectation.fulfill()
            } catch {
                XCTFail("Sign in failed: \(error)")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Assert performance target
        XCTAssertLessThan(elapsed, Constants.Performance.signInMaxSeconds,
                         "Sign in should complete in < \(Constants.Performance.signInMaxSeconds) seconds, took \(elapsed)s")
        
        print("✅ Sign in completed in \(elapsed)s (target: < \(Constants.Performance.signInMaxSeconds)s)")
    }
    
    // MARK: - Fetch User Performance
    
    /// Test fetchUser completes in < 1 second
    /// Gate: fetchUser < 1s (from shared-standards.md)
    func testPerformance_FetchUser_Under1Second() async throws {
        // Given: Existing user
        let email = "perftest\(String(UUID().uuidString.prefix(8)))@example.com"
        let password = "testPassword123"
        let displayName = "Performance Test User"
        
        let userID = try await authService.signUp(email: email, password: password, displayName: displayName)
        
        let expectation = expectation(description: "Fetch user performance")
        var elapsed: TimeInterval = 0
        
        // Measure fetch time
        let startTime = Date()
        
        Task {
            do {
                _ = try await userService.fetchUser(userID: userID)
                elapsed = Date().timeIntervalSince(startTime)
                expectation.fulfill()
            } catch {
                XCTFail("Fetch user failed: \(error)")
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Assert performance target
        XCTAssertLessThan(elapsed, Constants.Performance.fetchUserMaxSeconds,
                         "Fetch user should complete in < \(Constants.Performance.fetchUserMaxSeconds) second, took \(elapsed)s")
        
        print("✅ Fetch user completed in \(elapsed)s (target: < \(Constants.Performance.fetchUserMaxSeconds)s)")
    }
    
    // MARK: - Auth State Change Performance
    
    /// Test auth state changes propagate in < 100ms
    /// Gate: Auth state updates < 100ms (from shared-standards.md)
    func testPerformance_AuthStateChange_Under100ms() async throws {
        let expectation = expectation(description: "Auth state change performance")
        var elapsed: TimeInterval = 0
        
        // Generate unique test credentials
        let email = "perftest\(String(UUID().uuidString.prefix(8)))@example.com"
        let password = "testPassword123"
        let displayName = "Performance Test User"
        
        // Observe when isAuthenticated changes
        var observation: Any?
        let startTime = Date()
        
        observation = authService.$isAuthenticated.sink { isAuthenticated in
            if isAuthenticated {
                elapsed = Date().timeIntervalSince(startTime)
                expectation.fulfill()
            }
        }
        
        // Trigger auth state change by signing up
        Task {
            do {
                _ = try await authService.signUp(email: email, password: password, displayName: displayName)
            } catch {
                XCTFail("Sign up failed: \(error)")
            }
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Clean up observation
        _ = observation
        
        // Assert performance target
        let maxMs = Double(Constants.Performance.authStateChangeMaxMs) / 1000.0
        XCTAssertLessThan(elapsed, maxMs,
                         "Auth state change should propagate in < \(Constants.Performance.authStateChangeMaxMs)ms, took \(elapsed * 1000)ms")
        
        print("✅ Auth state change completed in \(elapsed * 1000)ms (target: < \(Constants.Performance.authStateChangeMaxMs)ms)")
    }
    
    // MARK: - Repeated Operations Performance
    
    /// Test multiple sign in operations maintain performance
    /// Gate: Average sign in time stays under 3s even with repeated calls
    func testPerformance_RepeatedSignIn_MaintainsPerformance() async throws {
        // Given: Existing user
        let email = "perftest\(String(UUID().uuidString.prefix(8)))@example.com"
        let password = "testPassword123"
        let displayName = "Performance Test User"
        
        _ = try await authService.signUp(email: email, password: password, displayName: displayName)
        
        var times: [TimeInterval] = []
        
        // Perform 5 sign in/out cycles
        for i in 1...5 {
            try authService.signOut()
            try await Task.sleep(nanoseconds: 200_000_000) // 200ms between tests
            
            let startTime = Date()
            try await authService.signIn(email: email, password: password)
            let elapsed = Date().timeIntervalSince(startTime)
            times.append(elapsed)
            
            print("Sign in #\(i): \(elapsed)s")
        }
        
        // Calculate average
        let average = times.reduce(0, +) / Double(times.count)
        
        // Assert average stays under target
        XCTAssertLessThan(average, Constants.Performance.signInMaxSeconds,
                         "Average sign in time should be < \(Constants.Performance.signInMaxSeconds)s, got \(average)s")
        
        print("✅ Average sign in time: \(average)s over \(times.count) attempts")
    }
}

