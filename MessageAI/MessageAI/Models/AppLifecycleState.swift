//
//  AppLifecycleState.swift
//  MessageAI
//
//  App lifecycle state enumeration for managing app state transitions
//  PR #4: Mobile Lifecycle Management
//

import Foundation

/// Represents the current lifecycle state of the app
/// - Note: Used for tracking app state transitions and managing connections
enum AppLifecycleState: String, Codable, Equatable {
    /// App is in the foreground and fully active
    case active
    
    /// App is transitioning between states (willResignActive/willEnterForeground)
    case inactive
    
    /// App is in the background (connections should be suspended)
    case background
    
    /// App was force-quit or terminated by system
    case terminated
    
    /// Human-readable description of the state
    var description: String {
        switch self {
        case .active:
            return "Active (Foreground)"
        case .inactive:
            return "Inactive (Transitioning)"
        case .background:
            return "Background"
        case .terminated:
            return "Terminated"
        }
    }
    
    /// Whether connections should be active in this state
    var shouldMaintainConnections: Bool {
        switch self {
        case .active, .inactive:
            return true
        case .background, .terminated:
            return false
        }
    }
}

