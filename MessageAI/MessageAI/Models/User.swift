//
//  User.swift
//  MessageAI
//
//  Core user data model matching Firestore schema
//

import Foundation
import FirebaseFirestore

/// User data model
/// - Note: Maps to Firestore collection 'users' with document ID = userID
struct User: Codable, Identifiable, Equatable {
    /// Firebase Auth UID - immutable
    var id: String
    
    /// Display name shown in UI
    /// - Validation: 1-50 characters
    var displayName: String
    
    /// User's email address - immutable after creation
    var email: String
    
    /// Optional profile photo URL
    var profilePhotoURL: String?
    
    /// Account creation timestamp - immutable
    var createdAt: Date
    
    /// Last activity timestamp - updated on user actions
    var lastActiveAt: Date
    
    /// Firestore collection name
    static let collectionName = "users"
    
    // MARK: - Computed Properties
    
    /// Extracts initials from display name (e.g., "John Doe" → "JD")
    var initials: String {
        displayName.extractInitials()
    }
    
    /// Formats creation date as "Member since Jan 2025"
    var memberSinceFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return "Member since \(formatter.string(from: createdAt))"
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case email
        case profilePhotoURL
        case createdAt
        case lastActiveAt
    }
    
    // MARK: - Initialization
    
    init(id: String, displayName: String, email: String, profilePhotoURL: String? = nil, createdAt: Date, lastActiveAt: Date) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.profilePhotoURL = profilePhotoURL
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        displayName = try container.decode(String.self, forKey: .displayName)
        email = try container.decode(String.self, forKey: .email)
        profilePhotoURL = try container.decodeIfPresent(String.self, forKey: .profilePhotoURL)
        
        // Handle Firestore Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .createdAt) {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let timestamp = try? container.decode(Timestamp.self, forKey: .lastActiveAt) {
            lastActiveAt = timestamp.dateValue()
        } else {
            lastActiveAt = try container.decode(Date.self, forKey: .lastActiveAt)
        }
    }
}

