//
//  MessageAttributionView.swift
//  MessageAI
//
//  PR-3: Message attribution for group chats
//  Displays sender avatar and name for each message
//

import SwiftUI

/// Message attribution view showing sender avatar and name for group chats
/// - Note: Only displayed for group chat messages (3+ members)
/// - Performance: Loads user profiles from cache or Firestore (target < 200ms)
struct MessageAttributionView: View {
    
    // MARK: - Properties
    
    let message: Message
    let isGroupChat: Bool
    @State private var senderUser: User?
    @State private var isLoading = true
    
    private let userService = UserService()
    
    // MARK: - Constants
    
    private let avatarSize: CGFloat = 32
    
    // MARK: - Body
    
    var body: some View {
        if isGroupChat {
            HStack(alignment: .top, spacing: 8) {
                // Sender avatar
                AvatarView(
                    photoURL: senderUser?.profilePhotoURL,
                    displayName: displayName,
                    size: avatarSize
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    // Sender name above message
                    Text(displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Message content (provided by parent)
                    // Parent will insert message bubble here
                }
            }
            .task {
                await loadSenderProfile()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Display name with fallback for loading or missing data
    private var displayName: String {
        if let user = senderUser {
            return user.displayName
        } else if let cachedName = message.senderName {
            return cachedName
        } else if isLoading {
            return "Loading..."
        } else {
            // Fallback to first 8 chars of sender ID
            let prefix = String(message.senderID.prefix(8))
            return "User \(prefix)"
        }
    }
    
    // MARK: - Private Methods
    
    /// Loads sender profile with caching for performance
    /// - Note: Uses UserService cache to minimize Firebase reads
    /// - Performance: Target < 50ms from cache, < 200ms from network
    private func loadSenderProfile() async {
        do {
            // Fetch user profile (will use cache if available)
            let user = try await userService.fetchUserProfile(userID: message.senderID)
            
            await MainActor.run {
                senderUser = user
                isLoading = false
            }
        } catch {
            // Silently fail - sender profile loading is not critical
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

#Preview("Group Chat Message") {
    MessageAttributionView(
        message: Message(
            id: "1",
            chatID: "chat1",
            senderID: "user123",
            text: "Hello group!",
            timestamp: Date(),
            senderName: "Alice Smith"
        ),
        isGroupChat: true
    )
    .padding()
}

#Preview("One-on-One Chat (Not Shown)") {
    MessageAttributionView(
        message: Message(
            id: "1",
            chatID: "chat1",
            senderID: "user123",
            text: "Hello!",
            timestamp: Date()
        ),
        isGroupChat: false
    )
    .padding()
}

