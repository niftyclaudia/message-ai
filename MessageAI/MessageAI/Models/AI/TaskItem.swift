//
//  TaskItem.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//

import Foundation
import FirebaseFirestore

/// Action item extracted from conversations
struct TaskItem: Codable, Identifiable {
    let id: String
    let taskDescription: String
    let chatId: String
    let messageId: String
    let extractedBy: AIFeature
    var assignee: String?
    var deadline: Date?
    var priority: TaskPriority
    var completionStatus: TaskStatus
    let createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        taskDescription: String,
        chatId: String,
        messageId: String,
        extractedBy: AIFeature,
        assignee: String? = nil,
        deadline: Date? = nil,
        priority: TaskPriority = .normal,
        completionStatus: TaskStatus = .pending,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.taskDescription = taskDescription
        self.chatId = chatId
        self.messageId = messageId
        self.extractedBy = extractedBy
        self.assignee = assignee
        self.deadline = deadline
        self.priority = priority
        self.completionStatus = completionStatus
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    enum CodingKeys: String, CodingKey {
        case id, taskDescription, chatId, messageId, extractedBy
        case assignee, deadline, priority, completionStatus
        case createdAt, updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        taskDescription = try container.decode(String.self, forKey: .taskDescription)
        chatId = try container.decode(String.self, forKey: .chatId)
        messageId = try container.decode(String.self, forKey: .messageId)
        extractedBy = try container.decode(AIFeature.self, forKey: .extractedBy)
        assignee = try container.decodeIfPresent(String.self, forKey: .assignee)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        completionStatus = try container.decode(TaskStatus.self, forKey: .completionStatus)
        
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .deadline) {
            deadline = firestoreTimestamp.dateValue()
        } else {
            deadline = try container.decodeIfPresent(Date.self, forKey: .deadline)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(taskDescription, forKey: .taskDescription)
        try container.encode(chatId, forKey: .chatId)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(extractedBy, forKey: .extractedBy)
        try container.encodeIfPresent(assignee, forKey: .assignee)
        if let deadline = deadline {
            try container.encode(Timestamp(date: deadline), forKey: .deadline)
        }
        try container.encode(priority, forKey: .priority)
        try container.encode(completionStatus, forKey: .completionStatus)
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
    }
}

