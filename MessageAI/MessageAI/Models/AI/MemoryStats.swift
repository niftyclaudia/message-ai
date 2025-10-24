//
//  MemoryStats.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation

/// Memory statistics for transparency and debugging
struct MemoryStats: Codable {
    let totalContextMessages: Int
    let totalActionItems: Int
    let totalDecisions: Int
    let totalLearningEntries: Int
    let totalConversations: Int
    let oldestEntryDate: Date?
    let estimatedSizeKB: Int
    
    init(
        totalContextMessages: Int = 0,
        totalActionItems: Int = 0,
        totalDecisions: Int = 0,
        totalLearningEntries: Int = 0,
        totalConversations: Int = 0,
        oldestEntryDate: Date? = nil,
        estimatedSizeKB: Int = 0
    ) {
        self.totalContextMessages = totalContextMessages
        self.totalActionItems = totalActionItems
        self.totalDecisions = totalDecisions
        self.totalLearningEntries = totalLearningEntries
        self.totalConversations = totalConversations
        self.oldestEntryDate = oldestEntryDate
        self.estimatedSizeKB = estimatedSizeKB
    }
}

