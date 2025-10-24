//
//  MockSlackThreadView.swift
//  MessageAI
//
//  PR-011: Mock Slack Integration Demo
//  Displays a mock Slack thread with AI summarization
//

import SwiftUI

struct MockSlackThreadView: View {
    @StateObject private var viewModel: MockSlackThreadViewModel
    @Environment(\.colorScheme) var colorScheme
    
    init(thread: SlackThread = .mockProjectThread) {
        _viewModel = StateObject(wrappedValue: MockSlackThreadViewModel(thread: thread))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                threadHeader
                
                Divider()
                
                // Messages
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.thread.messages) { message in
                        SlackMessageRow(message: message)
                    }
                }
                .padding(.horizontal)
                
                // Summary Section
                if viewModel.isLoading || viewModel.summary != nil || viewModel.error != nil {
                    Divider()
                        .padding(.top, 8)
                    
                    summarySection
                }
                
                // Summarize Button
                if viewModel.summary == nil && !viewModel.isLoading {
                    summarizeButton
                        .padding(.top, 8)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Slack Thread")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Components
    
    private var threadHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Slack logo
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("#\(viewModel.thread.channelName)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(viewModel.thread.workspaceName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                Label("\(viewModel.thread.messageCount) messages", systemImage: "message")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(viewModel.thread.participantCount) participants", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private var summarizeButton: some View {
        Button(action: {
            viewModel.summarizeThread()
        }) {
            HStack {
                Image(systemName: "sparkles")
                Text("Summarize Thread with AI")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Summary")
                    .font(.headline)
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if viewModel.summary != nil {
                    Button(action: {
                        viewModel.clearSummary()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let summary = viewModel.summary {
                Text(summary)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    )
                    .transition(.opacity.combined(with: .scale))
            }
            
            if let error = viewModel.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding(.horizontal)
        .animation(.spring(), value: viewModel.summary)
        .animation(.spring(), value: viewModel.isLoading)
    }
}

// MARK: - Slack Message Row

struct SlackMessageRow: View {
    let message: SlackMessage
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [avatarColor, avatarColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Text(message.username.prefix(1))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack(spacing: 8) {
                    Text(message.username)
                        .font(.system(size: 15, weight: .semibold))
                    
                    Text(formatTimestamp(message.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if message.isThreadParent {
                        Image(systemName: "arrow.turn.down.right")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
                
                // Message text
                Text(message.text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    // Generate consistent color for username
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .indigo]
        let index = abs(message.userId.hashValue) % colors.count
        return colors[index]
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct MockSlackThreadView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MockSlackThreadView()
        }
        .preferredColorScheme(.light)
        
        NavigationView {
            MockSlackThreadView(thread: .mockTechDiscussion)
        }
        .preferredColorScheme(.dark)
    }
}

