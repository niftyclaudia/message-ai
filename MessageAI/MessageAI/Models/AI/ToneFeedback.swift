//
//  ToneFeedback.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation

/// Tone feedback when user rates AI response helpfulness
struct ToneFeedback: Codable {
    let responseId: String
    let aiResponseText: String  // Truncated to 200 chars
    let wasHelpful: Bool
    let userComment: String?
    let featureSource: AIFeature
    
    init(
        responseId: String,
        aiResponseText: String,
        wasHelpful: Bool,
        userComment: String? = nil,
        featureSource: AIFeature
    ) {
        self.responseId = responseId
        // Truncate response text to 200 characters
        self.aiResponseText = String(aiResponseText.prefix(200))
        self.wasHelpful = wasHelpful
        self.userComment = userComment
        self.featureSource = featureSource
    }
}

