//
//  PriorityInboxView.swift
//  MessageAI
//
//  Priority-based message filtering and display
//

import SwiftUI

/// Priority inbox view for filtering and displaying messages by category
struct PriorityInboxView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = PriorityInboxViewModel()
    @State private var selectedCategory: MessageCategory? = nil
    @State private var showingSettings = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category filter tabs
                categoryFilterTabs
                
                // Messages list
                messagesList
            }
            .navigationTitle("Priority Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                PrioritySettingsView()
            }
        }
        .onAppear {
            viewModel.loadMessages()
        }
    }
    
    // MARK: - Category Filter Tabs
    
    private var categoryFilterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All messages tab
                CategoryTab(
                    title: "All",
                    count: viewModel.allMessages.count,
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )
                
                // Urgent messages tab
                CategoryTab(
                    title: "Urgent",
                    count: viewModel.urgentMessages.count,
                    isSelected: selectedCategory == .urgent,
                    action: { selectedCategory = .urgent }
                )
                
                // Can Wait messages tab
                CategoryTab(
                    title: "Can Wait",
                    count: viewModel.canWaitMessages.count,
                    isSelected: selectedCategory == .canWait,
                    action: { selectedCategory = .canWait }
                )
                
                // AI Handled messages tab
                CategoryTab(
                    title: "AI Handled",
                    count: viewModel.aiHandledMessages.count,
                    isSelected: selectedCategory == .aiHandled,
                    action: { selectedCategory = .aiHandled }
                )
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Messages List
    
    private var messagesList: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if filteredMessages.isEmpty {
                emptyStateView
            } else {
                messagesScrollView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading messages...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedCategory?.iconName ?? "message")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(emptyStateTitle)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var messagesScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredMessages) { message in
                    PriorityMessageRow(
                        message: message,
                        onTap: {
                            // Navigate to chat
                            viewModel.navigateToChat(message.chatID)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredMessages: [Message] {
        guard let selectedCategory = selectedCategory else {
            return viewModel.allMessages
        }
        
        return viewModel.messages(for: selectedCategory)
    }
    
    private var emptyStateTitle: String {
        switch selectedCategory {
        case .urgent:
            return "No Urgent Messages"
        case .canWait:
            return "No Can Wait Messages"
        case .aiHandled:
            return "No AI Handled Messages"
        case .none:
            return "No Messages"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedCategory {
        case .urgent:
            return "Great! No urgent messages requiring immediate attention."
        case .canWait:
            return "No messages that can wait. All caught up!"
        case .aiHandled:
            return "No messages that can be handled by AI."
        case .none:
            return "No messages to display."
        }
    }
}

// MARK: - Category Tab Component

struct CategoryTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Priority Message Row Component

struct PriorityMessageRow: View {
    let message: Message
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Priority badge
                if let categoryPrediction = message.categoryPrediction {
                    PriorityBadge(
                        category: categoryPrediction.category,
                        confidence: categoryPrediction.confidence,
                        showConfidence: true
                    )
                }
                
                // Message content
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text("Chat ID: \(message.chatID)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatTimestamp(message.timestamp))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Priority Settings View

struct PrioritySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsViewModel = PrioritySettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section("AI Categorization") {
                    Toggle("Enable AI Categorization", isOn: $settingsViewModel.isAICategorizationEnabled)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence Threshold")
                            .font(.system(size: 16, weight: .medium))
                        
                        HStack {
                            Slider(
                                value: $settingsViewModel.confidenceThreshold,
                                in: 0.5...1.0,
                                step: 0.1
                            )
                            
                            Text("\(Int(settingsViewModel.confidenceThreshold * 100))%")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section("Urgency Keywords") {
                    ForEach(settingsViewModel.urgencyKeywords, id: \.self) { keyword in
                        Text(keyword)
                    }
                }
            }
            .navigationTitle("Priority Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        settingsViewModel.saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct PriorityInboxView_Previews: PreviewProvider {
    static var previews: some View {
        PriorityInboxView()
    }
}
