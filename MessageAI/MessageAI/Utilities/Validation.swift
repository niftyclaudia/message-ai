//
//  Validation.swift
//  MessageAI
//
//  Client-side validation helpers for forms
//

import Foundation

/// Form validation helpers
/// - Note: Used for client-side validation before service calls
struct Validation {
    
    /// Validates email format using regex pattern
    /// - Parameter email: Email string to validate
    /// - Returns: True if email format is valid
    static func isValidEmail(_ email: String) -> Bool {
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.Validation.emailPattern)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Validates password strength
    /// - Parameter password: Password string to validate
    /// - Returns: True if password meets minimum requirements (6+ characters)
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= Constants.Validation.passwordMinLength
    }
    
    /// Validates display name length
    /// - Parameter name: Display name to validate
    /// - Returns: True if name is between 1-50 characters
    static func isValidDisplayName(_ name: String) -> Bool {
        let length = name.trimmingCharacters(in: .whitespacesAndNewlines).count
        return length >= Constants.Validation.displayNameMinLength &&
               length <= Constants.Validation.displayNameMaxLength
    }
    
    /// Gets user-friendly validation error message
    /// - Parameters:
    ///   - email: Email to validate
    ///   - password: Password to validate
    ///   - displayName: Optional display name to validate
    /// - Returns: Error message string or nil if valid
    static func getValidationError(email: String, password: String, displayName: String? = nil) -> String? {
        if email.isEmpty {
            return "Please enter your email address"
        }
        
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        
        if password.isEmpty {
            return "Please enter your password"
        }
        
        if !isValidPassword(password) {
            return "Password must be at least 6 characters"
        }
        
        if let name = displayName {
            if name.isEmpty {
                return "Please enter your display name"
            }
            
            if !isValidDisplayName(name) {
                return "Display name must be between 1-50 characters"
            }
        }
        
        return nil
    }
}

