//
//  LoginView.swift
//  MessageAI
//
//  Login screen with email/password authentication
//

import SwiftUI

/// Login view for existing users
/// - Note: Validates input before calling AuthService
struct LoginView: View {
    
    // MARK: - Environment Objects
    
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State
    
    @StateObject private var viewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    
    // MARK: - Initialization
    
    init(authService: AuthService? = nil) {
        // Use provided authService or create temporary one for preview
        let service = authService ?? AuthService()
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: service))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // Title
                    VStack(spacing: AppTheme.smallSpacing) {
                        Text("Welcome Back")
                            .font(AppTheme.titleFont)
                            .foregroundColor(AppTheme.primaryTextColor)
                        
                        Text("Sign in to continue")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.secondaryTextColor)
                    }
                    .padding(.top, AppTheme.extraLargeSpacing)
                    
                    // Form fields
                    VStack(spacing: AppTheme.mediumSpacing) {
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
                        .textContentType(.password)
                    }
                    .padding(.top, AppTheme.mediumSpacing)
                    
                    // Sign in button
                    PrimaryButton(
                        title: "Sign In",
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.signIn(email: email, password: password)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || viewModel.isLoading)
                    
                    // Sign up link
                    NavigationLink {
                        SignUpView()
                            .environmentObject(authService)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(AppTheme.secondaryTextColor)
                            Text("Sign Up")
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
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}

