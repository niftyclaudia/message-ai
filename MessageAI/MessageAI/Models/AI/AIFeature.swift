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
    case summarization = "summarization"
    case actionItemExtraction = "actionItemExtraction"
    case semanticSearch = "semanticSearch"
    case proactiveScheduling = "proactiveScheduling"
    
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
        case .summarization:
            return "Summarization"
        case .actionItemExtraction:
            return "Action Item Extraction"
        case .semanticSearch:
            return "Semantic Search"
        case .proactiveScheduling:
            return "Proactive Scheduling"
        }
    }
    
    /// Fallback mode description for error handling
    var fallbackModeDescription: String {
        switch self {
        case .threadSummary:
            return "Using manual thread review"
        case .actionItems:
            return "Using manual action tracking"
        case .smartSearch:
            return "Using basic keyword search"
        case .priorityDetection:
            return "Using manual priority review"
        case .decisionTracking:
            return "Using manual decision tracking"
        case .proactiveAssistant:
            return "Using manual assistance"
        case .summarization:
            return "Using manual summarization"
        case .actionItemExtraction:
            return "Using manual action extraction"
        case .semanticSearch:
            return "Using basic keyword search"
        case .proactiveScheduling:
            return "Using manual scheduling"
        }
    }
}

