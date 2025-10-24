//
//  DecisionItem.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation
import FirebaseFirestore

/// Decision item detected and tracked in conversations
struct DecisionItem: Codable, Identifiable {
    let id: String
    let decisionText: String
    let participants: [String]  // User IDs involved in decision
    let chatId: String
    let messageId: String
    let detectedBy: AIFeature
    let confidence: Double  // 0.0 - 1.0
    var isImportant: Bool
    var tags: [String]
    let createdAt: Date
    
    init(
        id: String = UUID().uuidString,
        decisionText: String,
        participants: [String],
        chatId: String,
        messageId: String,
        detectedBy: AIFeature,
        confidence: Double,
        isImportant: Bool = false,
        tags: [String] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.decisionText = decisionText
        self.participants = participants
        self.chatId = chatId
        self.messageId = messageId
        self.detectedBy = detectedBy
        // Clamp confidence between 0.0 and 1.0
        self.confidence = min(max(confidence, 0.0), 1.0)
        self.isImportant = isImportant
        self.tags = tags
        self.createdAt = createdAt
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case id, decisionText, participants, chatId, messageId
        case detectedBy, confidence, isImportant, tags, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        decisionText = try container.decode(String.self, forKey: .decisionText)
        participants = try container.decode([String].self, forKey: .participants)
        chatId = try container.decode(String.self, forKey: .chatId)
        messageId = try container.decode(String.self, forKey: .messageId)
        detectedBy = try container.decode(AIFeature.self, forKey: .detectedBy)
        confidence = try container.decode(Double.self, forKey: .confidence)
        isImportant = try container.decode(Bool.self, forKey: .isImportant)
        tags = try container.decode([String].self, forKey: .tags)
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(decisionText, forKey: .decisionText)
        try container.encode(participants, forKey: .participants)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(detectedBy, forKey: .detectedBy)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(isImportant, forKey: .isImportant)
        try container.encode(tags, forKey: .tags)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
    }
}

