//
//  MemberStatusRow.swift
//  MessageAI
//
//  PR-3: Member status row for group chat member list
//  Displays user avatar, name, and live presence indicator
//

import SwiftUI

/// Single row in member list showing user profile and presence status
/// - Note: Used in GroupMemberListView for displaying group members
/// - Performance: Updates presence in real-time (target < 500ms)
struct MemberStatusRow: View {
    
    // MARK: - Properties
    
    let user: User
    let presenceStatus: PresenceStatus
    
    // MARK: - Constants
    
    private let avatarSize: CGFloat = 44
    private let presenceIndicatorSize: CGFloat = 12
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            // User avatar with presence indicator overlay
            ZStack(alignment: .bottomTrailing) {
                AvatarView(
                    photoURL: user.profilePhotoURL,
                    displayName: user.displayName,
                    size: avatarSize
                )
                
                // Presence indicator badge
                PresenceIndicator(
                    status: presenceState,
                    size: presenceIndicatorSize,
                    showBorder: true
                )
                .offset(x: 2, y: 2)
            }
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    
    /// Converts PresenceStatus to PresenceState for indicator
    private var presenceState: PresenceState {
        switch presenceStatus.status {
        case .online:
            return .online
        case .offline:
            return .offline
        }
    }
    
    /// Status text showing online or last seen time
    private var statusText: String {
        switch presenceStatus.status {
        case .online:
            return "Online"
        case .offline:
            return "Offline"
        }
    }
}

// MARK: - Preview

#Preview("Online User") {
    MemberStatusRow(
        user: User(
            id: "1",
            displayName: "Alice Smith",
            email: "alice@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        ),
        presenceStatus: PresenceStatus(
            status: .online,
            lastSeen: Date()
        )
    )
    .padding()
}

#Preview("Offline User") {
    MemberStatusRow(
        user: User(
            id: "2",
            displayName: "Bob Johnson",
            email: "bob@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        ),
        presenceStatus: PresenceStatus(
            status: .offline,
            lastSeen: Date().addingTimeInterval(-3600)
        )
    )
    .padding()
}

#Preview("Multiple Members") {
    VStack {
        MemberStatusRow(
            user: User(
                id: "1",
                displayName: "Alice Smith",
                email: "alice@example.com",
                profilePhotoURL: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            presenceStatus: PresenceStatus(status: .online, lastSeen: Date())
        )
        
        Divider()
        
        MemberStatusRow(
            user: User(
                id: "2",
                displayName: "Bob Johnson",
                email: "bob@example.com",
                profilePhotoURL: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            presenceStatus: PresenceStatus(status: .offline, lastSeen: Date())
        )
        
        Divider()
        
        MemberStatusRow(
            user: User(
                id: "3",
                displayName: "Charlie Davis",
                email: "charlie@example.com",
                profilePhotoURL: nil,
                createdAt: Date(),
                lastActiveAt: Date()
            ),
            presenceStatus: PresenceStatus(status: .online, lastSeen: Date())
        )
    }
    .padding()
}

