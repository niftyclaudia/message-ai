//
//  FunctionCallingService.swift
//  MessageAI
//
//  Function Calling Service - iOS client for executing AI functions
//

import Foundation
import FirebaseFunctions

// MARK: - Protocol

public protocol FunctionCallingServiceProtocol {
    func summarizeThread(threadId: String, maxLength: Int?) async throws -> ThreadSummary
    func extractActionItems(threadId: String) async throws -> [ActionItem]
    func searchMessages(query: String, chatId: String?, limit: Int?) async throws -> [SearchResult]
    func categorizeMessage(messageId: String) async throws -> MessageCategory
    func trackDecisions(threadId: String) async throws -> [Decision]
    func detectSchedulingNeed(threadId: String) async throws -> SchedulingNeed
    func checkCalendar(startDate: Date, endDate: Date) async throws -> [CalendarEvent]
    func suggestMeetingTimes(participants: [String], duration: Int) async throws -> [MeetingTimeSuggestion]
}

// MARK: - Service Implementation

public class FunctionCallingService: FunctionCallingServiceProtocol {
    
    private let functions: Functions
    private let currentUserId: String
    
    // MARK: - Initialization
    
    public init(functions: Functions = Functions.functions(), currentUserId: String) {
        self.functions = functions
        self.currentUserId = currentUserId
    }
    
    // MARK: - 1. Summarize Thread
    
    public func summarizeThread(threadId: String, maxLength: Int? = nil) async throws -> ThreadSummary {
        var params: [String: Any] = ["threadId": threadId]
        if let maxLength = maxLength {
            params["maxLength"] = maxLength
        }
        
        return try await executeFunctionCall(functionName: "summarizeThread", parameters: params)
    }
    
    // MARK: - 2. Extract Action Items
    
    public func extractActionItems(threadId: String) async throws -> [ActionItem] {
        let params: [String: Any] = [
            "threadId": threadId,
            "userId": currentUserId
        ]
        
        return try await executeFunctionCall(functionName: "extractActionItems", parameters: params)
    }
    
    // MARK: - 3. Search Messages
    
    public func searchMessages(query: String, chatId: String? = nil, limit: Int? = nil) async throws -> [SearchResult] {
        var params: [String: Any] = [
            "query": query,
            "userId": currentUserId
        ]
        
        if let chatId = chatId {
            params["chatId"] = chatId
        }
        if let limit = limit {
            params["limit"] = limit
        }
        
        return try await executeFunctionCall(functionName: "searchMessages", parameters: params)
    }
    
    // MARK: - 4. Categorize Message
    
    public func categorizeMessage(messageId: String) async throws -> MessageCategory {
        let params: [String: Any] = [
            "messageId": messageId,
            "userId": currentUserId
        ]
        
        return try await executeFunctionCall(functionName: "categorizeMessage", parameters: params)
    }
    
    // MARK: - 5. Track Decisions
    
    public func trackDecisions(threadId: String) async throws -> [Decision] {
        let params: [String: Any] = ["threadId": threadId]
        
        return try await executeFunctionCall(functionName: "trackDecisions", parameters: params)
    }
    
    // MARK: - 6. Detect Scheduling Need
    
    public func detectSchedulingNeed(threadId: String) async throws -> SchedulingNeed {
        let params: [String: Any] = ["threadId": threadId]
        
        return try await executeFunctionCall(functionName: "detectSchedulingNeed", parameters: params)
    }
    
    // MARK: - 7. Check Calendar
    
    public func checkCalendar(startDate: Date, endDate: Date) async throws -> [CalendarEvent] {
        let params: [String: Any] = [
            "userId": currentUserId,
            "startDate": startDate.toISO8601String(),
            "endDate": endDate.toISO8601String()
        ]
        
        return try await executeFunctionCall(functionName: "checkCalendar", parameters: params)
    }
    
    // MARK: - 8. Suggest Meeting Times
    
    public func suggestMeetingTimes(participants: [String], duration: Int) async throws -> [MeetingTimeSuggestion] {
        let params: [String: Any] = [
            "participants": participants,
            "duration": duration
        ]
        
        return try await executeFunctionCall(functionName: "suggestMeetingTimes", parameters: params)
    }
    
    // MARK: - Core Execution Method
    
