//
//  AuthService.swift
//  MessageAI
//
//  Authentication service handling user sign up, sign in, and sign out
//

import Foundation
import FirebaseAuth
import Combine

/// Service for managing user authentication
/// - Note: Observable for SwiftUI state binding
class AuthService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently authenticated Firebase user
    @Published var currentUser: FirebaseAuth.User?
    
    /// Whether a user is currently authenticated
    @Published var isAuthenticated: Bool = false
    
    // MARK: - Private Properties
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let userService: UserService
    
    // MARK: - Initialization
    
    init(userService: UserService = UserService()) {
        self.userService = userService
        observeAuthState()
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    // MARK: - Public Methods
    
    /// Sign up a new user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password (min 6 characters)
    ///   - displayName: User's display name (1-50 characters)
    /// - Returns: The created user's ID
    /// - Throws: AuthError for validation or Firebase errors
    /// - Performance: Should complete in < 5 seconds (see shared-standards.md)
    /// - Note: Atomically creates both Auth user and Firestore document
    func signUp(email: String, password: String, displayName: String) async throws -> String {
        // Validate inputs before calling Firebase
        try validateEmail(email)
        try validatePassword(password)
        try validateDisplayName(displayName)
        
        do {
            // Create Firebase Auth user
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            let userID = authResult.user.uid
            
            // Create Firestore user document
            do {
                try await userService.createUser(userID: userID, displayName: displayName, email: email)
                print("✅ User signed up successfully: \(userID)")
                return userID
                
            } catch {
                // Rollback: Delete Auth user if Firestore creation fails
                print("⚠️ Firestore user creation failed, rolling back Auth user")
                try? await authResult.user.delete()
                throw AuthError.userDocumentCreationFailed
            }
            
        } catch let error as AuthError {
            throw error
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Sign in an existing user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Throws: AuthError for validation or Firebase errors
    /// - Performance: Should complete in < 3 seconds (see shared-standards.md)
    func signIn(email: String, password: String) async throws {
        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            print("✅ User signed in successfully: \(authResult.user.uid)")
            
        } catch {
            throw mapAuthError(error)
        }
    }
    
    /// Sign out the current user
    /// - Throws: AuthError if sign out fails
    /// - Note: Clears currentUser and isAuthenticated properties
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            print("✅ User signed out successfully")
            
        } catch {
            throw AuthError.unknown(error)
        }
    }
    
    /// Observes Firebase auth state changes and updates published properties
    /// - Note: Called automatically in init, updates happen < 100ms (shared-standards.md)
    func observeAuthState() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                
                if let user = user {
                    print("🔄 Auth state changed: User \(user.uid) authenticated")
                } else {
                    print("🔄 Auth state changed: No user authenticated")
                }
            }
        }
    }
    
    // MARK: - Validation Helpers
    
    /// Validates email format
    /// - Parameter email: Email to validate
    /// - Throws: AuthError.invalidEmail if format is invalid
    private func validateEmail(_ email: String) throws {
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", Constants.Validation.emailPattern)
        guard emailPredicate.evaluate(with: email) else {
            throw AuthError.invalidEmail
        }
    }
    
    /// Validates password strength
    /// - Parameter password: Password to validate
    /// - Throws: AuthError.weakPassword if too short
    private func validatePassword(_ password: String) throws {
        guard password.count >= Constants.Validation.passwordMinLength else {
            throw AuthError.weakPassword
        }
    }
    
    /// Validates display name length
    /// - Parameter displayName: Display name to validate
    /// - Throws: UserServiceError.invalidDisplayName if invalid
    private func validateDisplayName(_ displayName: String) throws {
        let length = displayName.count
        guard length >= Constants.Validation.displayNameMinLength &&
              length <= Constants.Validation.displayNameMaxLength else {
            throw AuthError.unknown(UserServiceError.invalidDisplayName)
        }
    }
    
    // MARK: - Error Mapping
    
    /// Maps Firebase AuthErrorCode to custom AuthError
    /// - Parameter error: The error to map
    /// - Returns: Mapped AuthError
    private func mapAuthError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        
        // Map Firebase Auth error codes to custom errors
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.wrongPassword.rawValue, AuthErrorCode.invalidCredential.rawValue:
            return .invalidCredentials
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        default:
            return .unknown(error)
        }
    }
}

