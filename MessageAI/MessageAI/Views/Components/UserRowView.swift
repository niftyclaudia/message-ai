//
//  UserRowView.swift
//  MessageAI
//
//  Reusable user row component for contact lists
//

import SwiftUI

/// Row view displaying user information in contact lists
struct UserRowView: View {
    
    // MARK: - Properties
    
    let user: User
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: AppTheme.mediumSpacing) {
            // Avatar
            AvatarView(
                photoURL: user.profilePhotoURL,
                displayName: user.displayName,
                size: 40
            )
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Text(user.email)
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
            
            Spacer()
        }
        .padding(.vertical, AppTheme.smallSpacing)
    }
}

#Preview {
    UserRowView(
        user: User(
            id: "1",
            displayName: "John Doe",
            email: "john@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        )
    )
    .padding()
}

