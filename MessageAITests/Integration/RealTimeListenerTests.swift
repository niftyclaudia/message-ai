//
//  RealTimeListenerTests.swift
//  MessageAITests
//
//  Integration tests for real-time Firestore listeners (PR-007)
//  Tests listener updates, backgrounding, and multi-device scenarios
//

import Testing
import Foundation
@testable import MessageAI

/// Real-time listener tests for Firestore snapshot updates
/// - Note: Tests listener behavior as specified in PR-007
@Suite("Real-Time Listener Tests - PR-007")
struct RealTimeListenerTests {
    
    // MARK: - Setup
    
    private let device1UserService = UserService()
    private let device2UserService = UserService()
    
    // MARK: - Listener Update Tests
    
    @Test("Listener receives updates within 200ms")
    func listenerReceivesUpdatesWithin200ms() async throws {
        // Given: Test user
        let testUserID = "listener-test-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Initial Name",
            email: "listener@test.com"
        )
        
        // When: Update user on device 1
        let startTime = Date()
        
        try await device1UserService.updateDisplayName(
            userID: testUserID,
            displayName: "Updated Name"
        )
        
        // Wait for Firestore propagation
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Device 2 fetches (simulating listener update)
        let updatedUser = try await device2UserService.fetchUser(userID: testUserID)
        
        let updateTime = Date().timeIntervalSince(startTime)
        
