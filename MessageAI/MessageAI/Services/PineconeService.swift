//
//  PineconeService.swift
//  MessageAI
//
//  Service for vector database operations via Pinecone
//  All Pinecone operations go through Cloud Functions
//

import Foundation
import FirebaseAuth

/// Service handling vector database operations with Pinecone
/// Communicates with Cloud Functions for embedding generation and search
class PineconeService: ObservableObject {
    
    // MARK: - Properties
    
    /// Base URL for Cloud Functions
    private let cloudFunctionsBaseURL: String
    
    /// URL session for network requests
    private let urlSession: URLSession
    
    /// Currently authenticated user
    private var currentUser: FirebaseAuth.User? {
        return Auth.auth().currentUser
    }
    
    // MARK: - Initialization
    
    init(cloudFunctionsBaseURL: String = "https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net") {
        self.cloudFunctionsBaseURL = cloudFunctionsBaseURL
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Generate embedding for a message
    /// - Parameters:
    ///   - messageId: ID of the message
    ///   - text: Message text to embed
    /// - Returns: Vector embedding array (1536 dimensions)
    func generateEmbedding(messageId: String, text: String) async throws -> [Double] {
        guard let userId = currentUser?.uid else {
            throw PineconeError.notAuthenticated
        }
        
        guard text.count >= 10 else {
            throw PineconeError.textTooShort
        }
        
        let endpoint = "\(cloudFunctionsBaseURL)/generateEmbedding"
        guard let url = URL(string: endpoint) else {
            throw PineconeError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "messageId": messageId,
            "text": text,
            "userId": userId
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PineconeError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PineconeError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let embedding = json?["embedding"] as? [Double] else {
            throw PineconeError.invalidEmbedding
        }
        
        // Validate embedding dimensions (OpenAI uses 1536)
        guard embedding.count == 1536 else {
            throw PineconeError.invalidEmbeddingDimensions(actual: embedding.count, expected: 1536)
        }
        
        return embedding
    }
    
    /// Upsert (insert or update) an embedding in Pinecone
    /// - Parameters:
    ///   - id: Unique identifier for the vector
    ///   - vector: Embedding vector array
    ///   - metadata: Additional metadata to store with the vector
    func upsertEmbedding(id: String, vector: [Double], metadata: [String: Any]) async throws {
        guard currentUser != nil else {
            throw PineconeError.notAuthenticated
        }
        
        guard vector.count == 1536 else {
            throw PineconeError.invalidEmbeddingDimensions(actual: vector.count, expected: 1536)
        }
        
        let endpoint = "\(cloudFunctionsBaseURL)/upsertEmbedding"
        guard let url = URL(string: endpoint) else {
            throw PineconeError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "id": id,
            "vector": vector,
            "metadata": metadata
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PineconeError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PineconeError.httpError(statusCode: httpResponse.statusCode)
        }
    }
    
    /// Query Pinecone for similar vectors
    /// - Parameters:
    ///   - vector: Query vector to find similar matches
    ///   - limit: Maximum number of results to return
    /// - Returns: Array of search results with relevance scores
    func querySimilar(vector: [Double], limit: Int = 20) async throws -> [PineconeMatch] {
        guard currentUser != nil else {
            throw PineconeError.notAuthenticated
        }
        
        guard vector.count == 1536 else {
            throw PineconeError.invalidEmbeddingDimensions(actual: vector.count, expected: 1536)
        }
        
        let endpoint = "\(cloudFunctionsBaseURL)/querySimilar"
        guard let url = URL(string: endpoint) else {
            throw PineconeError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "vector": vector,
            "limit": limit
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PineconeError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PineconeError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let matchesArray = json?["matches"] as? [[String: Any]] else {
            throw PineconeError.invalidResponse
        }
        
        return try matchesArray.map { matchDict in
            guard let id = matchDict["id"] as? String,
                  let score = matchDict["score"] as? Double else {
                throw PineconeError.invalidResponse
            }
            
            let metadata = matchDict["metadata"] as? [String: Any]
            return PineconeMatch(id: id, score: score, metadata: metadata)
        }
    }
    
    /// Delete an embedding from Pinecone
    /// - Parameter id: ID of the vector to delete
    func deleteEmbedding(id: String) async throws {
        guard currentUser != nil else {
            throw PineconeError.notAuthenticated
        }
        
        let endpoint = "\(cloudFunctionsBaseURL)/deleteEmbedding"
        guard let url = URL(string: endpoint) else {
            throw PineconeError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "id": id
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let idToken = try? await currentUser?.getIDToken() {
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PineconeError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw PineconeError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}

// MARK: - Supporting Types

/// Represents a match result from Pinecone vector search
struct PineconeMatch {
    let id: String
    let score: Double
    let metadata: [String: Any]?
}

/// Errors specific to Pinecone operations
enum PineconeError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case invalidEmbedding
    case invalidEmbeddingDimensions(actual: Int, expected: Int)
    case textTooShort
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated to perform this operation"
        case .invalidURL:
            return "Invalid Cloud Functions URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .invalidEmbedding:
            return "Invalid embedding received from server"
        case .invalidEmbeddingDimensions(let actual, let expected):
            return "Invalid embedding dimensions: got \(actual), expected \(expected)"
        case .textTooShort:
            return "Text must be at least 10 characters to generate embedding"
        }
    }
}

