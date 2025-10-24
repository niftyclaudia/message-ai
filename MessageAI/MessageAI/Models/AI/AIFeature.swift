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
}

