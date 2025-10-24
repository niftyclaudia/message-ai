//
//  MessageCategory.swift
//  MessageAI
//
//  Message priority categories for AI classification
//

import Foundation
import SwiftUI

/// Message priority categories used by AI classification
enum MessageCategory: String, Codable, CaseIterable, Equatable {
    case urgent = "urgent"
    case canWait = "can_wait"
    case aiHandled = "ai_handled"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .urgent:
            return "Urgent"
        case .canWait:
            return "Can Wait"
        case .aiHandled:
            return "AI Handled"
        }
    }
    
    /// Description for tooltip
    var description: String {
        switch self {
        case .urgent:
            return "Requires immediate attention"
        case .canWait:
            return "Can be addressed later"
        case .aiHandled:
            return "AI can respond automatically"
        }
    }
}

// MARK: - UI Extensions

extension MessageCategory {
    
    /// Icon name for the category
    var iconName: String {
        switch self {
        case .urgent:
            return "exclamationmark.triangle.fill"
        case .canWait:
            return "clock.fill"
        case .aiHandled:
            return "brain.head.profile"
        }
    }
    
    /// Background color for the badge
    var backgroundColor: Color {
        switch self {
        case .urgent:
            return Color.red.opacity(0.1)
        case .canWait:
            return Color.yellow.opacity(0.1)
        case .aiHandled:
            return Color.blue.opacity(0.1)
        }
    }
    
    /// Border color for the badge
    var borderColor: Color {
        switch self {
        case .urgent:
            return Color.red.opacity(0.3)
        case .canWait:
            return Color.yellow.opacity(0.3)
        case .aiHandled:
            return Color.blue.opacity(0.3)
        }
    }
    
    /// Icon color for the badge
    var iconColor: Color {
        switch self {
        case .urgent:
            return Color.red
        case .canWait:
            return Color.orange
        case .aiHandled:
            return Color.blue
        }
    }
    
    /// Text color for the badge
    var textColor: Color {
        switch self {
        case .urgent:
            return Color.red
        case .canWait:
            return Color.orange
        case .aiHandled:
            return Color.blue
        }
    }
}

