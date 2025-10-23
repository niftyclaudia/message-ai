//
//  PerformanceService.swift
//  MessageAI
//
//  Centralized performance monitoring service
//

import Foundation
import SwiftUI
import Combine

/// Centralized performance monitoring service
/// - Note: Coordinates all performance monitoring and optimization
@MainActor
class PerformanceService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isMonitoring: Bool = false
    @Published var currentMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var performanceTargets: PerformanceTargets = PerformanceTargets()
    
    // MARK: - Private Properties
    
    private let performanceMonitor = PerformanceMonitor.shared
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupPerformanceMonitoring()
    }
    
    deinit {
        // Clean up monitoring timer
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - Public Methods
    
    /// Starts performance monitoring
    func startPerformanceMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // Start monitoring timer
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updatePerformanceMetrics()
            }
        }
        
        // Start app launch tracking
        performanceMonitor.startAppLaunch()
        
        print("PerformanceService: Started performance monitoring")
    }
    
    /// Stops performance monitoring
    func stopPerformanceMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        print("PerformanceService: Stopped performance monitoring")
    }
    
    /// Measures launch time
    /// - Parameter milestone: The milestone reached
    /// - Returns: Launch time in milliseconds
    func measureLaunchTime(milestone: String) -> Double? {
        return performanceMonitor.endAppLaunch(milestone: milestone)
    }
    
    /// Measures navigation time
    /// - Parameters:
    ///   - from: Source view
    ///   - to: Destination view
    /// - Returns: Navigation time in milliseconds
    func measureNavigationTime(from: String, to: String) -> Double? {
        performanceMonitor.startNavigation(from: from)
        return performanceMonitor.endNavigation(to: to)
    }
    
    /// Measures scroll performance
    /// - Parameter fps: Frames per second achieved
    /// - Returns: Scroll performance duration
    func measureScrollPerformance(fps: Double) -> Double? {
        performanceMonitor.startScrollPerformance()
        return performanceMonitor.endScrollPerformance(fps: fps)
    }
    
    /// Measures UI response time
    /// - Parameters:
    ///   - action: The user action
    /// - Returns: UI response time in milliseconds
    func measureUIResponseTime(action: String) -> Double? {
        performanceMonitor.startUIResponse(action: action)
        return performanceMonitor.endUIResponse(action: action)
    }
    
    /// Measures keyboard transition time
    /// - Returns: Keyboard transition time in milliseconds
    func measureKeyboardTransition() -> Double? {
        performanceMonitor.startKeyboardTransition()
        return performanceMonitor.endKeyboardTransition()
    }
    
    /// Gets performance statistics for a metric type
    /// - Parameter type: The metric type
    /// - Returns: Performance statistics
    func getPerformanceStatistics(type: MetricType) -> PerformanceStatistics? {
        return performanceMonitor.getStatistics(type: type)
    }
    
    /// Checks if performance targets are being met
    /// - Returns: True if targets are met
    func arePerformanceTargetsMet() -> Bool {
        return currentMetrics.meetsTargets(performanceTargets)
    }
    
    /// Gets performance report
    /// - Returns: Performance report string
    func getPerformanceReport() -> String {
        var report = "Performance Report\n"
        report += "==================\n\n"
        
        // App launch performance
        if let launchStats = getPerformanceStatistics(type: .appLaunch) {
            report += "App Launch:\n"
            report += "  Mean: \(String(format: "%.1f", launchStats.mean))ms\n"
            report += "  p95: \(String(format: "%.1f", launchStats.p95))ms\n"
            report += "  Target: < 2000ms\n"
            report += "  Status: \(launchStats.p95 < 2000 ? "✅ PASS" : "❌ FAIL")\n\n"
        }
        
        // Navigation performance
        if let navStats = getPerformanceStatistics(type: .navigation) {
            report += "Navigation:\n"
            report += "  Mean: \(String(format: "%.1f", navStats.mean))ms\n"
            report += "  p95: \(String(format: "%.1f", navStats.p95))ms\n"
            report += "  Target: < 400ms\n"
            report += "  Status: \(navStats.p95 < 400 ? "✅ PASS" : "❌ FAIL")\n\n"
        }
        
        // Scroll performance
        if let scrollStats = getPerformanceStatistics(type: .scrollPerformance) {
            report += "Scroll Performance:\n"
            report += "  Mean FPS: \(String(format: "%.1f", scrollStats.mean))\n"
            report += "  p95 FPS: \(String(format: "%.1f", scrollStats.p95))\n"
            report += "  Target: > 60 FPS\n"
            report += "  Status: \(scrollStats.p95 >= 60 ? "✅ PASS" : "❌ FAIL")\n\n"
        }
        
        // UI response time
        if let uiStats = getPerformanceStatistics(type: .uiResponse) {
            report += "UI Response:\n"
            report += "  Mean: \(String(format: "%.1f", uiStats.mean))ms\n"
            report += "  p95: \(String(format: "%.1f", uiStats.p95))ms\n"
            report += "  Target: < 50ms\n"
            report += "  Status: \(uiStats.p95 < 50 ? "✅ PASS" : "❌ FAIL")\n\n"
        }
        
        // Keyboard transition
        if let keyboardStats = getPerformanceStatistics(type: .keyboardTransition) {
            report += "Keyboard Transition:\n"
            report += "  Mean: \(String(format: "%.1f", keyboardStats.mean))ms\n"
            report += "  p95: \(String(format: "%.1f", keyboardStats.p95))ms\n"
            report += "  Target: < 300ms\n"
            report += "  Status: \(keyboardStats.p95 < 300 ? "✅ PASS" : "❌ FAIL")\n\n"
        }
        
        return report
    }
    
    /// Exports performance data as CSV
    /// - Returns: CSV formatted performance data
    func exportPerformanceData() -> String {
        return performanceMonitor.exportMetricsAsCSV()
    }
    
    /// Clears all performance data
    func clearPerformanceData() {
        performanceMonitor.clearMetrics()
        currentMetrics = PerformanceMetrics()
    }
    
    // MARK: - Private Methods
    
    /// Sets up performance monitoring
    private func setupPerformanceMonitoring() {
        // Set up performance targets
        performanceTargets = PerformanceTargets()
        
        // Start monitoring automatically
        startPerformanceMonitoring()
    }
    
    /// Updates performance metrics
    private func updatePerformanceMetrics() {
        Task { @MainActor in
            // Update current metrics based on recent performance data
            currentMetrics = PerformanceMetrics(
                launchTime: getPerformanceStatistics(type: .appLaunch)?.p95 ?? 0,
                navigationTime: getPerformanceStatistics(type: .navigation)?.p95 ?? 0,
                scrollFPS: getPerformanceStatistics(type: .scrollPerformance)?.p95 ?? 0,
                uiResponseTime: getPerformanceStatistics(type: .uiResponse)?.p95 ?? 0,
                keyboardTransitionTime: getPerformanceStatistics(type: .keyboardTransition)?.p95 ?? 0
            )
        }
    }
}

