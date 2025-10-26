//
//  FocusSession.swift
//  MessageAI
//
//  Focus Session data model for session summarization functionality
//

import Foundation
import FirebaseFirestore

/// Focus Session status enum representing the state of a session
enum FocusSessionStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case summarized = "summarized"
}

/// Focus Session Summary data model representing a single Focus Mode session
/// - Note: Maps to Firestore collection 'focusSessions' with document ID = sessionID
struct FocusSessionSummary: Codable, Identifiable {
    /// Unique session identifier
    var id: String
    
    /// User ID who owns this session
    let userID: String
    
    /// When this session started
    let startTime: Date
    
    /// When this session ended (nil if still active)
    var endTime: Date?
    
    /// Number of messages during this session
    var messageCount: Int
    
    /// Number of urgent messages during this session
    var urgentMessageCount: Int
    
    /// Current status of the session
    var status: FocusSessionStatus
    
    /// ID of the generated summary (if any)
    var summaryID: String?
    
    /// When the summary was generated
    var summaryGeneratedAt: Date?
    
    /// Error message if summary generation failed
    var summaryError: String?
    
    /// When summary generation failed
    var summaryFailedAt: Date?
    
    /// Firestore collection name
    static let collectionName = "focusSessions"
    
    // MARK: - Computed Properties
    
    /// Duration of this session in seconds
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    /// Whether this session is currently active
    var isActive: Bool {
        return status == .active && endTime == nil
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case userID
        case startTime
        case endTime
        case messageCount
        case urgentMessageCount
        case status
        case summaryID
        case summaryGeneratedAt
        case summaryError
        case summaryFailedAt
    }
    
    // MARK: - Initialization
    
    init(id: String, userID: String, startTime: Date, endTime: Date? = nil, messageCount: Int = 0, urgentMessageCount: Int = 0, status: FocusSessionStatus = .active, summaryID: String? = nil, summaryGeneratedAt: Date? = nil, summaryError: String? = nil, summaryFailedAt: Date? = nil) {
        self.id = id
        self.userID = userID
        self.startTime = startTime
        self.endTime = endTime
        self.messageCount = messageCount
        self.urgentMessageCount = urgentMessageCount
        self.status = status
        self.summaryID = summaryID
        self.summaryGeneratedAt = summaryGeneratedAt
        self.summaryError = summaryError
        self.summaryFailedAt = summaryFailedAt
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userID = try container.decode(String.self, forKey: .userID)
        messageCount = try container.decodeIfPresent(Int.self, forKey: .messageCount) ?? 0
        urgentMessageCount = try container.decodeIfPresent(Int.self, forKey: .urgentMessageCount) ?? 0
        status = try container.decodeIfPresent(FocusSessionStatus.self, forKey: .status) ?? .active
        summaryID = try container.decodeIfPresent(String.self, forKey: .summaryID)
        summaryError = try container.decodeIfPresent(String.self, forKey: .summaryError)
        
        // Handle startTime with Firestore Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .startTime) {
            startTime = timestamp.dateValue()
        } else {
            startTime = try container.decode(Date.self, forKey: .startTime)
        }
        
        // Handle endTime (optional) with Firestore Timestamp conversion
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .endTime) {
            endTime = timestamp.dateValue()
        } else {
            endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        }
        
        // Handle summaryGeneratedAt (optional) with Firestore Timestamp conversion
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .summaryGeneratedAt) {
            summaryGeneratedAt = timestamp.dateValue()
        } else {
            summaryGeneratedAt = try container.decodeIfPresent(Date.self, forKey: .summaryGeneratedAt)
        }
        
        // Handle summaryFailedAt (optional) with Firestore Timestamp conversion
        if let timestamp = try? container.decodeIfPresent(Timestamp.self, forKey: .summaryFailedAt) {
            summaryFailedAt = timestamp.dateValue()
        } else {
            summaryFailedAt = try container.decodeIfPresent(Date.self, forKey: .summaryFailedAt)
        }
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encode(messageCount, forKey: .messageCount)
        try container.encode(urgentMessageCount, forKey: .urgentMessageCount)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(summaryID, forKey: .summaryID)
        try container.encodeIfPresent(summaryError, forKey: .summaryError)
        
        // Convert dates to Firestore Timestamps
        try container.encode(Timestamp(date: startTime), forKey: .startTime)
        
        if let endTime = endTime {
            try container.encode(Timestamp(date: endTime), forKey: .endTime)
        }
        
        if let summaryGeneratedAt = summaryGeneratedAt {
            try container.encode(Timestamp(date: summaryGeneratedAt), forKey: .summaryGeneratedAt)
        }
        
        if let summaryFailedAt = summaryFailedAt {
            try container.encode(Timestamp(date: summaryFailedAt), forKey: .summaryFailedAt)
        }
    }
}
