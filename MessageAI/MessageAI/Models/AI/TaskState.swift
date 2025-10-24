//
//  TaskState.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation
import FirebaseFirestore

/// Task state containing action items and decisions
struct TaskState: Codable {
    var actionItems: [TaskItem]
    var decisions: [DecisionItem]
    var lastSyncedAt: Date
    var version: Int
    
    init(
        actionItems: [TaskItem] = [],
        decisions: [DecisionItem] = [],
        lastSyncedAt: Date = Date(),
        version: Int = 1
    ) {
        self.actionItems = actionItems
        self.decisions = decisions
        self.lastSyncedAt = lastSyncedAt
        self.version = version
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case actionItems, decisions, lastSyncedAt, version
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actionItems = try container.decode([TaskItem].self, forKey: .actionItems)
        decisions = try container.decode([DecisionItem].self, forKey: .decisions)
        version = try container.decode(Int.self, forKey: .version)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastSyncedAt) {
            lastSyncedAt = timestamp.dateValue()
        } else {
            lastSyncedAt = try container.decode(Date.self, forKey: .lastSyncedAt)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(actionItems, forKey: .actionItems)
        try container.encode(decisions, forKey: .decisions)
        try container.encode(Timestamp(date: lastSyncedAt), forKey: .lastSyncedAt)
        try container.encode(version, forKey: .version)
    }
}