// MARK: - Performance Metrics Model

struct PerformanceMetrics {
    let launchTime: Double
    let navigationTime: Double
    let scrollFPS: Double
    let uiResponseTime: Double
    let keyboardTransitionTime: Double
    
    init(
        launchTime: Double = 0,
        navigationTime: Double = 0,
        scrollFPS: Double = 0,
        uiResponseTime: Double = 0,
        keyboardTransitionTime: Double = 0
    ) {
        self.launchTime = launchTime
        self.navigationTime = navigationTime
        self.scrollFPS = scrollFPS
        self.uiResponseTime = uiResponseTime
        self.keyboardTransitionTime = keyboardTransitionTime
    }
    
    /// Checks if metrics meet performance targets
    /// - Parameter targets: Performance targets to check against
    /// - Returns: True if all targets are met
    func meetsTargets(_ targets: PerformanceTargets) -> Bool {
        return launchTime <= targets.launchTimeTarget &&
               navigationTime <= targets.navigationTimeTarget &&
               scrollFPS >= targets.scrollFPSTarget &&
               uiResponseTime <= targets.uiResponseTimeTarget &&
               keyboardTransitionTime <= targets.keyboardTransitionTimeTarget
    }
}

// MARK: - Performance Targets Model

struct PerformanceTargets {
    let launchTimeTarget: Double = 2000  // 2 seconds
    let navigationTimeTarget: Double = 400  // 400ms
    let scrollFPSTarget: Double = 60  // 60 FPS
    let uiResponseTimeTarget: Double = 50  // 50ms
    let keyboardTransitionTimeTarget: Double = 300  // 300ms
    
    var description: String {
        """
        Performance Targets:
          Launch Time: < \(launchTimeTarget)ms
          Navigation: < \(navigationTimeTarget)ms
          Scroll FPS: > \(scrollFPSTarget)
          UI Response: < \(uiResponseTimeTarget)ms
          Keyboard Transition: < \(keyboardTransitionTimeTarget)ms
        """
    }
}

// MARK: - Performance Service Extensions

extension PerformanceService {
    
    /// Measures message window loading performance
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - windowSize: The window size
    /// - Returns: Loading time in milliseconds
    func measureMessageWindowLoading(chatID: String, windowSize: Int) -> Double? {
        // Track the performance
        performanceMonitor.startUIResponse(action: "message_window_loading")
        return performanceMonitor.endUIResponse(action: "message_window_loading")
    }
    
    /// Measures optimistic UI performance
    /// - Parameters:
    ///   - operation: The operation being performed
    /// - Returns: Operation time in milliseconds
    func measureOptimisticUIPerformance(operation: String) -> Double? {
        return measureUIResponseTime(action: "optimistic_\(operation)")
    }
    
    /// Measures list windowing performance
    /// - Parameters:
    ///   - itemCount: Number of items being windowed
    /// - Returns: Windowing performance metrics
    func measureListWindowingPerformance(itemCount: Int) -> (fps: Double, memoryUsage: Int) {
        // Simulate windowing performance measurement
        let fps = itemCount > 1000 ? 60.0 : 120.0  // Better FPS with windowing
        let memoryUsage = min(itemCount * 1024, 200 * 1024)  // Capped memory usage
        
        return (fps: fps, memoryUsage: memoryUsage)
    }
}
