//
//  PerformanceMonitor.swift
//  MessageAI
//
//  Performance monitoring utility for tracking app metrics
//

import Foundation
import os.log

/// Performance monitoring utility for tracking metrics
/// - Note: Tracks latency, FPS, and other performance indicators
class PerformanceMonitor {
    
    // MARK: - Singleton
    
    static let shared = PerformanceMonitor()
    
    // MARK: - Properties
    
    private var metrics: [PerformanceMetric] = []
    private let logger = OSLog(subsystem: "com.messageai.app", category: "Performance")
    private var messageLatencyTracking: [String: Date] = [:]  // messageID -> send time
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Message Latency Tracking
    
    /// Marks the start of message send operation
    /// - Parameter messageID: Unique message identifier
    func startMessageSend(messageID: String) {
        messageLatencyTracking[messageID] = Date()
        log("Message send started: \(messageID)")
    }
    
    /// Marks the end of message send operation and calculates latency
    /// - Parameters:
    ///   - messageID: Unique message identifier
    ///   - phase: Which phase completed (e.g., "serverAck", "rendered")
    /// - Returns: Latency in milliseconds
    @discardableResult
    func endMessageSend(messageID: String, phase: String = "rendered") -> Double? {
        guard let startTime = messageLatencyTracking[messageID] else {
            log("Warning: No start time found for message \(messageID)")
            return nil
        }
        
        let endTime = Date()
        let latencyMs = endTime.timeIntervalSince(startTime) * 1000
        
        let metric = PerformanceMetric(
            type: .messageLatency,
            value: latencyMs,
            metadata: ["messageID": messageID, "phase": phase]
        )
        
        metrics.append(metric)
        messageLatencyTracking.removeValue(forKey: messageID)
        
        log("Message \(messageID) \(phase) latency: \(String(format: "%.1f", latencyMs))ms")
        
        return latencyMs
    }
    
    // MARK: - App Launch Tracking
    
    private var appLaunchStart: Date?
    
    /// Marks the start of app launch
    func startAppLaunch() {
        appLaunchStart = Date()
        log("App launch started")
    }
    
    /// Marks the end of app launch and calculates time
    /// - Parameter milestone: Which milestone reached (e.g., "inbox", "firstRender")
    /// - Returns: Launch time in milliseconds
    @discardableResult
    func endAppLaunch(milestone: String) -> Double? {
        guard let startTime = appLaunchStart else {
            log("Warning: No app launch start time found")
            return nil
        }
        
        let endTime = Date()
        let launchTimeMs = endTime.timeIntervalSince(startTime) * 1000
        
        let metric = PerformanceMetric(
            type: .appLaunch,
            value: launchTimeMs,
            metadata: ["milestone": milestone]
        )
        
        metrics.append(metric)
        
        log("App launch to \(milestone): \(String(format: "%.1f", launchTimeMs))ms")
        
        return launchTimeMs
    }
    
    // MARK: - Navigation Tracking
    
    private var navigationStart: Date?
    
    /// Marks the start of navigation
    /// - Parameter from: Source view
    func startNavigation(from: String) {
        navigationStart = Date()
        log("Navigation started from \(from)")
    }
    
    /// Marks the end of navigation and calculates time
    /// - Parameters:
    ///   - to: Destination view
    /// - Returns: Navigation time in milliseconds
    @discardableResult
    func endNavigation(to: String) -> Double? {
        guard let startTime = navigationStart else {
            log("Warning: No navigation start time found")
            return nil
        }
        
        let endTime = Date()
        let navTimeMs = endTime.timeIntervalSince(startTime) * 1000
        
        let metric = PerformanceMetric(
            type: .navigation,
            value: navTimeMs,
            metadata: ["to": to]
        )
        
        metrics.append(metric)
        navigationStart = nil
        
        log("Navigation to \(to): \(String(format: "%.1f", navTimeMs))ms")
        
        return navTimeMs
    }
    
    // MARK: - Sync Tracking
    
    private var syncStart: Date?
    
    /// Marks the start of sync operation
    func startSync() {
        syncStart = Date()
        log("Sync started")
    }
    
