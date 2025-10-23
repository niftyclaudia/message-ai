//
//  ConnectionStatusView.swift
//  MessageAI
//
//  Connection status view for offline persistence system
//

import SwiftUI

/// View that displays connection status with animations
/// - Note: Shows connecting, syncing, and offline states with proper feedback
struct ConnectionStatusView: View {
    
    // MARK: - Properties
    
    let connectionState: ConnectionState
    let queuedMessageCount: Int
    let onRetry: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Connection icon with animation
                Image(systemName: connectionState.iconName)
                    .foregroundColor(connectionStateColor)
                    .font(.system(size: 16, weight: .medium))
                    .rotationEffect(connectionState.isSyncing ? .degrees(360) : .degrees(0))
                    .animation(
                        connectionState.isSyncing ? 
                        .linear(duration: 1.0).repeatForever(autoreverses: false) : 
                        .default,
                        value: connectionState.isSyncing
                    )
                
                // Connection status text
                Text(connectionState.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(connectionStateColor)
                
                Spacer()
                
                // Queued message count
                if queuedMessageCount > 0 {
                    Text("\(queuedMessageCount) queued")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray5))
                        .cornerRadius(12)
                }
            }
            
            // Additional info for specific states
            if case .syncing(let count) = connectionState {
                HStack {
                    Text("Sending \(count) message\(count == 1 ? "" : "s")...")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Progress indicator
                    ProgressView()
                        .scaleEffect(0.8)
                }
            } else if connectionState == .offline && queuedMessageCount > 0 {
                HStack {
                    Text("Messages will send when you're back online")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Retry", action: onRetry)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(connectionStateBackground)
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: connectionState)
    }
    
    // MARK: - Computed Properties
    
    private var connectionStateColor: Color {
        switch connectionState {
        case .online:
            return .green
        case .offline:
            return .red
        case .connecting:
            return .orange
        case .syncing:
            return .blue
        }
    }
    
    private var connectionStateBackground: Color {
        switch connectionState {
        case .online:
            return Color(.systemGray6)
        case .offline:
            return Color(.systemRed).opacity(0.1)
        case .connecting:
            return Color(.systemOrange).opacity(0.1)
        case .syncing:
            return Color(.systemBlue).opacity(0.1)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ConnectionStatusView(
            connectionState: .online,
            queuedMessageCount: 0,
            onRetry: {}
        )
        
        ConnectionStatusView(
            connectionState: .offline,
            queuedMessageCount: 3,
            onRetry: {}
        )
        
        ConnectionStatusView(
            connectionState: .connecting,
            queuedMessageCount: 2,
            onRetry: {}
        )
        
        ConnectionStatusView(
            connectionState: .syncing(3),
            queuedMessageCount: 3,
            onRetry: {}
        )
    }
    .padding()
}
