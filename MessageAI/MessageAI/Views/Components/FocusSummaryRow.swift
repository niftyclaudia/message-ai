//
//  FocusSummaryRow.swift
//  MessageAI
//
//  SwiftUI component for displaying summary items in lists
//

import SwiftUI

/// Row view for displaying Focus Mode session summaries in lists
struct FocusSummaryRow: View {
    
    // MARK: - Properties
    
    /// Summary to display
    let summary: FocusSummary
    
    /// Action to perform when row is tapped
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                summaryIcon
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    // Header
                    HStack {
                        Text("Focus Session")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Overview
                    Text(summary.overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata
                    HStack(spacing: 16) {
                        metadataItem(icon: "message", text: "\(summary.messageCount) messages")
                        metadataItem(icon: "clock", text: formatDuration(summary.sessionDuration))
                        metadataItem(icon: "checkmark.circle", text: "\(Int(summary.confidence * 100))%")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Summary Icon
    
    private var summaryIcon: some View {
        ZStack {
            Circle()
                .fill(iconBackgroundColor)
                .frame(width: 40, height: 40)
            
            Image(systemName: "doc.text")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconForegroundColor)
        }
    }
    
    // MARK: - Metadata Item
    
    private func metadataItem(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: summary.generatedAt)
    }
    
    private var iconBackgroundColor: Color {
        switch summary.method {
        case "openai":
            return .blue.opacity(0.1)
        case "fallback":
            return .orange.opacity(0.1)
        default:
            return .gray.opacity(0.1)
        }
    }
    
    private var iconForegroundColor: Color {
        switch summary.method {
        case "openai":
            return .blue
        case "fallback":
            return .orange
        default:
            return .gray
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
}

// MARK: - Preview

struct FocusSummaryRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            FocusSummaryRow(
                summary: FocusSummary(
                    id: "preview-1",
                    sessionID: nil,
                    userID: "user-1",
                    generatedAt: Date(),
                    overview: "Team discussed Q4 planning and resource allocation. Key topics included budget approval and hiring priorities.",
                    actionItems: [
                        "John to finalize budget proposal by Friday",
                        "Sarah to schedule interviews for new developer position"
                    ],
                    keyDecisions: [
                        "Approved 20% increase in development budget",
                        "Decided to hire 2 additional developers in Q4"
                    ],
                    messageCount: 15,
                    urgentMessageCount: 5,
                    confidence: 0.85,
                    processingTimeMs: 2500,
                    method: "openai",
                    sessionDuration: 45
                ),
                onTap: {}
            )
            
            FocusSummaryRow(
                summary: FocusSummary(
                    id: "preview-2",
                    sessionID: nil,
                    userID: "user-1",
                    generatedAt: Date().addingTimeInterval(-3600),
                    overview: "Quick standup meeting to discuss project status and blockers.",
                    actionItems: [],
                    keyDecisions: [],
                    messageCount: 8,
                    urgentMessageCount: 2,
                    confidence: 0.3,
                    processingTimeMs: 500,
                    method: "fallback",
                    sessionDuration: 15
                ),
                onTap: {}
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