    /// Marks the end of sync operation and calculates time
    /// - Parameter messageCount: Number of messages synced
    /// - Returns: Sync time in milliseconds
    @discardableResult
    func endSync(messageCount: Int = 0) -> Double? {
        guard let startTime = syncStart else {
            log("Warning: No sync start time found")
            return nil
        }
        
        let endTime = Date()
        let syncTimeMs = endTime.timeIntervalSince(startTime) * 1000
        
        let metric = PerformanceMetric(
            type: .syncTime,
            value: syncTimeMs,
            metadata: ["messageCount": "\(messageCount)"]
        )
        
        metrics.append(metric)
        syncStart = nil
        
        log("Sync completed in \(String(format: "%.1f", syncTimeMs))ms (\(messageCount) messages)")
        
        return syncTimeMs
    }
    
    // MARK: - Presence Propagation Tracking
    
    private var presenceChanges: [String: Date] = [:]  // userID -> change time
    
    /// Marks the start of presence change
    /// - Parameter userID: User whose presence changed
    func startPresenceChange(userID: String) {
        presenceChanges[userID] = Date()
        log("Presence change started for user \(userID)")
    }
    
    /// Marks the detection of presence change and calculates propagation time
    /// - Parameter userID: User whose presence changed
    /// - Returns: Propagation time in milliseconds
    @discardableResult
    func endPresenceChange(userID: String) -> Double? {
        guard let startTime = presenceChanges[userID] else {
            log("Warning: No presence change start time for user \(userID)")
            return nil
        }
        
        let endTime = Date()
        let propagationMs = endTime.timeIntervalSince(startTime) * 1000
        
        let metric = PerformanceMetric(
            type: .presencePropagation,
            value: propagationMs,
            metadata: ["userID": userID]
        )
        
        metrics.append(metric)
        presenceChanges.removeValue(forKey: userID)
        
        log("Presence propagation for \(userID): \(String(format: "%.1f", propagationMs))ms")
        
        return propagationMs
    }
    
    // MARK: - Typing Indicator Tracking
    
    private var typingStart: Date?
    
    /// Marks when typing indicator should appear
    func startTypingIndicator() {
        typingStart = Date()
        log("Typing indicator start")
    }
    
    /// Marks when typing indicator appears
    /// - Returns: Appearance time in milliseconds
    @discardableResult
    func endTypingIndicator() -> Double? {
        guard let startTime = typingStart else {
            log("Warning: No typing indicator start time")
            return nil
        }
        
        let endTime = Date()
        let appearanceMs = endTime.timeIntervalSince(startTime) * 1000
        
        let metric = PerformanceMetric(
            type: .typingIndicator,
            value: appearanceMs,
            metadata: [:]
        )
        
        metrics.append(metric)
        typingStart = nil
        
        log("Typing indicator appearance: \(String(format: "%.1f", appearanceMs))ms")
        
        return appearanceMs
    }
    
    // MARK: - Metrics Retrieval & Analysis
    
    /// Gets all metrics of a specific type
    /// - Parameter type: The metric type to filter by
    /// - Returns: Array of matching metrics
    func getMetrics(ofType type: MetricType) -> [PerformanceMetric] {
        return metrics.filter { $0.type == type }
    }
    
    /// Calculates percentile for a specific metric type
    /// - Parameters:
    ///   - type: The metric type
    ///   - percentile: Percentile to calculate (e.g., 95 for p95)
    /// - Returns: Percentile value in milliseconds
    func calculatePercentile(type: MetricType, percentile: Double) -> Double? {
        let values = getMetrics(ofType: type).map { $0.value }.sorted()
        guard !values.isEmpty else { return nil }
        
        let index = Int(Double(values.count) * percentile / 100.0)
        let safeIndex = min(max(0, index), values.count - 1)
        
        return values[safeIndex]
    }
    
    /// Gets statistics for a specific metric type
    /// - Parameter type: The metric type
    /// - Returns: Statistics (min, max, mean, p50, p95, p99)
    func getStatistics(type: MetricType) -> PerformanceStatistics? {
        let values = getMetrics(ofType: type).map { $0.value }
        guard !values.isEmpty else { return nil }
        
        let sorted = values.sorted()
        let count = Double(sorted.count)
        
        return PerformanceStatistics(
            type: type,
            count: sorted.count,
            min: sorted.first!,
            max: sorted.last!,
            mean: sorted.reduce(0, +) / count,
            p50: calculatePercentile(type: type, percentile: 50) ?? 0,
            p95: calculatePercentile(type: type, percentile: 95) ?? 0,
            p99: calculatePercentile(type: type, percentile: 99) ?? 0
        )
    }
    
    /// Clears all recorded metrics
    func clearMetrics() {
        metrics.removeAll()
        messageLatencyTracking.removeAll()
        presenceChanges.removeAll()
        log("All metrics cleared")
    }
    
