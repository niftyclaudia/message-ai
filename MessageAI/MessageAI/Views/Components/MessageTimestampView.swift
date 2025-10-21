//
//  MessageTimestampView.swift
//  MessageAI
//
//  Message timestamp component with server timestamp support
//

import SwiftUI

/// Message timestamp view that displays server timestamps for consistent ordering
/// - Note: Handles both client and server timestamps with fallback logic
struct MessageTimestampView: View {
    
    // MARK: - Properties
    
    let message: Message
    let isFromCurrentUser: Bool
    
    // MARK: - Computed Properties
    
    private var displayTimestamp: Date {
        // Use server timestamp if available, otherwise fall back to client timestamp
        return message.serverTimestamp ?? message.timestamp
    }
    
    private var formattedTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: displayTimestamp, relativeTo: Date())
    }
    
    private var isServerTimestamp: Bool {
        return message.serverTimestamp != nil
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 4) {
            if isFromCurrentUser {
                Spacer()
            }
            
            Text(formattedTimestamp)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            // Server timestamp indicator
            if isServerTimestamp {
                Image(systemName: "server.rack")
                    .font(.caption2)
                    .foregroundColor(.blue.opacity(0.6))
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
}

// MARK: - Timestamp Formatter

struct MessageTimestampFormatter {
    
    /// Formats a timestamp for display
    /// - Parameters:
    ///   - timestamp: The timestamp to format
    ///   - isServerTimestamp: Whether this is a server timestamp
    /// - Returns: Formatted timestamp string
    static func format(_ timestamp: Date, isServerTimestamp: Bool = false) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        
        let relativeString = formatter.localizedString(for: timestamp, relativeTo: Date())
        
        if isServerTimestamp {
            return "\(relativeString) (server)"
        } else {
            return relativeString
        }
    }
    
    /// Formats a timestamp with detailed information
    /// - Parameters:
    ///   - timestamp: The timestamp to format
    ///   - serverTimestamp: Optional server timestamp
    /// - Returns: Formatted timestamp string with server info
    static func formatDetailed(_ timestamp: Date, serverTimestamp: Date?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let timeString = formatter.string(from: timestamp)
        
        if let serverTimestamp = serverTimestamp {
            let serverTimeString = formatter.string(from: serverTimestamp)
            return "\(timeString) (server: \(serverTimeString))"
        } else {
            return timeString
        }
    }
}

// MARK: - Server Timestamp Indicator

struct ServerTimestampIndicator: View {
    
    // MARK: - Properties
    
    let hasServerTimestamp: Bool
    
    // MARK: - Body
    
    var body: some View {
        if hasServerTimestamp {
            Image(systemName: "server.rack")
                .font(.caption2)
                .foregroundColor(.blue.opacity(0.6))
                .help("Server timestamp")
        }
    }
}

// MARK: - Timestamp Comparison View

struct TimestampComparisonView: View {
    
    // MARK: - Properties
    
    let message: Message
    
    // MARK: - Computed Properties
    
    private var clientTimestamp: Date {
        return message.timestamp
    }
    
    private var serverTimestamp: Date? {
        return message.serverTimestamp
    }
    
    private var timeDifference: TimeInterval? {
        guard let serverTimestamp = serverTimestamp else { return nil }
        return serverTimestamp.timeIntervalSince(clientTimestamp)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Client:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(formatTimestamp(clientTimestamp))
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            
            if let serverTimestamp = serverTimestamp {
                HStack {
                    Text("Server:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatTimestamp(serverTimestamp))
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                if let difference = timeDifference {
                    HStack {
                        Text("Diff:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(String(format: "%.1fs", difference))
                            .font(.caption2)
                            .foregroundColor(difference > 1.0 ? .orange : .green)
                    }
                }
            } else {
                HStack {
                    Text("No server timestamp")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Methods
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Message with server timestamp
        MessageTimestampView(
            message: Message(
                id: "1",
                chatID: "chat1",
                senderID: "user1",
                text: "Message with server timestamp",
                timestamp: Date().addingTimeInterval(-300),
                serverTimestamp: Date().addingTimeInterval(-299),
                status: .delivered
            ),
            isFromCurrentUser: true
        )
        
        // Message without server timestamp
        MessageTimestampView(
            message: Message(
                id: "2",
                chatID: "chat1",
                senderID: "user1",
                text: "Message without server timestamp",
                timestamp: Date().addingTimeInterval(-200),
                status: .sent
            ),
            isFromCurrentUser: true
        )
        
        // Timestamp comparison view
        TimestampComparisonView(
            message: Message(
                id: "3",
                chatID: "chat1",
                senderID: "user1",
                text: "Comparison message",
                timestamp: Date().addingTimeInterval(-100),
                serverTimestamp: Date().addingTimeInterval(-99.5),
                status: .delivered
            )
        )
    }
    .padding()
}
