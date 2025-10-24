//
//  PriorityRules.swift
//  MessageAI
//
//  Priority rules configuration for AI message categorization
//

import Foundation

/// Priority rules defining how AI should categorize messages
/// - Note: Each rule can be toggled on/off by the user
struct PriorityRules: Codable, Equatable {
    /// Treat @mentions with deadline words as urgent
    var mentionsWithDeadlines: Bool
    
    /// Treat FYI messages as "Can Wait"
    var fyiMessages: Bool
    
    /// Treat questions needing response as "Can Wait" unless from urgent contacts
    var questionsNeedingResponse: Bool
    
    /// Treat approvals and decisions as urgent
    var approvalsAndDecisions: Bool
    
    // MARK: - Display Names
    
    /// Display name for mentions with deadlines rule
    static let mentionsWithDeadlinesName = "Mentions + Deadlines → Urgent"
    
    /// Display name for FYI messages rule
    static let fyiMessagesName = "FYI Messages → Can Wait"
    
    /// Display name for questions rule
    static let questionsNeedingResponseName = "Questions → Can Wait"
    
    /// Display name for approvals rule
    static let approvalsAndDecisionsName = "Approvals/Decisions → Urgent"
    
    // MARK: - Descriptions
    
    /// Description for mentions with deadlines rule
    static let mentionsWithDeadlinesDescription = "Messages with @mentions and deadline words (today, tomorrow, ASAP) are marked urgent"
    
    /// Description for FYI messages rule
    static let fyiMessagesDescription = "Messages starting with 'FYI' or 'For your information' are marked as can wait"
    
    /// Description for questions rule
    static let questionsNeedingResponseDescription = "Questions that need a response are marked as can wait unless from urgent contacts"
    
    /// Description for approvals rule
    static let approvalsAndDecisionsDescription = "Messages requesting approval or decisions are marked urgent"
    
    // MARK: - Defaults
    
    /// Default priority rules (sensible defaults for most users)
    static var defaultRules: PriorityRules {
        PriorityRules(
            mentionsWithDeadlines: true,
            fyiMessages: true,
            questionsNeedingResponse: false,
            approvalsAndDecisions: true
        )
    }
}

