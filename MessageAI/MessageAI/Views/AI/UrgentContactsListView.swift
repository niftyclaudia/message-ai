//
//  UrgentContactsListView.swift
//  MessageAI
//
//  Urgent contacts list section
//

import SwiftUI

/// List of urgent contacts with add/remove actions
struct UrgentContactsListView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: PreferencesViewModel
    @Binding var showContactSelection: Bool
    
    // MARK: - Body
    
    var body: some View {
        Section {
            // Contact list
            if let contacts = viewModel.preferences?.urgentContacts, !contacts.isEmpty {
                ForEach(contacts, id: \.self) { contactID in
                    contactRow(contactID: contactID)
                }
                .onDelete(perform: deleteContacts)
            } else {
                emptyState
            }
            
            // Add contact button
            if canAddMoreContacts {
                addContactButton
            }
        } header: {
            HStack {
                Text("Urgent Contacts")
                InfoTooltipView(message: "Messages from these contacts will always be prioritized as urgent (max 20)")
            }
        } footer: {
            Text("\(contactCount)/20 contacts")
                .font(AppTheme.captionFont)
                .foregroundColor(AppTheme.secondaryTextColor)
        }
    }
    
    // MARK: - Private Views
    
    /// Contact row
    private func contactRow(contactID: String) -> some View {
        HStack {
            // Avatar placeholder
            Circle()
                .fill(AppTheme.secondaryColor.opacity(0.3))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(contactID.prefix(2).uppercased())
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryTextColor)
                )
            
            Text(contactID)
                .font(AppTheme.bodyFont)
            
            Spacer()
        }
    }
    
    /// Empty state
    private var emptyState: some View {
        HStack {
            Image(systemName: "person.crop.circle.badge.plus")
                .foregroundColor(AppTheme.secondaryColor)
            
            Text("No urgent contacts yet")
                .font(AppTheme.bodyFont)
                .foregroundColor(AppTheme.secondaryTextColor)
        }
        .padding(.vertical, 8)
    }
    
    /// Add contact button
    private var addContactButton: some View {
        Button {
            showContactSelection = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Contact")
            }
            .foregroundColor(AppTheme.primaryColor)
        }
    }
    
    // MARK: - Computed Properties
    
    private var contactCount: Int {
        viewModel.preferences?.urgentContacts.count ?? 0
    }
    
    private var canAddMoreContacts: Bool {
        contactCount < 20
    }
    
    // MARK: - Private Methods
    
    /// Delete contacts at offsets
    private func deleteContacts(at offsets: IndexSet) {
        guard let contacts = viewModel.preferences?.urgentContacts else { return }
        
        for index in offsets {
            let contactID = contacts[index]
            Task {
                await viewModel.removeUrgentContact(contactID)
            }
        }
    }
}

