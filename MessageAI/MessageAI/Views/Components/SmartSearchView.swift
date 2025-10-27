//
//  SmartSearchView.swift
//  MessageAI
//
//  Main semantic search interface
//

import SwiftUI

/// Main view for semantic search functionality
struct SmartSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchService = SearchService()
    @State private var searchQuery: String = ""
    @State private var showingError: Bool = false
    @FocusState private var isSearchFieldFocused: Bool
    
    // Navigation callback
    let onResultTap: (String, String) -> Void  // (chatId, messageId)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search input
                searchInputSection
                
                Divider()
                
                // Content area
                if searchService.isSearching {
                    loadingView
                } else if let error = searchService.searchError {
                    errorView(error: error)
                } else if searchQuery.isEmpty {
                    emptyStateView
                } else if searchService.searchResults.isEmpty && !searchQuery.isEmpty {
                    noResultsView
                } else {
                    resultsListView
                }
            }
            .navigationTitle("Search Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !searchQuery.isEmpty {
                        Button(action: clearSearch) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .alert("Search Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                if let error = searchService.searchError {
                    Text(error.localizedDescription)
                }
            }
        }
            .onAppear {
            isSearchFieldFocused = true
        }
    }
    
    // MARK: - Search Input Section
    
    private var searchInputSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search messages...", text: $searchQuery)
                .focused($isSearchFieldFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }
                .onChange(of: searchQuery) { oldValue, newValue in
                    // Debounce search if needed
                    if newValue.isEmpty {
                        searchService.searchResults = []
                    }
                }
            
            if searchService.isSearching {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Content Views
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(error: SearchError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Search Unavailable")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Try Again") {
                performSearch()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Semantic Search")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Find messages by meaning, not just keywords")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Try searching for:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                suggestionChip("budget meeting")
                suggestionChip("urgent tasks")
                suggestionChip("decisions from last week")
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Results Found")
                .font(.headline)
            
            Text("Try using different keywords or phrases")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Search tips:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("• Use natural language")
                Text("• Try related terms")
                Text("• Check spelling")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(searchService.searchResults) { result in
                    VStack(spacing: 0) {
                        SearchResultRow(result: result) {
                            handleResultTap(result)
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Helper Views
    
    private func suggestionChip(_ text: String) -> some View {
        Button(action: {
            searchQuery = text
            performSearch()
        }) {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(16)
        }
    }
    
    // MARK: - Actions
    
    private func performSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        Task {
            do {
                _ = try await searchService.searchMessages(query: searchQuery)
            } catch {
                showingError = true
            }
        }
    }
    
    private func clearSearch() {
        searchQuery = ""
        searchService.searchResults = []
        isSearchFieldFocused = true
    }
    
    private func handleResultTap(_ result: SearchResult) {
        print("🔍 Tapped result: \(result.messageId) in conversation: \(result.conversationId)")
        
        // Close search modal first
        dismiss()
        
        // Call parent's navigation handler after dismiss completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onResultTap(result.conversationId, result.messageId)
        }
    }
}

// MARK: - Preview

#Preview {
    SmartSearchView { chatId, messageId in
        print("Preview: Navigate to \(chatId), message: \(messageId)")
    }
}

