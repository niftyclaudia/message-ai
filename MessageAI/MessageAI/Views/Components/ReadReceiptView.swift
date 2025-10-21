//
//  ReadReceiptView.swift
//  MessageAI
//
//  Read receipt component for group chat messages
//

import SwiftUI

/// Read receipt component showing who has read a message in group chats
/// - Note: Displays read status for group members with avatar/name indicators
struct ReadReceiptView: View {
    
    // MARK: - Properties
    
    let message: Message
    let chatMembers: [String]
    let currentUserID: String
    
    // MARK: - Computed Properties
    
    private var readCount: Int {
        message.readBy.count
    }
    
    private var totalMembers: Int {
        chatMembers.count
    }
    
    private var unreadMembers: [String] {
        chatMembers.filter { !message.readBy.contains($0) }
    }
    
    private var readMembers: [String] {
        message.readBy.filter { $0 != currentUserID }
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            if readCount == totalMembers {
                // All members have read
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("Read by all")
                    .font(.caption2)
                    .foregroundColor(.blue)
            } else if readCount > 1 {
                // Some members have read
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("Read by \(readCount) of \(totalMembers)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                // Only sender has read (or no one)
                Image(systemName: "checkmark")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("Sent")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Detailed read receipt view showing individual member read status
struct DetailedReadReceiptView: View {
    
    // MARK: - Properties
    
    let message: Message
    let chatMembers: [String]
    let currentUserID: String
    @State private var isExpanded: Bool = false
    
    // MARK: - Computed Properties
    
    private var readMembers: [String] {
        message.readBy.filter { $0 != currentUserID }
    }
    
    private var unreadMembers: [String] {
        chatMembers.filter { !message.readBy.contains($0) && $0 != currentUserID }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Summary view
            HStack(spacing: 4) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(message.readBy.count) of \(chatMembers.count) read")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
            
            // Expanded view
            if isExpanded {
                VStack(alignment: .trailing, spacing: 2) {
                    if !readMembers.isEmpty {
                        Text("Read by:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        ForEach(readMembers, id: \.self) { memberID in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                                
                                Text(getMemberDisplayName(memberID))
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    
                    if !unreadMembers.isEmpty {
                        Text("Not read by:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        ForEach(unreadMembers, id: \.self) { memberID in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 6, height: 6)
                                
                                Text(getMemberDisplayName(memberID))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMemberDisplayName(_ memberID: String) -> String {
        // In a real app, you'd fetch this from a user service
        // For now, return a simplified display name
        if memberID == currentUserID {
            return "You"
        } else {
            return "User \(memberID.prefix(4))"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // All members read
        ReadReceiptView(
            message: Message(
                id: "1",
                chatID: "chat1",
                senderID: "user1",
                text: "Hello everyone!",
                timestamp: Date(),
                readBy: ["user1", "user2", "user3", "user4"]
            ),
            chatMembers: ["user1", "user2", "user3", "user4"],
            currentUserID: "user1"
        )
        
        // Some members read
        ReadReceiptView(
            message: Message(
                id: "2",
                chatID: "chat1",
                senderID: "user1",
                text: "How are you all?",
                timestamp: Date(),
                readBy: ["user1", "user2"]
            ),
            chatMembers: ["user1", "user2", "user3", "user4"],
            currentUserID: "user1"
        )
        
        // Only sender read
        ReadReceiptView(
            message: Message(
                id: "3",
                chatID: "chat1",
                senderID: "user1",
                text: "Just sent this",
                timestamp: Date(),
                readBy: ["user1"]
            ),
            chatMembers: ["user1", "user2", "user3", "user4"],
            currentUserID: "user1"
        )
        
        // Detailed view
        DetailedReadReceiptView(
            message: Message(
                id: "4",
                chatID: "chat1",
                senderID: "user1",
                text: "Detailed read receipt",
                timestamp: Date(),
                readBy: ["user1", "user2", "user3"]
            ),
            chatMembers: ["user1", "user2", "user3", "user4"],
            currentUserID: "user1"
        )
    }
    .padding()
}
