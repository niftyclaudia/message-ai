//
//  RetryQueue.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Manages the retry queue for failed AI operations
//

import Foundation
import FirebaseFirestore

/// Service for managing retry queue operations
class RetryQueue {
    static let shared = RetryQueue()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Queue Management
    
    /// Add a failed request to the retry queue
    func addToQueue(error: AIError, context: AIContext) async throws -> String {
        guard error.retryable && context.retryCount < 4 else {
            throw NSError(
                domain: "RetryQueue",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Request not retryable or max retries exceeded"]
            )
        }
        
        let nextRetryDelay = calculateRetryDelay(
            initialDelay: error.retryDelay,
            retryCount: context.retryCount
        )
        
        let queueDoc: [String: Any] = [
            "id": context.requestId,
            "feature": context.feature.rawValue,
            "errorType": error.type.rawValue,
            "retryCount": context.retryCount,
            "nextRetryAt": Timestamp(date: Date().addingTimeInterval(nextRetryDelay)),
            "createdAt": Timestamp(date: Date()),
            "resolved": false
        ]
        
        try await db.collection("failedAIRequests")
            .document(context.requestId)
            .setData(queueDoc, merge: true)
        
        return context.requestId
    }
    
    /// Process the retry queue (called by background job)
    func processQueue() async throws -> (processed: Int, succeeded: Int, failed: Int) {
        let now = Timestamp(date: Date())
        
        // Query failed requests ready for retry
        let snapshot = try await db.collection("failedAIRequests")
            .whereField("resolved", isEqualTo: false)
            .whereField("nextRetryAt", isLessThanOrEqualTo: now)
            .limit(to: 50)
            .getDocuments()
        
        var processed = 0
        var succeeded = 0
        var failed = 0
        
        for document in snapshot.documents {
            processed += 1
            
            let data = document.data()
            let retryCount = data["retryCount"] as? Int ?? 0
            
            // Check if max retries exceeded
            if retryCount >= 4 {
                try await document.reference.updateData([
                    "resolved": true,
                    "resolvedAt": Timestamp(date: Date())
                ])
                failed += 1
                continue
            }
            
            // In production, this would dispatch to the appropriate AI service
            // For now, we mark as resolved for demonstration
            try await document.reference.updateData([
                "resolved": true,
                "resolvedAt": Timestamp(date: Date())
            ])
            
            succeeded += 1
        }
        
        return (processed, succeeded, failed)
    }
    
    // MARK: - Helpers
    
    /// Calculate retry delay with exponential backoff
    private func calculateRetryDelay(initialDelay: TimeInterval, retryCount: Int) -> TimeInterval {
        // Exponential backoff: delay * 2^retryCount
        let delay = initialDelay * pow(2.0, Double(retryCount))
        
        // Cap at 8 seconds maximum
        return min(delay, 8.0)
    }
}

