//
//  AIFeature.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation

/// AI features that can generate memory entries
enum AIFeature: String, Codable, CaseIterable {
    case threadSummary = "threadSummary"
    case actionItems = "actionItems"
    case smartSearch = "smartSearch"
    case priorityDetection = "priorityDetection"
    case decisionTracking = "decisionTracking"
    case proactiveAssistant = "proactiveAssistant"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .threadSummary:
            return "Thread Summary"
        case .actionItems:
            return "Action Items"
        case .smartSearch:
            return "Smart Search"
        case .priorityDetection:
            return "Priority Detection"
        case .decisionTracking:
            return "Decision Tracking"
        case .proactiveAssistant:
            return "Proactive Assistant"
        }
    }
    
    /// Description shown when in fallback mode
    var fallbackModeDescription: String {
        switch self {
        case .threadSummary:
            return "Using full thread view instead of AI summary"
        case .actionItems:
            return "Showing recent messages instead of extracted tasks"
        case .smartSearch:
            return "Using keyword search instead of semantic search"
        case .priorityDetection:
            return "Showing all messages in neutral inbox"
        case .decisionTracking:
            return "Decision detection temporarily disabled"
        case .proactiveAssistant:
            return "Manual scheduling instead of AI suggestions"
        }
    }
}

