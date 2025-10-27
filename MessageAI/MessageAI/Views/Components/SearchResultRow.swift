//
//  SearchResultRow.swift
//  MessageAI
//
//  Individual search result row component
//

import SwiftUI

/// Displays a single search result with message preview and relevance
struct SearchResultRow: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Relevance indicator
                VStack {
                    if result.isHighConfidence {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue.opacity(0.6))
                            .font(.caption2)
                    }
                }
                .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Sender name and timestamp
                    HStack {
                        Text(result.senderName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(result.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Message preview
                    Text(result.messagePreview)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Relevance score (optional - can be toggled)
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.caption2)
                        Text("Match: \(result.relevancePercentage)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Navigation chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        SearchResultRow(
            result: SearchResult(
                messageId: "1",
                conversationId: "conv1",
                relevanceScore: 0.92,
                messagePreview: "Let's schedule the budget meeting for next Tuesday at 2pm. Make sure to bring the Q4 reports.",
                timestamp: Date().addingTimeInterval(-3600),
                senderName: "Sarah Johnson"
            ),
            onTap: {}
        )
        
        Divider()
            .padding(.leading, 44)
        
        SearchResultRow(
            result: SearchResult(
                messageId: "2",
                conversationId: "conv2",
                relevanceScore: 0.75,
                messagePreview: "Did you see the latest update on the project timeline?",
                timestamp: Date().addingTimeInterval(-7200),
                senderName: "Mike Chen"
            ),
            onTap: {}
        )
        
        Divider()
            .padding(.leading, 44)
        
        SearchResultRow(
            result: SearchResult(
                messageId: "3",
                conversationId: "conv3",
                relevanceScore: 0.68,
                messagePreview: "Thanks for the quick response!",
                timestamp: Date().addingTimeInterval(-86400),
                senderName: "Emily Davis"
            ),
            onTap: {}
        )
    }
    .padding()
}

