//
//  ContactSelectionSheetView.swift
//  MessageAI
//
//  Modal sheet for selecting contacts to add as urgent
//

import SwiftUI

/// Sheet for selecting contacts from user's chat participants
struct ContactSelectionSheetView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PreferencesViewModel
    
    // MARK: - State
    
    @State private var searchText = ""
    @State private var availableContacts: [String] = []
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack {
                if availableContacts.isEmpty {
                    emptyState
                } else {
                    contactList
                }
            }
            .navigationTitle("Add Urgent Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .task {
                loadAvailableContacts()
            }
        }
    }
    
    // MARK: - Private Views
    
    /// Contact list
    private var contactList: some View {
        List {
            ForEach(filteredContacts, id: \.self) { contactID in
                contactRow(contactID)
            }
        }
    }
    
    /// Contact row
    private func contactRow(_ contactID: String) -> some View {
        Button {
            addContact(contactID)
        } label: {
            HStack {
                // Avatar placeholder
                Circle()
                    .fill(AppTheme.secondaryColor.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(contactID.prefix(2).uppercased())
                            .font(.caption)
                            .foregroundColor(AppTheme.primaryTextColor)
                    )
                
                Text(contactID)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Spacer()
                
                if isAlreadyAdded(contactID) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.successColor)
                }
            }
        }
        .disabled(isAlreadyAdded(contactID))
    }
    
    /// Empty state
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.secondaryColor)
            
            Text("No contacts available")
                .font(AppTheme.titleFont)
                .foregroundColor(AppTheme.primaryTextColor)
            
            Text("Start a chat to add contacts")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.secondaryTextColor)
        }
        .padding()
    }
    
    // MARK: - Computed Properties
    
    /// Filtered contacts based on search
    private var filteredContacts: [String] {
        if searchText.isEmpty {
            return availableContacts
        } else {
            return availableContacts.filter {
                $0.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load available contacts (placeholder - would fetch from ChatService)
    private func loadAvailableContacts() {
        // TODO: Fetch from ChatService when integrated
        // For now, use placeholder data
        availableContacts = [
            "user1@example.com",
            "user2@example.com",
            "user3@example.com"
        ]
    }
    
    /// Check if contact is already added
    private func isAlreadyAdded(_ contactID: String) -> Bool {
        viewModel.preferences?.urgentContacts.contains(contactID) ?? false
    }
    
    /// Add contact and dismiss
    private func addContact(_ contactID: String) {
        Task {
            await viewModel.addUrgentContact(contactID)
            dismiss()
        }
    }
}

