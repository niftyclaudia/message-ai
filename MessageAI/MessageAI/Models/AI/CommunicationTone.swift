//
//  CommunicationTone.swift
//  MessageAI
//
//  Communication tone preference for AI-generated responses
//

import Foundation

/// Communication tone options for AI-generated responses
/// - Note: Used in user preferences to customize AI response style
enum CommunicationTone: String, Codable, CaseIterable {
    case professional = "professional"
    case friendly = "friendly"
    case supportive = "supportive"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .professional:
            return "Professional"
        case .friendly:
            return "Friendly"
        case .supportive:
            return "Supportive"
        }
    }
    
    /// Description for tooltip/help text
    var description: String {
        switch self {
        case .professional:
            return "Formal and business-appropriate responses"
        case .friendly:
            return "Warm and conversational tone"
        case .supportive:
            return "Empathetic and encouraging tone"
        }
    }
}

