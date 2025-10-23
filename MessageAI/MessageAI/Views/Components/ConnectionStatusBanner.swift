//
//  ConnectionStatusBanner.swift
//  MessageAI
//
//  Unified connection status banner following Apple HIG
//

import SwiftUI

/// Minimal, unified status banner that only appears when needed
/// - Note: Follows Apple HIG - hidden when everything is normal (online)
struct ConnectionStatusBanner: View {
    
    // MARK: - Properties
    
    let connectionState: ConnectionState
    let queuedMessageCount: Int
    let onRetry: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        // Only show banner when NOT online (Apple HIG best practice)
        if connectionState != .online {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.system(size: 15, weight: .medium))
                    .rotationEffect(connectionState.isSyncing ? .degrees(360) : .degrees(0))
                    .animation(
                        connectionState.isSyncing ?
                        .linear(duration: 1.0).repeatForever(autoreverses: false) :
                        .default,
                        value: connectionState.isSyncing
                    )
                
                // Status text
                VStack(alignment: .leading, spacing: 2) {
                    Text(primaryText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let secondaryText = secondaryText {
                        Text(secondaryText)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action button (only for offline state)
                if connectionState == .offline && queuedMessageCount > 0 {
                    Button("Retry", action: onRetry)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                // Progress indicator (only for syncing)
                if connectionState.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: connectionState)
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch connectionState {
        case .offline:
            return "wifi.slash"
        case .connecting:
            return "wifi.exclamationmark"
        case .syncing:
            return "arrow.clockwise"
        case .online:
            return "checkmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch connectionState {
        case .offline:
            return .red
        case .connecting:
            return .orange
        case .syncing:
            return .blue
        case .online:
            return .green
        }
    }
    
    private var primaryText: String {
        switch connectionState {
        case .offline:
            return queuedMessageCount > 0 ? "Offline" : "No connection"
        case .connecting:
            return "Connecting..."
        case .syncing(let count):
            return "Sending \(count) message\(count == 1 ? "" : "s")"
        case .online:
            return "Connected"
        }
    }
    
    private var secondaryText: String? {
        switch connectionState {
        case .offline where queuedMessageCount > 0:
            return "\(queuedMessageCount) message\(queuedMessageCount == 1 ? "" : "s") queued"
        case .offline:
            return "Messages will send when reconnected"
        case .connecting where queuedMessageCount > 0:
            return "\(queuedMessageCount) pending"
        default:
            return nil
        }
    }
    
    private var backgroundColor: Color {
        switch connectionState {
        case .offline:
            return Color(.systemRed).opacity(0.12)
        case .connecting:
            return Color(.systemOrange).opacity(0.12)
        case .syncing:
            return Color(.systemBlue).opacity(0.12)
        case .online:
            return Color(.systemGreen).opacity(0.12)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        // Online - should be hidden
        ConnectionStatusBanner(
            connectionState: .online,
            queuedMessageCount: 0,
            onRetry: {}
        )
        
        Divider()
        
        // Offline with queued messages
        ConnectionStatusBanner(
            connectionState: .offline,
            queuedMessageCount: 3,
            onRetry: {}
        )
        
        Divider()
        
        // Connecting
        ConnectionStatusBanner(
            connectionState: .connecting,
            queuedMessageCount: 2,
            onRetry: {}
        )
        
        Divider()
        
        // Syncing
        ConnectionStatusBanner(
            connectionState: .syncing(2),
            queuedMessageCount: 2,
            onRetry: {}
        )
        
        Spacer()
    }
}

