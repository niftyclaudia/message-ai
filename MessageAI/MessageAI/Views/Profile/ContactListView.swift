//
//  ContactListView.swift
//  MessageAI
//
//  View for discovering and searching users
//

import SwiftUI

/// Contact discovery view with search functionality
struct ContactListView: View {
    
    // MARK: - State Objects
    
    @StateObject private var viewModel = ContactListViewModel()
    
    // MARK: - State
    
    @State private var searchText: String = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.allUsers.isEmpty {
                    LoadingView(message: "Loading users...")
                } else if viewModel.filteredUsers.isEmpty && !searchText.isEmpty {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.xmark",
                        message: "No users found"
                    )
                } else if viewModel.filteredUsers.isEmpty {
                    EmptyStateView(
                        icon: "person.2",
                        message: "No users yet"
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
                            .padding(.leading, 72) // Indent to align with text
                    }
                }
            }
            .padding(.top, AppTheme.smallSpacing)
        }
    }
}

#Preview {
    ContactListView()
}

