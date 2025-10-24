//
//  PreferencesService.swift
//  MessageAI
//
//  Service for managing user AI preferences with Firestore integration
//

import Foundation
import FirebaseFirestore

/// Service for managing user AI preferences and learning data
/// - Note: Handles CRUD operations and real-time sync for user preferences
class PreferencesService {
    
    // MARK: - Properties
    
    private let firestore: Firestore
    private let currentUserID: String?
    
    // MARK: - Initialization
    
    /// Initialize with optional user ID (defaults to nil, must be set before operations)
    init(userID: String? = nil) {
        self.firestore = FirebaseService.shared.getFirestore()
        self.currentUserID = userID
    }
    
    // MARK: - Preferences CRUD Operations
    
    /// Fetches user's AI preferences from Firestore
    /// - Parameter userID: Optional user ID (uses injected userID if not provided)
    /// - Returns: UserPreferences or nil if not configured
    /// - Throws: PreferencesError if fetch fails or user not authenticated
    /// - Performance: Target <100ms (p95) per PRD
    func fetchPreferences(for userID: String? = nil) async throws -> UserPreferences? {
        let userId = try getUserID(userID)
        
        do {
            let docRef = firestore
                .collection(User.collectionName)
                .document(userId)
                .collection(UserPreferences.collectionName)
                .document(UserPreferences.documentId)
            
            let document = try await docRef.getDocument()
            
            guard document.exists else {
                // No preferences configured yet - return nil (first-time user)
                return nil
            }
            
            var preferences = try document.data(as: UserPreferences.self)
            preferences.id = document.documentID
            return preferences
            
        } catch let error as DecodingError {
            throw PreferencesError.decodingError(error)
        } catch {
            throw PreferencesError.networkError(error)
        }
    }
    
    /// Saves user's AI preferences to Firestore
    /// - Parameters:
    ///   - preferences: Complete UserPreferences object to save
    ///   - userID: Optional user ID (uses injected userID if not provided)
    /// - Throws: PreferencesError if validation fails or save fails
    /// - Performance: Target <200ms (p95) per PRD
    func savePreferences(_ preferences: UserPreferences, for userID: String? = nil) async throws {
        let userId = try getUserID(userID)
        
        // Validate preferences before saving
        guard preferences.isValid else {
            throw PreferencesError.validationFailed(preferences.validationError ?? "Invalid preferences")
        }
        
        do {
            // Update timestamp
            var updatedPreferences = preferences
            updatedPreferences.updatedAt = Date()
            
            let docRef = firestore
                .collection(User.collectionName)
                .document(userId)
                .collection(UserPreferences.collectionName)
                .document(UserPreferences.documentId)
            
            try docRef.setData(from: updatedPreferences)
            
        } catch let error as EncodingError {
            throw PreferencesError.encodingError(error)
        } catch {
            throw PreferencesError.networkError(error)
        }
    }
    
