//
//  ReconnectingIndicator.swift
//  MessageAI
//
//  Brief reconnecting indicator shown during foreground sync
//  PR #4: Mobile Lifecycle Management
//

import SwiftUI

/// Brief indicator shown during app foreground reconnection
/// - Note: Auto-hides after reconnection completes (< 500ms target)
struct ReconnectingIndicator: View {
    
    // MARK: - Properties
    
    /// Whether reconnection is in progress
    let isReconnecting: Bool
    
    /// Last reconnect duration for display
    let reconnectDuration: TimeInterval
    
    // MARK: - Body
    
    var body: some View {
        if isReconnecting {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("Syncing...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .transition(.opacity.combined(with: .scale))
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        ReconnectingIndicator(
            isReconnecting: true,
            reconnectDuration: 250
        )
        
        ReconnectingIndicator(
            isReconnecting: false,
            reconnectDuration: 0
        )
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

