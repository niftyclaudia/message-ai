//
//  FocusSummaryView.swift
//  MessageAI
//
//  SwiftUI view for displaying Focus Mode session summaries
//

import SwiftUI

/// Modal view for displaying Focus Mode session summaries
struct FocusSummaryView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = FocusSummaryViewModel()
    @Environment(\.dismiss) private var dismiss
    
    /// Session ID to generate/display summary for
    let sessionID: String
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    loadingView
                } else if let summary = viewModel.summary {
                    summaryContent(summary)
                } else if viewModel.hasError {
                    errorView
                } else {
                    emptyView
                }
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        viewModel.dismissSummary()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.summary != nil {
                        exportButton
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadSummary(for: sessionID)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Generating Summary...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("This may take a few moments")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Summary Content
    
    private func summaryContent(_ summary: FocusSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                summaryHeader(summary)
                
                // Overview
                summarySection(
                    title: "Overview",
                    content: summary.overview,
                    icon: "doc.text"
                )
                
                // Action Items
                if viewModel.hasActionItems {
                    actionItemsSection(summary.actionItems)
                }
                
                // Key Decisions
                if viewModel.hasKeyDecisions {
                    keyDecisionsSection(summary.keyDecisions)
                }
                
                // Metadata
                metadataSection(summary)
            }
            .padding()
        }
    }
    
    // MARK: - Summary Header
    
    private func summaryHeader(_ summary: FocusSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Session Complete")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack {
                Label("\(summary.messageCount) messages", systemImage: "message")
                Spacer()
                Label(viewModel.formattedDuration ?? "", systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Summary Section
    
    private func summarySection(title: String, content: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Action Items Section
    
    private func actionItemsSection(_ actionItems: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .foregroundColor(.orange)
                Text("Action Items")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(actionItems.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(item)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Key Decisions Section
    
    private func keyDecisionsSection(_ decisions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.purple)
                Text("Key Decisions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(decisions.enumerated()), id: \.offset) { index, decision in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(decision)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Metadata Section
    
    private func metadataSection(_ summary: FocusSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.gray)
                Text("Summary Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                metadataRow("Generated", value: viewModel.formattedGenerationTime ?? "")
                metadataRow("Confidence", value: viewModel.formattedConfidence ?? "")
                metadataRow("Method", value: summary.method.capitalized)
                metadataRow("Processing Time", value: "\(summary.processingTimeMs)ms")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func metadataRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Summary Generation Failed")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Retry") {
                Task {
                    await viewModel.retrySummaryGeneration()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty View
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Summary Available")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Unable to generate a summary for this session")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Export Button
    
    private var exportButton: some View {
        Menu {
            Button("Export as Text") {
                Task {
                    await viewModel.exportSummary(format: .text)
                }
            }
            
            Button("Export as Markdown") {
                Task {
                    await viewModel.exportSummary(format: .markdown)
                }
            }
            
            Button("Export as PDF") {
                Task {
                    await viewModel.exportSummary(format: .pdf)
                }
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .disabled(viewModel.isExporting)
    }
}

// MARK: - Preview

struct FocusSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        FocusSummaryView(sessionID: "preview-session-id")
    }
}
