//
//  Constants.swift
//  MessageAI
//
//  App-wide constants
//

import Foundation

/// Application constants
enum Constants {
    
    // MARK: - Firebase Collections
    
    /// Firestore collection names
    enum Collections {
        static let users = "users"
        static let chats = "chats"
        static let messages = "messages"
    }
    
    // MARK: - Validation
    
    /// Field validation constants
    enum Validation {
        static let displayNameMinLength = 1
        static let displayNameMaxLength = 50
        static let passwordMinLength = 6
        
        /// Email validation regex pattern
        static let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    }
    
    // MARK: - Performance Targets
    
    /// Performance benchmarks from shared-standards.md
    enum Performance {
        static let firebaseInitMaxMs = 500
        static let signInMaxSeconds = 3.0
        static let signUpMaxSeconds = 5.0
        static let fetchUserMaxSeconds = 1.0
        static let messageSyncMaxMs = 100
        static let authStateChangeMaxMs = 100
    }
}

