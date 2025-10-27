//
//  SearchService.swift
//  MessageAI
//
//  Main service for semantic search functionality
//  Orchestrates embedding generation, vector search, and result retrieval
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import Combine

/// Main service handling semantic search operations
/// Coordinates between Pinecone, OpenAI, and Firestore
class SearchService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current search results
    @Published var searchResults: [SearchResult] = []
    
    /// Whether a search is currently in progress
    @Published var isSearching: Bool = false
    
    /// Current search error, if any
    @Published var searchError: SearchError?
    
    /// Recent search history
    @Published var searchHistory: [SearchQuery] = []
    
    // MARK: - Private Properties
    
    private let firestore = Firestore.firestore()
    private let functions = Functions.functions()
    
    /// Currently authenticated user
    private var currentUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Initialization
    
    init() {
        // Firebase Functions SDK handles URL resolution automatically
    }
    
    // MARK: - Public Methods - Search
    
    /// Perform semantic search across messages
    /// - Parameters:
    ///   - query: Natural language search query
    ///   - limit: Maximum number of results to return
    /// - Returns: Array of search results sorted by relevance
    @MainActor
    func searchMessages(query: String, limit: Int = 20) async throws -> [SearchResult] {
        guard let userId = currentUser?.uid else {
            throw SearchError.notAuthenticated
        }
        
        // Validate query
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            throw SearchError.emptyQuery
        }
        
        guard trimmedQuery.count >= 3 else {
            throw SearchError.queryTooShort
        }
        
        guard trimmedQuery.count <= 200 else {
            throw SearchError.queryTooLong
        }
        
        // Update UI state
        isSearching = true
        searchError = nil
        let startTime = Date()
        
        defer {
            Task { @MainActor in
                self.isSearching = false
            }
        }
        
        do {
            // Call Cloud Function using Firebase SDK (handles auth automatically)
            let callable = functions.httpsCallable("semanticSearch")
            let data: [String: Any] = [
                "query": trimmedQuery,
                "userId": userId,
                "limit": limit
            ]
            
            let result = try await callable.call(data)
            
            guard let resultData = result.data as? [String: Any],
                  let resultsArray = resultData["results"] as? [[String: Any]] else {
                throw SearchError.invalidResponse
            }
            
            // Parse results
            let results = try resultsArray.compactMap { resultDict -> SearchResult? in
                guard let messageId = resultDict["messageId"] as? String,
                      let conversationId = resultDict["conversationId"] as? String,
                      let relevanceScore = resultDict["relevanceScore"] as? Double,
                      let messagePreview = resultDict["messagePreview"] as? String,
                      let timestampString = resultDict["timestamp"] as? String,
                      let senderName = resultDict["senderName"] as? String else {
                    return nil
                }
                
                // Parse ISO8601 timestamp with fractional seconds
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                guard let timestamp = formatter.date(from: timestampString) else {
                    return nil
                }
                
                return SearchResult(
                    messageId: messageId,
                    conversationId: conversationId,
                    relevanceScore: relevanceScore,
                    messagePreview: messagePreview,
                    timestamp: timestamp,
                    senderName: senderName
                )
            }
            
            // Results are already filtered by backend, no need to filter again
            // Update published property on main thread
            await MainActor.run {
                self.searchResults = results
            }
            
            // Calculate duration
            let durationMs = Int(Date().timeIntervalSince(startTime) * 1000)
            
            // Save to search history
            try await saveSearchQuery(
                query: trimmedQuery,
                userId: userId,
                resultCount: results.count,
                resultIds: results.map { $0.id },
                wasSuccessful: true,
                durationMs: durationMs
            )
            
            return results
            
        } catch let error as SearchError {
            await MainActor.run {
                self.searchError = error
            }
            
            // Save failed search to history
            try? await saveSearchQuery(
                query: trimmedQuery,
                userId: userId,
                resultCount: 0,
                resultIds: [],
                wasSuccessful: false,
                errorMessage: error.localizedDescription
            )
            
            throw error
        } catch {
            let searchError = SearchError.unknown(error)
            await MainActor.run {
                self.searchError = searchError
            }
            throw searchError
        }
    }
    
    // MARK: - Public Methods - Search History
    
    /// Get recent search history for current user
    /// - Parameter limit: Maximum number of history items to return
    /// - Returns: Array of recent search queries
    func getSearchHistory(limit: Int = 10) async throws -> [SearchQuery] {
        guard let userId = currentUser?.uid else {
            throw SearchError.notAuthenticated
        }
        
        let snapshot = try await firestore.collection(SearchQuery.collectionName)
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        let history = try snapshot.documents.compactMap { document -> SearchQuery? in
            try document.data(as: SearchQuery.self)
        }
        
        await MainActor.run {
            self.searchHistory = history
        }
        
        return history
    }
    
    /// Clear all search history for current user
    func clearSearchHistory() async throws {
        guard let userId = currentUser?.uid else {
            throw SearchError.notAuthenticated
        }
        
        let snapshot = try await firestore.collection(SearchQuery.collectionName)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        // Delete in batch
        let batch = firestore.batch()
        snapshot.documents.forEach { document in
            batch.deleteDocument(document.reference)
        }
        
        try await batch.commit()
        
        await MainActor.run {
            self.searchHistory = []
        }
    }
    
    // MARK: - Private Methods
    
    /// Save a search query to history
    private func saveSearchQuery(query: String, userId: String, resultCount: Int, resultIds: [String], wasSuccessful: Bool, errorMessage: String? = nil, durationMs: Int? = nil) async throws {
        let searchQuery = SearchQuery(
            query: query,
            userId: userId,
            resultCount: resultCount,
            resultIds: resultIds,
            wasSuccessful: wasSuccessful,
            errorMessage: errorMessage,
            durationMs: durationMs
        )
        
        try firestore.collection(SearchQuery.collectionName)
            .document(searchQuery.id)
            .setData(from: searchQuery)
    }
}

// MARK: - Error Types

/// Errors specific to search operations
enum SearchError: LocalizedError {
    case notAuthenticated
    case emptyQuery
    case queryTooShort
    case queryTooLong
    case invalidURL
    case networkError
    case serverError(statusCode: Int)
    case invalidResponse
    case noResultsFound
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to search"
        case .emptyQuery:
            return "Please enter a search query"
        case .queryTooShort:
            return "Search query must be at least 3 characters"
        case .queryTooLong:
            return "Search query must be less than 200 characters"
        case .invalidURL:
            return "Invalid search service URL"
        case .networkError:
            return "Network connection error. Please try again."
        case .serverError(let statusCode):
            return "Server error (\(statusCode)). Please try again."
        case .invalidResponse:
            return "Invalid response from search service"
        case .noResultsFound:
            return "No messages found matching your search"
        case .unknown(let error):
            return "Search failed: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .emptyQuery, .queryTooShort:
            return "Try entering a more specific search query"
        case .queryTooLong:
            return "Try shortening your search query"
        case .networkError:
            return "Check your internet connection and try again"
        case .noResultsFound:
            return "Try using different keywords or phrases"
        default:
            return "Please try again or contact support if the problem persists"
        }
    }
}

