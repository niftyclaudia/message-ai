//
//  MemoryService.swift
//  MessageAI
//
//  Created by Cody Agent on 10/24/2025.
//  PR-004: Memory & State Management System
//
//  Core memory service for AI state management, session context, task persistence,
//  and learning data collection. Enables AI features to remember context, track tasks,
//  and learn from user behavior.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Memory Error

enum MemoryError: LocalizedError {
    case contextLimitExceeded
    case invalidTaskState
    case sessionExpired
    case dataCorruption
    case missingUserId
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .contextLimitExceeded:
            return "Session context exceeded limits (20 messages, 5 queries)"
        case .invalidTaskState:
            return "Task state data is invalid or corrupted"
        case .sessionExpired:
            return "Session has expired (>24 hours old)"
        case .dataCorruption:
            return "Memory data is corrupted and cannot be decoded"
        case .missingUserId:
            return "User ID is missing or user is not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Memory Service Protocol

protocol MemoryServiceProtocol {
    // Session Context
    func fetchSessionContext() async throws -> SessionContext
    func updateSessionContext(message: ContextMessage?, query: AIQuery?) async throws
    func clearExpiredContext() async throws
    func setActiveConversation(_ conversationId: String) async throws
    func getRecentContext(limit: Int) async throws -> [ContextMessage]
    
    // Task State
    func fetchTaskState() async throws -> TaskState
    func addActionItem(_ item: TaskItem) async throws
    func updateActionItemStatus(id: String, status: TaskStatus) async throws
    func addDecision(_ decision: DecisionItem) async throws
    func flagDecisionAsImportant(id: String) async throws
    func archiveOldTasks() async throws
    
    // Learning Data
    func logCategorizationOverride(messageId: String, chatId: String, originalCategory: MessageCategory, userCategory: MessageCategory, messageContext: MessageContext) async throws
    func logMeetingPreference(_ preference: MeetingPreference) async throws
    func logToneFeedback(_ feedback: ToneFeedback) async throws
    func fetchLearningData(days: Int) async throws -> [LearningDataEntry]
    
    // Conversation History
    func saveConversation(query: String, response: String, featureSource: AIFeature, contextUsed: [String], confidence: Double) async throws
    func fetchConversationHistory(days: Int, feature: AIFeature?) async throws -> [ConversationHistoryEntry]
    func updateConversationFeedback(id: String, wasHelpful: Bool) async throws
    
    // Utility
    func clearMemory() async throws
    func getMemoryStats() async throws -> MemoryStats
    func observeTaskState(completion: @escaping (Result<TaskState, Error>) -> Void) -> ListenerRegistration
}

// MARK: - Memory Service Implementation

class MemoryService: ObservableObject, MemoryServiceProtocol {
    
    private let db = Firestore.firestore()
    private var taskStateListener: ListenerRegistration?
    
    // MARK: - Helper Properties
    
    private var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private func userAIStateRef() throws -> CollectionReference {
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        return db.collection("users").document(userId).collection("aiState")
    }
    
    // MARK: - Session Context Methods
    
    /// Fetches current session context (<100ms target)
    func fetchSessionContext() async throws -> SessionContext {
        let ref = try userAIStateRef()
        
        do {
            let document = try await ref.document("sessionContext").getDocument()
            
            if document.exists, let data = document.data() {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let context = try JSONDecoder().decode(SessionContext.self, from: jsonData)
                return context
            } else {
                // Return default empty context
                return SessionContext()
            }
        } catch {
            throw MemoryError.networkError(error)
        }
    }
    
    /// Updates session context with new message or query (prunes if needed)
    func updateSessionContext(message: ContextMessage? = nil, query: AIQuery? = nil) async throws {
        let ref = try userAIStateRef()
        var context = try await fetchSessionContext()
        
        // Add new message if provided
        if let message = message {
            context.recentMessages.append(message)
        }
        
        // Add new query if provided
        if let query = query {
            context.recentQueries.append(query)
        }
        
        // Update timestamp
        context.lastActiveTimestamp = Date()
        context.updatedAt = Date()
        
        // Prune to enforce limits (20 messages, 5 queries)
        context = context.pruned()
        
        // Validate
        guard context.isValid() else {
            throw MemoryError.contextLimitExceeded
        }
        
        // Save to Firestore
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(context)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        try await ref.document("sessionContext").setData(dictionary)
    }
    
