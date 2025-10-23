//
//  ForgotPasswordView.swift
//  MessageAI
//
//  Password reset screen for forgotten passwords
//

import SwiftUI

/// Forgot password view for password recovery
/// - Note: Sends reset email via Firebase Auth
struct ForgotPasswordView: View {
    
    // MARK: - Environment Objects
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var notificationService: NotificationService
    
    // MARK: - State
    
    @StateObject private var viewModel: AuthViewModel
    @State private var email: String = ""
    @State private var showSuccessMessage: Bool = false
    
    // MARK: - Initialization
    
    init(authService: AuthService? = nil, notificationService: NotificationService? = nil, prefillEmail: String = "") {
        // Use provided services or create temporary ones for preview
        let auth = authService ?? AuthService()
        let notification = notificationService ?? NotificationService()
        _viewModel = StateObject(wrappedValue: AuthViewModel(authService: auth, notificationService: notification))
        _email = State(initialValue: prefillEmail)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    // Title
                    VStack(spacing: AppTheme.smallSpacing) {
                        Text("Reset Password")
                            .font(AppTheme.titleFont)
                            .foregroundColor(AppTheme.primaryTextColor)
                        
                        Text("Enter your email address and we'll send you instructions to reset your password")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.secondaryTextColor)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AppTheme.extraLargeSpacing)
                    
                    // Email field
                    CustomTextField(
                        placeholder: "Email",
                        text: $email
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .padding(.top, AppTheme.mediumSpacing)
                    
                    // Send reset link button
                    PrimaryButton(
                        title: "Send Reset Link",
                        isLoading: viewModel.isLoading
                    ) {
                        Task {
                            await viewModel.sendPasswordReset(email: email)
                            // Show success message and dismiss after delay
                            if viewModel.errorMessage?.contains("Check your email") == true {
                                showSuccessMessage = true
                                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                                dismiss()
                            }
                        }
                    }
                    .disabled(email.isEmpty || viewModel.isLoading)
                    
                    // Back to login button
                    Button {
                        dismiss()
                    } label: {
                        Text("Back to Login")
                            .font(AppTheme.bodyFont)
                            .foregroundColor(AppTheme.primaryColor)
                            .fontWeight(.semibold)
                    }
                    .padding(.top, AppTheme.smallSpacing)
                    .disabled(viewModel.isLoading)
                }
                .padding(AppTheme.mediumSpacing)
            }
            .background(AppTheme.backgroundColor)
            .hideKeyboard()
            .errorAlert(isPresented: $viewModel.showError, error: $viewModel.errorMessage)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ForgotPasswordView()
        .environmentObject(AuthService())
        .environmentObject(NotificationService())
}

