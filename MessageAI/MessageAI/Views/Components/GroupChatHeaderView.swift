//
//  GroupChatHeaderView.swift
//  MessageAI
//
//  PR-3: Enhanced header for group chats
//  Displays group name and member count, tappable to open member list
//

import SwiftUI

/// Enhanced header view for group chats
/// - Note: Displays group name (or member names), member count, and is tappable
/// - Performance: Opens member list in < 400ms on tap
struct GroupChatHeaderView: View {
    
    // MARK: - Properties
    
    let chat: Chat
    let onTap: () -> Void
    
    @State private var memberNames: String = ""
    
    private let userService = UserService()
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text(displayTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(memberCountText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .task {
            await loadMemberNames()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Display title showing group name or member names
    private var displayTitle: String {
        if let groupName = chat.groupName, !groupName.isEmpty {
            return groupName
        } else if !memberNames.isEmpty {
            return memberNames
        } else {
            return "Group Chat"
        }
    }
    
    /// Member count text
    private var memberCountText: String {
        let count = chat.members.count
        return "\(count) member\(count == 1 ? "" : "s")"
    }
    
    // MARK: - Private Methods
    
    /// Loads member names for display if no group name is set
    /// - Note: For unnamed groups, shows comma-separated member names
    /// - Performance: Uses cached user profiles when available
    private func loadMemberNames() async {
        // Skip if group has a name
        guard chat.groupName == nil || chat.groupName?.isEmpty == true else {
            return
        }
        
        do {
            // Fetch member profiles (uses cache)
            let memberProfiles = try await userService.fetchMultipleUserProfiles(userIDs: chat.members)
            
            // Create comma-separated list of names (max 3)
            let names = chat.members.prefix(3).compactMap { memberProfiles[$0]?.displayName }
            let namesList = names.joined(separator: ", ")
            
            await MainActor.run {
                if names.count < chat.members.count {
                    memberNames = "\(namesList), ..."
                } else {
                    memberNames = namesList
                }
            }
        } catch {
            // Silently fail - member names are not critical for header
        }
    }
}

// MARK: - Preview

#Preview("Named Group") {
    GroupChatHeaderView(
        chat: Chat(
            id: "chat1",
            members: ["user1", "user2", "user3"],
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: true,
            groupName: "Team Chat",
            createdAt: Date(),
            createdBy: "user1"
        ),
        onTap: { print("Tapped") }
    )
    .padding()
}

#Preview("Unnamed Group") {
    GroupChatHeaderView(
        chat: Chat(
            id: "chat1",
            members: ["user1", "user2", "user3"],
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: true,
            groupName: nil,
            createdAt: Date(),
            createdBy: "user1"
        ),
        onTap: { print("Tapped") }
    )
    .padding()
}

#Preview("Large Group") {
    GroupChatHeaderView(
        chat: Chat(
            id: "chat1",
            members: Array(repeating: "user", count: 10),
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: true,
            groupName: "Large Team",
            createdAt: Date(),
            createdBy: "user1"
        ),
        onTap: { print("Tapped") }
    )
    .padding()
}

