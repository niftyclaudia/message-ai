//
//  UserPreferences.swift
//  MessageAI
//
//  User AI preferences configuration model
//

import Foundation
import FirebaseFirestore

/// User AI preferences for personalized message prioritization and AI behavior
/// - Note: Maps to Firestore document 'users/{userId}/preferences/aiPreferences'
struct UserPreferences: Codable, Identifiable, Equatable {
    /// Preference document ID (typically "aiPreferences")
    var id: String
    
    /// Focus hours configuration
    var focusHours: FocusHours
    
    /// Array of user IDs marked as urgent contacts (max 20)
    var urgentContacts: [String]
    
    /// Array of urgent keywords for message detection (min 3, max 50)
    var urgentKeywords: [String]
    
    /// Priority rules configuration
    var priorityRules: PriorityRules
    
    /// Preferred communication tone for AI responses
    var communicationTone: CommunicationTone
    
    /// When preferences were created
    var createdAt: Date
    
    /// When preferences were last updated
    var updatedAt: Date
    
    /// Schema version for future migrations
    var version: Int
    
    /// Firestore collection name
    static let collectionName = "preferences"
    
    /// Document ID for AI preferences
    static let documentId = "aiPreferences"
    
    // MARK: - Validation
    
    /// Validates preference constraints
    var isValid: Bool {
        return urgentContacts.count <= 20 &&
               urgentKeywords.count >= 3 &&
               urgentKeywords.count <= 50 &&
               focusHours.isValid &&
               version > 0
    }
    
    /// Error description if validation fails
    var validationError: String? {
        if urgentContacts.count > 20 {
            return "Maximum 20 urgent contacts allowed"
        }
        if urgentKeywords.count < 3 {
            return "Minimum 3 urgent keywords required"
        }
        if urgentKeywords.count > 50 {
            return "Maximum 50 urgent keywords allowed"
        }
        if !focusHours.isValid {
            return "Focus hours must have start time before end time"
        }
        return nil
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case focusHours
        case urgentContacts
        case urgentKeywords
        case priorityRules
        case communicationTone
        case createdAt
        case updatedAt
        case version
    }
    
    // MARK: - Initialization
    
    init(id: String = UserPreferences.documentId, focusHours: FocusHours, urgentContacts: [String], urgentKeywords: [String], priorityRules: PriorityRules, communicationTone: CommunicationTone, createdAt: Date, updatedAt: Date, version: Int) {
        self.id = id
        self.focusHours = focusHours
        self.urgentContacts = urgentContacts
        self.urgentKeywords = urgentKeywords
        self.priorityRules = priorityRules
        self.communicationTone = communicationTone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.version = version
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UserPreferences.documentId
        focusHours = try container.decode(FocusHours.self, forKey: .focusHours)
        urgentContacts = try container.decode([String].self, forKey: .urgentContacts)
        urgentKeywords = try container.decode([String].self, forKey: .urgentKeywords)
        priorityRules = try container.decode(PriorityRules.self, forKey: .priorityRules)
        communicationTone = try container.decode(CommunicationTone.self, forKey: .communicationTone)
        version = try container.decode(Int.self, forKey: .version)
        
        // Handle Firestore Timestamp conversion for createdAt
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        // Handle Firestore Timestamp conversion for updatedAt
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        }
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(focusHours, forKey: .focusHours)
        try container.encode(urgentContacts, forKey: .urgentContacts)
        try container.encode(urgentKeywords, forKey: .urgentKeywords)
        try container.encode(priorityRules, forKey: .priorityRules)
        try container.encode(communicationTone, forKey: .communicationTone)
        try container.encode(version, forKey: .version)
        
        // Convert dates to Firestore Timestamps
        try container.encode(Timestamp(date: createdAt), forKey: .createdAt)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
    }
    
    // MARK: - Default Preferences
    
    /// Default preferences for new users
    static var defaultPreferences: UserPreferences {
        let now = Date()
        return UserPreferences(
            id: documentId,
            focusHours: FocusHours.defaultFocusHours,
            urgentContacts: [],
            urgentKeywords: ["urgent", "critical", "asap", "emergency", "production down"],
            priorityRules: PriorityRules.defaultRules,
            communicationTone: .friendly,
            createdAt: now,
            updatedAt: now,
            version: 1
        )
    }
}

