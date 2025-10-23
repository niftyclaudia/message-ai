//
//  SkeletonView.swift
//  MessageAI
//
//  Skeleton loading view for smooth loading states
//

import SwiftUI

/// Skeleton view for loading states
/// - Note: Provides smooth loading animations for better UX
struct SkeletonView: View {
    
    // MARK: - Properties
    
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    let animation: Animation
    @State private var isAnimating: Bool = false
    
    // MARK: - Initialization
    
    init(
        width: CGFloat? = nil,
        height: CGFloat = 20,
        cornerRadius: CGFloat = 4,
        animation: Animation = .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    ) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.animation = animation
    }
    
    // MARK: - Body
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .opacity(isAnimating ? 0.3 : 0.7)
            .onAppear {
                withAnimation(animation) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton View Variants

/// Skeleton view for message rows
struct MessageSkeletonView: View {
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar skeleton
            SkeletonView(width: 40, height: 40, cornerRadius: 20)
            
            VStack(alignment: .leading, spacing: 8) {
                // Message bubble skeleton
                SkeletonView(width: 200, height: 60, cornerRadius: 16)
                
                // Timestamp skeleton
                SkeletonView(width: 80, height: 12, cornerRadius: 6)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

/// Skeleton view for chat list rows
struct ChatRowSkeletonView: View {
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar skeleton
            SkeletonView(width: 50, height: 50, cornerRadius: 25)
            
            VStack(alignment: .leading, spacing: 8) {
                // Chat title skeleton
                SkeletonView(width: 150, height: 16, cornerRadius: 8)
                
                // Last message skeleton
                SkeletonView(width: 200, height: 14, cornerRadius: 7)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                // Timestamp skeleton
                SkeletonView(width: 40, height: 12, cornerRadius: 6)
                
                // Unread count skeleton
                SkeletonView(width: 20, height: 20, cornerRadius: 10)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Skeleton view for message input
struct MessageInputSkeletonView: View {
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input skeleton
            SkeletonView(width: nil, height: 40, cornerRadius: 20)
                .frame(maxWidth: .infinity)
            
            // Send button skeleton
            SkeletonView(width: 40, height: 40, cornerRadius: 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

/// Skeleton view for group chat header
struct GroupChatHeaderSkeletonView: View {
    
    var body: some View {
        HStack(spacing: 12) {
            // Group avatar skeleton
            SkeletonView(width: 40, height: 40, cornerRadius: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                // Group name skeleton
                SkeletonView(width: 120, height: 16, cornerRadius: 8)
                
                // Member count skeleton
                SkeletonView(width: 80, height: 12, cornerRadius: 6)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Skeleton List Views

/// Skeleton view for message list
struct MessageListSkeletonView: View {
    
    let count: Int
    
    init(count: Int = 5) {
        self.count = count
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(0..<count, id: \.self) { _ in
                    MessageSkeletonView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

/// Skeleton view for chat list
struct ChatListSkeletonView: View {
    
    let count: Int
    
    init(count: Int = 8) {
        self.count = count
    }
    
    var body: some View {
        List {
            ForEach(0..<count, id: \.self) { _ in
                ChatRowSkeletonView()
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Preview

#Preview("Message Skeleton") {
    MessageSkeletonView()
}

#Preview("Chat List Skeleton") {
    ChatRowSkeletonView()
}

#Preview("Message List Skeleton") {
    MessageListSkeletonView()
}

#Preview("Message Input Skeleton") {
    MessageInputSkeletonView()
}
