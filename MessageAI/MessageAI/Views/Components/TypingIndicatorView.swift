//
//  TypingIndicatorView.swift
//  MessageAI
//
//  Visual typing indicator showing users currently typing (iPhone-style)
//

import SwiftUI

/// Displays typing indicator for chat
/// - Note: iPhone-style animated dots in a bubble, with optional user names above
struct TypingIndicatorView: View {
    
    // MARK: - Properties
    
    let typingUsers: [TypingUser]
    
    // MARK: - Animation State
    
    @State private var dot1Offset: CGFloat = 0
    @State private var dot2Offset: CGFloat = 0
    @State private var dot3Offset: CGFloat = 0
    
    // MARK: - Body
    
    var body: some View {
        if !typingUsers.isEmpty {
            HStack(alignment: .bottom, spacing: 8) {
                // Typing bubble (iPhone-style)
                VStack(alignment: .leading, spacing: 4) {
                    // Optional: Show who's typing above the bubble
                    if !typingUsers.isEmpty {
                        Text(typingText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    // Animated dots bubble
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(Color(.darkGray))
                                .frame(width: 8, height: 8)
                                .offset(y: offsetForDot(index))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.systemGray5))
                    )
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                startAnimation()
            }
        }
    }
    
    // MARK: - Animation
    
    private func startAnimation() {
        // Staggered bounce animation for each dot
        withAnimation(
            Animation.easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
        ) {
            dot1Offset = -4
        }
        
        withAnimation(
            Animation.easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
                .delay(0.2)
        ) {
            dot2Offset = -4
        }
        
        withAnimation(
            Animation.easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true)
                .delay(0.4)
        ) {
            dot3Offset = -4
        }
    }
    
    private func offsetForDot(_ index: Int) -> CGFloat {
        switch index {
        case 0: return dot1Offset
        case 1: return dot2Offset
        case 2: return dot3Offset
        default: return 0
        }
    }
    
    // MARK: - Private Computed Properties
    
    /// Formats typing text based on number of users
    private var typingText: String {
        switch typingUsers.count {
        case 0:
            return ""
        case 1:
            return typingUsers[0].userName
        case 2:
            return "\(typingUsers[0].userName) and \(typingUsers[1].userName)"
        default:
            return "\(typingUsers[0].userName) and \(typingUsers.count - 1) others"
        }
    }
}

// MARK: - Preview

#Preview("Single User") {
    TypingIndicatorView(typingUsers: [
        TypingUser(userID: "1", userName: "Alice")
    ])
    .previewLayout(.sizeThatFits)
}

#Preview("Two Users") {
    TypingIndicatorView(typingUsers: [
        TypingUser(userID: "1", userName: "Alice"),
        TypingUser(userID: "2", userName: "Bob")
    ])
    .previewLayout(.sizeThatFits)
}

#Preview("Three Users") {
    TypingIndicatorView(typingUsers: [
        TypingUser(userID: "1", userName: "Alice"),
        TypingUser(userID: "2", userName: "Bob"),
        TypingUser(userID: "3", userName: "Charlie")
    ])
    .previewLayout(.sizeThatFits)
}

#Preview("Many Users") {
    TypingIndicatorView(typingUsers: [
        TypingUser(userID: "1", userName: "Alice"),
        TypingUser(userID: "2", userName: "Bob"),
        TypingUser(userID: "3", userName: "Charlie"),
        TypingUser(userID: "4", userName: "David"),
        TypingUser(userID: "5", userName: "Eve")
    ])
    .previewLayout(.sizeThatFits)
}

