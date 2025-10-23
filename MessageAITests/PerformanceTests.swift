//
//  PerformanceTests.swift
//  MessageAITests
//
//  Essential performance tests for PR-5 optimization features
//

import Testing
import Foundation
@testable import MessageAI

/// Essential performance tests for optimization features
/// - Note: Streamlined tests focusing on core functionality validation
struct PerformanceTests {
    
    // MARK: - Core Performance Tests
    
    @Test("Performance Monitor Tracks Launch Time")
    func performanceMonitorTracksLaunchTime() async throws {
        let monitor = PerformanceMonitor.shared
        
        monitor.startAppLaunch()
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        let launchTime = monitor.endAppLaunch(milestone: "interactive")
        
        #expect(launchTime != nil)
        #expect(launchTime! >= 100)
        #expect(launchTime! < 1000)
    }
    
    @Test("Performance Monitor Tracks Navigation Time")
    func performanceMonitorTracksNavigationTime() async throws {
        let monitor = PerformanceMonitor.shared
        
        monitor.startNavigation(from: "ChatList")
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        let navTime = monitor.endNavigation(to: "ChatView")
        
        #expect(navTime != nil)
        #expect(navTime! >= 50)
        #expect(navTime! < 500)
    }
    
    @Test("List Windowing Loads Messages Correctly")
    func listWindowingLoadsMessagesCorrectly() async throws {
        let windowing = ListWindowing<Message>()
        let config = ListWindowingConfig()
        
        let itemLoader: (Int, Int) async throws -> [Message] = { startIndex, count in
            let messages = (startIndex..<startIndex + count).map { index in
                Message(
                    id: "message_\(index)",
                    chatID: "chat1",
                    senderID: "user1",
                    text: "Message \(index)",
                    timestamp: Date(),
                    serverTimestamp: nil,
                    readBy: ["user1"],
                    status: .sent,
                    senderName: nil,
                    isOffline: false,
                    retryCount: 0,
                    isOptimistic: false
                )
            }
            return messages
        }
        
        let messages = try await windowing.loadWindow(
            around: 100,
            totalCount: 1000,
            itemLoader: itemLoader
        )
        
        #expect(messages.count <= config.windowSize)
        #expect(windowing.getWindowStart() >= 0)
        #expect(windowing.getWindowEnd() <= 1000)
    }
    
    @Test("Optimistic UI Handles Operations")
    func optimisticUIHandlesOperations() async throws {
        let optimisticUI = OptimisticUI()
        
        let operation: () async throws -> String = {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            return "success"
        }
        
        let result = await optimisticUI.performOptimisticOperation(
            operation: operation,
            fallback: "fallback"
        )
        
        #expect(result == "success")
        #expect(optimisticUI.currentState == .success(operation: "Completed"))
    }
    
    @Test("Keyboard Optimizer Handles Transitions")
    func keyboardOptimizerHandlesTransitions() async throws {
        let optimizer = KeyboardOptimizer()
        
        optimizer.handleKeyboardTransition(height: 300)
        #expect(optimizer.isKeyboardVisible == true)
        #expect(optimizer.keyboardHeight == 300)
        
        optimizer.handleKeyboardTransition(height: 0)
        #expect(optimizer.isKeyboardVisible == false)
        #expect(optimizer.keyboardHeight == 0)
    }
    
    @Test("Performance Service Measures Core Metrics")
    func performanceServiceMeasuresCoreMetrics() async throws {
        let service = PerformanceService()
        
        service.startPerformanceMonitoring()
        
        let launchTime = service.measureLaunchTime(milestone: "interactive")
        let navTime = service.measureNavigationTime(from: "ChatList", to: "ChatView")
        let scrollTime = service.measureScrollPerformance(fps: 60.0)
        
        #expect(launchTime != nil)
        #expect(navTime != nil)
        #expect(scrollTime != nil)
    }
    
    @Test("Performance Targets Are Validated")
    func performanceTargetsAreValidated() async throws {
        let targets = PerformanceTargets()
        
        // Test meeting targets
        let goodMetrics = PerformanceMetrics(
            launchTime: 1500, // 1.5 seconds (under 2 second target)
            navigationTime: 300, // 300ms (under 400ms target)
            scrollFPS: 60, // 60 FPS (meets target)
            uiResponseTime: 30, // 30ms (under 50ms target)
            keyboardTransitionTime: 200 // 200ms (under 300ms target)
        )
        
        #expect(goodMetrics.meetsTargets(targets) == true)
        
        // Test missing targets
        let badMetrics = PerformanceMetrics(
            launchTime: 3000, // 3 seconds (over 2 second target)
            navigationTime: 600, // 600ms (over 400ms target)
            scrollFPS: 30, // 30 FPS (under 60 FPS target)
            uiResponseTime: 100, // 100ms (over 50ms target)
            keyboardTransitionTime: 500 // 500ms (over 300ms target)
        )
        
        #expect(badMetrics.meetsTargets(targets) == false)
    }
}
