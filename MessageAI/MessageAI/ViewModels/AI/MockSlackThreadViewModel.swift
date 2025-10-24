//
//  MockSlackThreadViewModel.swift
//  MessageAI
//
//  PR-011: Mock Slack Integration Demo
//  Connects mock Slack thread to real AI summarization
//

import Foundation
import Combine

@MainActor
class MockSlackThreadViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var thread: SlackThread
    @Published var summary: String?
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Services
    
    private let aiService: AIService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(thread: SlackThread, aiService: AIService = AIService.shared) {
        self.thread = thread
        self.aiService = aiService
    }
    
    // MARK: - Public Methods
    
    /// Summarize the Slack thread using AI
    func summarizeThread() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Format thread messages as a prompt
                let threadText = formatThreadForSummarization()
                
                // Use existing AI service to generate summary
                let aiSummary = try await aiService.generateSummary(
                    for: threadText,
                    context: "Slack thread from #\(thread.channelName)"
                )
                
                await MainActor.run {
                    self.summary = aiSummary
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.error = "Failed to generate summary. Please try again."
                    self.isLoading = false
                }
                print("❌ Summarization error: \(error)")
            }
        }
    }
    
    /// Clear the current summary
    func clearSummary() {
        summary = nil
        error = nil
    }
    
    // MARK: - Private Methods
    
    /// Format the thread messages into a text block for AI summarization
    private func formatThreadForSummarization() -> String {
        var formattedText = "Summarize this Slack conversation from #\(thread.channelName):\n\n"
        
        for message in thread.messages {
            let timestamp = formatTimestamp(message.timestamp)
            formattedText += "[\(timestamp)] \(message.username): \(message.text)\n"
        }
        
        formattedText += "\nProvide a concise summary highlighting:"
        formattedText += "\n- Main topic(s) discussed"
        formattedText += "\n- Key decisions made"
        formattedText += "\n- Action items or next steps"
        formattedText += "\n- Important participants"
        
        return formattedText
    }
    
    /// Format timestamp for display
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - AIService Extension

extension AIService {
    /// Generate a summary for given text
    /// This uses the existing AI chat/summarization infrastructure
    func generateSummary(for text: String, context: String? = nil) async throws -> String {
        // Use the existing chat function with a summarization prompt
        let prompt: String
        if let context = context {
            prompt = "Context: \(context)\n\n\(text)"
        } else {
            prompt = text
        }
        
        // Call existing AI function
        // This will use your deployed Cloud Functions
        let response = try await sendMessage(
            userId: "demo-user",  // Placeholder for demo
            conversationId: "slack-summary-\(UUID().uuidString)",
            message: prompt
        )
        
        return response.message
    }
}

