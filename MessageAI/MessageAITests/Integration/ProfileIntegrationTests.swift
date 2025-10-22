//
//  ProfileIntegrationTests.swift
//  MessageAITests
//
//  Integration tests for profile management
//

import XCTest
@testable import MessageAI
import FirebaseFirestore

final class ProfileIntegrationTests: XCTestCase {
    
    var userService: UserService!
    var photoService: PhotoService!
    var testUserID: String!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Initialize Firebase
        try FirebaseService.shared.configure()
        
        userService = UserService()
        photoService = PhotoService()
        testUserID = "test_\(UUID().uuidString.prefix(8))"
    }
    
    override func tearDownWithError() throws {
        // Cleanup
        if let userID = testUserID {
            let db = FirebaseService.shared.getFirestore()
            try? db.collection(Constants.Collections.users).document(userID).delete()
        }
        
        userService = nil
        photoService = nil
        testUserID = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Profile Update Integration
    
    /// Test updating profile updates Firestore and can be fetched
    /// Gate: Firestore matches UI state
    func testUpdateProfile_UpdatesFirestoreAndUI() async throws {
        // Given: User exists
        try await userService.createUser(
            userID: testUserID,
            displayName: "Original Name",
            email: "test@example.com"
        )
        
        // When: Updating display name
        let newName = "Updated Name"
        try await userService.updateDisplayName(userID: testUserID, displayName: newName)
        
        // Then: Fetch should return updated data
        let updatedUser = try await userService.fetchUser(userID: testUserID)
        XCTAssertEqual(updatedUser.displayName, newName, "Firestore should have updated name")
    }
    
    /// Test photo upload updates both Storage and Firestore
    /// Gate: Photo in Storage, URL in Firestore
    func testUploadPhoto_UpdatesStorageAndFirestore() async throws {
        // Given: User exists
        try await userService.createUser(
            userID: testUserID,
            displayName: "Test User",
            email: "test@example.com"
        )
        
        // When: Uploading photo
        let testImage = createTestImage()
        let photoURL = try await photoService.uploadProfilePhoto(
            image: testImage,
            userID: testUserID
        ) { _ in }
        
        // Then: Photo URL should be valid
        XCTAssertFalse(photoURL.isEmpty, "Should return valid URL")
        XCTAssertTrue(photoURL.contains("profile_photos"), "URL should contain correct path")
        
        // Update Firestore with URL
        try await userService.updateProfilePhoto(userID: testUserID, photoURL: photoURL)
        
        // Verify Firestore has URL
        let user = try await userService.fetchUser(userID: testUserID)
        XCTAssertEqual(user.profilePhotoURL, photoURL, "Firestore should have photo URL")
        
        // Cleanup: Delete photo
        try? await photoService.deleteProfilePhoto(photoURL: photoURL)
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

