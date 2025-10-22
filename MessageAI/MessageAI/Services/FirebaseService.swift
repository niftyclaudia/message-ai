//
//  FirebaseService.swift
//  MessageAI
//
//  Firebase configuration and initialization service
//

import Foundation
import FirebaseCore
import FirebaseFirestore

/// Singleton service for Firebase configuration and Firestore instance management
/// - Note: Must call configure() before using any Firebase services
class FirebaseService {
    
    // MARK: - Singleton
    
    static let shared = FirebaseService()
    
    // MARK: - Properties
    
    private var isConfigured = false
    private var firestoreInstance: Firestore?
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Configures Firebase and Firestore with offline persistence
    /// - Throws: FirebaseConfigError if configuration fails
    /// - Note: Safe to call multiple times (idempotent)
    /// - Performance: Should complete in < 500ms (see shared-standards.md)
    func configure() throws {
        // Idempotent - safe to call multiple times
        if isConfigured {
            return
        }
        
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Configure Firestore with offline persistence using new API
        let settings = FirestoreSettings()
        
        // Use new cacheSettings API with 50MB limit as per PRD requirements
        let cacheSizeBytes = 50 * 1024 * 1024 // 50MB
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: cacheSizeBytes))
        
        let db = Firestore.firestore()
        db.settings = settings
        
        firestoreInstance = db
        isConfigured = true
        
    }
    
    /// Returns the configured Firestore instance
    /// - Returns: Firestore instance
    /// - Precondition: configure() must be called first
    func getFirestore() -> Firestore {
        guard let firestore = firestoreInstance else {
            // Attempt to get Firestore instance even if not explicitly configured
            // This handles cases where Firebase was configured elsewhere
            return Firestore.firestore()
        }
        return firestore
    }
}

