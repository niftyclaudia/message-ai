//
//  FallbackModeManager.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Tracks consecutive failures and manages fallback mode state
//

import Foundation
import Combine

/// Manages fallback mode state for AI features
@MainActor
class FallbackModeManager: ObservableObject {
    static let shared = FallbackModeManager()
    
    /// Current fallback mode state for each feature
    @Published private(set) var fallbackModeState: [AIFeature: Bool] = [:]
    
    /// Consecutive failure count for each feature
    private var consecutiveFailures: [AIFeature: Int] = [:]
    
    /// Threshold for entering fallback mode (3 consecutive failures)
    private let fallbackThreshold = 3
    
    private init() {
        // Initialize all features to normal mode
        for feature in AIFeature.allCases {
            fallbackModeState[feature] = false
            consecutiveFailures[feature] = 0
        }
    }
    
    // MARK: - Failure Tracking
    
    /// Record a failure for a specific feature
    func recordFailure(for feature: AIFeature) {
        let count = (consecutiveFailures[feature] ?? 0) + 1
        consecutiveFailures[feature] = count
        
        print("📊 Feature \(feature.rawValue) failure count: \(count)")
        
        // Enter fallback mode if threshold reached
        if count >= fallbackThreshold && fallbackModeState[feature] != true {
            enterFallbackMode(for: feature)
        }
    }
    
    /// Record a success to reset failure count
    func recordSuccess(for feature: AIFeature) {
        let previousCount = consecutiveFailures[feature] ?? 0
        consecutiveFailures[feature] = 0
        
        // Exit fallback mode if currently active
        if fallbackModeState[feature] == true {
            exitFallbackMode(for: feature)
        }
        
        if previousCount > 0 {
            print("✅ Feature \(feature.rawValue) success - failure count reset")
        }
    }
    
    // MARK: - Fallback Mode State
    
    /// Check if a feature is in fallback mode
    func isInFallbackMode(feature: AIFeature) -> Bool {
        return fallbackModeState[feature] ?? false
    }
    
    /// Enter fallback mode for a feature
    private func enterFallbackMode(for feature: AIFeature) {
        fallbackModeState[feature] = true
        print("⚠️ Feature \(feature.rawValue) entered fallback mode after \(fallbackThreshold) consecutive failures")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .fallbackModeChanged,
            object: nil,
            userInfo: ["feature": feature, "active": true]
        )
    }
    
    /// Exit fallback mode for a feature
    private func exitFallbackMode(for feature: AIFeature) {
        fallbackModeState[feature] = false
        print("✅ Feature \(feature.rawValue) exited fallback mode")
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .fallbackModeChanged,
            object: nil,
            userInfo: ["feature": feature, "active": false]
        )
    }
    
    /// Manually reset fallback mode for a feature (for testing or manual recovery)
    func resetFallbackMode(for feature: AIFeature) {
        consecutiveFailures[feature] = 0
        if fallbackModeState[feature] == true {
            exitFallbackMode(for: feature)
        }
    }
    
    /// Get current failure count for a feature
    func getFailureCount(for feature: AIFeature) -> Int {
        return consecutiveFailures[feature] ?? 0
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let fallbackModeChanged = Notification.Name("fallbackModeChanged")
}

