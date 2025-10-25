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
    // Notification service temporarily disabled
    // @EnvironmentObject private var notificationService: NotificationService
    
    // MARK: - State
    
    @StateObject private var viewModel: AuthViewModel
    @State private var email: String = ""
    @State private var password: String = ""
    
    // MARK: - Initialization
    
    init(authService: AuthService? = nil, notificationService: NotificationService? = nil) {
        // Use provided services or create temporary ones for preview
        let auth = authService ?? AuthService()
        // Notification service temporarily disabled
        // let notification = notificationService ?? NotificationService()
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: auth, notificationService: nil))
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

                    // Divider with "or" text
                    HStack {
                        Rectangle()
                            .fill(AppTheme.secondaryTextColor.opacity(0.3))
                            .frame(height: 1)

                        Text("or")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.secondaryTextColor)
                            .padding(.horizontal, AppTheme.smallSpacing)

                        Rectangle()
                            .fill(AppTheme.secondaryTextColor.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, AppTheme.smallSpacing)

                    // Google Sign-In button
                    Button {
                        Task {
                            await viewModel.signInWithGoogle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)

                            Text("Sign in with Google")
                                .font(AppTheme.bodyFont)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.mediumRadius)
                                .stroke(AppTheme.secondaryTextColor.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.mediumRadius)
                    }
                    .disabled(viewModel.isLoading)

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

