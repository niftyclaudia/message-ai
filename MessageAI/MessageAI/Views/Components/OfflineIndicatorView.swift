//
//  OfflineIndicatorView.swift
//  MessageAI
//
//  Offline status indicator component
//

import SwiftUI

/// Offline indicator view showing connection status
/// - Note: Displays when offline with queued message count
struct OfflineIndicatorView: View {
    
    // MARK: - Properties
    
    let isOffline: Bool
    let queuedMessageCount: Int
    let onRetry: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        if isOffline {
            HStack(spacing: 8) {
                // Offline icon
                Image(systemName: "wifi.slash")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                // Offline text
                Text("Offline")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                // Queued message count
                if queuedMessageCount > 0 {
                    Text("(\(queuedMessageCount) queued)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Retry button
                Button("Retry") {
                    onRetry()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.orange.opacity(0.1))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.orange.opacity(0.3)),
                alignment: .top
            )
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        OfflineIndicatorView(
            isOffline: true,
            queuedMessageCount: 3,
            onRetry: {}
        )
        
        OfflineIndicatorView(
            isOffline: false,
            queuedMessageCount: 0,
            onRetry: {}
        )
    }
}
