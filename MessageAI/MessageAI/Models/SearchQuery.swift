//
//  SearchQuery.swift
//  MessageAI
//
//  Search query history data model for tracking user searches
//

import Foundation
import FirebaseFirestore

/// Represents a search query and its metadata
/// Used for search history and analytics
struct SearchQuery: Codable, Identifiable {
    /// Unique identifier for this search query
    var id: String
    
    /// The search query text entered by user
    let query: String
    
    /// User ID who performed the search
    let userId: String
    
    /// When the search was performed
    let timestamp: Date
    
    /// Number of results returned
    let resultCount: Int
    
    /// Search results (array of SearchResult IDs)
    var resultIds: [String]
    
    /// Whether the search was successful
    let wasSuccessful: Bool
    
    /// Error message if search failed
    var errorMessage: String?
    
    /// Search duration in milliseconds
    var durationMs: Int?
    
    /// Firestore collection name
    static let collectionName = "searchHistory"
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case query
        case userId
        case timestamp
        case resultCount
        case resultIds
        case wasSuccessful
        case errorMessage
        case durationMs
    }
    
    // MARK: - Initialization
    
    init(id: String = UUID().uuidString, query: String, userId: String, timestamp: Date = Date(), resultCount: Int = 0, resultIds: [String] = [], wasSuccessful: Bool = true, errorMessage: String? = nil, durationMs: Int? = nil) {
        self.id = id
        self.query = query
        self.userId = userId
        self.timestamp = timestamp
        self.resultCount = resultCount
        self.resultIds = resultIds
        self.wasSuccessful = wasSuccessful
        self.errorMessage = errorMessage
        self.durationMs = durationMs
    }
    
    // MARK: - Firestore Encoding/Decoding
    
    /// Initialize from Firestore document
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        query = try container.decode(String.self, forKey: .query)
        userId = try container.decode(String.self, forKey: .userId)
        resultCount = try container.decode(Int.self, forKey: .resultCount)
        resultIds = try container.decodeIfPresent([String].self, forKey: .resultIds) ?? []
        wasSuccessful = try container.decodeIfPresent(Bool.self, forKey: .wasSuccessful) ?? true
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        durationMs = try container.decodeIfPresent(Int.self, forKey: .durationMs)
        
        // Handle Firestore Timestamp conversion
        if let timestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        }
    }
    
    /// Encode to Firestore document
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(query, forKey: .query)
        try container.encode(userId, forKey: .userId)
        try container.encode(resultCount, forKey: .resultCount)
        try container.encode(resultIds, forKey: .resultIds)
        try container.encode(wasSuccessful, forKey: .wasSuccessful)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
        try container.encodeIfPresent(durationMs, forKey: .durationMs)
        
        // Convert date to Firestore Timestamp
        try container.encode(Timestamp(date: timestamp), forKey: .timestamp)
    }
}

// MARK: - Helper Methods

extension SearchQuery {
    /// Check if the query was performed recently (within last hour)
    var isRecent: Bool {
        return timestamp.timeIntervalSinceNow > -3600
    }
    
    /// Get formatted duration string
    var formattedDuration: String {
        guard let ms = durationMs else { return "N/A" }
        if ms < 1000 {
            return "\(ms)ms"
        } else {
            return String(format: "%.2fs", Double(ms) / 1000.0)
        }
    }
    
    /// Check if search met performance target (<2s)
    var meetsPerformanceTarget: Bool {
        guard let ms = durationMs else { return false }
        return ms < 2000
    }
}

