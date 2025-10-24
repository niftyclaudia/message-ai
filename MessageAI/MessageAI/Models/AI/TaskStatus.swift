//
//  TaskStatus.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation

/// Completion status for task items
enum TaskStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "inProgress"
    case completed = "completed"
    case archived = "archived"
}

