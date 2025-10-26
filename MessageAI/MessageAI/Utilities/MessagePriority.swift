//
//  MessagePriority.swift
//  MessageAI
//
//  Shared constants and utilities for message priority handling
//

import Foundation

/// Message priority levels and validation utilities
enum MessagePriority: String, CaseIterable {
    case urgent = "urgent"
    case normal = "normal"
    
    /// All valid priority values as strings
    static let allValues: [String] = MessagePriority.allCases.map { $0.rawValue }
    
    /// Validates if a string is a valid priority
    /// - Parameter priority: The priority string to validate
    /// - Returns: True if the priority is valid
    static func isValid(_ priority: String) -> Bool {
        return allValues.contains(priority)
    }
    
    /// Default priority when none is specified
    static let `default`: MessagePriority = .normal
}
