//
//  AuthViewModel.swift
//  MessageAI
//
//  View model for authentication flow logic and state management
//

import Foundation
import Combine

/// View model handling authentication flow logic
/// - Note: Delegates actual authentication to AuthService, handles UI state
@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether an authentication operation is in progress
    @Published var isLoading: Bool = false
    
    /// User-friendly error message to display
    @Published var errorMessage: String?
    
    /// Shows error alert when true
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    
    private let authService: AuthService
    
    // MARK: - Initialization
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    
    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Note: Updates isLoading and errorMessage during operation
    func signIn(email: String, password: String) async {
        // Client-side validation
        if let validationError = Validation.getValidationError(email: email, password: password) {
            showErrorAlert(validationError)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signIn(email: email, password: password)
            // Success - AuthService will update isAuthenticated
        } catch {
            showErrorAlert(getUserFriendlyMessage(for: error))
        }
        
        isLoading = false
    }
    
    /// Sign up with email, password, and display name
    /// - Parameters:
    ///   - displayName: User's display name
    ///   - email: User's email address
    ///   - password: User's password
    ///   - confirmPassword: Password confirmation
    /// - Note: Updates isLoading and errorMessage during operation
    func signUp(displayName: String, email: String, password: String, confirmPassword: String) async {
        // Client-side validation
        if password != confirmPassword {
            showErrorAlert("Passwords do not match")
            return
        }
        
        if let validationError = Validation.getValidationError(email: email, password: password, displayName: displayName) {
            showErrorAlert(validationError)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.signUp(email: email, password: password, displayName: displayName)
            // Success - AuthService will update isAuthenticated
        } catch {
            showErrorAlert(getUserFriendlyMessage(for: error))
        }
        
        isLoading = false
    }
    
    /// Clear error state
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Private Methods
    
    /// Shows error alert with message
    /// - Parameter message: Error message to display
    private func showErrorAlert(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    /// Converts AuthError to user-friendly message
    /// - Parameter error: Error to convert
    /// - Returns: User-friendly error message
    private func getUserFriendlyMessage(for error: Error) -> String {
        if let authError = error as? AuthError {
            switch authError {
            case .invalidEmail:
                return "Please enter a valid email address"
            case .emailAlreadyInUse:
                return "This email is already registered. Please sign in instead."
            case .weakPassword:
                return "Password must be at least 6 characters"
            case .invalidCredentials:
                return "Invalid email or password. Please try again."
            case .userNotFound:
                return "No account found with this email"
            case .networkError:
                return "Network error. Please check your connection and try again."
            case .userDocumentCreationFailed:
                return "Failed to create user profile. Please try again."
            case .unknown(let underlyingError):
                return "An error occurred: \(underlyingError.localizedDescription)"
            }
        }
        
        return "An unexpected error occurred. Please try again."
    }
}

