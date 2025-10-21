//
//  MessageStatusView.swift
//  MessageAI
//
//  Message status indicator component
//

import SwiftUI

/// Message status view showing delivery status
/// - Note: Displays sending, sent, delivered, read, failed, and queued states
struct MessageStatusView: View {
    
    // MARK: - Properties
    
    let status: MessageStatus
    let onRetry: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
            
            if let onRetry = onRetry, status == .failed {
                retryButton(onRetry: onRetry)
            }
        }
    }
    
    // MARK: - Status Icon
    
    private var statusIcon: some View {
        Group {
            switch status {
            case .sending:
                ProgressView()
                    .scaleEffect(0.6)
                    .tint(.blue)
                
            case .sent:
                Image(systemName: "checkmark")
                    .font(.caption)
                    .foregroundColor(.blue)
                
            case .delivered:
                Image(systemName: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
                
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundColor(.red)
                
            case .queued:
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
    
    // MARK: - Retry Button
    
    private func retryButton(onRetry: @escaping () -> Void) -> some View {
        Button(action: onRetry) {
            Image(systemName: "arrow.clockwise")
                .font(.caption)
                .foregroundColor(.blue)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ForEach(MessageStatus.allCases, id: \.self) { status in
            HStack {
                Text(status.rawValue.capitalized)
                    .font(.caption)
                
                Spacer()
                
                MessageStatusView(
                    status: status,
                    onRetry: status == .failed ? {} : nil
                )
            }
            .padding(.horizontal)
        }
    }
    .padding()
}
