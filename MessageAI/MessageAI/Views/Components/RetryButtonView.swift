//
//  RetryButtonView.swift
//  MessageAI
//
//  Retry button component for failed messages
//

import SwiftUI

/// Retry button view for failed messages
/// - Note: Provides retry functionality with loading states
struct RetryButtonView: View {
    
    // MARK: - Properties
    
    let isRetrying: Bool
    let onRetry: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onRetry) {
            HStack(spacing: 4) {
                if isRetrying {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                
                Text(isRetrying ? "Retrying..." : "Retry")
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isRetrying)
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        RetryButtonView(
            isRetrying: false,
            onRetry: {}
        )
        
        RetryButtonView(
            isRetrying: true,
            onRetry: {}
        )
    }
    .padding()
}
