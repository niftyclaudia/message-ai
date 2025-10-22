//
//  RetryButtonView.swift
//  MessageAI
//
//  Retry button component for failed messages
//

import SwiftUI

/// View that displays a retry button for failed messages
/// - Note: Shows retry button with loading state and retry count
struct RetryButtonView: View {
    
    // MARK: - Properties
    
    let isRetrying: Bool
    let retryCount: Int
    let maxRetries: Int
    let onRetry: () -> Void
    let onDelete: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 8) {
            if isRetrying {
                ProgressView()
                    .scaleEffect(0.8)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("Retrying...")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
            } else {
                Button(action: onRetry) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                        
                        Text("Retry")
                            .font(.system(size: 12, weight: .medium))
                    }
                }
                .foregroundColor(.blue)
                .disabled(retryCount >= maxRetries)
                
                if retryCount > 0 {
                    Text("(\(retryCount)/\(maxRetries))")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        RetryButtonView(
            isRetrying: false,
            retryCount: 0,
            maxRetries: 3,
            onRetry: {},
            onDelete: {}
        )
        
        RetryButtonView(
            isRetrying: false,
            retryCount: 1,
            maxRetries: 3,
            onRetry: {},
            onDelete: {}
        )
        
        RetryButtonView(
            isRetrying: true,
            retryCount: 1,
            maxRetries: 3,
            onRetry: {},
            onDelete: {}
        )
        
        RetryButtonView(
            isRetrying: false,
            retryCount: 3,
            maxRetries: 3,
            onRetry: {},
            onDelete: {}
        )
    }
    .padding()
}