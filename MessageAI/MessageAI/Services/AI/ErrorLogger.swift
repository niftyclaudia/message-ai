//
//  ErrorLogger.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Handles logging of AI errors to Crashlytics and Firestore
//

import Foundation
import FirebaseFirestore
import FirebaseCrashlytics
import CryptoKit

/// Service for logging AI errors with privacy preservation
class ErrorLogger {
    static let shared = ErrorLogger()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Firestore Logging
    
    /// Log error to Firestore /failedAIRequests/ collection
    func logToFirestore(error: AIError, context: AIContext) async throws {
        let nextRetryDelay = calculateRetryDelay(
            initialDelay: error.retryDelay,
            retryCount: context.retryCount
        )
        
        let requestDoc: [String: Any] = [
            "id": context.requestId,
            "userId": hashForPrivacy(context.userId), // Privacy: hashed
            "feature": context.feature.rawValue,
            "errorType": error.type.rawValue,
            "timestamp": Timestamp(date: context.timestamp),
            "retryCount": context.retryCount,
            "nextRetryAt": Timestamp(date: Date().addingTimeInterval(nextRetryDelay)),
            "requestContext": [
                "messageId": context.messageId as Any,
                "threadId": context.threadId as Any,
                "query": context.query != nil ? hashForPrivacy(context.query!) as Any : NSNull(), // Privacy: hashed
            ],
            "errorDetails": [
                "message": error.message,
                "statusCode": error.statusCode as Any,
            ],
            "resolved": false
        ]
        
        try await db.collection("failedAIRequests")
            .document(context.requestId)
            .setData(requestDoc)
    }
    
    // MARK: - Privacy Helpers
    
    /// Hash a string for privacy-preserving logging
    private func hashForPrivacy(_ value: String) -> String {
        let data = Data(value.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined().prefix(16).description
    }
    
    /// Calculate retry delay with exponential backoff
    private func calculateRetryDelay(initialDelay: TimeInterval, retryCount: Int) -> TimeInterval {
        // Exponential backoff: delay * 2^retryCount
        let delay = initialDelay * pow(2.0, Double(retryCount))
        
        // Cap at 8 seconds maximum
        return min(delay, 8.0)
    }
}