    /// Removes context entries older than 24 hours
    func clearExpiredContext() async throws {
        var context = try await fetchSessionContext()
        let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60) // 24 hours ago
        
        // Filter out expired messages
        context.recentMessages = context.recentMessages.filter { $0.timestamp > cutoffDate }
        
        // Filter out expired queries
        context.recentQueries = context.recentQueries.filter { $0.timestamp > cutoffDate }
        
        context.updatedAt = Date()
        
        // Save updated context
        let ref = try userAIStateRef()
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(context)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        try await ref.document("sessionContext").setData(dictionary)
    }
    
    /// Sets the active conversation ID
    func setActiveConversation(_ conversationId: String) async throws {
        var context = try await fetchSessionContext()
        context.currentConversationId = conversationId
        context.lastActiveTimestamp = Date()
        context.updatedAt = Date()
        
        let ref = try userAIStateRef()
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(context)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        try await ref.document("sessionContext").setData(dictionary)
    }
    
    /// Gets recent context messages for AI prompts
    func getRecentContext(limit: Int = 20) async throws -> [ContextMessage] {
        let context = try await fetchSessionContext()
        let limitedCount = min(limit, context.recentMessages.count)
        return Array(context.recentMessages.suffix(limitedCount))
    }
    
    // MARK: - Task State Methods
    
    /// Fetches current task state
    func fetchTaskState() async throws -> TaskState {
        let ref = try userAIStateRef()
        
        do {
            let document = try await ref.document("taskState").getDocument()
            
            if document.exists, let data = document.data() {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let taskState = try JSONDecoder().decode(TaskState.self, from: jsonData)
                return taskState
            } else {
                // Return default empty task state
                return TaskState()
            }
        } catch {
            throw MemoryError.networkError(error)
        }
    }
    
    /// Adds a new action item (<300ms sync target)
    func addActionItem(_ item: TaskItem) async throws {
        var taskState = try await fetchTaskState()
        taskState.actionItems.append(item)
        taskState.lastSyncedAt = Date()
        taskState.version += 1
        
        try await saveTaskState(taskState)
    }
    
    /// Updates action item status
    func updateActionItemStatus(id: String, status: TaskStatus) async throws {
        var taskState = try await fetchTaskState()
        
        if let index = taskState.actionItems.firstIndex(where: { $0.id == id }) {
            taskState.actionItems[index].completionStatus = status
            taskState.actionItems[index].updatedAt = Date()
            taskState.lastSyncedAt = Date()
            taskState.version += 1
            
            try await saveTaskState(taskState)
        } else {
            throw MemoryError.invalidTaskState
        }
    }
    
    /// Adds a new decision item
    func addDecision(_ decision: DecisionItem) async throws {
        var taskState = try await fetchTaskState()
        taskState.decisions.append(decision)
        taskState.lastSyncedAt = Date()
        taskState.version += 1
        
        try await saveTaskState(taskState)
    }
    
    /// Flags a decision as important (preserves beyond 90 days)
    func flagDecisionAsImportant(id: String) async throws {
        var taskState = try await fetchTaskState()
        
        if let index = taskState.decisions.firstIndex(where: { $0.id == id }) {
            taskState.decisions[index].isImportant = true
            taskState.lastSyncedAt = Date()
            taskState.version += 1
            
            try await saveTaskState(taskState)
        } else {
            throw MemoryError.invalidTaskState
        }
    }
    
    /// Archives completed tasks older than 30 days
    func archiveOldTasks() async throws {
        var taskState = try await fetchTaskState()
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
        
        // Archive completed tasks older than 30 days
        for index in 0..<taskState.actionItems.count {
            let item = taskState.actionItems[index]
            if item.completionStatus == .completed && item.updatedAt < cutoffDate {
                taskState.actionItems[index].completionStatus = .archived
            }
        }
        
        taskState.lastSyncedAt = Date()
        
        try await saveTaskState(taskState)
    }
    
