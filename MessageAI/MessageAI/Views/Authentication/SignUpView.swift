//
//  SignUpView.swift
//  MessageAI
//
//  Sign up screen for new user registration
//

import SwiftUI

/// Sign up view for new users
/// - Note: Validates input before calling AuthService
struct SignUpView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State
    
    @StateObject private var viewModel: AuthViewModel
    @State private var displayName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword
    }
    
    // MARK: - Initialization
    
    init(authService: AuthService? = nil) {
        // Use provided authService or create temporary one for preview
        let service = authService ?? AuthService()
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: service))
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.largeSpacing) {
                // Title
                VStack(spacing: AppTheme.smallSpacing) {
                    Text("Create Account")
                        .font(AppTheme.titleFont)
                        .foregroundColor(AppTheme.primaryTextColor)
                    
                    Text("Sign up to get started")
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.secondaryTextColor)
                }
                .padding(.top, AppTheme.extraLargeSpacing)
                
                // Form fields
                VStack(spacing: AppTheme.mediumSpacing) {
                    CustomTextField(
                        placeholder: "Display Name",
                        text: $displayName
                    )
                    .textContentType(.name)
                    
                    CustomTextField(
                        placeholder: "Email",
                        text: $email
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    
                    CustomTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true
                    )
                    .textContentType(.newPassword)
                    
                    CustomTextField(
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true
                    )
                    .textContentType(.newPassword)
                    
                    // Password match indicator
                    if !password.isEmpty && !confirmPassword.isEmpty {
                        HStack {
                            Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(password == confirmPassword ? AppTheme.successColor : AppTheme.errorColor)
                            
                            Text(password == confirmPassword ? "Passwords match" : "Passwords do not match")
                                .font(AppTheme.captionFont)
                                .foregroundColor(password == confirmPassword ? AppTheme.successColor : AppTheme.errorColor)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, AppTheme.mediumSpacing)
                
                // Sign up button
                PrimaryButton(
                    title: "Sign Up",
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.signUp(
                            displayName: displayName,
                            email: email,
                            password: password,
                            confirmPassword: confirmPassword
                        )
                    }
                }
                .disabled(!isFormValid || viewModel.isLoading)
                
                // Back to login hint
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(AppTheme.secondaryTextColor)
                        Text("Sign In")
                            .foregroundColor(AppTheme.primaryColor)
                            .fontWeight(.semibold)
                    }
                    .font(AppTheme.bodyFont)
                }
                .padding(.top, AppTheme.smallSpacing)
            }
            .padding(AppTheme.mediumSpacing)
        }
        .background(AppTheme.backgroundColor)
        .hideKeyboard()
        .errorAlert(isPresented: $viewModel.showError, error: $viewModel.errorMessage)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthService())
    }
}

