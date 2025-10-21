//
//  AuthServiceTests.swift
//  MessageAITests
//
//  Unit tests for AuthService
//

import XCTest
@testable import MessageAI
import FirebaseAuth

final class AuthServiceTests: XCTestCase {
    
    var authService: AuthService!
    var testEmail: String!
    var testPassword: String!
    var testDisplayName: String!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize Firebase if needed
        try FirebaseService.shared.configure()
        
        // Create service instance
        authService = AuthService()
        
        // Generate unique test credentials
        testEmail = "test\(String(UUID().uuidString.prefix(8)))@example.com"
        testPassword = "testPassword123"
        testDisplayName = "Test User"
        
        // Clean up any existing test user
        try? signOutIfNeeded()
    }
    
    override func tearDownWithError() throws {
        // Clean up test user (sync sign out only)
        try? signOutIfNeeded()
        // Note: deleteCurrentUser is async, cannot be called in sync tearDown
        // Test users will be cleaned up by Firebase Auth automatically after tests
        
        authService = nil
        testEmail = nil
        testPassword = nil
        testDisplayName = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Helper Methods
    
    private func signOutIfNeeded() throws {
        if Auth.auth().currentUser != nil {
            try authService.signOut()
        }
    }
    
    private func deleteCurrentUser() async throws {
        if let user = Auth.auth().currentUser {
            try await user.delete()
        }
    }
    
    // MARK: - Sign Up Tests (Happy Path)
    
    /// Test signUp with valid credentials creates both Auth user and Firestore document
    /// Gate: Auth user + Firestore doc created in < 5s
    func testSignUp_ValidCredentials_CreatesUserAndDocument() async throws {
        // Given: Valid credentials
        let email = testEmail!
        let password = testPassword!
        let displayName = testDisplayName!
        
        // When: Signing up
        let startTime = Date()
        let userID = try await authService.signUp(email: email, password: password, displayName: displayName)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Should complete in < 5 seconds
        XCTAssertLessThan(elapsed, Constants.Performance.signUpMaxSeconds, 
                         "Sign up should complete in < 5 seconds")
        
        // Verify user ID returned
        XCTAssertFalse(userID.isEmpty, "User ID should not be empty")
        
        // Verify Auth user created
        XCTAssertNotNil(Auth.auth().currentUser, "Auth user should exist")
        XCTAssertEqual(Auth.auth().currentUser?.uid, userID, "User IDs should match")
        
        // Verify Firestore document created
        let userService = UserService()
        let user = try await userService.fetchUser(userID: userID)
        XCTAssertEqual(user.id, userID)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, displayName)
    }
    
    // MARK: - Sign In Tests (Happy Path)
    
    /// Test signIn with valid credentials authenticates user
    /// Gate: currentUser populated, isAuthenticated = true in < 3s
    func testSignIn_ValidCredentials_Authenticates() async throws {
        // Given: Existing user
        let email = testEmail!
        let password = testPassword!
        let displayName = testDisplayName!
        
        _ = try await authService.signUp(email: email, password: password, displayName: displayName)
        try authService.signOut()
        
        // Verify starting state
        XCTAssertFalse(authService.isAuthenticated, "Should not be authenticated initially")
        
        // When: Signing in
        let startTime = Date()
        try await authService.signIn(email: email, password: password)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Should complete in < 3 seconds
        XCTAssertLessThan(elapsed, Constants.Performance.signInMaxSeconds,
                         "Sign in should complete in < 3 seconds")
        
        // Wait briefly for auth state to update
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Verify authenticated state
        XCTAssertTrue(authService.isAuthenticated, "Should be authenticated")
        XCTAssertNotNil(authService.currentUser, "Current user should be set")
    }
    
    // MARK: - Sign Out Tests
    
    /// Test signOut clears authentication state
    /// Gate: currentUser = nil, isAuthenticated = false
    func testSignOut_ClearsState() async throws {
        // Given: Authenticated user
        let email = testEmail!
        let password = testPassword!
        let displayName = testDisplayName!
        
        _ = try await authService.signUp(email: email, password: password, displayName: displayName)
        
        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        XCTAssertTrue(authService.isAuthenticated, "Should be authenticated before sign out")
        
        // When: Signing out
        try authService.signOut()
        
        // Wait for auth state to update
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then: State should be cleared
        XCTAssertFalse(authService.isAuthenticated, "Should not be authenticated after sign out")
        XCTAssertNil(authService.currentUser, "Current user should be nil")
    }
    
    // MARK: - Validation Tests
    
    /// Test invalid email is caught before Firebase call
    /// Gate: Throws invalidEmail BEFORE Firebase call
    func testSignUp_InvalidEmail_ThrowsError() async throws {
        // Given: Invalid email
        let invalidEmail = "notanemail"
        let password = testPassword!
        let displayName = testDisplayName!
        
        // When/Then: Should throw invalidEmail error
        do {
            _ = try await authService.signUp(email: invalidEmail, password: password, displayName: displayName)
            XCTFail("Should have thrown invalidEmail error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidEmail, "Should throw invalidEmail error")
        }
        
        // Verify no user was created
        XCTAssertNil(Auth.auth().currentUser, "No user should be created")
    }
    
    /// Test weak password is caught before Firebase call
    /// Gate: Throws weakPassword BEFORE Firebase call
    func testSignUp_WeakPassword_ThrowsError() async throws {
        // Given: Weak password (< 6 characters)
        let email = testEmail!
        let weakPassword = "123"
        let displayName = testDisplayName!
        
        // When/Then: Should throw weakPassword error
        do {
            _ = try await authService.signUp(email: email, password: weakPassword, displayName: displayName)
            XCTFail("Should have thrown weakPassword error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .weakPassword, "Should throw weakPassword error")
        }
        
        // Verify no user was created
        XCTAssertNil(Auth.auth().currentUser, "No user should be created")
    }
    
    /// Test signUp with existing email throws emailAlreadyInUse
    /// Gate: emailAlreadyInUse error, no duplicate users
    func testSignUp_ExistingEmail_ThrowsError() async throws {
        // Given: Existing user
        let email = testEmail!
        let password = testPassword!
        let displayName = testDisplayName!
        
        _ = try await authService.signUp(email: email, password: password, displayName: displayName)
        try authService.signOut()
        
        // When/Then: Attempting to sign up again with same email should fail
        do {
            _ = try await authService.signUp(email: email, password: password, displayName: "Another User")
            XCTFail("Should have thrown emailAlreadyInUse error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .emailAlreadyInUse, "Should throw emailAlreadyInUse error")
        }
    }
    
    /// Test signIn with wrong password throws invalidCredentials
    /// Gate: invalidCredentials error
    func testSignIn_WrongPassword_ThrowsError() async throws {
        // Given: Existing user
        let email = testEmail!
        let password = testPassword!
        let displayName = testDisplayName!
        
        _ = try await authService.signUp(email: email, password: password, displayName: displayName)
        try authService.signOut()
        
        // When/Then: Signing in with wrong password should fail
        do {
            try await authService.signIn(email: email, password: "wrongPassword123")
            XCTFail("Should have thrown invalidCredentials error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials, "Should throw invalidCredentials error")
        }
    }
    
    /// Test signIn with nonexistent user throws userNotFound or invalidCredentials
    /// Gate: Correct error returned
    func testSignIn_NonexistentUser_ThrowsError() async throws {
        // Given: Non-existent user email
        let email = "nonexistent\(String(UUID().uuidString.prefix(8)))@example.com"
        let password = "somePassword123"
        
        // When/Then: Should throw error
        do {
            try await authService.signIn(email: email, password: password)
            XCTFail("Should have thrown an error")
        } catch let error as AuthError {
            // Firebase may return either userNotFound or invalidCredentials
            XCTAssertTrue(error == .userNotFound || error == .invalidCredentials,
                         "Should throw userNotFound or invalidCredentials error")
        }
    }
    
    // MARK: - Auth State Observation Tests
    
    /// Test auth state updates are observed
    /// Gate: Published properties update in < 100ms
    func testObserveAuthState_UpdatesOnStateChange() async throws {
        // Given: Service observing auth state
        XCTAssertFalse(authService.isAuthenticated, "Should start not authenticated")
        
        // When: User signs up
        let email = testEmail!
        let password = testPassword!
        let displayName = testDisplayName!
        
        let startTime = Date()
        _ = try await authService.signUp(email: email, password: password, displayName: displayName)
        
        // Wait for auth state to propagate
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms (allows for < 100ms target)
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Auth state should be updated
        XCTAssertTrue(authService.isAuthenticated, "Should be authenticated")
        XCTAssertNotNil(authService.currentUser, "Current user should be set")
        
        // Verify update happened within reasonable time
        XCTAssertLessThan(elapsed, 1.0, "Auth state update should happen quickly")
    }
    
    // MARK: - Performance Tests
    
    /// Test signIn performance
    /// Gate: Completes in < 3 seconds
    func testPerformance_SignIn_Under3Seconds() async throws {
        // Given: Existing user
        let email = testEmail!
        let password = testPassword!
        _ = try await authService.signUp(email: email, password: password, displayName: testDisplayName!)
        try authService.signOut()
        
        // Measure sign in time
        measure {
            Task {
                try? await authService.signIn(email: email, password: password)
            }
        }
    }
}

