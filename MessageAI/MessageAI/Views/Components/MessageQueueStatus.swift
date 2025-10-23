//
//  MessageQueueStatus.swift
//  MessageAI
//
//  Message queue status view for offline persistence
//

import SwiftUI

/// View that displays queued message count and status
/// - Note: Shows offline queue information with clear visual feedback
struct MessageQueueStatus: View {
    
    // MARK: - Properties
    
    let queuedMessageCount: Int
    let maxQueueSize: Int
    let isQueueFull: Bool
    let onRetry: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        if queuedMessageCount > 0 {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "tray.full")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Offline Queue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Queue status indicator
                    HStack(spacing: 4) {
                        Text("\(queuedMessageCount)/\(maxQueueSize)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isQueueFull ? .red : .orange)
                        
                        if isQueueFull {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 10))
                        }
                    }
                }
                
                // Queue details
                HStack {
                    Text("\(queuedMessageCount) message\(queuedMessageCount == 1 ? "" : "s") queued for delivery")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Retry Now", action: onRetry)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                // Queue capacity warning
                if isQueueFull {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 10))
                        
                        Text("Queue is full. Oldest messages will be removed when new ones are added.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.red)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(.systemOrange).opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        MessageQueueStatus(
            queuedMessageCount: 0,
            maxQueueSize: 3,
            isQueueFull: false,
            onRetry: {}
        )
        
        MessageQueueStatus(
            queuedMessageCount: 2,
            maxQueueSize: 3,
            isQueueFull: false,
            onRetry: {}
        )
        
        MessageQueueStatus(
            queuedMessageCount: 3,
            maxQueueSize: 3,
            isQueueFull: true,
            onRetry: {}
        )
    }
    .padding()
}
