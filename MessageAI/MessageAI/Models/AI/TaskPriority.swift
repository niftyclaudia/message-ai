//
//  TaskPriority.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation

/// Priority levels for task items
enum TaskPriority: String, Codable, CaseIterable {
    case urgent = "urgent"
    case normal = "normal"
    case low = "low"
}

