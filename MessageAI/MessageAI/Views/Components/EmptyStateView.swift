//
//  EmptyStateView.swift
//  MessageAI
//
//  Reusable empty state placeholder view
//

import SwiftUI

/// Empty state view with icon and message
/// - Note: Used for placeholder content before features are implemented
struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: AppTheme.mediumSpacing) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.secondaryTextColor)
            
            Text(message)
                .font(AppTheme.headlineFont)
                .foregroundColor(AppTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundColor)
    }
}

#Preview {
    EmptyStateView(icon: "bubble.left.and.bubble.right", message: "Chat list coming soon")
}