    /// Helper to save task state
    private func saveTaskState(_ taskState: TaskState) async throws {
        let ref = try userAIStateRef()
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(taskState)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        try await ref.document("taskState").setData(dictionary)
    }
    
    // MARK: - Learning Data Methods
    
    /// Logs a categorization override for AI learning (<150ms target)
    func logCategorizationOverride(
        messageId: String,
        chatId: String,
        originalCategory: MessageCategory,
        userCategory: MessageCategory,
        messageContext: MessageContext
    ) async throws {
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        
        let entry = LearningDataEntry(
            id: UUID().uuidString,
            messageId: messageId,
            chatId: chatId,
            originalCategory: originalCategory,
            userCategory: userCategory,
            timestamp: Date(),
            messageContext: messageContext,
            createdAt: Date()
        )
        
        let ref = db.collection("users").document(userId)
            .collection("aiState").document("learningData")
            .collection("entries").document(entry.id)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(entry)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        try await ref.setData(dictionary)
    }
    
    /// Logs meeting preference feedback
    func logMeetingPreference(_ preference: MeetingPreference) async throws {
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        
        let id = UUID().uuidString
        let ref = db.collection("users").document(userId)
            .collection("aiState").document("learningData")
            .collection("meetingPreferences").document(id)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(preference)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        var data = dictionary
        data["id"] = id
        data["timestamp"] = Timestamp(date: Date())
        data["createdAt"] = Timestamp(date: Date())
        
        try await ref.setData(data)
    }
    
    /// Logs tone feedback
    func logToneFeedback(_ feedback: ToneFeedback) async throws {
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        
        let id = UUID().uuidString
        let ref = db.collection("users").document(userId)
            .collection("aiState").document("learningData")
            .collection("toneFeedback").document(id)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(feedback)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        var data = dictionary
        data["id"] = id
        data["timestamp"] = Timestamp(date: Date())
        data["createdAt"] = Timestamp(date: Date())
        
        try await ref.setData(data)
    }
    
