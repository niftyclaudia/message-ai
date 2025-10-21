//
//  UserServiceError.swift
//  MessageAI
//
//  User service error types with user-friendly descriptions
//

import Foundation

/// Errors that can occur during user service operations
enum UserServiceError: LocalizedError, Equatable {
    case invalidDisplayName
    case notFound
    case permissionDenied
    case networkError
    case unknown(Error)
    
    // MARK: - Equatable
    
    static func == (lhs: UserServiceError, rhs: UserServiceError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidDisplayName, .invalidDisplayName):
            return true
        case (.notFound, .notFound):
            return true
        case (.permissionDenied, .permissionDenied):
            return true
        case (.networkError, .networkError):
            return true
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return (lhsError as NSError).domain == (rhsError as NSError).domain &&
                   (lhsError as NSError).code == (rhsError as NSError).code
        default:
            return false
        }
    }
    
    /// User-friendly error descriptions
    var errorDescription: String? {
        switch self {
        case .invalidDisplayName:
            return "Display name must be between 1 and 50 characters."
        case .notFound:
            return "User not found."
        case .permissionDenied:
            return "You don't have permission to perform this action."
        case .networkError:
            return "Network connection error. Please check your internet connection and try again."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    /// Recovery suggestions for users
    var recoverySuggestion: String? {
        switch self {
        case .invalidDisplayName:
            return "Choose a display name between 1 and 50 characters."
        case .notFound:
            return "This user may have been deleted or doesn't exist."
        case .permissionDenied:
            return "You can only edit your own profile."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknown:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

