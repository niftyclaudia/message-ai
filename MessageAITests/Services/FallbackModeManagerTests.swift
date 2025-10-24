//
//  FallbackModeManagerTests.swift
//  MessageAITests
//
//  PR-AI-005: Unit tests for FallbackModeManager
//

import Testing
import Foundation
@testable import MessageAI

@Suite("FallbackModeManager Tests")
struct FallbackModeManagerTests {
    
    @Test("Initial state is normal mode (not fallback)")
    @MainActor
    func testInitialState() async throws {
        let manager = FallbackModeManager.shared
        
        for feature in AIFeature.allCases {
            #expect(manager.isInFallbackMode(feature: feature) == false)
            #expect(manager.getFailureCount(for: feature) >= 0)
        }
    }
    
    @Test("Records failures correctly")
    @MainActor
    func testRecordFailure() async throws {
        let manager = FallbackModeManager.shared
        let feature = AIFeature.summarization
        
        // Reset state
        manager.resetFallbackMode(for: feature)
        
        // Record first failure
        manager.recordFailure(for: feature)
        #expect(manager.getFailureCount(for: feature) == 1)
        #expect(manager.isInFallbackMode(feature: feature) == false)
        
        // Record second failure
        manager.recordFailure(for: feature)
        #expect(manager.getFailureCount(for: feature) == 2)
        #expect(manager.isInFallbackMode(feature: feature) == false)
    }
    
    @Test("Enters fallback mode after 3 consecutive failures")
    @MainActor
    func testFallbackModeThreshold() async throws {
        let manager = FallbackModeManager.shared
        let feature = AIFeature.semanticSearch
        
        // Reset state
        manager.resetFallbackMode(for: feature)
        
        // Record 3 failures
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        
        #expect(manager.isInFallbackMode(feature: feature) == true)
        #expect(manager.getFailureCount(for: feature) == 3)
    }
    
    @Test("Exits fallback mode on success")
    @MainActor
    func testExitFallbackMode() async throws {
        let manager = FallbackModeManager.shared
        let feature = AIFeature.priorityDetection
        
        // Enter fallback mode
        manager.resetFallbackMode(for: feature)
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        #expect(manager.isInFallbackMode(feature: feature) == true)
        
        // Record success
        manager.recordSuccess(for: feature)
        
        #expect(manager.isInFallbackMode(feature: feature) == false)
        #expect(manager.getFailureCount(for: feature) == 0)
    }
    
    @Test("Reset clears failure count and exits fallback mode")
    @MainActor
    func testResetFallbackMode() async throws {
        let manager = FallbackModeManager.shared
        let feature = AIFeature.actionItemExtraction
        
        // Enter fallback mode
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        #expect(manager.isInFallbackMode(feature: feature) == true)
        
        // Reset
        manager.resetFallbackMode(for: feature)
        
        #expect(manager.isInFallbackMode(feature: feature) == false)
        #expect(manager.getFailureCount(for: feature) == 0)
    }
    
    @Test("Independent tracking per feature")
    @MainActor
    func testIndependentFeatureTracking() async throws {
        let manager = FallbackModeManager.shared
        
        // Reset all
        for feature in AIFeature.allCases {
            manager.resetFallbackMode(for: feature)
        }
        
        // Fail summarization
        manager.recordFailure(for: .summarization)
        manager.recordFailure(for: .summarization)
        manager.recordFailure(for: .summarization)
        
        // Check summarization in fallback, others not
        #expect(manager.isInFallbackMode(feature: .summarization) == true)
        #expect(manager.isInFallbackMode(feature: .semanticSearch) == false)
        #expect(manager.isInFallbackMode(feature: .priorityDetection) == false)
    }
    
    @Test("Published state updates on changes")
    @MainActor
    func testPublishedStateUpdates() async throws {
        let manager = FallbackModeManager.shared
        let feature = AIFeature.decisionTracking
        
        // Reset state
        manager.resetFallbackMode(for: feature)
        
        var stateChanges: [Bool] = []
        
        // Observe state changes (simplified - in real app would use Combine)
        let initialState = manager.fallbackModeState[feature] ?? false
        stateChanges.append(initialState)
        
        // Enter fallback mode
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        manager.recordFailure(for: feature)
        
        let fallbackState = manager.fallbackModeState[feature] ?? false
        stateChanges.append(fallbackState)
        
        // Exit fallback mode
        manager.recordSuccess(for: feature)
        
        let normalState = manager.fallbackModeState[feature] ?? false
        stateChanges.append(normalState)
        
        #expect(stateChanges == [false, true, false])
    }
}

