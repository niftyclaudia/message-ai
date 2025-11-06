//
//  ContactListView.swift
//  MessageAI
//
//  View for discovering and searching users
//

import SwiftUI

/// Contact discovery view with search functionality
struct ContactListView: View {
    
    // MARK: - Environment Objects
    
    @EnvironmentObject private var authService: AuthService
    
    // MARK: - State Objects
    
    @StateObject private var viewModel: ContactListViewModel
    
    // MARK: - State
    
    @State private var searchText: String = ""
    
    // MARK: - Initialization
    
    init() {
        // Create viewModel without authService initially
        // Will inject it via setAuthService in task
        _viewModel = StateObject(wrappedValue: ContactListViewModel())
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.allUsers.isEmpty {
                    LoadingView(message: "Loading contacts...")
                } else if let errorMessage = viewModel.errorMessage {
                    // Error state with retry button
                    // If not authenticated, show specific message to sign in again
                    if errorMessage.contains("authenticated") {
                        authenticationErrorView
                    } else {
                        errorStateView(message: errorMessage)
                    }
                } else if viewModel.filteredUsers.isEmpty && !searchText.isEmpty {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.xmark",
                        message: "No users found"
                    )
                } else if viewModel.filteredUsers.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        message: "No contacts yet"
                    )
                } else {
                    contactList
                }
            }
            .navigationTitle("Contacts")
            .searchable(
                text: $searchText,
                prompt: "Search by name or email"
            )
            .onChange(of: searchText) { oldValue, newValue in
                viewModel.searchQuery = newValue
            }
            .task {
                // Inject the authenticated authService into viewModel
                viewModel.setAuthService(authService)
                await viewModel.loadUsers()
                viewModel.observeUsersRealTime()
                viewModel.observePresence()
            }
            .onDisappear {
                viewModel.stopObserving()
                viewModel.stopObservingPresence()
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Scrollable contact list
    private var contactList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredUsers) { user in
                    UserRowView(
                        user: user,
                        presenceStatus: viewModel.userPresence[user.id]
                    )
                    .padding(.horizontal, AppTheme.mediumSpacing)
                    
                    if user.id != viewModel.filteredUsers.last?.id {
                        Divider()
                            .padding(.leading, 72)
                    }
                }
            }
            .padding(.top, AppTheme.smallSpacing)
        }
    }
    
    /// Error state view with retry button
    private func errorStateView(message: String) -> some View {
        VStack(spacing: AppTheme.mediumSpacing) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Failed to load contacts")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.largeSpacing)
            
            Button {
                Task {
                    await viewModel.retry()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.body)
                    .padding(.horizontal, AppTheme.largeSpacing)
                    .padding(.vertical, AppTheme.smallSpacing)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    /// Authentication error view with sign out option
    private var authenticationErrorView: some View {
        VStack(spacing: AppTheme.mediumSpacing) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Session Expired")
                .font(.headline)
            
            Text("Your session has expired. Please sign out and sign back in.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.largeSpacing)
            
            Button {
                Task {
                    try? await authService.signOut()
                }
            } label: {
                Label("Sign Out", systemImage: "arrow.right.square")
                    .font(.body)
                    .padding(.horizontal, AppTheme.largeSpacing)
                    .padding(.vertical, AppTheme.smallSpacing)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }
}

#Preview {
    ContactListView()
}

