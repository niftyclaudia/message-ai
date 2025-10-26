//
//  HoldingPlaceholderView.swift
//  MessageAI
//
//  Placeholder view for messages held in HOLDING section
//

import SwiftUI

/// Placeholder view shown in HOLDING section when non-priority messages are filtered
struct HoldingPlaceholderView: View {
    
    var body: some View {
        VStack(spacing: 12) {
            // Message text
            Text("Messages are waiting quietly for you")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    HoldingPlaceholderView()
        .padding()
        .background(Color(.systemBackground))
}
