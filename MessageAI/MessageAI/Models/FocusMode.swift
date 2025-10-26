//
//  FocusMode.swift
//  MessageAI
//
//  Focus Mode data models for message filtering
//

import Foundation

/// Focus Mode state model
struct FocusMode: Codable {
    /// Whether Focus Mode is currently active
    var isActive: Bool
    
    /// Timestamp when Focus Mode was last activated
    var activatedAt: Date?
    
    /// Current session ID (UUID)
    var sessionId: String?
    
    /// Initialize with default values
    init(isActive: Bool = false, activatedAt: Date? = nil, sessionId: String? = nil) {
        self.isActive = isActive
        self.activatedAt = activatedAt
        self.sessionId = sessionId
    }
}

/// Focus Session model for tracking active sessions
struct FocusSession: Codable, Identifiable {
    /// Unique session identifier
    let id: String
    
    /// When this session started
    let startTime: Date
    
    /// When this session ended (nil if still active)
    var endTime: Date?
    
    /// Number of messages during this session
    var messageCount: Int
    
    /// Duration of this session in seconds
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    /// Whether this session is currently active
    var isActive: Bool {
        return endTime == nil
    }
    
    init(id: String, startTime: Date, endTime: Date? = nil, messageCount: Int = 0) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.messageCount = messageCount
    }
} 