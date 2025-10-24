//
//  MessageCategory.swift
//  MessageAI
//
//  Message priority categories for AI classification
//

import Foundation

/// Message priority categories used by AI classification
enum MessageCategory: String, Codable, CaseIterable {
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

