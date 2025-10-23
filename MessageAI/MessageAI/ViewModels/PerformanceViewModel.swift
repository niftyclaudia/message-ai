//
//  PerformanceViewModel.swift
//  MessageAI
//
//  Performance view model for managing performance state and metrics
//

import Foundation
import SwiftUI
import Combine

/// Performance view model for managing performance state and metrics
/// - Note: Coordinates performance monitoring and optimization across the app
@MainActor
class PerformanceViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isPerformanceMonitoring: Bool = false
    @Published var currentMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var performanceTargets: PerformanceTargets = PerformanceTargets()
    @Published var isOptimisticUIEnabled: Bool = true
    @Published var isListWindowingEnabled: Bool = true
    @Published var isKeyboardOptimizationEnabled: Bool = true
    @Published var performanceReport: String = ""
    @Published var isGeneratingReport: Bool = false
    
    // MARK: - Private Properties
    
    private let performanceService: PerformanceService
    private let optimisticUI: OptimisticUI
    private let keyboardOptimizer: KeyboardOptimizer
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        performanceService: PerformanceService? = nil,
        optimisticUI: OptimisticUI? = nil,
        keyboardOptimizer: KeyboardOptimizer? = nil
    ) {
        self.performanceService = performanceService ?? PerformanceService()
        self.optimisticUI = optimisticUI ?? OptimisticUI()
        self.keyboardOptimizer = keyboardOptimizer ?? KeyboardOptimizer()
        
        Task { @MainActor in
            setupPerformanceMonitoring()
        }
    }
    
    // MARK: - Public Methods
    
    /// Starts performance monitoring
    func startPerformanceMonitoring() {
        performanceService.startPerformanceMonitoring()
        isPerformanceMonitoring = true
        
        // Start keyboard optimization
        if isKeyboardOptimizationEnabled {
            keyboardOptimizer.optimizeKeyboardHandling()
        }
    }
    
    /// Stops performance monitoring
    func stopPerformanceMonitoring() {
        performanceService.stopPerformanceMonitoring()
        isPerformanceMonitoring = false
    }
    
    /// Measures app launch performance
    /// - Parameter milestone: The milestone reached
    /// - Returns: Launch time in milliseconds
    func measureLaunchTime(milestone: String) -> Double? {
        return performanceService.measureLaunchTime(milestone: milestone)
    }
    
    /// Measures navigation performance
    /// - Parameters:
    ///   - from: Source view
    ///   - to: Destination view
    /// - Returns: Navigation time in milliseconds
    func measureNavigationTime(from: String, to: String) -> Double? {
        return performanceService.measureNavigationTime(from: from, to: to)
    }
    
    /// Measures scroll performance
    /// - Parameter fps: Frames per second achieved
    /// - Returns: Scroll performance duration
    func measureScrollPerformance(fps: Double) -> Double? {
        return performanceService.measureScrollPerformance(fps: fps)
    }
    
    /// Measures UI response time
    /// - Parameters:
    ///   - action: The user action
    /// - Returns: UI response time in milliseconds
    func measureUIResponseTime(action: String) -> Double? {
        return performanceService.measureUIResponseTime(action: action)
    }
    
    /// Measures keyboard transition time
    /// - Returns: Keyboard transition time in milliseconds
    func measureKeyboardTransition() -> Double? {
        return performanceService.measureKeyboardTransition()
    }
    
    /// Performs optimistic operation
    /// - Parameters:
    ///   - operation: The operation to perform
    ///   - fallback: Fallback value if operation fails
    /// - Returns: Result of the operation
    func performOptimisticOperation<T>(
        operation: @escaping () async throws -> T,
        fallback: T
    ) async -> T {
        guard isOptimisticUIEnabled else {
            return try! await operation()
        }
        
        return await optimisticUI.performOptimisticOperation(
            operation: operation,
            fallback: fallback
        )
    }
    
    /// Retries failed operation
    /// - Parameters:
    ///   - operation: The operation to retry
    ///   - maxRetries: Maximum number of retries
    /// - Returns: Result of the retry operation
    func retryFailedOperation<T>(
        operation: @escaping () async throws -> T,
        maxRetries: Int = 3
    ) async throws -> T {
        return try await optimisticUI.retryFailedOperation(
            operation: operation,
            maxRetries: maxRetries
        )
    }
    
    /// Updates UI state
    /// - Parameter state: The new UI state
    func updateUIState(_ state: UIState) {
        optimisticUI.updateUIState(state)
    }
    
    /// Gets current UI state
    /// - Returns: Current UI state
    func getCurrentUIState() -> UIState {
        return optimisticUI.currentState
    }
    
    /// Gets error message if in error state
    /// - Returns: Error message or nil
    func getErrorMessage() -> String? {
        return optimisticUI.getErrorMessage()
    }
    
    /// Checks if currently in optimistic state
    /// - Returns: True if in optimistic state
    func isInOptimisticState() -> Bool {
        return optimisticUI.isInOptimisticState()
    }
    
    /// Checks if currently retrying
    /// - Returns: True if retrying
    func isRetrying() -> Bool {
        return optimisticUI.isRetrying()
    }
    
    /// Handles keyboard transition
    /// - Parameter height: New keyboard height
    func handleKeyboardTransition(height: CGFloat) {
        guard isKeyboardOptimizationEnabled else { return }
        keyboardOptimizer.handleKeyboardTransition(height: height)
    }
    
    /// Adds haptic feedback for interaction
    /// - Parameter interaction: The haptic interaction type
    func addHapticFeedback(for interaction: HapticInteraction) {
        guard isKeyboardOptimizationEnabled else { return }
        keyboardOptimizer.addHapticFeedback(for: interaction)
    }
    
    /// Gets keyboard safe area
    /// - Returns: Safe area height
    func getKeyboardSafeArea() -> CGFloat {
        return keyboardOptimizer.getKeyboardSafeArea()
    }
    
    /// Checks if keyboard is transitioning
    /// - Returns: True if transitioning
    func isKeyboardTransitioning() -> Bool {
        return keyboardOptimizer.isKeyboardTransitioning()
    }
    
    /// Gets keyboard animation
    /// - Returns: Animation curve for keyboard transitions
    func getKeyboardAnimation() -> Animation {
        return keyboardOptimizer.getKeyboardAnimation()
    }
    
    /// Generates performance report
    func generatePerformanceReport() async {
        isGeneratingReport = true
        
        // Generate report in background
        let report = performanceService.getPerformanceReport()
        
        await MainActor.run {
            performanceReport = report
            isGeneratingReport = false
        }
    }
    
    /// Exports performance data
    /// - Returns: CSV formatted performance data
    func exportPerformanceData() -> String {
        return performanceService.exportPerformanceData()
    }
    
    /// Clears performance data
    func clearPerformanceData() {
        performanceService.clearPerformanceData()
        performanceReport = ""
    }
    
    /// Checks if performance targets are met
    /// - Returns: True if targets are met
    func arePerformanceTargetsMet() -> Bool {
        return performanceService.arePerformanceTargetsMet()
    }
    
    /// Toggles optimistic UI
    /// - Parameter enabled: Whether to enable optimistic UI
    func toggleOptimisticUI(enabled: Bool) {
        isOptimisticUIEnabled = enabled
    }
    
    /// Toggles list windowing
    /// - Parameter enabled: Whether to enable list windowing
    func toggleListWindowing(enabled: Bool) {
        isListWindowingEnabled = enabled
    }
    
    /// Toggles keyboard optimization
    /// - Parameter enabled: Whether to enable keyboard optimization
    func toggleKeyboardOptimization(enabled: Bool) {
        isKeyboardOptimizationEnabled = enabled
        
        if enabled {
            keyboardOptimizer.optimizeKeyboardHandling()
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up performance monitoring
    private func setupPerformanceMonitoring() {
        // Observe performance service changes
        performanceService.$currentMetrics
            .assign(to: \.currentMetrics, on: self)
            .store(in: &cancellables)
        
        performanceService.$performanceTargets
            .assign(to: \.performanceTargets, on: self)
            .store(in: &cancellables)
        
        performanceService.$isMonitoring
            .assign(to: \.isPerformanceMonitoring, on: self)
            .store(in: &cancellables)
        
        // Start monitoring automatically
        startPerformanceMonitoring()
    }
}

// MARK: - Performance View Model Extensions

extension PerformanceViewModel {
    
    /// Measures message window loading performance
    /// - Parameters:
    ///   - chatID: The chat ID
    ///   - windowSize: The window size
    /// - Returns: Loading time in milliseconds
    func measureMessageWindowLoading(chatID: String, windowSize: Int) -> Double? {
        return performanceService.measureMessageWindowLoading(chatID: chatID, windowSize: windowSize)
    }
    
    /// Measures optimistic UI performance
    /// - Parameters:
    ///   - operation: The operation being performed
    /// - Returns: Operation time in milliseconds
    func measureOptimisticUIPerformance(operation: String) -> Double? {
        return performanceService.measureOptimisticUIPerformance(operation: operation)
    }
    
    /// Measures list windowing performance
    /// - Parameters:
    ///   - itemCount: Number of items being windowed
    /// - Returns: Windowing performance metrics
    func measureListWindowingPerformance(itemCount: Int) -> (fps: Double, memoryUsage: Int) {
        return performanceService.measureListWindowingPerformance(itemCount: itemCount)
    }
    
    /// Gets performance statistics for a metric type
    /// - Parameter type: The metric type
    /// - Returns: Performance statistics
    func getPerformanceStatistics(type: MetricType) -> PerformanceStatistics? {
        return performanceService.getPerformanceStatistics(type: type)
    }
}

// MARK: - Performance View Model for Chat

extension PerformanceViewModel {
    
    /// Optimizes chat view for performance
    /// - Parameters:
    ///   - messageCount: Number of messages
    ///   - isGroupChat: Whether it's a group chat
    func optimizeChatView(messageCount: Int, isGroupChat: Bool) {
        // Enable list windowing for large message counts
        if messageCount > 100 {
            toggleListWindowing(enabled: true)
        }
        
        // Enable optimistic UI for better responsiveness
        toggleOptimisticUI(enabled: true)
        
        // Enable keyboard optimization
        toggleKeyboardOptimization(enabled: true)
    }
    
    /// Optimizes chat list view for performance
    /// - Parameters:
    ///   - chatCount: Number of chats
    func optimizeChatListView(chatCount: Int) {
        // Enable list windowing for large chat counts
        if chatCount > 50 {
            toggleListWindowing(enabled: true)
        }
        
        // Enable optimistic UI for better responsiveness
        toggleOptimisticUI(enabled: true)
    }
}
