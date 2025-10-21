//
//  ValidationTests.swift
//  MessageAITests
//
//  Unit tests for validation helpers
//

import XCTest
@testable import MessageAI

final class ValidationTests: XCTestCase {
    
    // MARK: - Email Validation Tests
    
    func testEmailValidation_ValidEmails_ReturnsTrue() {
        let validEmails = [
            "test@example.com",
            "user.name@example.com",
            "user+tag@example.co.uk",
            "123@test.com"
        ]
        
        for email in validEmails {
            XCTAssertTrue(Validation.isValidEmail(email), "Expected \(email) to be valid")
        }
    }
    
    func testEmailValidation_InvalidEmails_ReturnsFalse() {
        let invalidEmails = [
            "",
            "invalid",
            "@example.com",
            "user@",
            "user @example.com",
            "user@example",
            "user@.com"
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(Validation.isValidEmail(email), "Expected \(email) to be invalid")
        }
    }
    
    // MARK: - Password Validation Tests
    
    func testPasswordValidation_ValidPasswords_ReturnsTrue() {
        let validPasswords = [
            "123456",
            "password",
            "securePass123!",
            "a".repeat(50)
        ]
        
        for password in validPasswords {
            XCTAssertTrue(Validation.isValidPassword(password), "Expected \(password) to be valid")
        }
    }
    
    func testPasswordValidation_WeakPasswords_ReturnsFalse() {
        let weakPasswords = [
            "",
            "a",
            "12345",
            "pass"
        ]
        
        for password in weakPasswords {
            XCTAssertFalse(Validation.isValidPassword(password), "Expected \(password) to be invalid")
        }
    }
    
    // MARK: - Display Name Validation Tests
    
    func testDisplayNameValidation_ValidNames_ReturnsTrue() {
        let validNames = [
            "John",
            "John Doe",
            "A",
            "a".repeat(50),
            "User123"
        ]
        
        for name in validNames {
            XCTAssertTrue(Validation.isValidDisplayName(name), "Expected '\(name)' to be valid")
        }
    }
    
    func testDisplayNameValidation_InvalidNames_ReturnsFalse() {
        let invalidNames = [
            "",
            "   ",
            "a".repeat(51)
        ]
        
        for name in invalidNames {
            XCTAssertFalse(Validation.isValidDisplayName(name), "Expected '\(name)' to be invalid")
        }
    }
    
    // MARK: - Validation Error Message Tests
    
    func testGetValidationError_EmptyEmail_ReturnsError() {
        let error = Validation.getValidationError(email: "", password: "password123")
        XCTAssertEqual(error, "Please enter your email address")
    }
    
    func testGetValidationError_InvalidEmail_ReturnsError() {
        let error = Validation.getValidationError(email: "invalid", password: "password123")
        XCTAssertEqual(error, "Please enter a valid email address")
    }
    
    func testGetValidationError_EmptyPassword_ReturnsError() {
        let error = Validation.getValidationError(email: "test@example.com", password: "")
        XCTAssertEqual(error, "Please enter your password")
    }
    
    func testGetValidationError_WeakPassword_ReturnsError() {
        let error = Validation.getValidationError(email: "test@example.com", password: "123")
        XCTAssertEqual(error, "Password must be at least 6 characters")
    }
    
    func testGetValidationError_EmptyDisplayName_ReturnsError() {
        let error = Validation.getValidationError(
            email: "test@example.com",
            password: "password123",
            displayName: ""
        )
        XCTAssertEqual(error, "Please enter your display name")
    }
    
    func testGetValidationError_InvalidDisplayName_ReturnsError() {
        let error = Validation.getValidationError(
            email: "test@example.com",
            password: "password123",
            displayName: "a".repeat(51)
        )
        XCTAssertEqual(error, "Display name must be between 1-50 characters")
    }
    
    func testGetValidationError_ValidInputs_ReturnsNil() {
        let error = Validation.getValidationError(
            email: "test@example.com",
            password: "password123",
            displayName: "John Doe"
        )
        XCTAssertNil(error)
    }
}

// MARK: - Helper Extension

private extension String {
    func `repeat`(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

