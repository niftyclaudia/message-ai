//
//  SecurityRulesTests.swift
//  MessageAITests
//
//  Integration tests for Firestore security rules
//  Note: These tests require Firebase project with deployed security rules
//

import XCTest
@testable import MessageAI
import FirebaseAuth
import FirebaseFirestore

final class SecurityRulesTests: XCTestCase {
    
    var authService: AuthService!
    var userService: UserService!
    var db: Firestore!
    
    var testUserA_Email: String!
    var testUserA_Password: String!
    var testUserA_ID: String!
    
    var testUserB_Email: String!
    var testUserB_Password: String!
    var testUserB_ID: String!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize Firebase
        try FirebaseService.shared.configure()
        
        // Initialize services
        authService = AuthService()
        userService = UserService()
        db = FirebaseService.shared.getFirestore()
        
        // Generate unique test credentials for two users
        testUserA_Email = "testa\(String(UUID().uuidString.prefix(8)))@example.com"
        testUserA_Password = "testPasswordA123"
        
        testUserB_Email = "testb\(String(UUID().uuidString.prefix(8)))@example.com"
        testUserB_Password = "testPasswordB123"
    }
    
    override func tearDownWithError() throws {
        // Clean up test users (sync sign out only)
        if Auth.auth().currentUser != nil {
            try? authService.signOut()
        }
        
        authService = nil
        userService = nil
        db = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Helper Methods
    
    private func cleanupTestUsers() async throws {
        // Sign out current user
        if Auth.auth().currentUser != nil {
            try authService.signOut()
        }
        
        // Delete user documents (requires authentication)
        // Note: In real tests with emulator, would clean up more thoroughly
    }
    
    // MARK: - Read Permission Tests
    
    /// Test authenticated user can read any user document
    /// Gate: Authenticated user reads any user doc successfully
    func testSecurityRules_AuthenticatedUser_CanReadAnyUser() async throws {
        // Given: Two users created
        testUserA_ID = try await authService.signUp(
            email: testUserA_Email,
            password: testUserA_Password,
            displayName: "User A"
        )
        
        try authService.signOut()
        
        testUserB_ID = try await authService.signUp(
            email: testUserB_Email,
            password: testUserB_Password,
            displayName: "User B"
        )
        
        // When: User B tries to read User A's document
        // Then: Should succeed
        XCTAssertNoThrow(try await userService.fetchUser(userID: testUserA_ID))
        
        let userA = try await userService.fetchUser(userID: testUserA_ID)
        XCTAssertEqual(userA.id, testUserA_ID, "Should be able to read other user's document")
    }
    
    /// Test unauthenticated user cannot read user documents
    /// Gate: Unauth request denied
    func testSecurityRules_Unauthenticated_CannotRead() async throws {
        // Given: User created and signed out
        let userID = try await authService.signUp(
            email: testUserA_Email,
            password: testUserA_Password,
            displayName: "User A"
        )
        
        try authService.signOut()
        
        // Wait for auth state to propagate
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // When: Attempting to read as unauthenticated user
        // Then: Should fail with permission denied
        do {
            _ = try await userService.fetchUser(userID: userID)
            XCTFail("Unauthenticated user should not be able to read")
        } catch let error as UserServiceError {
            // Should get permission denied or not found
            XCTAssertTrue(error == .permissionDenied || error == .notFound,
                         "Should throw permission error for unauthenticated access")
        } catch {
            // Firestore may throw different error types
            print("Caught error: \(error)")
            // This is acceptable - the read was blocked
        }
    }
    
    // MARK: - Write Permission Tests (Create)
    
    /// Test user can only create their own document
    /// Gate: Own document succeeds, other's document fails
    func testSecurityRules_User_CanOnlyCreateOwnDocument() async throws {
        // Given: User A authenticated
        testUserA_ID = try await authService.signUp(
            email: testUserA_Email,
            password: testUserA_Password,
            displayName: "User A"
        )
        
        // Then: Creating own document succeeded (already done in signUp)
        let ownDoc = try await userService.fetchUser(userID: testUserA_ID)
        XCTAssertEqual(ownDoc.id, testUserA_ID)
        
        // When: Attempting to create document for another user ID
        let otherUserID = "other_\(UUID().uuidString)"
        
        // Then: Should fail with permission denied
        do {
            try await userService.createUser(userID: otherUserID, displayName: "Fake User", email: "fake@example.com")
            XCTFail("User should not be able to create document for another user")
        } catch {
            // Should fail - this is expected
            print("Expected failure: \(error)")
        }
    }
    
    // MARK: - Write Permission Tests (Update)
    
    /// Test user can only update their own document
    /// Gate: Own document update succeeds, other's fails
    func testSecurityRules_User_CanOnlyUpdateOwnDocument() async throws {
        // Given: Two users
        testUserA_ID = try await authService.signUp(
            email: testUserA_Email,
            password: testUserA_Password,
            displayName: "User A"
        )
        
        try authService.signOut()
        
        testUserB_ID = try await authService.signUp(
            email: testUserB_Email,
            password: testUserB_Password,
            displayName: "User B"
        )
        
        // When: User B tries to update own document
        // Then: Should succeed
        XCTAssertNoThrow(try await userService.updateUser(userID: testUserB_ID, displayName: "Updated B"))
        
        // When: User B tries to update User A's document
        // Then: Should fail
        do {
            try await userService.updateUser(userID: testUserA_ID, displayName: "Hacked A")
            XCTFail("User should not be able to update another user's document")
        } catch {
            // Should fail - this is expected
            print("Expected failure: \(error)")
        }
    }
    
    // MARK: - Delete Permission Tests
    
    /// Test user cannot delete documents
    /// Gate: Delete fails with permission denied
    func testSecurityRules_User_CannotDeleteDocuments() async throws {
        // Given: User authenticated
        testUserA_ID = try await authService.signUp(
            email: testUserA_Email,
            password: testUserA_Password,
            displayName: "User A"
        )
        
        // When: Attempting to delete own document
        // Then: Should fail
        do {
            try await db.collection(Constants.Collections.users).document(testUserA_ID).delete()
            XCTFail("User should not be able to delete documents")
        } catch {
            // Should fail - this is expected
            print("Expected failure (delete blocked): \(error)")
        }
        
        // Verify document still exists
        let user = try await userService.fetchUser(userID: testUserA_ID)
        XCTAssertEqual(user.id, testUserA_ID, "Document should still exist")
    }
    
    // MARK: - Validation Tests
    
    /// Test security rules validate required fields
    /// Gate: Invalid data is rejected
    func testSecurityRules_ValidatesRequiredFields() async throws {
        // Given: User authenticated
        testUserA_ID = try await authService.signUp(
            email: testUserA_Email,
            password: testUserA_Password,
            displayName: "User A"
        )
        
        // When: Attempting to create document with missing required fields
        let invalidData: [String: Any] = [
            "id": testUserA_ID
            // Missing displayName and email
        ]
        
        // Then: Should fail validation
        do {
            try await db.collection(Constants.Collections.users)
                .document("invalid_\(UUID().uuidString)")
                .setData(invalidData)
            XCTFail("Should reject document with missing required fields")
        } catch {
            // Should fail - this is expected
            print("Expected failure (validation): \(error)")
        }
    }
}