    private func executeFunctionCall<T: Codable>(functionName: String, parameters: [String: Any]) async throws -> T {
        let data: [String: Any] = [
            "functionName": functionName,
            "parameters": parameters
        ]
        
        do {
            let result = try await functions.httpsCallable("executeFunctionCall").call(data)
            
            // Parse FunctionExecutionResult
            guard let resultData = result.data as? [String: Any] else {
                throw FunctionCallingError.decodingError(message: "Invalid response format")
            }
            
            // Check if execution was successful
            guard let success = resultData["success"] as? Bool, success else {
                // Parse error
                if let errorDict = resultData["error"] as? [String: Any],
                   let codeString = errorDict["code"] as? String,
                   let code = FunctionCallingErrorCode(rawValue: codeString),
                   let message = errorDict["message"] as? String {
                    let details = errorDict["details"] as? String
                    throw FunctionCallingError.functionError(code: code, message: message, details: details)
                } else {
                    throw FunctionCallingError.unknownError(message: "Function execution failed")
                }
            }
            
            // Extract result
            guard let resultValue = resultData["result"] else {
                throw FunctionCallingError.decodingError(message: "Missing result in response")
            }
            
            // Convert to JSON data for decoding
            let jsonData = try JSONSerialization.data(withJSONObject: resultValue)
            
            // Decode to target type
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                
                // Try decoding as timestamp (milliseconds)
                if let timestamp = try? container.decode(Double.self) {
                    return Date(timeIntervalSince1970: timestamp / 1000.0)
                }
                
                // Try decoding as ISO 8601 string
                if let dateString = try? container.decode(String.self) {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Try without fractional seconds
                    formatter.formatOptions = [.withInternetDateTime]
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
            }
            
            let decoded = try decoder.decode(T.self, from: jsonData)
            return decoded
            
        } catch let error as FunctionCallingError {
            throw error
        } catch {
            // Handle Firebase Functions errors
            if let functionsError = error as NSError? {
                switch functionsError.code {
                case FunctionsErrorCode.unauthenticated.rawValue:
                    throw FunctionCallingError.authenticationError(message: "Must be authenticated")
                case FunctionsErrorCode.permissionDenied.rawValue:
                    throw FunctionCallingError.permissionDenied(message: "Permission denied")
                case FunctionsErrorCode.deadlineExceeded.rawValue:
                    throw FunctionCallingError.timeout(message: "Request timed out")
                case FunctionsErrorCode.unavailable.rawValue:
                    throw FunctionCallingError.serviceUnavailable(message: "Service temporarily unavailable")
                default:
                    throw FunctionCallingError.networkError(error: error)
                }
            }
            
            throw FunctionCallingError.unknownError(message: error.localizedDescription)
        }
    }
}

// MARK: - Error Types

public enum FunctionCallingError: LocalizedError {
    case invalidParameters(message: String)
    case permissionDenied(message: String)
    case timeout(message: String)
    case serviceUnavailable(message: String)
    case networkError(error: Error)
    case decodingError(message: String)
    case authenticationError(message: String)
    case functionError(code: FunctionCallingErrorCode, message: String, details: String?)
    case unknownError(message: String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        case .timeout(let message):
            return "Request timeout: \(message)"
        case .serviceUnavailable(let message):
            return "Service unavailable: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let message):
            return "Response decoding error: \(message)"
        case .authenticationError(let message):
            return "Authentication error: \(message)"
        case .functionError(_, let message, let details):
            if let details = details {
                return "\(message) - \(details)"
            }
            return message
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Mock Service for Testing

#if DEBUG
public class MockFunctionCallingService: FunctionCallingServiceProtocol {
    
    public init() {}
    
    public func summarizeThread(threadId: String, maxLength: Int?) async throws -> ThreadSummary {
        return ThreadSummary(
            summary: "Mock thread summary for testing",
            keyPoints: ["Point 1", "Point 2", "Point 3"],
            participants: ["user1", "user2"],
            decisionCount: 2,
            messageCount: 15
        )
    }
    
    public func extractActionItems(threadId: String) async throws -> [ActionItem] {
        return [
            ActionItem(id: "1", task: "Review document", sourceMessageId: "msg1"),
            ActionItem(id: "2", task: "Send report", deadline: Date().addingTimeInterval(86400), sourceMessageId: "msg2")
        ]
    }
    
    public func searchMessages(query: String, chatId: String?, limit: Int?) async throws -> [SearchResult] {
        return [
            SearchResult(messageId: "msg1", text: "Found message 1", senderId: "user1", timestamp: Date(), relevanceScore: 0.95),
            SearchResult(messageId: "msg2", text: "Found message 2", senderId: "user2", timestamp: Date(), relevanceScore: 0.88)
        ]
    }
    
    public func categorizeMessage(messageId: String) async throws -> MessageCategory {
        return MessageCategory(category: .canWait, confidence: 0.85, reasoning: "Not time-sensitive", signals: ["question", "inquiry"])
    }
    
    public func trackDecisions(threadId: String) async throws -> [Decision] {
        return [
            Decision(id: "1", decisionText: "Decided to use approach A", participants: ["user1", "user2"], timestamp: Date(), confidence: 0.9)
        ]
    }
    
    public func detectSchedulingNeed(threadId: String) async throws -> SchedulingNeed {
        return SchedulingNeed(detected: true, participants: ["user1", "user2"], suggestedDuration: 30, urgency: .medium)
    }
    
    public func checkCalendar(startDate: Date, endDate: Date) async throws -> [CalendarEvent] {
        return [
            CalendarEvent(id: "1", title: "Team Meeting", startTime: Date(), endTime: Date().addingTimeInterval(3600))
        ]
    }
    
    public func suggestMeetingTimes(participants: [String], duration: Int) async throws -> [MeetingTimeSuggestion] {
        return [
            MeetingTimeSuggestion(id: "1", startTime: Date().addingTimeInterval(86400), endTime: Date().addingTimeInterval(86400 + 1800), availableParticipants: participants, score: 1.0, reasoning: "All participants available")
        ]
    }
}
#endif