    /// Updates a specific preference field without overwriting entire document
    /// - Parameters:
    ///   - field: Preference field path (e.g., "focusHours.enabled")
    ///   - value: New value for the field
    ///   - userID: Optional user ID (uses injected userID if not provided)
    /// - Throws: PreferencesError if update fails
    func updatePreference(field: String, value: Any, for userID: String? = nil) async throws {
        let userId = try getUserID(userID)
        
        do {
            let docRef = firestore
                .collection(User.collectionName)
                .document(userId)
                .collection(UserPreferences.collectionName)
                .document(UserPreferences.documentId)
            
            try await docRef.updateData([
                field: value,
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
        } catch {
            throw PreferencesError.networkError(error)
        }
    }
    
    // MARK: - Urgent Contacts Management
    
    /// Adds a user to urgent contacts list
    /// - Parameters:
    ///   - contactUserID: User ID to add as urgent contact
    ///   - userID: Optional user ID (uses injected userID if not provided)
    /// - Throws: PreferencesError if max contacts (20) reached or operation fails
    func addUrgentContact(_ contactUserID: String, for userID: String? = nil) async throws {
        let userId = try getUserID(userID)
        
        // Fetch current preferences to check count
        guard let currentPreferences = try await fetchPreferences(for: userId) else {
            throw PreferencesError.preferencesNotFound
        }
        
        // Check if already in list
        if currentPreferences.urgentContacts.contains(contactUserID) {
            return // Already added, no-op
        }
        
        // Check max limit
        if currentPreferences.urgentContacts.count >= 20 {
            throw PreferencesError.tooManyContacts
        }
        
        do {
            let docRef = firestore
                .collection(User.collectionName)
                .document(userId)
                .collection(UserPreferences.collectionName)
                .document(UserPreferences.documentId)
            
            try await docRef.updateData([
                "urgentContacts": FieldValue.arrayUnion([contactUserID]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
        } catch {
            throw PreferencesError.networkError(error)
        }
    }
    
    /// Removes a user from urgent contacts list
    /// - Parameters:
    ///   - contactUserID: User ID to remove
    ///   - userID: Optional user ID (uses injected userID if not provided)
    /// - Throws: PreferencesError if operation fails
    func removeUrgentContact(_ contactUserID: String, for userID: String? = nil) async throws {
        let userId = try getUserID(userID)
        
        do {
            let docRef = firestore
                .collection(User.collectionName)
                .document(userId)
                .collection(UserPreferences.collectionName)
                .document(UserPreferences.documentId)
            
            try await docRef.updateData([
                "urgentContacts": FieldValue.arrayRemove([contactUserID]),
                "updatedAt": FieldValue.serverTimestamp()
            ])
            
        } catch {
            throw PreferencesError.networkError(error)
        }
    }
    
    // MARK: - Learning Data Operations
    
    /// Logs learning data when user overrides AI categorization
    /// - Parameters:
    ///   - messageId: Message that was recategorized
    ///   - chatId: Chat ID where message was sent
    ///   - originalCategory: AI's prediction
    ///   - userCategory: User's correction
    ///   - context: Message context for learning
    ///   - userID: Optional user ID (uses injected userID if not provided)
    /// - Throws: PreferencesError if logging fails
    /// - Performance: Target <150ms (p95) per PRD
    func logOverride(
        messageId: String,
        chatId: String,
        originalCategory: MessageCategory,
        userCategory: MessageCategory,
        context: MessageContext,
        for userID: String? = nil
    ) async throws {
        let userId = try getUserID(userID)
        
        let now = Date()
        let entry = LearningDataEntry(
            id: UUID().uuidString,
            messageId: messageId,
            chatId: chatId,
            originalCategory: originalCategory,
            userCategory: userCategory,
            timestamp: now,
            messageContext: context,
            createdAt: now
        )
        
        do {
            let docRef = firestore
                .collection(User.collectionName)
                .document(userId)
                .collection("aiState")
                .document("learningData")
                .collection(LearningDataEntry.collectionName)
                .document(entry.id)
            
            try docRef.setData(from: entry)
            
        } catch let error as EncodingError {
            throw PreferencesError.encodingError(error)
        } catch {
            throw PreferencesError.networkError(error)
        }
    }
    
    /// Fetches recent learning data for pattern analysis
    /// - Parameters:
    ///   - days: Number of days to query (default: 30)
    ///   - limit: Maximum number of entries to return (default: 100)
    ///   - userID: Optional user ID (uses injected userID if not provided)
    /// - Returns: Array of recent learning data entries
    /// - Throws: PreferencesError if fetch fails
    func fetchLearningData(days: Int = 30, limit: Int = 100, for userID: String? = nil) async throws -> [LearningDataEntry] {
        let userId = try getUserID(userID)
        
        // Calculate cutoff date
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
            throw PreferencesError.invalidDateRange
        }
        
        do {
            let querySnapshot = try await firestore
                .collection(User.collectionName)
                .document(userId)
                .collection("aiState")
                .document("learningData")
                .collection(LearningDataEntry.collectionName)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: cutoffDate))
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            var entries: [LearningDataEntry] = []
            for document in querySnapshot.documents {
                do {
                    var entry = try document.data(as: LearningDataEntry.self)
                    entry.id = document.documentID
                    entries.append(entry)
                } catch {
                    // Continue with other documents if one fails
                    continue
                }
            }
            
            return entries
            
        } catch let error as DecodingError {
            throw PreferencesError.decodingError(error)
        } catch {
            throw PreferencesError.networkError(error)
        }
    }
    
    // MARK: - Real-Time Sync
    
    /// Sets up real-time listener for preference changes
    /// - Parameters:
    ///   - userID: Optional user ID (uses injected userID if not provided)
    ///   - completion: Callback with updated preferences (nil if deleted)
    /// - Returns: ListenerRegistration for cleanup
    /// - Throws: PreferencesError if userID is not available
    /// - Performance: Updates should sync <500ms across devices per PRD
    func observePreferences(for userID: String? = nil, completion: @escaping (UserPreferences?) -> Void) throws -> ListenerRegistration {
        let userId = try getUserID(userID)
        
        let docRef = firestore
            .collection(User.collectionName)
            .document(userId)
            .collection(UserPreferences.collectionName)
            .document(UserPreferences.documentId)
        
        return docRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            
            do {
                var preferences = try snapshot.data(as: UserPreferences.self)
                preferences.id = snapshot.documentID
                completion(preferences)
            } catch {
                completion(nil)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets user ID from parameter or injected property
    /// - Parameter userID: Optional user ID parameter
    /// - Returns: Valid user ID
    /// - Throws: PreferencesError.missingUserId if no user ID available
    private func getUserID(_ userID: String?) throws -> String {
        guard let userId = userID ?? currentUserID else {
            throw PreferencesError.missingUserId
        }
        return userId
    }
}

// MARK: - Preferences Error

/// Errors that can occur in PreferencesService operations
enum PreferencesError: Error, LocalizedError {
    case invalidFocusHours
    case tooManyContacts
    case tooFewKeywords
    case tooManyKeywords
    case missingUserId
    case preferencesNotFound
    case networkError(Error)
    case validationFailed(String)
    case encodingError(Error)
    case decodingError(Error)
    case invalidDateRange
    
    var errorDescription: String? {
        switch self {
        case .invalidFocusHours:
            return "Focus hours must have start time before end time"
        case .tooManyContacts:
            return "Maximum 20 urgent contacts allowed"
        case .tooFewKeywords:
            return "Please add at least 3 urgent keywords"
        case .tooManyKeywords:
            return "Maximum 50 keywords allowed"
        case .missingUserId:
            return "User not authenticated"
        case .preferencesNotFound:
            return "Preferences not found. Please configure your preferences first."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .encodingError(let error):
            return "Failed to save preferences: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to load preferences: \(error.localizedDescription)"
        case .invalidDateRange:
            return "Invalid date range specified"
        }
    }
}

