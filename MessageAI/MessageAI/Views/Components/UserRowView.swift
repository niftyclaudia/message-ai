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
    let presenceStatus: PresenceState?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: AppTheme.mediumSpacing) {
            // Avatar with presence indicator
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    photoURL: user.profilePhotoURL,
                    displayName: user.displayName,
                    size: 50
                )
                
                // Presence indicator
                if let presenceStatus = presenceStatus {
                    PresenceIndicator(status: presenceStatus, size: 12)
                        .offset(x: 2, y: 2)
                }
            }
            
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

#Preview("User Online") {
    UserRowView(
        user: User(
            id: "1",
            displayName: "John Doe",
            email: "john@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        ),
        presenceStatus: .online
    )
    .padding()
}

#Preview("User Offline") {
    UserRowView(
        user: User(
            id: "2",
            displayName: "Jane Smith",
            email: "jane@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        ),
        presenceStatus: .offline
    )
    .padding()
}

#Preview("User No Presence") {
    UserRowView(
        user: User(
            id: "3",
            displayName: "Unknown User",
            email: "unknown@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        ),
        presenceStatus: nil
    )
    .padding()
}

