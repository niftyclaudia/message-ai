//
//  LoadingView.swift
//  MessageAI
//
//  Reusable loading indicator view
//

import SwiftUI

/// Loading indicator with optional message
/// - Note: Can be used as full-screen overlay or inline
struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: AppTheme.mediumSpacing) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryColor))
                .scaleEffect(1.5)
            
            if let message = message {
                Text(message)
                    .font(AppTheme.bodyFont)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.backgroundColor)
    }
}

#Preview {
    LoadingView(message: "Loading...")
}

