//
//  OfflineIndicatorView.swift
//  MessageAI
//
//  Offline status indicator component
//

import SwiftUI

/// View that displays offline status and connection information
/// - Note: Shows when device is offline with queued message count
struct OfflineIndicatorView: View {
    
    // MARK: - Properties
    
    let connectionState: ConnectionState
    let queuedMessageCount: Int
    let onRetry: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ConnectionStatusView(
            connectionState: connectionState,
            queuedMessageCount: queuedMessageCount,
            onRetry: onRetry
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        OfflineIndicatorView(
            connectionState: .offline,
            queuedMessageCount: 3,
            onRetry: {}
        )
        
        OfflineIndicatorView(
            connectionState: .online,
            queuedMessageCount: 0,
            onRetry: {}
        )
        
        OfflineIndicatorView(
            connectionState: .connecting,
            queuedMessageCount: 2,
            onRetry: {}
        )
        
        OfflineIndicatorView(
            connectionState: .syncing(3),
            queuedMessageCount: 3,
            onRetry: {}
        )
    }
    .padding()
}