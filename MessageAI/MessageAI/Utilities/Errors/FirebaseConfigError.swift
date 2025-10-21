//
//  FirebaseConfigError.swift
//  MessageAI
//
//  Firebase configuration error types
//

import Foundation

/// Errors that can occur during Firebase configuration
enum FirebaseConfigError: LocalizedError {
    case alreadyConfigured
    case missingPlist
    case configurationFailed(Error)
    
    /// User-friendly error descriptions
    var errorDescription: String? {
        switch self {
        case .alreadyConfigured:
            return "Firebase has already been configured."
        case .missingPlist:
            return "GoogleService-Info.plist is missing. Please add it to the project."
        case .configurationFailed(let error):
            return "Firebase configuration failed: \(error.localizedDescription)"
        }
    }
    
    /// Recovery suggestions
    var recoverySuggestion: String? {
        switch self {
        case .alreadyConfigured:
            return "This is not an error - Firebase is already initialized."
        case .missingPlist:
            return "Download GoogleService-Info.plist from Firebase Console and add it to your Xcode project."
        case .configurationFailed:
            return "Check your GoogleService-Info.plist file and Firebase project settings."
        }
    }
}

