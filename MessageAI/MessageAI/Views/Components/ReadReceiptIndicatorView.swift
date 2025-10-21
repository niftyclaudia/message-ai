//
//  ReadReceiptIndicatorView.swift
//  MessageAI
//
//  SwiftUI component for displaying message read receipt status
//

import SwiftUI

/// Read receipt indicator showing message delivery and read status
struct ReadReceiptIndicatorView: View {
    // MARK: - Properties
    
    /// The message status to display
    let status: MessageStatus
    
    /// Whether the message has been read (from readBy array)
    let isRead: Bool
    
    /// The color to use for the indicator
    let color: Color
    
    // MARK: - Initialization
    
    init(status: MessageStatus, isRead: Bool = false, color: Color = .blue) {
        self.status = status
        self.isRead = isRead
        self.color = color
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 2) {
            switch status {
            case .sending:
                // Clock icon for sending
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
            case .sent:
                // Single checkmark for sent
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.gray)
                
            case .delivered:
                // Double checkmark for delivered
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .offset(x: -4)
                
            case .read:
                // Double checkmark in blue for read
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(color)
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(color)
                    .offset(x: -4)
                
            case .failed:
                // Exclamation mark for failed
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
                
            case .queued:
                // Clock icon for queued
                Image(systemName: "clock.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding(.leading, status == .delivered || status == .read ? 4 : 0)
    }
}

// MARK: - Preview Provider

#Preview("Sending") {
    ReadReceiptIndicatorView(status: .sending)
}

#Preview("Sent") {
    ReadReceiptIndicatorView(status: .sent)
}

#Preview("Delivered") {
    ReadReceiptIndicatorView(status: .delivered)
}

#Preview("Read") {
    ReadReceiptIndicatorView(status: .read)
}

#Preview("Failed") {
    ReadReceiptIndicatorView(status: .failed)
}

#Preview("Queued") {
    ReadReceiptIndicatorView(status: .queued)
}

#Preview("All States") {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Text("Sending:")
            ReadReceiptIndicatorView(status: .sending)
        }
        
        HStack {
            Text("Sent:")
            ReadReceiptIndicatorView(status: .sent)
        }
        
        HStack {
            Text("Delivered:")
            ReadReceiptIndicatorView(status: .delivered)
        }
        
        HStack {
            Text("Read:")
            ReadReceiptIndicatorView(status: .read)
        }
        
        HStack {
            Text("Failed:")
            ReadReceiptIndicatorView(status: .failed)
        }
        
        HStack {
            Text("Queued:")
            ReadReceiptIndicatorView(status: .queued)
        }
    }
    .padding()
}