    /// Fetches learning data entries (max 100 entries)
    func fetchLearningData(days: Int) async throws -> [LearningDataEntry] {
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))
        let cutoffTimestamp = Timestamp(date: cutoffDate)
        
        let ref = db.collection("users").document(userId)
            .collection("aiState").document("learningData")
            .collection("entries")
        
        var query: Query = ref
            .whereField("timestamp", isGreaterThan: cutoffTimestamp)
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
        
        let snapshot = try await query.getDocuments()
        
        var entries: [LearningDataEntry] = []
        for document in snapshot.documents {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                let entry = try JSONDecoder().decode(LearningDataEntry.self, from: jsonData)
                entries.append(entry)
            } catch {
                // Skip corrupted entries
                continue
            }
        }
        
        return entries
    }
    
    // MARK: - Conversation History Methods
    
    /// Saves a conversation entry (<200ms target)
    func saveConversation(
        query: String,
        response: String,
        featureSource: AIFeature,
        contextUsed: [String],
        confidence: Double
    ) async throws {
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        
        let entry = ConversationHistoryEntry(
            userQuery: query,
            aiResponse: response,
            featureSource: featureSource,
            contextUsed: contextUsed,
            confidence: confidence
        )
        
        let ref = db.collection("users").document(userId)
            .collection("aiState").document("conversationHistory")
            .collection("entries").document(entry.id)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(entry)
        let dictionary = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] ?? [:]
        
        try await ref.setData(dictionary)
    }
    
    /// Fetches conversation history
    func fetchConversationHistory(days: Int, feature: AIFeature? = nil) async throws -> [ConversationHistoryEntry] {
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        
        let cutoffDate = Date().addingTimeInterval(-Double(days * 24 * 60 * 60))
        let cutoffTimestamp = Timestamp(date: cutoffDate)
        
        var query: Query = db.collection("users").document(userId)
            .collection("aiState").document("conversationHistory")
            .collection("entries")
            .whereField("timestamp", isGreaterThan: cutoffTimestamp)
            .order(by: "timestamp", descending: true)
        
        if let feature = feature {
            query = query.whereField("featureSource", isEqualTo: feature.rawValue)
        }
        
        let snapshot = try await query.getDocuments()
        
        var entries: [ConversationHistoryEntry] = []
        for document in snapshot.documents {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: document.data())
                let entry = try JSONDecoder().decode(ConversationHistoryEntry.self, from: jsonData)
                entries.append(entry)
            } catch {
                continue
            }
        }
        
        return entries
    }
    
    /// Updates conversation feedback
    func updateConversationFeedback(id: String, wasHelpful: Bool) async throws {
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        
        let ref = db.collection("users").document(userId)
            .collection("aiState").document("conversationHistory")
            .collection("entries").document(id)
        
        try await ref.updateData([
            "wasHelpful": wasHelpful
        ])
    }
    
    // MARK: - Utility Methods
    
    /// Clears all memory except important items
    func clearMemory() async throws {
        let ref = try userAIStateRef()
        
        // Clear session context
        try await ref.document("sessionContext").delete()
        
        // Clear task state (preserve important decisions and active tasks)
        var taskState = try await fetchTaskState()
        taskState.actionItems = taskState.actionItems.filter {
            $0.completionStatus != .completed && $0.completionStatus != .archived
        }
        taskState.decisions = taskState.decisions.filter { $0.isImportant }
        try await saveTaskState(taskState)
        
        // Note: Learning data and conversation history cleanup handled by Cloud Functions
    }
    
    /// Gets memory statistics
    func getMemoryStats() async throws -> MemoryStats {
        let context = try await fetchSessionContext()
        let taskState = try await fetchTaskState()
        
        guard let userId = currentUserId else {
            throw MemoryError.missingUserId
        }
        
        // Count learning entries
        let learningRef = db.collection("users").document(userId)
            .collection("aiState").document("learningData")
            .collection("entries")
        let learningSnapshot = try await learningRef.getDocuments()
        
        // Count conversation entries
        let conversationRef = db.collection("users").document(userId)
            .collection("aiState").document("conversationHistory")
            .collection("entries")
        let conversationSnapshot = try await conversationRef.getDocuments()
        
        // Find oldest entry
        var oldestDate: Date?
        if let firstMessage = context.recentMessages.first {
            oldestDate = firstMessage.timestamp
        }
        
        // Estimate size (rough calculation)
        let estimatedSize = (context.recentMessages.count * 200 // messages
                           + context.recentQueries.count * 300 // queries
                           + taskState.actionItems.count * 500 // tasks
                           + taskState.decisions.count * 400 // decisions
                           + learningSnapshot.documents.count * 300 // learning
                           + conversationSnapshot.documents.count * 500) / 1024 // KB
        
        return MemoryStats(
            totalContextMessages: context.recentMessages.count,
            totalActionItems: taskState.actionItems.count,
            totalDecisions: taskState.decisions.count,
            totalLearningEntries: learningSnapshot.documents.count,
            totalConversations: conversationSnapshot.documents.count,
            oldestEntryDate: oldestDate,
            estimatedSizeKB: estimatedSize
        )
    }
    
    /// Observes task state changes in real-time
    func observeTaskState(completion: @escaping (Result<TaskState, Error>) -> Void) -> ListenerRegistration {
        guard let userId = currentUserId else {
            completion(.failure(MemoryError.missingUserId))
            return db.collection("dummy").addSnapshotListener { _, _ in } // Return dummy listener
        }
        
        let ref = db.collection("users").document(userId)
            .collection("aiState").document("taskState")
        
        return ref.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(MemoryError.networkError(error)))
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                completion(.success(TaskState()))
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let taskState = try JSONDecoder().decode(TaskState.self, from: jsonData)
                completion(.success(taskState))
            } catch {
                completion(.failure(MemoryError.dataCorruption))
            }
        }
    }
    
    deinit {
        taskStateListener?.remove()
    }
}

