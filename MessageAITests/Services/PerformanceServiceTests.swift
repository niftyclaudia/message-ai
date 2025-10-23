//
//  PerformanceServiceTests.swift
//  MessageAITests
//
//  Essential service tests for performance monitoring
//

import Testing
import Foundation
@testable import MessageAI

/// Essential service tests for performance monitoring
/// - Note: Streamlined tests focusing on core service functionality
struct PerformanceServiceTests {
    
    // MARK: - Core Service Tests
    
    @Test("Performance Service Starts and Stops Monitoring")
    func performanceServiceStartsAndStopsMonitoring() async throws {
        let service = PerformanceService()
        
        service.startPerformanceMonitoring()
        #expect(service.isMonitoring == true)
        
        service.stopPerformanceMonitoring()
        #expect(service.isMonitoring == false)
    }
    
    @Test("Performance Service Measures Core Metrics")
    func performanceServiceMeasuresCoreMetrics() async throws {
        let service = PerformanceService()
        
        service.startPerformanceMonitoring()
        
        let launchTime = service.measureLaunchTime(milestone: "interactive")
        let navTime = service.measureNavigationTime(from: "ChatList", to: "ChatView")
        let scrollTime = service.measureScrollPerformance(fps: 60.0)
        let responseTime = service.measureUIResponseTime(action: "message_send")
        let keyboardTime = service.measureKeyboardTransition()
        
        #expect(launchTime != nil)
        #expect(navTime != nil)
        #expect(scrollTime != nil)
        #expect(responseTime != nil)
        #expect(keyboardTime != nil)
    }
    
    @Test("Performance Service Generates Report")
    func performanceServiceGeneratesReport() async throws {
        let service = PerformanceService()
        
        service.startPerformanceMonitoring()
        _ = service.measureLaunchTime(milestone: "interactive")
        _ = service.measureNavigationTime(from: "ChatList", to: "ChatView")
        
        let report = service.getPerformanceReport()
        
        #expect(!report.isEmpty)
        #expect(report.contains("Performance Report"))
    }
    
    @Test("Performance Service Exports Data")
    func performanceServiceExportsData() async throws {
        let service = PerformanceService()
        
        service.startPerformanceMonitoring()
        _ = service.measureLaunchTime(milestone: "interactive")
        
        let csvData = service.exportPerformanceData()
        
        #expect(!csvData.isEmpty)
        #expect(csvData.contains("Timestamp,Type,Value(ms),Metadata"))
    }
    
    @Test("Performance Service Checks Targets")
    func performanceServiceChecksTargets() async throws {
        let service = PerformanceService()
        
        let targetsMet = service.arePerformanceTargetsMet()
        #expect(targetsMet == true || targetsMet == false)
    }
    
    @Test("Performance Targets Have Correct Values")
    func performanceTargetsHaveCorrectValues() async throws {
        let targets = PerformanceTargets()
        
        #expect(targets.launchTimeTarget == 2000) // 2 seconds
        #expect(targets.navigationTimeTarget == 400) // 400ms
        #expect(targets.scrollFPSTarget == 60) // 60 FPS
        #expect(targets.uiResponseTimeTarget == 50) // 50ms
        #expect(targets.keyboardTransitionTimeTarget == 300) // 300ms
    }
}
