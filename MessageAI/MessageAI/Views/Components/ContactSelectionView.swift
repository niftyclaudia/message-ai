//
//  ContactSelectionView.swift
//  MessageAI
//
//  Individual contact row with selection checkbox
//

import SwiftUI

/// Individual contact row with selection checkbox
/// - Note: Displays user info and handles selection state
struct ContactSelectionView: View {
    
    // MARK: - Properties
    
    let user: User
    let isSelected: Bool
    let onToggle: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile photo or initials
            profileImageView
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Selection checkbox
            selectionButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
    
    // MARK: - Subviews
    
    private var profileImageView: some View {
        Group {
            if let photoURL = user.profilePhotoURL, !photoURL.isEmpty {
                AsyncImage(url: URL(string: photoURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
    
    private var initialsView: some View {
        Text(user.initials)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Color.blue)
            .clipShape(Circle())
    }
    
    private var selectionButton: some View {
        Button(action: onToggle) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundColor(isSelected ? .blue : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        ContactSelectionView(
            user: User(
                id: "1",
                displayName: "John Doe",
                email: "john@example.com",
                profilePhotoURL: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            isSelected: false,
            onToggle: {}
        )
        
        ContactSelectionView(
            user: User(
                id: "2",
                displayName: "Jane Smith",
                email: "jane@example.com",
                profilePhotoURL: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            isSelected: true,
            onToggle: {}
        )
    }
}
