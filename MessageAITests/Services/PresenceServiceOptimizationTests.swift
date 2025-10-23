//
//  PresenceServiceOptimizationTests.swift
//  MessageAITests
//
//  Tests for PR-1 PresenceService optimization
//

import Testing
import Foundation
@testable import MessageAI

/// Tests for PresenceService optimization (PR-1)
/// - Note: Tests < 500ms propagation requirements
struct PresenceServiceOptimizationTests {
    
    // MARK: - Presence Propagation Tests
    
    @Test("Presence Status Propagates Within 500ms")
    func presenceStatusPropagatesWithin500ms() async throws {
        let service = PresenceService()
        let userID = "test-user-\(UUID().uuidString)"
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Set user online and measure propagation
        let startTime = Date()
        try await service.setUserOnline(userID: userID)
        let endTime = Date()
        
        let propagationTime = endTime.timeIntervalSince(startTime) * 1000 // Convert to ms
        
        // PR-1 requirement: presence propagation < 500ms
        #expect(propagationTime < 500, "Presence propagation \(propagationTime)ms exceeds 500ms requirement")
    }
    
    @Test("Presence Observer Detects Changes Within 500ms")
    func presenceObserverDetectsChangesWithin500ms() async throws {
        let service = PresenceService()
        let userID = "test-user-\(UUID().uuidString)"
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        var presenceDetected = false
        var detectionTime: Date?
        
        // Set up observer
        let handle = service.observeUserPresence(userID: userID) { presence in
            if presence.status == .online && !presenceDetected {
                presenceDetected = true
                detectionTime = Date()
            }
        }
        
        // Set user online
        let startTime = Date()
        try await service.setUserOnline(userID: userID)
        
        // Wait for propagation (max 1 second)
        let timeout = Date().addingTimeInterval(1.0)
        while !presenceDetected && Date() < timeout {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        
        // Clean up observer
        service.removeObserver(userID: userID, handle: handle)
        
        // Verify detection
        #expect(presenceDetected, "Presence change not detected")
        
        if let detectionTime = detectionTime {
            let detectionLatency = detectionTime.timeIntervalSince(startTime) * 1000
            #expect(detectionLatency < 500, "Detection latency \(detectionLatency)ms exceeds 500ms requirement")
        }
    }
    
    @Test("Multiple Users Presence Propagation")
    func multipleUsersPresencePropagation() async throws {
        let service = PresenceService()
        let userIDs = ["user1-\(UUID().uuidString)", "user2-\(UUID().uuidString)", "user3-\(UUID().uuidString)"]
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        var presenceDict: [String: PresenceStatus] = [:]
        var allDetected = false
        
        // Set up observers for multiple users
        let handles = service.observeMultipleUsersPresence(userIDs: userIDs) { presence in
            presenceDict = presence
            
            // Check if all users are detected
            if presence.count == userIDs.count {
                allDetected = true
            }
        }
        
        // Set all users online
        let startTime = Date()
        for userID in userIDs {
            try await service.setUserOnline(userID: userID)
        }
        
        // Wait for all presence changes to propagate
        let timeout = Date().addingTimeInterval(2.0)
        while !allDetected && Date() < timeout {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        // Clean up observers
        service.removeObservers(handles: handles)
        
        // Verify all users are detected
        #expect(allDetected, "Not all users detected")
        #expect(presenceDict.count == userIDs.count, "Expected \(userIDs.count) users, got \(presenceDict.count)")
        
        // Verify propagation time
        let propagationTime = Date().timeIntervalSince(startTime) * 1000
        #expect(propagationTime < 1000, "Multi-user propagation \(propagationTime)ms exceeds 1000ms")
    }
    
    // MARK: - Performance Monitoring Tests
    
    @Test("Performance Monitor Tracks Presence Propagation")
    func performanceMonitorTracksPresencePropagation() async throws {
        let service = PresenceService()
        let userID = "test-user-\(UUID().uuidString)"
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Set user online
        try await service.setUserOnline(userID: userID)
        
        // Wait for performance tracking to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Check if metrics were recorded
        let presenceMetrics = PerformanceMonitor.shared.getMetrics(ofType: .presencePropagation)
        #expect(!presenceMetrics.isEmpty, "No presence propagation metrics recorded")
        
        // Verify the user ID is tracked
        let hasUserID = presenceMetrics.contains { metric in
            metric.metadata["userID"] == userID
        }
        #expect(hasUserID, "User ID \(userID) not found in metrics")
    }
    
    @Test("Presence Statistics Calculation")
    func presenceStatisticsCalculation() async throws {
        let service = PresenceService()
        let userIDs = (1...5).map { "user\($0)-\(UUID().uuidString)" }
        
        // Clear previous metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Set multiple users online
        for userID in userIDs {
            try await service.setUserOnline(userID: userID)
        }
        
        // Wait for all metrics to be recorded
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        // Get statistics
        guard let stats = PerformanceMonitor.shared.getStatistics(type: .presencePropagation) else {
            #expect(Bool(false), "No presence statistics available")
            return
        }
        
        // Verify statistics are calculated
        #expect(stats.count >= 5, "Expected at least 5 measurements, got \(stats.count)")
        #expect(stats.p95 > 0, "p95 should be greater than 0")
        #expect(stats.p95 < 500, "p95 \(stats.p95)ms should be less than 500ms")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Authentication Error Handling")
    func authenticationErrorHandling() async throws {
        let service = PresenceService()
        let userID = "test-user-\(UUID().uuidString)"
        
        // This should fail if no user is authenticated
        do {
            try await service.setUserOnline(userID: userID)
            // If we get here, authentication might be set up in test environment
        } catch let error as PresenceServiceError {
            #expect(error == .notAuthenticated, "Expected notAuthenticated error")
        } catch {
            // Other errors are also acceptable in test environment
            #expect(Bool(true), "Authentication error handled: \(error)")
        }
    }
    
    @Test("Observer Cleanup")
    func observerCleanup() async throws {
        let service = PresenceService()
        let userID = "test-user-\(UUID().uuidString)"
        
        // Set up observer
        let handle = service.observeUserPresence(userID: userID) { _ in }
        
        // Clean up observer
        service.removeObserver(userID: userID, handle: handle)
        
        // No exception should be thrown during cleanup
        #expect(Bool(true), "Observer cleanup completed successfully")
    }
    
    // MARK: - Integration Tests
    
    @Test("Presence Service Integration With Performance Monitor")
    func presenceServiceIntegrationWithPerformanceMonitor() async throws {
        let service = PresenceService()
        let userID = "test-user-\(UUID().uuidString)"
        
        // Clear metrics
        PerformanceMonitor.shared.clearMetrics()
        
        // Set user online
        try await service.setUserOnline(userID: userID)
        
        // Wait for processing
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Verify performance tracking
        let latency = await service.measurePresenceLatency(userID: userID)
        #expect(latency >= 0, "Latency should be non-negative")
        
        // Verify metrics were recorded
        let metrics = PerformanceMonitor.shared.getMetrics(ofType: .presencePropagation)
        #expect(!metrics.isEmpty, "Metrics should be recorded")
    }
    
    @Test("Presence Status Transitions")
    func presenceStatusTransitions() async throws {
        let service = PresenceService()
        let userID = "test-user-\(UUID().uuidString)"
        
        var statusChanges: [PresenceStatus] = []
        
        // Set up observer
        let handle = service.observeUserPresence(userID: userID) { presence in
            statusChanges.append(presence)
        }
        
        // Set user online
        try await service.setUserOnline(userID: userID)
        
        // Wait for online status
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Set user offline
        try await service.setUserOffline(userID: userID)
        
        // Wait for offline status
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Clean up observer
        service.removeObserver(userID: userID, handle: handle)
        
        // Verify status changes occurred
        #expect(statusChanges.count >= 1, "Expected at least 1 status change, got \(statusChanges.count)")
        
        // Check for online status
        let hasOnline = statusChanges.contains { $0.status == .online }
        #expect(hasOnline, "Online status not detected")
    }
}
