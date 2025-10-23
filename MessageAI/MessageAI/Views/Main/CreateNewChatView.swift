//
//  CreateNewChatView.swift
//  MessageAI
//
//  Main chat creation interface with contact list
//

import SwiftUI

/// Main chat creation interface with contact list
/// - Note: Handles contact selection, search, and chat creation flow
struct CreateNewChatView: View {
    
    // MARK: - Properties
    
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var createdChat: Chat?
    @State private var navigateToChat = false
    @StateObject private var viewModel: CreateChatViewModel
    
    // Callback to handle chat creation completion
    let onChatCreated: ((Chat) -> Void)?
    
    // MARK: - Initialization
    
    init(onChatCreated: ((Chat) -> Void)? = nil) {
        // Initialize with placeholder - will be updated in onAppear
        _viewModel = StateObject(wrappedValue: CreateChatViewModel(authService: AuthService()))
        self.onChatCreated = onChatCreated
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Contact list
                contactList
                
                // Create button
                createButton
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                // Update the view model with the correct AuthService from environment
                viewModel.updateAuthService(authService)
                
                Task {
                    await viewModel.loadContacts()
                }
            }
            .onChange(of: viewModel.searchQuery) { _, _ in
                Task {
                    await viewModel.searchContacts()
                }
            }
            .onChange(of: viewModel.isChatCreated) { _, isCreated in
                if isCreated {
                    Task {
                        await fetchCreatedChat()
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Fetches the created chat and navigates to it
    private func fetchCreatedChat() async {
        guard let chat = await viewModel.fetchCreatedChat() else {
            return
        }
        
        await MainActor.run {
            self.createdChat = chat
            
            // Use callback if provided, otherwise try navigation
            if let onChatCreated = self.onChatCreated {
                onChatCreated(chat)
                dismiss()
            } else {
                self.navigateToChat = true
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search contacts...", text: $viewModel.searchQuery)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
    
    private var contactList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredContacts.isEmpty {
                emptyStateView
            } else {
                contactsListView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading contacts...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No contacts found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Try adjusting your search or check your contact list")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
    
    private var contactsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filteredContacts) { contact in
                    ContactSelectionView(
                        user: contact,
                        isSelected: viewModel.selectedContacts.contains(contact.id),
                        onToggle: {
                            viewModel.toggleContactSelection(userID: contact.id)
                        }
                    )
                    
                    if contact.id != viewModel.filteredContacts.last?.id {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
        }
    }
    
    private var createButton: some View {
        VStack(spacing: 12) {
            // Selection summary
            if !viewModel.selectedContacts.isEmpty {
                selectionSummary
            }
            
            // Create button
            ChatCreationButton(
                isEnabled: viewModel.canCreateChat,
                isLoading: viewModel.isLoading,
                selectedCount: viewModel.selectedCount,
                isGroupChat: viewModel.isGroupChat,
                onTap: {
                    Task {
                        await viewModel.createChat()
                    }
                }
            )
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
    }
    
    private var selectionSummary: some View {
        HStack {
            Text(viewModel.isGroupChat ? "Group Chat" : "Direct Message")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(viewModel.selectedCount) selected")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    CreateNewChatView()
}
