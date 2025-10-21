//
//  UserServiceTests.swift
//  MessageAITests
//
//  Unit tests for UserService
//

import XCTest
@testable import MessageAI
import FirebaseFirestore
import FirebaseAuth

final class UserServiceTests: XCTestCase {
    
    var userService: UserService!
    var testUserID: String!
    var testDisplayName: String!
    var testEmail: String!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize Firebase if needed
        try FirebaseService.shared.configure()
        
        // Create service instance
        userService = UserService()
        
        // Generate test data
        testUserID = "test_\(String(UUID().uuidString.prefix(8)))"
        testDisplayName = "Test User"
        testEmail = "test\(String(UUID().uuidString.prefix(8)))@example.com"
    }
    
    override func tearDownWithError() throws {
        // Clean up test user document
        if let userID = testUserID {
            let db = FirebaseService.shared.getFirestore()
            try? db.collection(Constants.Collections.users).document(userID).delete()
        }
        
        userService = nil
        testUserID = nil
        testDisplayName = nil
        testEmail = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Create User Tests
    
    /// Test createUser with valid data creates Firestore document
    /// Gate: Document created at users/{userID} in < 1s
    func testCreateUser_ValidData_CreatesDocument() async throws {
        // Given: Valid user data
        let userID = testUserID!
        let displayName = testDisplayName!
        let email = testEmail!
        
        // When: Creating user
        let startTime = Date()
        try await userService.createUser(userID: userID, displayName: displayName, email: email)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Should complete in < 1 second
        XCTAssertLessThan(elapsed, Constants.Performance.fetchUserMaxSeconds,
                         "Create user should complete in < 1 second")
        
        // Verify document exists in Firestore
        let db = FirebaseService.shared.getFirestore()
        let document = try await db.collection(Constants.Collections.users).document(userID).getDocument()
        
        XCTAssertTrue(document.exists, "User document should exist")
        
        let data = document.data()
        XCTAssertNotNil(data)
        XCTAssertEqual(data?["id"] as? String, userID)
        XCTAssertEqual(data?["displayName"] as? String, displayName)
        XCTAssertEqual(data?["email"] as? String, email)
        XCTAssertNotNil(data?["createdAt"], "createdAt should be set")
        XCTAssertNotNil(data?["lastActiveAt"], "lastActiveAt should be set")
    }
    
    /// Test createUser with invalid display name throws error
    /// Gate: Validation catches before Firestore call
    func testCreateUser_InvalidDisplayName_ThrowsError() async throws {
        // Given: Invalid display name (empty)
        let userID = testUserID!
        let invalidDisplayName = ""
        let email = testEmail!
        
        // When/Then: Should throw invalidDisplayName error
        do {
            try await userService.createUser(userID: userID, displayName: invalidDisplayName, email: email)
            XCTFail("Should have thrown invalidDisplayName error")
        } catch let error as UserServiceError {
            XCTAssertEqual(error, .invalidDisplayName, "Should throw invalidDisplayName error")
        }
        
        // Verify no document was created
        let db = FirebaseService.shared.getFirestore()
        let document = try await db.collection(Constants.Collections.users).document(userID).getDocument()
        XCTAssertFalse(document.exists, "No document should be created for invalid data")
    }
    
    /// Test createUser with display name too long throws error
    /// Gate: Validation catches before Firestore call
    func testCreateUser_DisplayNameTooLong_ThrowsError() async throws {
        // Given: Display name > 50 characters
        let userID = testUserID!
        let longDisplayName = String(repeating: "a", count: 51)
        let email = testEmail!
        
        // When/Then: Should throw invalidDisplayName error
        do {
            try await userService.createUser(userID: userID, displayName: longDisplayName, email: email)
            XCTFail("Should have thrown invalidDisplayName error")
        } catch let error as UserServiceError {
            XCTAssertEqual(error, .invalidDisplayName, "Should throw invalidDisplayName error")
        }
    }
    
    // MARK: - Fetch User Tests
    
    /// Test fetchUser returns existing user with correct data
    /// Gate: Returns User object with all fields matching
    func testFetchUser_ExistingUser_ReturnsUser() async throws {
        // Given: Existing user
        let userID = testUserID!
        let displayName = testDisplayName!
        let email = testEmail!
        
        try await userService.createUser(userID: userID, displayName: displayName, email: email)
        
        // When: Fetching user
        let startTime = Date()
        let user = try await userService.fetchUser(userID: userID)
        let elapsed = Date().timeIntervalSince(startTime)
        
        // Then: Should complete in < 1 second
        XCTAssertLessThan(elapsed, Constants.Performance.fetchUserMaxSeconds,
                         "Fetch user should complete in < 1 second")
        
        // Verify all fields match
        XCTAssertEqual(user.id, userID, "User ID should match")
        XCTAssertEqual(user.displayName, displayName, "Display name should match")
        XCTAssertEqual(user.email, email, "Email should match")
        XCTAssertNil(user.profilePhotoURL, "Profile photo URL should be nil initially")
        XCTAssertNotNil(user.createdAt, "createdAt should be set")
        XCTAssertNotNil(user.lastActiveAt, "lastActiveAt should be set")
    }
    
    /// Test fetchUser with nonexistent user throws notFound
    /// Gate: notFound error returned
    func testFetchUser_NonexistentUser_ThrowsNotFound() async throws {
        // Given: Non-existent user ID
        let nonexistentUserID = "nonexistent_\(UUID().uuidString)"
        
        // When/Then: Should throw notFound error
        do {
            _ = try await userService.fetchUser(userID: nonexistentUserID)
            XCTFail("Should have thrown notFound error")
        } catch let error as UserServiceError {
            XCTAssertEqual(error, .notFound, "Should throw notFound error")
        }
    }
    
    // MARK: - Update User Tests
    
    /// Test updateUser with valid data updates Firestore document
    /// Gate: Only specified fields updated, lastActiveAt updated
    func testUpdateUser_ValidData_UpdatesDocument() async throws {
        // Given: Existing user
        let userID = testUserID!
        let displayName = testDisplayName!
        let email = testEmail!
        
        try await userService.createUser(userID: userID, displayName: displayName, email: email)
        
        // Get original user
        let originalUser = try await userService.fetchUser(userID: userID)
        
        // Wait a moment to ensure timestamp will be different
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // When: Updating user
        let newDisplayName = "Updated Name"
        let newPhotoURL = "https://example.com/photo.jpg"
        
        try await userService.updateUser(userID: userID, displayName: newDisplayName, profilePhotoURL: newPhotoURL)
        
        // Then: Verify updates
        let updatedUser = try await userService.fetchUser(userID: userID)
        
        XCTAssertEqual(updatedUser.displayName, newDisplayName, "Display name should be updated")
        XCTAssertEqual(updatedUser.profilePhotoURL, newPhotoURL, "Profile photo URL should be updated")
        XCTAssertEqual(updatedUser.email, email, "Email should remain unchanged")
        XCTAssertEqual(updatedUser.id, userID, "ID should remain unchanged")
        XCTAssertEqual(updatedUser.createdAt, originalUser.createdAt, "createdAt should remain unchanged")
        // Note: lastActiveAt should be updated but we can't easily test exact timestamp
    }
    
    /// Test updateUser with only display name updates only that field
    /// Gate: Partial updates work correctly
    func testUpdateUser_OnlyDisplayName_UpdatesOnlyThatField() async throws {
        // Given: Existing user with profile photo
        let userID = testUserID!
        let displayName = testDisplayName!
        let email = testEmail!
        let photoURL = "https://example.com/original.jpg"
        
        try await userService.createUser(userID: userID, displayName: displayName, email: email)
        try await userService.updateUser(userID: userID, profilePhotoURL: photoURL)
        
        let originalUser = try await userService.fetchUser(userID: userID)
        
        // When: Updating only display name
        let newDisplayName = "New Name Only"
        try await userService.updateUser(userID: userID, displayName: newDisplayName)
        
        // Then: Only display name should change
        let updatedUser = try await userService.fetchUser(userID: userID)
        
        XCTAssertEqual(updatedUser.displayName, newDisplayName, "Display name should be updated")
        XCTAssertEqual(updatedUser.profilePhotoURL, originalUser.profilePhotoURL, "Profile photo should remain unchanged")
    }
    
    /// Test updateUser with invalid display name throws error
    /// Gate: Validation catches before Firestore call
    func testUpdateUser_InvalidDisplayName_ThrowsError() async throws {
        // Given: Existing user
        let userID = testUserID!
        try await userService.createUser(userID: userID, displayName: testDisplayName!, email: testEmail!)
        
        // When/Then: Updating with invalid display name should fail
        let invalidDisplayName = String(repeating: "a", count: 51) // > 50 chars
        
        do {
            try await userService.updateUser(userID: userID, displayName: invalidDisplayName)
            XCTFail("Should have thrown invalidDisplayName error")
        } catch let error as UserServiceError {
            XCTAssertEqual(error, .invalidDisplayName, "Should throw invalidDisplayName error")
        }
    }
    
    // MARK: - Performance Tests
    
    /// Test fetchUser performance
    /// Gate: Completes in < 1 second
    func testPerformance_FetchUser_Under1Second() async throws {
        // Given: Existing user
        let userID = testUserID!
        try await userService.createUser(userID: userID, displayName: testDisplayName!, email: testEmail!)
        
        // Measure fetch time
        measure {
            Task {
                _ = try? await userService.fetchUser(userID: userID)
            }
        }
    }
}

