//
//  PresenceIndicator.swift
//  MessageAI
//
//  Reusable presence indicator component showing online/offline status
//

import SwiftUI

/// Visual indicator for user presence status (online/offline)
/// - Note: Displays as a colored dot with optional connecting/error states
struct PresenceIndicator: View {
    
    // MARK: - Properties
    
    let status: PresenceState
    let size: CGFloat
    let showBorder: Bool
    
    // MARK: - Initialization
    
    /// Initialize presence indicator
    /// - Parameters:
    ///   - status: The presence state to display
    ///   - size: Size of the indicator dot (default: 12)
    ///   - showBorder: Whether to show white border (default: true)
    init(status: PresenceState, size: CGFloat = 12, showBorder: Bool = true) {
        self.status = status
        self.size = size
        self.showBorder = showBorder
    }
    
    // MARK: - Body
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: size, height: size)
            .overlay(
                showBorder ?
                Circle()
                    .strokeBorder(Color(.systemBackground), lineWidth: 2)
                : nil
            )
            .shadow(color: statusColor.opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Private Computed Properties
    
    /// Returns the appropriate color for the current status
    private var statusColor: Color {
        switch status {
        case .online:
            return .green
        case .offline:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview("Online Status") {
    HStack(spacing: 20) {
        PresenceIndicator(status: .online, size: 12)
        PresenceIndicator(status: .online, size: 16)
        PresenceIndicator(status: .online, size: 20)
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Offline Status") {
    HStack(spacing: 20) {
        PresenceIndicator(status: .offline, size: 12)
        PresenceIndicator(status: .offline, size: 16)
        PresenceIndicator(status: .offline, size: 20)
    }
    .padding()
    .background(Color(.systemBackground))
}

#Preview("All States") {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            PresenceIndicator(status: .online)
            Text("Online")
        }
        
        HStack(spacing: 12) {
            PresenceIndicator(status: .offline)
            Text("Offline")
        }
        
        HStack(spacing: 12) {
            PresenceIndicator(status: .online, showBorder: false)
            Text("Online (no border)")
        }
        
        HStack(spacing: 12) {
            PresenceIndicator(status: .offline, showBorder: false)
            Text("Offline (no border)")
        }
    }
    .padding()
}

