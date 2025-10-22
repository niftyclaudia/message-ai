//
//  AuthError.swift
//  MessageAI
//
//  Authentication error types with user-friendly descriptions
//

import Foundation

/// Errors that can occur during authentication operations
enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case invalidCredentials
    case userNotFound
    case networkError
    case userDocumentCreationFailed
    case googleSignInCancelled
    case googleSignInFailed
    case googleSignInTimeout
    case missingGoogleClientID
    case unknown(Error)
    
    // MARK: - Equatable
    
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidEmail, .invalidEmail):
            return true
        case (.emailAlreadyInUse, .emailAlreadyInUse):
            return true
        case (.weakPassword, .weakPassword):
            return true
        case (.invalidCredentials, .invalidCredentials):
            return true
        case (.userNotFound, .userNotFound):
            return true
        case (.networkError, .networkError):
            return true
        case (.userDocumentCreationFailed, .userDocumentCreationFailed):
            return true
        case (.googleSignInCancelled, .googleSignInCancelled):
            return true
        case (.googleSignInFailed, .googleSignInFailed):
            return true
        case (.googleSignInTimeout, .googleSignInTimeout):
            return true
        case (.missingGoogleClientID, .missingGoogleClientID):
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
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyInUse:
            return "This email address is already registered. Please sign in or use a different email."
        case .weakPassword:
            return "Password must be at least 6 characters long."
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .userNotFound:
            return "No account found with this email address."
        case .networkError:
            return "Network connection error. Please check your internet connection and try again."
        case .userDocumentCreationFailed:
            return "Failed to create user profile. Please try again."
        case .googleSignInCancelled:
            return "Google Sign-In was cancelled."
        case .googleSignInFailed:
            return "Google Sign-In failed. Please try again."
        case .googleSignInTimeout:
            return "Google Sign-In timed out. Please try again."
        case .missingGoogleClientID:
            return "Google Sign-In is not properly configured. Please contact support."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    /// Recovery suggestions for users
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Check that your email address is formatted correctly (e.g., user@example.com)"
        case .emailAlreadyInUse:
            return "Try signing in instead, or use the 'Forgot Password' option if needed."
        case .weakPassword:
            return "Choose a password with at least 6 characters for better security."
        case .invalidCredentials:
            return "Double-check your email and password, or use 'Forgot Password' to reset."
        case .userNotFound:
            return "Please sign up first to create an account."
        case .networkError:
            return "Check your internet connection and try again."
        case .userDocumentCreationFailed:
            return "Please try signing up again. If the problem persists, contact support."
        case .googleSignInCancelled:
            return "You can try again by tapping the 'Sign in with Google' button."
        case .googleSignInFailed:
            return "Make sure you have an active internet connection and try again."
        case .googleSignInTimeout:
            return "The sign-in process took too long. Please try again."
        case .missingGoogleClientID:
            return "This is a configuration issue. Please contact support."
        case .unknown:
            return "Please try again. If the problem persists, contact support."
        }
    }
}