    /// Exports metrics as CSV string
    /// - Returns: CSV formatted string
    func exportMetricsAsCSV() -> String {
        var csv = "Timestamp,Type,Value(ms),Metadata\n"
        
        for metric in metrics {
            let metadataStr = metric.metadata.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
            csv += "\(metric.timestamp),\(metric.type.rawValue),\(metric.value),\(metadataStr)\n"
        }
        
        return csv
    }
    
    // MARK: - PR-4 Lifecycle Metrics
    
    private var reconnectStart: Date?
    private var deepLinkStart: Date?
    
    /// Marks the start of reconnect operation
    func startReconnect() {
        reconnectStart = Date()
        log("Reconnect started")
    }
    
    /// Marks the end of reconnect operation
    /// - Returns: Reconnect time in milliseconds
    @discardableResult
    func endReconnect() -> Double? {
        guard let startTime = reconnectStart else {
            log("Warning: No reconnect start time")
            return nil
        }
        
        let endTime = Date()
        let reconnectMs = endTime.timeIntervalSince(startTime) * 1000
        
        let metric = PerformanceMetric(
            type: .reconnectLatency,
            value: reconnectMs,
            metadata: [:]
        )
        
        metrics.append(metric)
        reconnectStart = nil
        
        log("Reconnect completed in \(String(format: "%.1f", reconnectMs))ms")
        
        return reconnectMs
    }
    
    /// Marks the start of deep link navigation
    func startDeepLinkNavigation() {
        deepLinkStart = Date()
        log("Deep link navigation started")
    }
    
    /// Marks the end of deep link navigation
    /// - Returns: Navigation time in milliseconds
    @discardableResult
    func endDeepLinkNavigation() -> Double? {
        guard let startTime = deepLinkStart else {
            log("Warning: No deep link navigation start time")
            return nil
        }
        
        let endTime = Date()
        let navMs = endTime.timeIntervalSince(startTime) * 1000
        
        let metric = PerformanceMetric(
            type: .deepLinkNavigation,
            value: navMs,
            metadata: [:]
        )
        
        metrics.append(metric)
        deepLinkStart = nil
        
        log("Deep link navigation completed in \(String(format: "%.1f", navMs))ms")
        
        return navMs
    }
    
    /// Track a lifecycle transition
    /// - Parameters:
    ///   - from: Source state
    ///   - to: Destination state
    ///   - duration: Transition duration in seconds
    func trackLifecycleTransition(from: AppLifecycleState, to: AppLifecycleState, duration: TimeInterval) {
        let durationMs = duration * 1000
        
        let metric = PerformanceMetric(
            type: .lifecycleTransition,
            value: durationMs,
            metadata: [
                "from": from.rawValue,
                "to": to.rawValue
            ]
        )
        
        metrics.append(metric)
        
        log("Lifecycle transition \(from.rawValue) → \(to.rawValue): \(String(format: "%.1f", durationMs))ms")
    }
    
    // MARK: - Logging
    
    private func log(_ message: String) {
        os_log("%{public}@", log: logger, type: .debug, message)
    }
}

// MARK: - PerformanceMetric Model

struct PerformanceMetric {
    let id: UUID = UUID()
    let timestamp: Date = Date()
    let type: MetricType
    let value: Double  // Value in milliseconds
    let metadata: [String: String]
}

// MARK: - MetricType Enum

enum MetricType: String, CaseIterable {
    case messageLatency = "message_latency"
    case appLaunch = "app_launch"
    case navigation = "navigation"
    case syncTime = "sync_time"
    case presencePropagation = "presence_propagation"
    case typingIndicator = "typing_indicator"
    case scrollPerformance = "scroll_performance"
    // PR #4: New lifecycle metrics
    case lifecycleTransition = "lifecycle_transition"
    case reconnectLatency = "reconnect_latency"
    case deepLinkNavigation = "deeplink_navigation"
}

// MARK: - PerformanceStatistics Model

struct PerformanceStatistics {
    let type: MetricType
    let count: Int
    let min: Double
    let max: Double
    let mean: Double
    let p50: Double
    let p95: Double
    let p99: Double
    
    var description: String {
        """
        \(type.rawValue) Statistics (n=\(count)):
          Min: \(String(format: "%.1f", min))ms
          Max: \(String(format: "%.1f", max))ms
          Mean: \(String(format: "%.1f", mean))ms
          p50: \(String(format: "%.1f", p50))ms
          p95: \(String(format: "%.1f", p95))ms
          p99: \(String(format: "%.1f", p99))ms
        """
    }
}

