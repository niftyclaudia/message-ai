//
//  ProfileView.swift
//  MessageAI
//
//  View displaying user profile
//

import SwiftUI

/// Main profile view showing user information
struct ProfileView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State Objects
    
    @StateObject private var viewModel: ProfileViewModel
    
    // MARK: - State
    
    @State private var showEditProfile = false
    @State private var showLogoutAlert = false
    
    // MARK: - Initialization
    
    init() {
        _viewModel = StateObject(wrappedValue: ProfileViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.user == nil {
                    LoadingView(message: "Loading profile...")
                } else if let user = viewModel.user {
                    profileContent(user: user)
                } else if let errorMessage = viewModel.errorMessage {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        message: errorMessage
                    )
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showLogoutAlert = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    handleLogout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showEditProfile) {
                ProfileEditView()
                    .environmentObject(authService)
            }
            .task {
                // Pass the environment's authService to the ViewModel
                await viewModel.loadProfile(authService: authService)
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Main profile content
    private func profileContent(user: User) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.largeSpacing) {
                // Avatar
                AvatarView(
                    photoURL: user.profilePhotoURL,
                    displayName: user.displayName,
                    size: 120
                )
                .padding(.top, AppTheme.largeSpacing)
                
                // User info
                VStack(spacing: AppTheme.smallSpacing) {
                    Text(user.displayName)
                        .font(AppTheme.titleFont)
                        .foregroundColor(AppTheme.primaryTextColor)
                    
                    Text(user.email)
                        .font(AppTheme.bodyFont)
                        .foregroundColor(AppTheme.secondaryTextColor)
                    
                    Text(user.memberSinceFormatted)
                        .font(AppTheme.captionFont)
                        .foregroundColor(AppTheme.secondaryTextColor)
                }
                
                // Edit button
                PrimaryButton(
                    title: "Edit Profile",
                    isLoading: false
                ) {
                    showEditProfile = true
                }
                .padding(.horizontal, AppTheme.largeSpacing)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles user logout
    private func handleLogout() {
        do {
            try authService.signOut()
        } catch {
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService())
}

