//
//  ChatInfoView.swift
//  MessageAI
//
//  View displaying chat information and details
//

import SwiftUI

/// Chat information view showing details about the conversation
struct ChatInfoView: View {
    
    // MARK: - Properties
    
    let chat: Chat
    let otherUser: User?
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.largeSpacing) {
                    
                    if chat.isGroupChat {
                        groupChatInfo
                    } else {
                        oneOnOneChatInfo
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.largeSpacing)
            }
            .navigationTitle(chat.isGroupChat ? "Group Info" : "Contact Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - One-on-One Chat Info
    
    private var oneOnOneChatInfo: some View {
        VStack(spacing: AppTheme.mediumSpacing) {
            // Avatar
            if let otherUser = otherUser {
                AvatarView(
                    photoURL: otherUser.profilePhotoURL,
                    displayName: otherUser.displayName,
                    size: 100
                )
                
                Text(otherUser.displayName)
                    .font(AppTheme.titleFont)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Text(otherUser.email)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.secondaryTextColor)
                
                Text("Last active: \(formatDate(otherUser.lastActiveAt))")
                    .font(AppTheme.captionFont)
                    .foregroundColor(AppTheme.secondaryTextColor)
            } else {
                Text("User information not available")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Group Chat Info
    
    private var groupChatInfo: some View {
        VStack(alignment: .leading, spacing: AppTheme.mediumSpacing) {
            // Group icon
            HStack {
                Spacer()
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.primaryColor)
                    .padding(AppTheme.largeSpacing)
                    .background(
                        Circle()
                            .fill(AppTheme.primaryColor.opacity(0.1))
                    )
                Spacer()
            }
            
            // Group name
            if let groupName = chat.groupName {
                Text(groupName)
                    .font(AppTheme.titleFont)
                    .foregroundColor(AppTheme.primaryTextColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // Members count
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("Members")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Text("\(chat.members.count) members")
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
            .padding(.top, AppTheme.mediumSpacing)
            
            Divider()
            
            // Created info
            VStack(alignment: .leading, spacing: AppTheme.smallSpacing) {
                Text("Created")
                    .font(AppTheme.headlineFont)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Text(formatDate(chat.createdAt))
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ChatInfoView(
        chat: Chat(
            id: "test",
            members: ["user1", "user2"],
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: "user1",
            isGroupChat: false,
            createdAt: Date(),
            createdBy: "user1"
        ),
        otherUser: User(
            id: "user2",
            displayName: "John Doe",
            email: "john@example.com",
            profilePhotoURL: nil,
            createdAt: Date(),
            lastActiveAt: Date()
        )
    )
}

