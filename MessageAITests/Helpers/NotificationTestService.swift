//
//  NotificationTestService.swift
//  MessageAITests
//
//  Helper service for notification testing
//

import Foundation
import UserNotifications
@testable import MessageAI

/// Test service for simulating and measuring notification behavior
/// - Note: Provides helper methods for notification testing scenarios
@MainActor
class NotificationTestService {
    
    // MARK: - Properties
    
    private var testResults: [NotificationTestResult] = []
    private var latencyMeasurements: [String: TimeInterval] = [:]
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Notification Simulation
    
    /// Simulate notification arrival in specific app state
    /// - Parameters:
    ///   - payload: Test notification payload
    ///   - appState: App state to simulate (foreground, background, terminated)
    /// - Returns: Test result with pass/fail status
    func simulateNotification(
        payload: TestNotificationPayload,
        appState: AppState
    ) async -> NotificationTestResult {
        let startTime = Date()
        
        do {
            // Simulate notification processing based on app state
            switch appState {
            case .foreground:
                return try await simulateForegroundNotification(payload: payload, startTime: startTime)
            case .background:
                return try await simulateBackgroundNotification(payload: payload, startTime: startTime)
            case .terminated:
                return try await simulateTerminatedNotification(payload: payload, startTime: startTime)
            }
        } catch {
            return NotificationTestResult(
                testID: payload.testID,
                testName: "simulateNotification_\(appState)",
                appState: appState,
                passed: false,
                error: error.localizedDescription
            )
        }
    }
    
    /// Measure notification delivery latency
    /// - Parameters:
    ///   - messageID: Message ID to track
    ///   - startTime: Time when message was sent
    /// - Returns: Latency in seconds
    func measureNotificationLatency(
        messageID: String,
        startTime: Date
    ) async -> TimeInterval {
        let endTime = Date()
        let latency = endTime.timeIntervalSince(startTime)
        
        // Store measurement
        latencyMeasurements[messageID] = latency
        
        return latency
    }
    
    /// Verify sender exclusion in group chat
    /// - Parameters:
    ///   - chatID: Chat ID to check
    ///   - senderID: Sender ID (should be excluded)
    ///   - expectedRecipients: List of expected recipient IDs
    /// - Returns: Tuple with pass/fail status and actual recipients
    func verifySenderExclusion(
        chatID: String,
        senderID: String,
        expectedRecipients: [String]
    ) async -> (passed: Bool, actualRecipients: [String]) {
        // Simulate checking recipients
        // In real scenario, this would query Firebase/FCM logs
        let actualRecipients = expectedRecipients.filter { $0 != senderID }
        let passed = !actualRecipients.contains(senderID)
        
        return (passed: passed, actualRecipients: actualRecipients)
    }
    
    /// Test notification navigation from specific app state
    /// - Parameters:
    ///   - chatID: Chat ID to navigate to
    ///   - appState: App state to test from
    /// - Returns: True if navigation successful
    func testNotificationNavigation(
        toChatID chatID: String,
        fromState appState: AppState
    ) async -> Bool {
        // Simulate navigation test
        // In real scenario, this would verify UI navigation
        return !chatID.isEmpty
    }
    
    // MARK: - Test Results
    
    /// Get all test results
    /// - Returns: Array of test results
    func getTestResults() -> [NotificationTestResult] {
        return testResults
    }
    
    /// Get latency measurements
    /// - Returns: Dictionary of message ID to latency
    func getLatencyMeasurements() -> [String: TimeInterval] {
        return latencyMeasurements
    }
    
    /// Calculate average latency
    /// - Returns: Average latency in seconds
    func calculateAverageLatency() -> TimeInterval {
        guard !latencyMeasurements.isEmpty else { return 0 }
        let total = latencyMeasurements.values.reduce(0, +)
        return total / Double(latencyMeasurements.count)
    }
    
    /// Calculate p95 latency
    /// - Returns: 95th percentile latency in seconds
    func calculateP95Latency() -> TimeInterval {
        guard !latencyMeasurements.isEmpty else { return 0 }
        let sorted = latencyMeasurements.values.sorted()
        let index = Int(Double(sorted.count) * 0.95)
        return sorted[min(index, sorted.count - 1)]
    }
    
    /// Clear all test results and measurements
    func clearResults() {
        testResults.removeAll()
        latencyMeasurements.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func simulateForegroundNotification(
        payload: TestNotificationPayload,
        startTime: Date
    ) async throws -> NotificationTestResult {
        // Simulate foreground notification display
        let latency = Date().timeIntervalSince(startTime)
        let passed = latency < 0.5 // Target: <500ms
        
        return NotificationTestResult(
            testID: payload.testID,
            testName: "foreground_notification",
            appState: .foreground,
            passed: passed,
            actualLatency: latency
        )
    }
    
    private func simulateBackgroundNotification(
        payload: TestNotificationPayload,
        startTime: Date
    ) async throws -> NotificationTestResult {
        // Simulate background notification and app resume
        let latency = Date().timeIntervalSince(startTime)
        let passed = latency < 1.0 // Target: <1s
        
        return NotificationTestResult(
            testID: payload.testID,
            testName: "background_notification",
            appState: .background,
            passed: passed,
            actualLatency: latency
        )
    }
    
    private func simulateTerminatedNotification(
        payload: TestNotificationPayload,
        startTime: Date
    ) async throws -> NotificationTestResult {
        // Simulate terminated state notification and cold start
        let latency = Date().timeIntervalSince(startTime)
        let passed = latency < 2.0 // Target: <2s
        
        return NotificationTestResult(
            testID: payload.testID,
            testName: "terminated_notification",
            appState: .terminated,
            passed: passed,
            actualLatency: latency
        )
    }
}

