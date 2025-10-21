//
//  UserService.swift
//  MessageAI
//
//  Service for managing user documents in Firestore
//

import Foundation
import FirebaseFirestore

/// Service for user CRUD operations in Firestore
class UserService {
    
    // MARK: - Properties
    
    private let db: Firestore
    private var usersCollection: CollectionReference {
        db.collection(Constants.Collections.users)
    }
    
    // MARK: - Initialization
    
    init(firestore: Firestore? = nil) {
        self.db = firestore ?? FirebaseService.shared.getFirestore()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new user document in Firestore
    /// - Parameters:
    ///   - userID: Firebase Auth UID
    ///   - displayName: User's display name (1-50 characters)
    ///   - email: User's email address
    /// - Throws: UserServiceError for validation or Firestore errors
    /// - Performance: Should complete in < 1 second (see shared-standards.md)
    /// - Note: Uses server timestamp for date fields
    func createUser(userID: String, displayName: String, email: String) async throws {
        // Validate display name
        try validateDisplayName(displayName)
        
        // Prepare user data with server timestamps
        let userData: [String: Any] = [
            "id": userID,
            "displayName": displayName,
            "email": email,
            "createdAt": FieldValue.serverTimestamp(),
            "lastActiveAt": FieldValue.serverTimestamp()
        ]
        
        do {
            try await usersCollection.document(userID).setData(userData)
            print("✅ User document created: \(userID)")
            
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    /// Fetches a user document from Firestore
    /// - Parameter userID: Firebase Auth UID
    /// - Returns: User object
    /// - Throws: UserServiceError.notFound if user doesn't exist, or other Firestore errors
    /// - Performance: Should complete in < 1 second (see shared-standards.md)
    func fetchUser(userID: String) async throws -> User {
        do {
            let document = try await usersCollection.document(userID).getDocument()
            
            guard document.exists else {
                throw UserServiceError.notFound
            }
            
            // Decode document data to User model
            let data = document.data() ?? [:]
            let user = try decodeUser(from: data, id: userID)
            
            print("✅ User fetched: \(userID)")
            return user
            
        } catch let error as UserServiceError {
            throw error
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    /// Updates user document fields in Firestore
    /// - Parameters:
    ///   - userID: Firebase Auth UID
    ///   - displayName: Optional new display name
    ///   - profilePhotoURL: Optional new profile photo URL
    /// - Throws: UserServiceError for validation or Firestore errors
    /// - Note: Only updates provided fields, updates lastActiveAt automatically
    func updateUser(userID: String, displayName: String? = nil, profilePhotoURL: String? = nil) async throws {
        // Validate display name if provided
        if let displayName = displayName {
            try validateDisplayName(displayName)
        }
        
        // Build update data for only provided fields
        var updateData: [String: Any] = [
            "lastActiveAt": FieldValue.serverTimestamp()
        ]
        
        if let displayName = displayName {
            updateData["displayName"] = displayName
        }
        
        if let profilePhotoURL = profilePhotoURL {
            updateData["profilePhotoURL"] = profilePhotoURL
        }
        
        do {
            try await usersCollection.document(userID).updateData(updateData)
            print("✅ User updated: \(userID)")
            
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Validates display name length
    /// - Parameter displayName: Display name to validate
    /// - Throws: UserServiceError.invalidDisplayName if invalid
    private func validateDisplayName(_ displayName: String) throws {
        let length = displayName.count
        guard length >= Constants.Validation.displayNameMinLength &&
              length <= Constants.Validation.displayNameMaxLength else {
            throw UserServiceError.invalidDisplayName
        }
    }
    
    // MARK: - Decoding Helpers
    
    /// Decodes Firestore document data into User model
    /// - Parameters:
    ///   - data: Firestore document data
    ///   - id: User ID
    /// - Returns: User object
    /// - Throws: UserServiceError.unknown if decoding fails
    private func decodeUser(from data: [String: Any], id: String) throws -> User {
        // Extract fields with defaults for optional values
        guard let displayName = data["displayName"] as? String,
              let email = data["email"] as? String else {
            throw UserServiceError.unknown(NSError(domain: "UserService", code: -1, 
                userInfo: [NSLocalizedDescriptionKey: "Missing required user fields"]))
        }
        
        let profilePhotoURL = data["profilePhotoURL"] as? String
        
        // Handle Firestore Timestamps
        let createdAt: Date
        if let timestamp = data["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else {
            createdAt = Date() // Fallback for missing timestamp
        }
        
        let lastActiveAt: Date
        if let timestamp = data["lastActiveAt"] as? Timestamp {
            lastActiveAt = timestamp.dateValue()
        } else {
            lastActiveAt = Date() // Fallback for missing timestamp
        }
        
        return User(
            id: id,
            displayName: displayName,
            email: email,
            profilePhotoURL: profilePhotoURL,
            createdAt: createdAt,
            lastActiveAt: lastActiveAt
        )
    }
    
    // MARK: - Error Mapping
    
    /// Maps Firestore errors to UserServiceError
    /// - Parameter error: The error to map
    /// - Returns: Mapped UserServiceError
    private func mapFirestoreError(_ error: Error) -> UserServiceError {
        let nsError = error as NSError
        
        // Check for Firestore error codes
        if nsError.domain == "FIRFirestoreErrorDomain" {
            switch nsError.code {
            case 7: // Permission denied
                return .permissionDenied
            case 14: // Unavailable (network error)
                return .networkError
            default:
                return .unknown(error)
            }
        }
        
        return .unknown(error)
    }
}

