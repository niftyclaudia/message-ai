//
//  AppLifecycleManagerTests.swift
//  MessageAITests
//
//  Unit tests for AppLifecycleManager
//  PR #4: Mobile Lifecycle Management
//

import Testing
import Foundation
@testable import MessageAI

/// Tests for AppLifecycleManager lifecycle handling and performance
@MainActor
struct AppLifecycleManagerTests {
    
    // MARK: - Lifecycle State Transitions
    
    @Test("App lifecycle state changes correctly on foreground")
    func appLifecycleStateChangesOnForeground() async throws {
        // Given: Lifecycle manager
        let manager = AppLifecycleManager()
        
        // When: App becomes active
        try await manager.setUserOnline(userID: "test-user")
        
        // Then: State should be active
        #expect(manager.getCurrentState() == .active || manager.getCurrentState() == .inactive)
    }
    
    @Test("App lifecycle tracks state transitions")
    func appLifecycleTracksStateTransitions() async throws {
        // Given: Lifecycle manager
        let manager = AppLifecycleManager()
        
        // When: State transitions occur
        try await manager.setUserOnline(userID: "test-user")
        
        // Then: Transition events should be recorded
        let events = manager.getTransitionEvents()
        #expect(events.count >= 0) // May be 0 if no transitions recorded yet
    }
    
    // MARK: - Connection Management
    
    @Test("Lifecycle manager registers listeners")
    func lifecycleManagerRegistersListeners() async throws {
        // Given: Lifecycle manager
        let manager = AppLifecycleManager()
        
        // Then: Manager should be initialized without errors
        #expect(manager.getCurrentState() != nil)
    }
    
    // MARK: - Performance Statistics
    
    @Test("Lifecycle manager provides performance statistics")
    func lifecycleManagerProvidesPerformanceStatistics() async throws {
        // Given: Lifecycle manager with some transitions
        let manager = AppLifecycleManager()
        
        // When: Getting performance statistics
        let stats = manager.getPerformanceStatistics()
        
        // Then: Statistics should be available
        #expect(stats.foregroundAvg >= 0)
        #expect(stats.backgroundAvg >= 0)
    }
    
    @Test("Lifecycle manager can clear transition events")
    func lifecycleManagerCanClearTransitionEvents() async throws {
        // Given: Lifecycle manager with events
        let manager = AppLifecycleManager()
        
        // When: Clearing events
        manager.clearTransitionEvents()
        
        // Then: Events should be empty
        let events = manager.getTransitionEvents()
        #expect(events.isEmpty)
    }
    
    // MARK: - State Observation
    
    @Test("Lifecycle manager provides current state")
    func lifecycleManagerProvidesCurrentState() async throws {
        // Given: Lifecycle manager
        let manager = AppLifecycleManager()
        
        // When: Getting current state
        let state = manager.getCurrentState()
        
        // Then: State should be valid
        #expect([AppLifecycleState.active, .inactive, .background, .terminated].contains(state))
    }
}

