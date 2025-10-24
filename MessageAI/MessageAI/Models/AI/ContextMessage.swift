//
//  ContextMessage.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation
import FirebaseFirestore

/// Truncated message snapshot for session context (max 200 chars)
struct ContextMessage: Codable {
    let messageId: String
    let chatId: String
    let senderId: String
    let text: String  // Truncated to 200 chars
    let timestamp: Date
    
    init(messageId: String, chatId: String, senderId: String, text: String, timestamp: Date) {
        self.messageId = messageId
        self.chatId = chatId
        self.senderId = senderId
        // Truncate text to 200 characters
        self.text = String(text.prefix(200))
        self.timestamp = timestamp
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case messageId, chatId, senderId, text, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messageId = try container.decode(String.self, forKey: .messageId)
        chatId = try container.decode(String.self, forKey: .chatId)
        senderId = try container.decode(String.self, forKey: .senderId)
        text = try container.decode(String.self, forKey: .text)
        
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(text, forKey: .text)
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
    }
}

