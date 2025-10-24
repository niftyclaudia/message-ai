//
//  FunctionCallingModels.swift
//  MessageAI
//
//  Function Calling Framework - Swift models matching TypeScript schemas
//

import Foundation

// MARK: - Error Models

public enum FunctionCallingErrorCode: String, Codable {
    case invalidFunction = "invalid_function"
    case invalidParameters = "invalid_parameters"
    case permissionDenied = "permission_denied"
    case timeout = "timeout"
    case serviceUnavailable = "service_unavailable"
    case internalError = "internal_error"
}

public struct FunctionExecutionError: Codable {
    public let code: FunctionCallingErrorCode
    public let message: String
    public let details: String?
    
    public init(code: FunctionCallingErrorCode, message: String, details: String? = nil) {
        self.code = code
        self.message = message
        self.details = details
    }
}

public struct FunctionExecutionResult<T: Codable>: Codable {
    public let success: Bool
    public let result: T?
    public let error: FunctionExecutionError?
    public let executionTime: Int
    
    public init(success: Bool, result: T? = nil, error: FunctionExecutionError? = nil, executionTime: Int) {
        self.success = success
        self.result = result
        self.error = error
        self.executionTime = executionTime
    }
}

// MARK: - 1. Thread Summary Models

public struct ThreadSummary: Codable, Identifiable {
    public let id: String
    public let summary: String
    public let keyPoints: [String]
    public let participants: [String]
    public let decisionCount: Int
    public let messageCount: Int
    
    public init(id: String = UUID().uuidString, summary: String, keyPoints: [String], participants: [String], decisionCount: Int, messageCount: Int) {
        self.id = id
        self.summary = summary
        self.keyPoints = keyPoints
        self.participants = participants
        self.decisionCount = decisionCount
        self.messageCount = messageCount
    }
}

// MARK: - 2. Action Item Models

public struct ActionItem: Codable, Identifiable {
    public let id: String
    public let task: String
    public let deadline: Date?
    public let assignee: String?
    public let sourceMessageId: String
    public let createdAt: Date
    
    public init(id: String, task: String, deadline: Date? = nil, assignee: String? = nil, sourceMessageId: String, createdAt: Date = Date()) {
        self.id = id
        self.task = task
        self.deadline = deadline
        self.assignee = assignee
        self.sourceMessageId = sourceMessageId
        self.createdAt = createdAt
    }
}

// MARK: - 3. Search Result Models

public struct SearchResult: Codable, Identifiable {
    public let id: String
    public let messageId: String
    public let text: String
    public let senderId: String
    public let timestamp: Date
    public let relevanceScore: Double
    
    public init(id: String = UUID().uuidString, messageId: String, text: String, senderId: String, timestamp: Date, relevanceScore: Double) {
        self.id = id
        self.messageId = messageId
        self.text = text
        self.senderId = senderId
        self.timestamp = timestamp
        self.relevanceScore = relevanceScore
    }
}

// MARK: - 4. Message Category Models

public enum CategoryType: String, Codable {
    case urgent = "urgent"
    case canWait = "canWait"
    case aiHandled = "aiHandled"
}

public struct MessageCategory: Codable {
    public let category: CategoryType
    public let confidence: Double
    public let reasoning: String
    public let signals: [String]
    
    public init(category: CategoryType, confidence: Double, reasoning: String, signals: [String]) {
        self.category = category
        self.confidence = confidence
        self.reasoning = reasoning
        self.signals = signals
    }
}

// MARK: - 5. Decision Models

public struct Decision: Codable, Identifiable {
    public let id: String
    public let decisionText: String
    public let participants: [String]
    public let timestamp: Date
    public let confidence: Double
    
    public init(id: String, decisionText: String, participants: [String], timestamp: Date, confidence: Double) {
        self.id = id
        self.decisionText = decisionText
        self.participants = participants
        self.timestamp = timestamp
        self.confidence = confidence
    }
}

// MARK: - 6. Scheduling Need Models

public struct SchedulingNeed: Codable {
    public let detected: Bool
    public let participants: [String]
    public let suggestedDuration: Int // minutes
    public let urgency: UrgencyLevel
    
    public enum UrgencyLevel: String, Codable {
        case high = "high"
        case medium = "medium"
        case low = "low"
    }
    
    public init(detected: Bool, participants: [String], suggestedDuration: Int, urgency: UrgencyLevel) {
        self.detected = detected
        self.participants = participants
        self.suggestedDuration = suggestedDuration
        self.urgency = urgency
    }
}

// MARK: - 7. Calendar Event Models

public struct CalendarEvent: Codable, Identifiable {
    public let id: String
    public let title: String
    public let startTime: Date
    public let endTime: Date
    
    public init(id: String, title: String, startTime: Date, endTime: Date) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - 8. Meeting Time Suggestion Models

public struct TimeRange: Codable {
    public let start: String // HH:MM format
    public let end: String // HH:MM format
    
    public init(start: String, end: String) {
        self.start = start
        self.end = end
    }
}

public struct MeetingTimeSuggestion: Codable, Identifiable {
    public let id: String
    public let startTime: Date
    public let endTime: Date
    public let availableParticipants: [String]
    public let score: Double
    public let reasoning: String
    
    public init(id: String, startTime: Date, endTime: Date, availableParticipants: [String], score: Double, reasoning: String) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.availableParticipants = availableParticipants
        self.score = score
        self.reasoning = reasoning
    }
}

// MARK: - Helper Extensions

extension Date {
    /// Convert to ISO 8601 string for API calls
    public func toISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}

// MARK: - Custom Coding Keys for Firebase Timestamp Compatibility

extension ThreadSummary {
    enum CodingKeys: String, CodingKey {
        case id, summary, keyPoints, participants, decisionCount, messageCount
    }
}

extension ActionItem {
    enum CodingKeys: String, CodingKey {
        case id, task, deadline, assignee, sourceMessageId, createdAt
    }
}

extension SearchResult {
    enum CodingKeys: String, CodingKey {
        case id, messageId, text, senderId, timestamp, relevanceScore
    }
}

extension Decision {
    enum CodingKeys: String, CodingKey {
        case id, decisionText, participants, timestamp, confidence
    }
}

extension CalendarEvent {
    enum CodingKeys: String, CodingKey {
        case id, title, startTime, endTime
    }
}

extension MeetingTimeSuggestion {
    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, availableParticipants, score, reasoning
    }
}

