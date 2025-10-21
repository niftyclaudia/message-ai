//
//  OptimisticUpdateView.swift
//  MessageAI
//
//  Optimistic update management component
//

import SwiftUI

/// Optimistic update view for managing optimistic message states
/// - Note: Handles optimistic message display and status management
struct OptimisticUpdateView: View {
    
    // MARK: - Properties
    
    @ObservedObject var optimisticService: OptimisticUpdateService
    let chatID: String
    let onRetry: (String) -> Void
    let onDelete: (String) -> Void
    
    // MARK: - Computed Properties
    
    private var optimisticMessages: [OptimisticMessage] {
        optimisticService.getOptimisticMessages(for: chatID)
    }
    
    private var hasOptimisticMessages: Bool {
        !optimisticMessages.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        if hasOptimisticMessages {
            VStack(alignment: .leading, spacing: 8) {
                optimisticMessagesHeader
                
                ForEach(optimisticMessages) { message in
                    OptimisticMessageItemView(
                        message: message,
                        onRetry: { onRetry(message.id) },
                        onDelete: { onDelete(message.id) }
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Optimistic Messages Header
    
    private var optimisticMessagesHeader: some View {
        HStack {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.orange)
            
            Text("Optimistic Messages")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            Spacer()
            
            Text("\(optimisticMessages.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Optimistic Message Item View

struct OptimisticMessageItemView: View {
    
    // MARK: - Properties
    
    let message: OptimisticMessage
    let onRetry: () -> Void
    let onDelete: () -> Void
    
    // MARK: - Animation Properties
    
    @State private var isAnimating: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 8) {
            // Status indicator
            OptimisticStatusIndicator(
                status: message.status,
                isAnimating: isAnimating
            )
            
            // Message text
            Text(message.text)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                if message.status == .failed {
                    Button(action: onRetry) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            if message.status == .sending {
                isAnimating = true
            }
        }
    }
}

// MARK: - Optimistic Status Indicator

struct OptimisticStatusIndicator: View {
    
    // MARK: - Properties
    
    let status: MessageStatus
    let isAnimating: Bool
    
    // MARK: - Animation Properties
    
    @State private var rotationAngle: Double = 0
    @State private var scale: Double = 1.0
    
    // MARK: - Body
    
    var body: some View {
        Group {
            switch status {
            case .sending:
                if isAnimating {
                    ProgressView()
                        .scaleEffect(0.4)
                        .tint(.blue)
                        .rotationEffect(.degrees(rotationAngle))
                } else {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
            case .sent:
                Image(systemName: "checkmark")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
            case .delivered:
                Image(systemName: "checkmark.circle")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
            case .read:
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
            case .failed:
                Image(systemName: "exclamationmark.circle")
                    .font(.caption2)
                    .foregroundColor(.red)
                
            case .queued:
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .scaleEffect(scale)
        .onAppear {
            if isAnimating && status == .sending {
                withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    scale = 1.1
                }
            }
        }
    }
}

// MARK: - Optimistic Update Summary

struct OptimisticUpdateSummary: View {
    
    // MARK: - Properties
    
    @ObservedObject var optimisticService: OptimisticUpdateService
    let chatID: String
    
    // MARK: - Computed Properties
    
    private var optimisticMessages: [OptimisticMessage] {
        optimisticService.getOptimisticMessages(for: chatID)
    }
    
    private var sendingCount: Int {
        optimisticMessages.filter { $0.status == .sending }.count
    }
    
    private var failedCount: Int {
        optimisticMessages.filter { $0.status == .failed }.count
    }
    
    private var queuedCount: Int {
        optimisticMessages.filter { $0.status == .queued }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        if !optimisticMessages.isEmpty {
            HStack(spacing: 12) {
                if sendingCount > 0 {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(.blue)
                        Text("\(sendingCount) sending")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                if failedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.caption2)
                            .foregroundColor(.red)
                        Text("\(failedCount) failed")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
                
                if queuedCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(queuedCount) queued")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        // Optimistic update view with messages
        OptimisticUpdateView(
            optimisticService: {
                let service = OptimisticUpdateService()
                service.addOptimisticMessage(OptimisticMessage(
                    id: "1",
                    chatID: "chat1",
                    text: "This is an optimistic message being sent...",
                    timestamp: Date(),
                    senderID: "user1",
                    status: .sending
                ))
                service.addOptimisticMessage(OptimisticMessage(
                    id: "2",
                    chatID: "chat1",
                    text: "This message failed to send",
                    timestamp: Date(),
                    senderID: "user1",
                    status: .failed
                ))
                return service
            }(),
            chatID: "chat1",
            onRetry: { _ in },
            onDelete: { _ in }
        )
        
        // Optimistic update summary
        OptimisticUpdateSummary(
            optimisticService: {
                let service = OptimisticUpdateService()
                service.addOptimisticMessage(OptimisticMessage(
                    id: "1",
                    chatID: "chat1",
                    text: "Sending message",
                    timestamp: Date(),
                    senderID: "user1",
                    status: .sending
                ))
                service.addOptimisticMessage(OptimisticMessage(
                    id: "2",
                    chatID: "chat1",
                    text: "Failed message",
                    timestamp: Date(),
                    senderID: "user1",
                    status: .failed
                ))
                return service
            }(),
            chatID: "chat1"
        )
    }
    .padding()
}
