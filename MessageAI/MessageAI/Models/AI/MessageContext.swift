//
//  MessageContext.swift
//  MessageAI
//
//  Context information for AI learning data
//

import Foundation

/// Context information captured when AI categorizes a message
/// - Note: Used for learning and improving AI accuracy over time
struct MessageContext: Codable, Equatable {
    /// User ID of the message sender
    var senderUserId: String
    
    /// First 100 characters of the message for context
    var messagePreview: String
    
    /// Whether the message contained deadline keywords
    var hadDeadline: Bool
    
    /// Whether the message contained @mentions
    var hadMention: Bool
    
    /// Keywords that matched urgency patterns
    var matchedKeywords: [String]
    
    // MARK: - Initialization
    
    init(senderUserId: String, messagePreview: String, hadDeadline: Bool, hadMention: Bool, matchedKeywords: [String]) {
        self.senderUserId = senderUserId
        // Truncate preview to 100 characters
        self.messagePreview = String(messagePreview.prefix(100))
        self.hadDeadline = hadDeadline
        self.hadMention = hadMention
        self.matchedKeywords = matchedKeywords
    }
    
    // MARK: - Dictionary Conversion
    
    /// Convert to dictionary for Firestore/API calls
    func toDictionary() -> [String: Any] {
        return [
            "senderUserId": senderUserId,
            "messagePreview": messagePreview,
            "hadDeadline": hadDeadline,
            "hadMention": hadMention,
            "matchedKeywords": matchedKeywords
        ]
    }
}

