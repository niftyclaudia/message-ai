//
//  PasswordResetTests.swift
//  MessageAITests
//
//  Tests for password reset functionality using Swift Testing
//

import Testing
import Foundation
@testable import MessageAI

/// Password reset tests verifying email validation and Firebase integration
/// - Note: Uses Swift Testing framework with @Test syntax
@Suite("Password Reset Tests")
struct PasswordResetTests {
    
    // MARK: - Setup
    
    private let authService = AuthService()
    
    // MARK: - Email Validation Tests
    
    @Test("Valid email sends reset successfully")
    func validEmailSendsResetSuccessfully() async throws {
        // Given: Valid email address
        let validEmail = "test@example.com"
        
        // When: Send password reset email
        // Note: This will actually call Firebase, which will silently succeed even for non-existent emails
        // for security reasons (doesn't reveal if account exists)
        do {
            try await authService.sendPasswordResetEmail(email: validEmail)
            // Success - no error thrown
        } catch {
            // If error occurs, it should not be a validation error
            let authError = error as? AuthError
            #expect(authError != .invalidEmail, "Valid email should not throw invalidEmail error")
        }
    }
    
    @Test("Invalid email format throws validation error")
    func invalidEmailFormatThrowsValidationError() async throws {
        // Given: Invalid email formats
        let invalidEmails = [
            "notanemail",
            "missing@domain",
            "@nodomain.com",
            "spaces in@email.com",
            "no-tld@domain",
            ""
        ]
        
        for invalidEmail in invalidEmails {
            // When: Try to send password reset with invalid email
            var threwError = false
            var errorType: AuthError?
            
            do {
                try await authService.sendPasswordResetEmail(email: invalidEmail)
            } catch let error as AuthError {
                threwError = true
                errorType = error
            } catch {
                threwError = true
            }
            
            // Then: Should throw validation error
            #expect(threwError, "Invalid email '\(invalidEmail)' should throw error")
            
            // For empty string and clearly invalid formats, we expect invalidEmail error
            if invalidEmail.isEmpty || !invalidEmail.contains("@") {
                #expect(errorType == .invalidEmail, "Should throw invalidEmail error for '\(invalidEmail)'")
            }
        }
    }
    
    @Test("Empty email throws validation error")
    func emptyEmailThrowsValidationError() async throws {
        // Given: Empty email
        let emptyEmail = ""
        
        // When: Try to send password reset
        var threwError = false
        var errorType: AuthError?
        
        do {
            try await authService.sendPasswordResetEmail(email: emptyEmail)
        } catch let error as AuthError {
            threwError = true
            errorType = error
        } catch {
            threwError = true
        }
        
        // Then: Should throw validation error
        #expect(threwError, "Empty email should throw error")
        #expect(errorType == .invalidEmail, "Should throw invalidEmail error")
    }
    
    @Test("Email with only spaces throws validation error")
    func emailWithOnlySpacesThrowsValidationError() async throws {
        // Given: Email with only spaces
        let spacesEmail = "   "
        
        // When: Try to send password reset
        var threwError = false
        
        do {
            try await authService.sendPasswordResetEmail(email: spacesEmail)
        } catch {
            threwError = true
        }
        
        // Then: Should throw validation error
        #expect(threwError, "Email with only spaces should throw error")
    }
    
    // MARK: - Performance Tests
    
