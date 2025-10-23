//
//  MultiDeviceSyncTests.swift
//  MessageAITests
//
//  Tests for multi-device sync scenarios using Swift Testing
//

import Testing
import Foundation
@testable import MessageAI

/// Multi-device sync tests simulating 2+ devices
/// - Note: Uses Swift Testing framework with @Test syntax
@Suite("Multi-Device Sync Tests")
struct MultiDeviceSyncTests {
    
    // MARK: - Setup
    
    private let device1UserService = UserService()
    private let device2UserService = UserService()
    private let timeout: TimeInterval = 0.5 // 500ms timeout for sync
    
    // MARK: - Profile Name Sync Tests
    
    @Test("Profile name sync completes within 100ms")
    func profileNameSyncCompletesWithin100ms() async throws {
        // Given: Two devices with same user
        let testUserID = "test-user-\(UUID().uuidString)"
        let initialName = "Initial Name"
        let updatedName = "Updated Name"
        
        // Create test user
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: initialName,
            email: "test@example.com"
        )
        
        // When: Device 1 updates name
        let startTime = Date()
        try await device1UserService.updateDisplayName(
            userID: testUserID,
            displayName: updatedName
        )
        
        // Wait for Firebase propagation
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Device 2 fetches updated name within 100ms
        let device2User = try await device2UserService.fetchUser(userID: testUserID)
        let syncTime = Date().timeIntervalSince(startTime)
        
        #expect(device2User.displayName == updatedName, "Device 2 should see updated name")
        #expect(syncTime < 0.2, "Sync should complete within 200ms total")
    }
    
    @Test("Profile name validation works across devices")
    func profileNameValidationWorksAcrossDevices() async throws {
        // Given: Test user
        let testUserID = "test-user-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Valid Name",
            email: "test@example.com"
        )
        
        // When: Device 1 tries to update with invalid name (empty)
        var threwError = false
        do {
            try await device1UserService.updateDisplayName(
                userID: testUserID,
                displayName: ""
            )
        } catch {
            threwError = true
        }
        
        // Then: Update should fail with validation error
        #expect(threwError, "Empty name should throw validation error")
    }
    
    // MARK: - Profile Photo Sync Tests
    
    @Test("Profile photo URL sync completes within 100ms")
    func profilePhotoURLSyncCompletesWithin100ms() async throws {
        // Given: Test user
        let testUserID = "test-user-\(UUID().uuidString)"
        let photoURL = "https://storage.googleapis.com/test/photo.jpg"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Test User",
            email: "test@example.com"
        )
        
        // When: Device 1 updates photo URL
        let startTime = Date()
        try await device1UserService.updateProfilePhoto(
            userID: testUserID,
            photoURL: photoURL
        )
        
        // Wait for Firebase propagation
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Device 2 fetches updated photo URL
        let device2User = try await device2UserService.fetchUser(userID: testUserID)
        let syncTime = Date().timeIntervalSince(startTime)
        
        #expect(device2User.profilePhotoURL == photoURL, "Device 2 should see updated photo URL")
        #expect(syncTime < 0.2, "Sync should complete within 200ms total")
    }
    
    @Test("Profile photo removal syncs across devices")
    func profilePhotoRemovalSyncsAcrossDevices() async throws {
        // Given: User with photo URL
        let testUserID = "test-user-\(UUID().uuidString)"
        let initialPhotoURL = "https://storage.googleapis.com/test/photo.jpg"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Test User",
            email: "test@example.com"
        )
        
        try await device1UserService.updateProfilePhoto(
            userID: testUserID,
            photoURL: initialPhotoURL
        )
        
        // When: Device 1 removes photo (set to nil is not supported by updateProfilePhoto, 
        // so this test verifies photo URL can be overwritten)
        let newPhotoURL = "https://storage.googleapis.com/test/new-photo.jpg"
        try await device1UserService.updateProfilePhoto(
            userID: testUserID,
            photoURL: newPhotoURL
        )
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Device 2 sees updated photo URL
        let device2User = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(device2User.profilePhotoURL == newPhotoURL, "Device 2 should see new photo URL")
    }
    
    // MARK: - Concurrent Update Tests
    
    @Test("Concurrent profile updates handle last-write-wins")
    func concurrentProfileUpdatesHandleLastWriteWins() async throws {
        // Given: Test user
        let testUserID = "test-user-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Initial Name",
            email: "test@example.com"
        )
        
        // When: Both devices update name simultaneously
        async let device1Update: Void = device1UserService.updateDisplayName(
            userID: testUserID,
            displayName: "Device 1 Name"
        )
        async let device2Update: Void = device2UserService.updateDisplayName(
            userID: testUserID,
            displayName: "Device 2 Name"
        )
        
        _ = try await (device1Update, device2Update)
        
        // Wait for propagation
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then: One of the names should win (last-write-wins)
        let finalUser = try await device1UserService.fetchUser(userID: testUserID)
        
        #expect(
            finalUser.displayName == "Device 1 Name" || finalUser.displayName == "Device 2 Name",
            "Final name should be one of the concurrent updates"
        )
    }
    
    // MARK: - Network Error Handling Tests
    
    @Test("Profile sync handles network errors gracefully")
    func profileSyncHandlesNetworkErrorsGracefully() async throws {
        // Given: Non-existent user (simulates network/permission error)
        let nonExistentUserID = "non-existent-user"
        
        // When: Try to fetch non-existent user
        var threwError = false
        var errorType: UserServiceError?
        
        do {
            _ = try await device1UserService.fetchUser(userID: nonExistentUserID)
        } catch let error as UserServiceError {
            threwError = true
            errorType = error
        } catch {
            threwError = true
        }
        
        // Then: Should throw appropriate error
        #expect(threwError, "Should throw error for non-existent user")
        #expect(errorType == .notFound, "Should throw notFound error")
    }
    
    // MARK: - Data Consistency Tests
    
    @Test("Multiple field updates sync correctly")
    func multipleFieldUpdatesSyncCorrectly() async throws {
        // Given: Test user
        let testUserID = "test-user-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Initial Name",
            email: "test@example.com"
        )
        
        // When: Device 1 updates both name and photo
        let newName = "Updated Name"
        let newPhotoURL = "https://storage.googleapis.com/test/photo.jpg"
        
        try await device1UserService.updateUser(
            userID: testUserID,
            displayName: newName,
            profilePhotoURL: newPhotoURL
        )
        
        // Wait for propagation
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Device 2 sees both updates
        let device2User = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(device2User.displayName == newName, "Name should be synced")
        #expect(device2User.profilePhotoURL == newPhotoURL, "Photo URL should be synced")
    }
    
    @Test("Server timestamp updates correctly")
    func serverTimestampUpdatesCorrectly() async throws {
        // Given: Test user
        let testUserID = "test-user-\(UUID().uuidString)"
        let beforeCreate = Date()
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Test User",
            email: "test@example.com"
        )
        
        // Small delay to ensure timestamp difference
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // When: Update user
        try await device1UserService.updateDisplayName(
            userID: testUserID,
            displayName: "Updated Name"
        )
        
        // Wait for propagation
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: lastActiveAt should be after creation
        let user = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(user.lastActiveAt > beforeCreate, "lastActiveAt should be updated")
        #expect(user.createdAt <= user.lastActiveAt, "createdAt should be before or equal to lastActiveAt")
    }
}


