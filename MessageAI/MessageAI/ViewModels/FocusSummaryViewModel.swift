//
//  FocusSummaryViewModel.swift
//  MessageAI
//
//  ViewModel for managing Focus Mode session summary display and interactions
//

import Foundation
import SwiftUI

/// ViewModel for managing Focus Mode session summary state
@MainActor
class FocusSummaryViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current summary being displayed
    @Published var summary: FocusSummary?
    
    /// Loading state for summary generation
    @Published var isLoading: Bool = false
    
    /// Error state for summary operations
    @Published var error: Error?
    
    /// Whether the summary modal is presented
    @Published var isPresented: Bool = false
    
    /// Export loading state
    @Published var isExporting: Bool = false
    
    /// Export error state
    @Published var exportError: Error?
    
    /// Selected export format
    @Published var selectedExportFormat: ExportFormat = .text
    
    // MARK: - Private Properties
    
    /// Summary service for API operations
    private let summaryService: SummaryService
    
    /// Focus session service for session management
    private let focusSessionService: FocusSessionService
    
    // MARK: - Initialization
    
    @MainActor
    init(summaryService: SummaryService? = nil, focusSessionService: FocusSessionService? = nil) {
        self.summaryService = summaryService ?? SummaryService()
        self.focusSessionService = focusSessionService ?? FocusSessionService()
    }
    
    // MARK: - Public Methods
    
    /// Generates a summary for the given session
    /// - Parameter sessionID: ID of the session to summarize
    func generateSummary(for sessionID: String) async {
        isLoading = true
        error = nil
        
        do {
            let generatedSummary = try await summaryService.generateSessionSummary(sessionID: sessionID)
            summary = generatedSummary
            isPresented = true
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Loads an existing summary
    /// - Parameter sessionID: ID of the session
    func loadSummary(for sessionID: String) async {
        isLoading = true
        error = nil
        
        do {
            if let existingSummary = try await summaryService.getSessionSummary(sessionID: sessionID) {
                summary = existingSummary
                isPresented = true
            } else {
                // No summary exists, generate one
                await generateSummary(for: sessionID)
            }
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Dismisses the summary modal
    func dismissSummary() {
        isPresented = false
        summary = nil
        error = nil
    }
    
    /// Exports the current summary
    /// - Parameter format: Export format
    func exportSummary(format: ExportFormat) async {
        guard let summary = summary else { return }
        
        isExporting = true
        exportError = nil
        
        do {
            let exportData = try await summaryService.exportSummary(summary: summary, format: format)
            
            // Present share sheet
            await presentShareSheet(data: exportData, format: format)
            
        } catch {
            exportError = error
        }
        
        isExporting = false
    }
    
    /// Retries summary generation
    func retrySummaryGeneration() async {
        guard let summary = summary else { return }
        
        await generateSummary(for: summary.sessionID)
    }
    
    /// Clears the current error
    func clearError() {
        error = nil
        exportError = nil
    }
    
    // MARK: - Private Methods
    
    /// Presents the share sheet with export data
    /// - Parameters:
    ///   - data: Export data
    ///   - format: Export format
    private func presentShareSheet(data: Data, format: ExportFormat) async {
        // This would typically use UIActivityViewController
        // For now, we'll just simulate the share action
        print("📤 Exporting summary as \(format.rawValue)")
        print("📤 Data size: \(data.count) bytes")
        
        // In a real implementation, you would:
        // 1. Create a temporary file with the data
        // 2. Present UIActivityViewController
        // 3. Clean up the temporary file after sharing
    }
}

// MARK: - Computed Properties

extension FocusSummaryViewModel {
    
    /// Whether there's an active error
    var hasError: Bool {
        return error != nil || exportError != nil
    }
    
    /// Current error message
    var errorMessage: String? {
        return error?.localizedDescription ?? exportError?.localizedDescription
    }
    
    /// Whether the summary has action items
    var hasActionItems: Bool {
        return summary?.actionItems.isEmpty == false
    }
    
    /// Whether the summary has key decisions
    var hasKeyDecisions: Bool {
        return summary?.keyDecisions.isEmpty == false
    }
    
    /// Formatted session duration
    var formattedDuration: String? {
        guard let summary = summary else { return nil }
        return formatDuration(summary.sessionDuration)
    }
    
    /// Formatted confidence percentage
    var formattedConfidence: String? {
        guard let summary = summary else { return nil }
        return String(format: "%.0f%%", summary.confidence * 100)
    }
    
    /// Formatted generation time
    var formattedGenerationTime: String? {
        guard let summary = summary else { return nil }
        return DateFormatter.localizedString(from: summary.generatedAt, dateStyle: .medium, timeStyle: .short)
    }
}

// MARK: - Helper Methods

extension FocusSummaryViewModel {
    
    /// Formats duration in minutes to human-readable string
    /// - Parameter minutes: Duration in minutes
    /// - Returns: Formatted duration string
    private func formatDuration(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours) hour\(hours == 1 ? "" : "s") \(remainingMinutes) minutes"
            }
        }
    }
}
