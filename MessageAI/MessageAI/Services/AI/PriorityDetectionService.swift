//
//  PriorityDetectionService.swift
//  MessageAI
//
//  AI-powered priority detection service for message categorization
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

/// Service for AI-powered message priority detection and categorization
@MainActor
class PriorityDetectionService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    // MARK: - Published Properties
    
    @Published var isProcessing = false
    @Published var lastError: Error?
    
    // MARK: - Configuration
    
    private let confidenceThreshold: Double = 0.7
    private let maxRetryAttempts = 3
    private let timeoutInterval: TimeInterval = 10.0
    
    // MARK: - Public Methods
    
    /// Categorizes a message using AI analysis
    /// - Parameters:
    ///   - message: The message to categorize
    ///   - context: Additional context for categorization
    /// - Returns: CategoryPrediction result
    func categorizeMessage(_ message: Message, context: MessageContext? = nil) async throws -> CategoryPrediction {
        guard let currentUser = auth.currentUser else {
            throw PriorityDetectionError.notAuthenticated
        }
        
        isProcessing = true
        lastError = nil
        
        do {
            // Extract metadata from message
            let metadata = extractMetadata(from: message)
            
            // Call Cloud Function for AI categorization
            let prediction = try await callAICategorization(
                messageID: message.id,
                text: message.text,
                metadata: metadata,
                userID: currentUser.uid,
                context: context
            )
            
            // Update message with prediction
            try await updateMessagePrediction(messageID: message.id, chatID: message.chatID, prediction: prediction)
            
            isProcessing = false
            return prediction
            
        } catch {
            isProcessing = false
            lastError = error
            
            // Use intelligent fallback prediction instead of neutral
            return createFallbackPrediction(
                messageID: message.id,
                text: message.text,
                userID: currentUser.uid
            )
        }
    }
    
    /// Retrieves categorized messages for a chat
    /// - Parameters:
    ///   - chatID: The chat identifier
    ///   - category: Optional category filter
    /// - Returns: Array of categorized messages
    func getCategorizedMessages(chatID: String, category: MessageCategory? = nil) async throws -> [Message] {
        var query = db.collection("chats")
            .document(chatID)
            .collection("messages")
            .whereField("categoryPrediction.category", isNotEqualTo: NSNull())
        
        if let category = category {
            query = query.whereField("categoryPrediction.category", isEqualTo: category.rawValue)
        }
        
        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { document in
            try? document.data(as: Message.self)
        }
    }
    
    /// Updates user preferences for AI categorization
    /// - Parameter preferences: The new preferences
    func updateUserPreferences(_ preferences: PriorityPreferences) async throws {
        guard let currentUser = auth.currentUser else {
            throw PriorityDetectionError.notAuthenticated
        }
        
        let userRef = db.collection("users").document(currentUser.uid)
        try await userRef.updateData([
            "priorityPreferences": try Firestore.Encoder().encode(preferences)
        ])
    }
    
    /// Checks if AI categorization is enabled for the current user
    /// - Returns: Boolean indicating if AI categorization is enabled
    func isAICategorizationEnabled() async throws -> Bool {
        guard let currentUser = auth.currentUser else {
            throw PriorityDetectionError.notAuthenticated
        }
        
        let userDoc = try await db.collection("users").document(currentUser.uid).getDocument()
        
        if let data = userDoc.data(),
           let preferences = data["priorityPreferences"] as? [String: Any],
           let enabled = preferences["aiCategorizationEnabled"] as? Bool {
            return enabled
        }
        
        // Default to enabled if not set
        return true
    }
    
    /// Creates a fallback prediction when Cloud Function fails
    private func createFallbackPrediction(messageID: String, text: String, userID: String) -> CategoryPrediction {
        let lowercasedText = text.lowercased()
        
        // Enhanced keyword-based categorization
        let urgentKeywords = ["urgent", "asap", "emergency", "critical", "immediately", "deadline", "today", "tomorrow", "server down", "down", "broken", "fix", "help"]
        let actionKeywords = ["please", "need", "request", "ask", "help", "schedule", "meeting"]
        
        let hasUrgent = urgentKeywords.contains(where: { lowercasedText.contains($0) })
        let hasAction = actionKeywords.contains(where: { lowercasedText.contains($0) })
        
        // Debug logging
        print("🔍 Fallback analysis for: '\(text)'")
        print("🔍 Lowercased: '\(lowercasedText)'")
        print("🔍 Has urgent keywords: \(hasUrgent)")
        print("🔍 Has action keywords: \(hasAction)")
        
        let category: MessageCategory
        let confidence: Double
        let reasoning: String
        
        if hasUrgent {
            category = .urgent
            confidence = 0.95  // Very high confidence for urgent keywords
            let foundKeywords = urgentKeywords.filter { lowercasedText.contains($0) }
            reasoning = "URGENT: Contains urgency keywords: \(foundKeywords.joined(separator: ", "))"
            print("🚨 Categorizing as URGENT with confidence: \(confidence)")
        } else if hasAction {
            category = .aiHandled
            confidence = 0.7
            let foundKeywords = actionKeywords.filter { lowercasedText.contains($0) }
            reasoning = "Contains action keywords: \(foundKeywords.joined(separator: ", "))"
            print("🤖 Categorizing as AI HANDLED with confidence: \(confidence)")
        } else {
            category = .canWait
            confidence = 0.6
            reasoning = "No urgency or action keywords detected"
            print("🟡 Categorizing as CAN WAIT with confidence: \(confidence)")
        }
        
        return CategoryPrediction(
            category: category,
            confidence: confidence,
            reasoning: reasoning,
            timestamp: Date(),
            messageID: messageID,
            userID: userID,
            isOffline: false,
            modelVersion: "fallback-1.0"
        )
    }
    
    // MARK: - Private Methods
    
    /// Extracts searchable metadata from a message
    private func extractMetadata(from message: Message) -> SearchableMetadata {
        let text = message.text.lowercased()
        
        // Extract keywords (simple implementation)
        let keywords = extractKeywords(from: text)
        
        // Extract participants (mentions, names)
        let participants = extractParticipants(from: text)
        
        // Check for urgency indicators
        let urgencyIndicators = extractUrgencyIndicators(from: text)
        
        // Determine sentiment
        let sentiment = analyzeSentiment(text)
        
        // Determine length category
        let lengthCategory = determineLengthCategory(text.count)
        
        // Check for questions
        let containsQuestions = text.contains("?") || text.contains("how") || text.contains("what") || text.contains("when") || text.contains("where") || text.contains("why")
        
        // Check for action items
        let containsActionItems = text.contains("todo") || text.contains("task") || text.contains("action") || text.contains("need to") || text.contains("should")
        
        return SearchableMetadata(
            keywords: keywords,
            participants: participants,
            decisionMade: containsActionItems,
            urgencyIndicators: urgencyIndicators,
            sentiment: sentiment,
            lengthCategory: lengthCategory,
            containsQuestions: containsQuestions,
            containsActionItems: containsActionItems
        )
    }
    
    /// Extracts keywords from message text
    private func extractKeywords(from text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 } // Filter out short words
            .filter { !$0.isEmpty }
        
        // Simple keyword extraction (in production, use more sophisticated NLP)
        return Array(Set(words)).prefix(10).map { $0 }
    }
    
    /// Extracts participant names from message text
    private func extractParticipants(from text: String) -> [String] {
        // Look for @mentions or common name patterns
        let mentions = text.components(separatedBy: " ")
            .filter { $0.hasPrefix("@") }
            .map { String($0.dropFirst()) }
        
        return mentions
    }
    
    /// Extracts urgency indicators from message text
    private func extractUrgencyIndicators(from text: String) -> [String] {
        let urgencyWords = ["urgent", "asap", "immediately", "emergency", "critical", "important", "rush", "deadline"]
        
        return urgencyWords.filter { text.contains($0) }
    }
    
    /// Analyzes sentiment of message text
    private func analyzeSentiment(_ text: String) -> SentimentType {
        let positiveWords = ["good", "great", "excellent", "amazing", "wonderful", "fantastic"]
        let negativeWords = ["bad", "terrible", "awful", "horrible", "disappointed", "frustrated"]
        let urgentWords = ["urgent", "asap", "emergency", "critical", "immediately"]
        
        let positiveCount = positiveWords.filter { text.contains($0) }.count
        let negativeCount = negativeWords.filter { text.contains($0) }.count
        let urgentCount = urgentWords.filter { text.contains($0) }.count
        
        if urgentCount > 0 {
            return .urgent
        } else if positiveCount > negativeCount {
            return .positive
        } else if negativeCount > positiveCount {
            return .negative
        } else {
            return .neutral
        }
    }
    
    /// Determines length category based on character count
    private func determineLengthCategory(_ count: Int) -> LengthCategory {
        if count < 50 {
            return .short
        } else if count < 200 {
            return .medium
        } else {
            return .long
        }
    }
    
    /// Calls Cloud Function for AI categorization
    private func callAICategorization(
        messageID: String,
        text: String,
        metadata: SearchableMetadata,
        userID: String,
        context: MessageContext?
    ) async throws -> CategoryPrediction {
        
        let function = Functions.functions().httpsCallable("categorizeMessage")
        
        // Create a simplified metadata dictionary without Date objects
        let metadataDict: [String: Any] = [
            "keywords": metadata.keywords,
            "participants": metadata.participants,
            "decisionMade": metadata.decisionMade,
            "urgencyIndicators": metadata.urgencyIndicators,
            "sentiment": metadata.sentiment.rawValue,
            "lengthCategory": metadata.lengthCategory.rawValue,
            "containsQuestions": metadata.containsQuestions,
            "containsActionItems": metadata.containsActionItems,
            "extractionVersion": metadata.extractionVersion
        ]
        
        let requestData: [String: Any] = [
            "messageID": messageID,
            "text": text,
            "metadata": metadataDict,
            "userID": userID,
            "context": context?.toDictionary() ?? [:]
        ]
        
        do {
            let result = try await function.call(requestData)
            
            guard let data = result.data as? [String: Any],
                  let categoryString = data["category"] as? String,
                  let category = MessageCategory(rawValue: categoryString),
                  let confidence = data["confidence"] as? Double,
                  let reasoning = data["reasoning"] as? String else {
                throw PriorityDetectionError.invalidResponse
            }
            
            return CategoryPrediction(
                category: category,
                confidence: confidence,
                reasoning: reasoning,
                messageID: messageID,
                userID: userID
            )
        } catch {
            // Fallback to local categorization if Cloud Function fails
            print("⚠️ Cloud Function failed, using local fallback: \(error)")
            return createFallbackPrediction(messageID: messageID, text: text, userID: userID)
        }
    }
    
    /// Updates message with categorization prediction
    private func updateMessagePrediction(messageID: String, chatID: String, prediction: CategoryPrediction) async throws {
        // Update the message in the correct path
        let messageRef = db.collection("chats").document(chatID).collection("messages").document(messageID)
        
        try await messageRef.updateData([
            "categoryPrediction": try Firestore.Encoder().encode(prediction),
            "embeddingGenerated": true
        ])
    }
}

// MARK: - Supporting Types

/// Priority detection specific errors
enum PriorityDetectionError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case networkFailure
    case aiServiceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkFailure:
            return "Network connection failed"
        case .aiServiceUnavailable:
            return "AI service temporarily unavailable"
        }
    }
}

/// User preferences for priority detection
struct PriorityPreferences: Codable {
    let aiCategorizationEnabled: Bool
    let confidenceThreshold: Double
    let urgencyKeywords: [String]
    let customRules: [String: String]
    
    init(
        aiCategorizationEnabled: Bool = true,
        confidenceThreshold: Double = 0.7,
        urgencyKeywords: [String] = ["urgent", "asap", "emergency"],
        customRules: [String: String] = [:]
    ) {
        self.aiCategorizationEnabled = aiCategorizationEnabled
        self.confidenceThreshold = confidenceThreshold
        self.urgencyKeywords = urgencyKeywords
        self.customRules = customRules
    }
}
