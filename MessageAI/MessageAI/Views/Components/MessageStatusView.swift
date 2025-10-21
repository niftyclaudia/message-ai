//
//  MessageStatusView.swift
//  MessageAI
//
//  Message status indicator component
//

import SwiftUI

/// View that displays the delivery status of a message
/// - Note: Shows different icons and colors based on message status
struct MessageStatusView: View {
    
    // MARK: - Properties
    
    let status: MessageStatus
    let isOptimistic: Bool
    let retryCount: Int
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusColor)
            
            if isOptimistic {
                Text("Sending...")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            } else if retryCount > 0 {
                Text("Retry \(retryCount)")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusIcon: some View {
        Group {
            switch status {
            case .sending:
                Image(systemName: "clock")
            case .sent:
                Image(systemName: "checkmark")
            case .delivered:
                Image(systemName: "checkmark.circle")
            case .read:
                Image(systemName: "checkmark.circle.fill")
            case .failed:
                Image(systemName: "exclamationmark.triangle")
            case .queued:
                Image(systemName: "clock.arrow.circlepath")
            }
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .sending:
            return .orange
        case .sent:
            return .blue
        case .delivered:
            return .green
        case .read:
            return .green
        case .failed:
            return .red
        case .queued:
            return .purple
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        HStack {
            Text("Sending")
            Spacer()
            MessageStatusView(
                status: .sending,
                isOptimistic: true,
                retryCount: 0
            )
        }
        
        HStack {
            Text("Sent")
            Spacer()
            MessageStatusView(
                status: .sent,
                isOptimistic: false,
                retryCount: 0
            )
        }
        
        HStack {
            Text("Delivered")
            Spacer()
            MessageStatusView(
                status: .delivered,
                isOptimistic: false,
                retryCount: 0
            )
        }
        
        HStack {
            Text("Read")
            Spacer()
            MessageStatusView(
                status: .read,
                isOptimistic: false,
                retryCount: 0
            )
        }
        
        HStack {
            Text("Failed")
            Spacer()
            MessageStatusView(
                status: .failed,
                isOptimistic: false,
                retryCount: 2
            )
        }
        
        HStack {
            Text("Queued")
            Spacer()
            MessageStatusView(
                status: .queued,
                isOptimistic: false,
                retryCount: 0
            )
        }
    }
    .padding()
}