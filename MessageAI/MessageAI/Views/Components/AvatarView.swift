//
//  AvatarView.swift
//  MessageAI
//
//  Reusable avatar component showing photo or initials
//

import SwiftUI

/// Reusable avatar view that displays profile photo or initials
struct AvatarView: View {
    
    // MARK: - Properties
    
    let photoURL: String?
    let displayName: String
    let size: CGFloat
    
    // MARK: - Private Computed Properties
    
    /// Background color generated from display name hash for consistency
    private var backgroundColor: Color {
        let hash = abs(displayName.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.3, brightness: 0.9)
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let photoURL = photoURL, !photoURL.isEmpty, let url = URL(string: photoURL) {
                // Show profile photo with caching enabled
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        initialsView
                    @unknown default:
                        initialsView
                    }
                }
                // Removed .id(photoURL) to enable proper caching
                // Cache invalidation now handled via timestamp in URL
            } else {
                // Show initials
                initialsView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    // MARK: - Private Views
    
    /// View showing user's initials
    private var initialsView: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
            
            Text(displayName.extractInitials())
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview("With Photo URL") {
    AvatarView(
        photoURL: "https://example.com/photo.jpg",
        displayName: "John Doe",
        size: 120
    )
}

#Preview("With Initials") {
    AvatarView(
        photoURL: nil,
        displayName: "Jane Smith",
        size: 120
    )
}

#Preview("Small Size") {
    AvatarView(
        photoURL: nil,
        displayName: "Alice Wonder",
        size: 40
    )
}

