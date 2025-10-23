//
//  LifecycleTransitionEvent.swift
//  MessageAI
//
//  Model for tracking app lifecycle state transitions
//  PR #4: Mobile Lifecycle Management
//

import Foundation

/// Represents a lifecycle state transition event for monitoring and debugging
/// - Note: Used for performance tracking and diagnostics
struct LifecycleTransitionEvent: Identifiable, Codable {
    /// Unique identifier for the transition event
    let id: UUID
    
    /// State the app transitioned from
    let fromState: AppLifecycleState
    
    /// State the app transitioned to
    let toState: AppLifecycleState
    
    /// When the transition occurred
    let timestamp: Date
    
    /// How long the transition took (in seconds)
    let duration: TimeInterval
    
    /// Number of messages pending when transition occurred
    let messagesPending: Int
    
    /// Whether the transition completed successfully
    let success: Bool
    
    /// Optional error message if transition failed
    let errorMessage: String?
    
    // MARK: - Initialization
    
    init(
        from: AppLifecycleState,
        to: AppLifecycleState,
        duration: TimeInterval,
        messagesPending: Int = 0,
        success: Bool = true,
        errorMessage: String? = nil
    ) {
        self.id = UUID()
        self.fromState = from
        self.toState = to
        self.timestamp = Date()
        self.duration = duration
        self.messagesPending = messagesPending
        self.success = success
        self.errorMessage = errorMessage
    }
    
    // MARK: - Computed Properties
    
    /// Human-readable description of the transition
    var description: String {
        let durationMs = String(format: "%.1f", duration * 1000)
        return "\(fromState.description) → \(toState.description) (\(durationMs)ms)"
    }
    
    /// Whether this transition involved going to background
    var isBackgrounding: Bool {
        return toState == .background || toState == .terminated
    }
    
    /// Whether this transition involved coming to foreground
    var isForegrounding: Bool {
        return toState == .active && (fromState == .background || fromState == .inactive)
    }
    
    /// Whether this transition met performance targets
    var meetsPerformanceTarget: Bool {
        // Foregrounding should complete in < 500ms (PR #4 requirement)
        if isForegrounding {
            return duration < 0.5
        }
        // Backgrounding should complete in < 2s (PR #4 requirement)
        if isBackgrounding {
            return duration < 2.0
        }
        return true
    }
}

