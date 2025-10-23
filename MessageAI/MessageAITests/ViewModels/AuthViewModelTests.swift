//
//  AuthViewModelTests.swift
//  MessageAITests
//
//  Unit tests for AuthViewModel
//

import XCTest
@testable import MessageAI

@MainActor
final class AuthViewModelTests: XCTestCase {
    
    var mockAuthService: MockAuthService!
    var viewModel: AuthViewModel!
    
    override func setUp() async throws {
        try await super.setUp()
        mockAuthService = MockAuthService()
        let mockNotificationService = MockNotificationService()
        viewModel = AuthViewModel(authService: mockAuthService, notificationService: mockNotificationService)
    }
    
    override func tearDown() async throws {
        mockAuthService = nil
        viewModel = nil
        try await super.tearDown()
    }
    
    // MARK: - Sign In Tests
    
    func testSignIn_ValidCredentials_Success() async {
        // Given
        let email = "test@example.com"
        let password = "password123"
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Then
        XCTAssertTrue(mockAuthService.signInCalled)
        XCTAssertEqual(mockAuthService.lastEmail, email)
        XCTAssertEqual(mockAuthService.lastPassword, password)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testSignIn_EmptyEmail_ShowsError() async {
        // Given
        let email = ""
        let password = "password123"
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Then
        XCTAssertFalse(mockAuthService.signInCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
    }
    
    func testSignIn_InvalidEmail_ShowsError() async {
        // Given
        let email = "invalid-email"
        let password = "password123"
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Then
        XCTAssertFalse(mockAuthService.signInCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
    }
    
    func testSignIn_WeakPassword_ShowsError() async {
        // Given
        let email = "test@example.com"
        let password = "123"
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Then
        XCTAssertFalse(mockAuthService.signInCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
    }
    
    func testSignIn_ServiceError_ShowsUserFriendlyMessage() async {
        // Given
        let email = "test@example.com"
        let password = "password123"
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = AuthError.invalidCredentials
        
        // When
        await viewModel.signIn(email: email, password: password)
        
        // Then
        XCTAssertTrue(mockAuthService.signInCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.errorMessage, "Invalid email or password. Please try again.")
    }
    
    // MARK: - Sign Up Tests
    
    func testSignUp_ValidData_Success() async {
        // Given
        let displayName = "Test User"
        let email = "test@example.com"
        let password = "password123"
        let confirmPassword = "password123"
        mockAuthService.shouldSucceed = true
        
        // When
        await viewModel.signUp(displayName: displayName, email: email, password: password, confirmPassword: confirmPassword)
        
        // Then
        XCTAssertTrue(mockAuthService.signUpCalled)
        XCTAssertEqual(mockAuthService.lastDisplayName, displayName)
        XCTAssertEqual(mockAuthService.lastEmail, email)
        XCTAssertEqual(mockAuthService.lastPassword, password)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testSignUp_PasswordMismatch_ShowsError() async {
        // Given
        let displayName = "Test User"
        let email = "test@example.com"
        let password = "password123"
        let confirmPassword = "different123"
        
        // When
        await viewModel.signUp(displayName: displayName, email: email, password: password, confirmPassword: confirmPassword)
        
        // Then
        XCTAssertFalse(mockAuthService.signUpCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "Passwords do not match")
        XCTAssertTrue(viewModel.showError)
    }
    
    func testSignUp_InvalidEmail_ShowsError() async {
        // Given
        let displayName = "Test User"
        let email = "invalid"
        let password = "password123"
        let confirmPassword = "password123"
        
        // When
        await viewModel.signUp(displayName: displayName, email: email, password: password, confirmPassword: confirmPassword)
        
        // Then
        XCTAssertFalse(mockAuthService.signUpCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.showError)
    }
    
    func testSignUp_EmailAlreadyInUse_ShowsUserFriendlyMessage() async {
        // Given
        let displayName = "Test User"
        let email = "test@example.com"
        let password = "password123"
        let confirmPassword = "password123"
        mockAuthService.shouldSucceed = false
        mockAuthService.errorToThrow = AuthError.emailAlreadyInUse
        
        // When
        await viewModel.signUp(displayName: displayName, email: email, password: password, confirmPassword: confirmPassword)
        
        // Then
        XCTAssertTrue(mockAuthService.signUpCalled)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "This email is already registered. Please sign in instead.")
        XCTAssertTrue(viewModel.showError)
    }
    
    // MARK: - Clear Error Test
    
    func testClearError_ResetsErrorState() async {
        // Given
        viewModel.errorMessage = "Test error"
        viewModel.showError = true
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.showError)
    }
}

// MARK: - Mock Auth Service

class MockAuthService: AuthService {
    var shouldSucceed = true
    var errorToThrow: Error?
    
    var signInCalled = false
    var signUpCalled = false
    var signOutCalled = false
    
    var lastEmail: String?
    var lastPassword: String?
    var lastDisplayName: String?
    
    override func signIn(email: String, password: String) async throws {
        signInCalled = true
        lastEmail = email
        lastPassword = password
        
        if !shouldSucceed {
            throw errorToThrow ?? AuthError.invalidCredentials
        }
    }
    
    override func signUp(email: String, password: String, displayName: String) async throws -> String {
        signUpCalled = true
        lastEmail = email
        lastPassword = password
        lastDisplayName = displayName
        
        if !shouldSucceed {
            throw errorToThrow ?? AuthError.emailAlreadyInUse
        }
        
        return "mock-user-id"
    }
    
    override func signOut() throws {
        signOutCalled = true
        
        if !shouldSucceed {
            throw errorToThrow ?? AuthError.unknown(NSError(domain: "test", code: -1))
        }
    }
}