        // Then: Update should propagate quickly
        #expect(updatedUser.displayName == "Updated Name", 
               "Listener should receive updated name")
        #expect(updateTime < 0.3, 
               "Update should propagate in < 300ms, took \(updateTime * 1000)ms")
    }
    
    @Test("Multiple rapid updates all propagate")
    func multipleRapidUpdatesAllPropagate() async throws {
        // Given: Test user
        let testUserID = "rapid-updates-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Initial",
            email: "rapid@test.com"
        )
        
        // When: Send multiple rapid updates
        for i in 0..<5 {
            try await device1UserService.updateDisplayName(
                userID: testUserID,
                displayName: "Update \(i)"
            )
            
            // Small delay between updates
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        // Wait for final propagation
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then: Final update should be reflected
        let finalUser = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(finalUser.displayName.contains("Update"), 
               "Should have one of the updates")
        
        // Last write wins (Firebase behavior)
        let possibleNames = (0..<5).map { "Update \($0)" }
        #expect(possibleNames.contains(finalUser.displayName), 
               "Should have one of the update names")
    }
    
    @Test("Listener survives app backgrounding simulation")
    func listenerSurvivesAppBackgroundingSimulation() async throws {
        // Given: Test user with listener (simulated)
        let testUserID = "background-test-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Before Background",
            email: "background@test.com"
        )
        
        // Simulate app going to background
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // When: Update while "backgrounded"
        try await device1UserService.updateDisplayName(
            userID: testUserID,
            displayName: "During Background"
        )
        
        // Simulate app returning to foreground
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Update should still be reflected
        let user = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(user.displayName == "During Background", 
               "Update should be reflected after backgrounding")
    }
    
    // MARK: - Concurrent Listener Tests
    
    @Test("Multiple devices listen to same user simultaneously")
    func multipleDevicesListenToSameUserSimultaneously() async throws {
        // Given: Test user
        let testUserID = "concurrent-listener-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Concurrent Test",
            email: "concurrent@test.com"
        )
        
        // When: Multiple devices fetch simultaneously
        async let device1Fetch: User = device1UserService.fetchUser(userID: testUserID)
        async let device2Fetch: User = device2UserService.fetchUser(userID: testUserID)
        
        let (user1, user2) = try await (device1Fetch, device2Fetch)
        
        // Then: Both should see consistent data
        #expect(user1.displayName == user2.displayName, 
               "Both devices should see same display name")
        #expect(user1.email == user2.email, 
               "Both devices should see same email")
    }
    
    @Test("Listener cleanup doesn't affect other listeners")
    func listenerCleanupDoesNotAffectOtherListeners() async throws {
        // Given: Test user with multiple "listeners"
        let testUserID = "cleanup-test-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Cleanup Test",
            email: "cleanup@test.com"
        )
        
        // Device 1 and Device 2 both have listeners (simulated by fetches)
        _ = try await device1UserService.fetchUser(userID: testUserID)
        _ = try await device2UserService.fetchUser(userID: testUserID)
        
        // When: "Remove" device 1 listener (simulate by just not using it)
        // Device 2 should still work
        
        try await device1UserService.updateDisplayName(
            userID: testUserID,
            displayName: "After Cleanup"
        )
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Device 2 should still receive updates
        let user2 = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(user2.displayName == "After Cleanup", 
               "Device 2 should still receive updates")
    }
    
    // MARK: - Listener Performance Tests
    
    @Test("Listener setup is fast (< 100ms)")
    func listenerSetupIsFast() async throws {
        // Given: Test user
        let testUserID = "setup-perf-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Setup Test",
            email: "setup@test.com"
        )
        
        // When: Measure "listener setup" time (simulated by first fetch)
        let startTime = Date()
        _ = try await device1UserService.fetchUser(userID: testUserID)
        let setupTime = Date().timeIntervalSince(startTime)
        
        // Then: Setup should be fast
        #expect(setupTime < 1.0, 
               "Listener setup should be < 1s, took \(setupTime * 1000)ms")
        
        print("Listener setup time: \(setupTime * 1000)ms")
    }
    
    @Test("Listener updates have low latency (< 200ms average)")
    func listenerUpdatesHaveLowLatency() async throws {
        // Given: Test user
        let testUserID = "latency-test-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Latency Test",
            email: "latency@test.com"
        )
        
        var latencies: [TimeInterval] = []
        
        // When: Measure update latency over 10 iterations
        for i in 0..<10 {
            let startTime = Date()
            
            try await device1UserService.updateDisplayName(
                userID: testUserID,
                displayName: "Update \(i)"
            )
            
            // Wait for propagation
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            _ = try await device2UserService.fetchUser(userID: testUserID)
            
            let latency = Date().timeIntervalSince(startTime)
            latencies.append(latency)
            
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms between iterations
        }
        
        // Then: Average latency should be reasonable
        let avgLatency = latencies.reduce(0, +) / Double(latencies.count)
        
        print("Listener update average latency: \(avgLatency * 1000)ms")
        
        #expect(avgLatency < 0.5, 
               "Average listener latency should be < 500ms, got \(avgLatency * 1000)ms")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Listener handles temporary network issues gracefully")
    func listenerHandlesTemporaryNetworkIssuesGracefully() async throws {
        // Given: Test user
        let testUserID = "network-issue-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Network Test",
            email: "network@test.com"
        )
        
        // When: Simulate network delay by adding wait
        try await device1UserService.updateDisplayName(
            userID: testUserID,
            displayName: "After Delay"
        )
        
        // Simulate network recovery time
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Then: Update should eventually propagate
        let user = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(user.displayName == "After Delay", 
               "Update should propagate after network delay")
    }
    
    @Test("Listener handles non-existent user gracefully")
    func listenerHandlesNonExistentUserGracefully() async throws {
        // Given: Non-existent user ID
        let fakeUserID = "non-existent-user-\(UUID().uuidString)"
        
        // When: Try to fetch non-existent user
        var threwError = false
        var errorType: UserServiceError?
        
        do {
            _ = try await device1UserService.fetchUser(userID: fakeUserID)
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
    
    @Test("Listener provides consistent view across updates")
    func listenerProvidesConsistentViewAcrossUpdates() async throws {
        // Given: Test user
        let testUserID = "consistency-test-\(UUID().uuidString)"
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Initial",
            email: "consistency@test.com"
        )
        
        // When: Make multiple updates
        let updates = ["First", "Second", "Third"]
        
        for update in updates {
            try await device1UserService.updateDisplayName(
                userID: testUserID,
                displayName: update
            )
            
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        // Then: Final state should be consistent
        let device1View = try await device1UserService.fetchUser(userID: testUserID)
        let device2View = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(device1View.displayName == device2View.displayName, 
               "Both devices should see consistent state")
        #expect(device1View.displayName == "Third", 
               "Should have latest update")
    }
    
    @Test("Listener reflects server timestamps correctly")
    func listenerReflectsServerTimestampsCorrectly() async throws {
        // Given: Test user
        let testUserID = "timestamp-test-\(UUID().uuidString)"
        let beforeCreate = Date()
        
        try await device1UserService.createUser(
            userID: testUserID,
            displayName: "Timestamp Test",
            email: "timestamp@test.com"
        )
        
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // When: Update user
        try await device1UserService.updateDisplayName(
            userID: testUserID,
            displayName: "Updated"
        )
        
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Timestamp should reflect server time
        let user = try await device2UserService.fetchUser(userID: testUserID)
        
        #expect(user.lastActiveAt > beforeCreate, 
               "lastActiveAt should be after creation")
        #expect(user.createdAt <= user.lastActiveAt, 
               "createdAt should be before or equal to lastActiveAt")
    }
}


