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
    
    let isOffline: Bool
    let queuedMessageCount: Int
    let connectionType: ConnectionType
    let onRetry: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        if isOffline {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.red)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Offline")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                    
                    Spacer()
                    
                    if queuedMessageCount > 0 {
                        Text("\(queuedMessageCount) queued")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                if queuedMessageCount > 0 {
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
            .background(Color(.systemGray6))
            .cornerRadius(8)
        } else {
            // Show connection type when online
            HStack {
                Image(systemName: connectionIcon)
                    .foregroundColor(connectionColor)
                    .font(.system(size: 14, weight: .medium))
                
                Text(connectionText)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionIcon: String {
        switch connectionType {
        case .wifi:
            return "wifi"
        case .cellular:
            return "antenna.radiowaves.left.and.right"
        case .ethernet:
            return "cable.connector"
        case .none:
            return "wifi.slash"
        }
    }
    
    private var connectionColor: Color {
        switch connectionType {
        case .wifi:
            return .green
        case .cellular:
            return .blue
        case .ethernet:
            return .purple
        case .none:
            return .red
        }
    }
    
    private var connectionText: String {
        switch connectionType {
        case .wifi:
            return "Connected via Wi-Fi"
        case .cellular:
            return "Connected via Cellular"
        case .ethernet:
            return "Connected via Ethernet"
        case .none:
            return "No Connection"
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        OfflineIndicatorView(
            isOffline: true,
            queuedMessageCount: 3,
            connectionType: .none,
            onRetry: {}
        )
        
        OfflineIndicatorView(
            isOffline: false,
            queuedMessageCount: 0,
            connectionType: .wifi,
            onRetry: {}
        )
        
        OfflineIndicatorView(
            isOffline: false,
            queuedMessageCount: 0,
            connectionType: .cellular,
            onRetry: {}
        )
    }
    .padding()
}