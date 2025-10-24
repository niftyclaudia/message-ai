//
//  SearchableMetadata.swift
//  MessageAI
//
//  Searchable metadata for AI categorization and semantic search
//

import Foundation

/// Searchable metadata extracted from messages for AI processing
struct SearchableMetadata: Codable {
    /// Extracted keywords from the message
    let keywords: [String]
    
    /// Participant names mentioned in the message
    let participants: [String]
    
    /// Whether a decision was made or requested
    let decisionMade: Bool
    
    /// Urgency indicators found in the message
    let urgencyIndicators: [String]
    
    /// Sentiment analysis result
    let sentiment: SentimentType
    
    /// Message length category
    let lengthCategory: LengthCategory
    
    /// Whether message contains questions
    let containsQuestions: Bool
    
    /// Whether message contains action items
    let containsActionItems: Bool
    
    /// Timestamp when metadata was extracted
    let extractedAt: Date
    
    /// Version of the extraction model
    let extractionVersion: String
    
    // MARK: - Initialization
    
    init(
        keywords: [String] = [],
        participants: [String] = [],
        decisionMade: Bool = false,
        urgencyIndicators: [String] = [],
        sentiment: SentimentType = .neutral,
        lengthCategory: LengthCategory = .medium,
        containsQuestions: Bool = false,
        containsActionItems: Bool = false,
        extractedAt: Date = Date(),
        extractionVersion: String = "1.0"
    ) {
        self.keywords = keywords
        self.participants = participants
        self.decisionMade = decisionMade
        self.urgencyIndicators = urgencyIndicators
        self.sentiment = sentiment
        self.lengthCategory = lengthCategory
        self.containsQuestions = containsQuestions
        self.containsActionItems = containsActionItems
        self.extractedAt = extractedAt
        self.extractionVersion = extractionVersion
    }
    
    // MARK: - Helper Methods
    
    /// Returns combined searchable text
    var searchableText: String {
        let allText = keywords + participants + urgencyIndicators
        return allText.joined(separator: " ")
    }
    
    /// Returns urgency score based on indicators
    var urgencyScore: Double {
        let urgentKeywords = ["urgent", "asap", "immediately", "emergency", "critical", "important"]
        let urgentCount = urgencyIndicators.filter { indicator in
            urgentKeywords.contains { $0.lowercased() == indicator.lowercased() }
        }.count
        
        return Double(urgentCount) / Double(max(urgencyIndicators.count, 1))
    }
    
    /// Whether this message appears urgent based on metadata
    var appearsUrgent: Bool {
        return urgencyScore > 0.3 || urgencyIndicators.contains { $0.lowercased().contains("urgent") }
    }
}

// MARK: - Supporting Enums

/// Sentiment analysis result
enum SentimentType: String, Codable, CaseIterable {
    case positive = "positive"
    case negative = "negative"
    case neutral = "neutral"
    case urgent = "urgent"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .positive:
            return "Positive"
        case .negative:
            return "Negative"
        case .neutral:
            return "Neutral"
        case .urgent:
            return "Urgent"
        }
    }
}

/// Message length categories
enum LengthCategory: String, Codable, CaseIterable {
    case short = "short"      // < 50 characters
    case medium = "medium"    // 50-200 characters
    case long = "long"        // > 200 characters
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .short:
            return "Short"
        case .medium:
            return "Medium"
        case .long:
            return "Long"
        }
    }
    
    /// Character count threshold
    var threshold: Int {
        switch self {
        case .short:
            return 50
        case .medium:
            return 200
        case .long:
            return Int.max
        }
    }
}
