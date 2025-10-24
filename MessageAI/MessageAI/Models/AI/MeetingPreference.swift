//
//  MeetingPreference.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation
import FirebaseFirestore

/// Meeting preference feedback when user accepts/rejects AI suggestions
struct MeetingPreference: Codable {
    let suggestionId: String
    let wasAccepted: Bool
    let suggestedTime: Date?
    let suggestedDuration: Int?  // Minutes
    let participants: [String]
    let reasonForRejection: String?
    
    init(
        suggestionId: String,
        wasAccepted: Bool,
        suggestedTime: Date? = nil,
        suggestedDuration: Int? = nil,
        participants: [String] = [],
        reasonForRejection: String? = nil
    ) {
        self.suggestionId = suggestionId
        self.wasAccepted = wasAccepted
        self.suggestedTime = suggestedTime
        self.suggestedDuration = suggestedDuration
        self.participants = participants
        self.reasonForRejection = reasonForRejection
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case suggestionId, wasAccepted, suggestedTime, suggestedDuration, participants, reasonForRejection
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        suggestionId = try container.decode(String.self, forKey: .suggestionId)
        wasAccepted = try container.decode(Bool.self, forKey: .wasAccepted)
        suggestedDuration = try container.decodeIfPresent(Int.self, forKey: .suggestedDuration)
        participants = try container.decode([String].self, forKey: .participants)
        reasonForRejection = try container.decodeIfPresent(String.self, forKey: .reasonForRejection)
        
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .suggestedTime) {
            suggestedTime = firestoreTimestamp.dateValue()
        } else {
            suggestedTime = try container.decodeIfPresent(Date.self, forKey: .suggestedTime)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(suggestionId, forKey: .suggestionId)
        try container.encode(wasAccepted, forKey: .wasAccepted)
        try container.encodeIfPresent(suggestedDuration, forKey: .suggestedDuration)
        try container.encode(participants, forKey: .participants)
        try container.encodeIfPresent(reasonForRejection, forKey: .reasonForRejection)
        
        if let time = suggestedTime {
            try container.encode(Timestamp(date: time), forKey: .suggestedTime)
        }
    }
}

