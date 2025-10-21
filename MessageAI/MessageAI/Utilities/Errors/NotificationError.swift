//
//  NotificationError.swift
//  MessageAI
//
//  Error types for notification operations
//

import Foundation

/// Errors that can occur during notification operations
enum NotificationError: LocalizedError {
    case permissionDenied
    case tokenRegistrationFailed
    case firestoreUpdateFailed
    case invalidPayload
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Notification permission was denied"
        case .tokenRegistrationFailed:
            return "Failed to register device token"
        case .firestoreUpdateFailed:
            return "Failed to update token in database"
        case .invalidPayload:
            return "Notification payload is invalid or malformed"
        }
    }
}
