//
//  AIFeature.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Identifies which AI feature encountered an error
//

import Foundation

/// Enumeration of AI features that can fail and require error handling
enum AIFeature: String, Codable, CaseIterable {
    /// Thread summarization (PR #AI-006)
    case summarization
    
    /// Action item extraction (PR #AI-007)
    case actionItemExtraction
    
    /// Semantic search (PR #AI-008)
    case semanticSearch
    
    /// Priority detection & inbox categorization (PR #AI-009)
    case priorityDetection
    
    /// Decision tracking (PR #AI-010)
    case decisionTracking
    
    /// Proactive scheduling assistant (PR #AI-011)
    case proactiveScheduling
    
    /// Human-readable feature name for UI display
    var displayName: String {
        switch self {
        case .summarization:
            return "Thread Summarization"
        case .actionItemExtraction:
            return "Action Item Detection"
        case .semanticSearch:
            return "Smart Search"
        case .priorityDetection:
            return "Priority Detection"
        case .decisionTracking:
            return "Decision Tracking"
        case .proactiveScheduling:
            return "Scheduling Assistant"
        }
    }
    
    /// Fallback mode description for UI banner
    var fallbackModeDescription: String {
        switch self {
        case .summarization:
            return "Showing full threads"
        case .actionItemExtraction:
            return "Showing recent messages"
        case .semanticSearch:
            return "Using basic search"
        case .priorityDetection:
            return "All messages in Inbox"
        case .decisionTracking:
            return "Showing raw history"
        case .proactiveScheduling:
            return "Manual scheduling"
        }
    }
}