    @Test("Password reset completes within 2 seconds")
    func passwordResetCompletesWithin2Seconds() async throws {
        // Given: Valid email
        let email = "performance-test@example.com"
        
        // When: Measure reset email send time
        let startTime = Date()
        
        do {
            try await authService.sendPasswordResetEmail(email: email)
            let duration = Date().timeIntervalSince(startTime)
            
            // Then: Should complete within 2 seconds
            #expect(duration < 2.0, "Password reset should complete within 2 seconds, took \(duration)s")
        } catch {
            // Firebase may throw network error in test environment
            // We still verify the operation completed quickly
            let duration = Date().timeIntervalSince(startTime)
            #expect(duration < 2.0, "Operation should complete (even with error) within 2 seconds")
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Case sensitivity in email is handled")
    func caseSensitivityInEmailIsHandled() async throws {
        // Given: Emails with different cases
        let lowerCaseEmail = "test@example.com"
        let upperCaseEmail = "TEST@EXAMPLE.COM"
        let mixedCaseEmail = "TeSt@ExAmPlE.CoM"
        
        // When: Try to send reset for each variation
        // All should be accepted as valid format (Firebase handles case-insensitivity)
        for email in [lowerCaseEmail, upperCaseEmail, mixedCaseEmail] {
            do {
                try await authService.sendPasswordResetEmail(email: email)
                // Success - no validation error
            } catch let error as AuthError {
                // Should not be validation error
                #expect(error != .invalidEmail, "Email '\(email)' should be valid format")
            } catch {
                // Other errors (network, etc.) are acceptable in tests
            }
        }
    }
    
    @Test("Email with special characters validates correctly")
    func emailWithSpecialCharactersValidatesCorrectly() async throws {
        // Given: Valid emails with special characters
        let specialCharEmails = [
            "user+tag@example.com",
            "user.name@example.com",
            "user_name@example.com",
            "user-name@example.com"
        ]
        
        for email in specialCharEmails {
            // When: Try to send reset
            do {
                try await authService.sendPasswordResetEmail(email: email)
                // Success - no validation error
            } catch let error as AuthError {
                // Should not be validation error for valid formats
                #expect(error != .invalidEmail, "Email '\(email)' should be valid format")
            } catch {
                // Other errors are acceptable
            }
        }
    }
    
    @Test("Long email addresses are handled")
    func longEmailAddressesAreHandled() async throws {
        // Given: Very long but valid email
        let longLocalPart = String(repeating: "a", count: 50)
        let longEmail = "\(longLocalPart)@example.com"
        
        // When: Try to send reset
        do {
            try await authService.sendPasswordResetEmail(email: longEmail)
            // Success - no validation error
        } catch let error as AuthError {
            // Should not be validation error
            #expect(error != .invalidEmail, "Long but valid email should be accepted")
        } catch {
            // Other errors are acceptable
        }
    }
    
    // MARK: - AuthViewModel Integration Tests
    
    @Test("AuthViewModel handles password reset correctly")
    func authViewModelHandlesPasswordResetCorrectly() async {
        // Given: AuthViewModel
        let notificationService = NotificationService()
        let viewModel = AuthViewModel(authService: authService, notificationService: notificationService)
        let validEmail = "viewmodel-test@example.com"
        
        // When: Call sendPasswordReset
        await viewModel.sendPasswordReset(email: validEmail)
        
        // Then: Should not throw error and should update loading state
        // Note: In actual UI, this would show success message
        #expect(!viewModel.isLoading, "Loading should be false after completion")
    }
    
    @Test("AuthViewModel validates empty email")
    func authViewModelValidatesEmptyEmail() async {
        // Given: AuthViewModel and empty email
        let notificationService = NotificationService()
        let viewModel = AuthViewModel(authService: authService, notificationService: notificationService)
        let emptyEmail = ""
        
        // When: Try to send reset with empty email
        await viewModel.sendPasswordReset(email: emptyEmail)
        
        // Then: Should show error message
        #expect(viewModel.errorMessage != nil, "Should have error message for empty email")
        #expect(viewModel.showError, "Should show error alert")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Network error is properly handled")
    func networkErrorIsProperlyHandled() async throws {
        // Note: This test verifies error handling exists
        // Actual network errors are difficult to simulate without mocking
        
        // Given: Valid email
        let email = "network-test@example.com"
        
        // When: Try to send reset
        do {
            try await authService.sendPasswordResetEmail(email: email)
            // If successful, no error to handle
        } catch let error as AuthError {
            // Then: Should be a recognized error type
            let isRecognizedError = (
                error == .invalidEmail ||
                error == .networkError ||
                error == .userNotFound
            )
            
            if case .unknown = error {
                // Unknown errors are acceptable in test environment
            } else {
                #expect(isRecognizedError, "Should be a recognized AuthError type")
            }
        } catch {
            // Other errors are acceptable in test environment
        }
    }
}


