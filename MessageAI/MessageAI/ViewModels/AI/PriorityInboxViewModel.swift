//
//  PriorityInboxViewModel.swift
//  MessageAI
//
//  View model for priority inbox functionality
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// View model for priority inbox state management
@MainActor
class PriorityInboxViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var allMessages: [Message] = []
    @Published var urgentMessages: [Message] = []
    @Published var canWaitMessages: [Message] = []
    @Published var aiHandledMessages: [Message] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    private var messageListener: ListenerRegistration?
    
    // MARK: - Public Methods
    
    /// Loads all messages with categorization
    func loadMessages() {
        guard let currentUser = auth.currentUser else { return }
        
        isLoading = true
        error = nil
        
        // Listen to all messages for the current user
        messageListener = db.collection("messages")
            .whereField("readBy", arrayContains: currentUser.uid)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.error = error
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let messages = documents.compactMap { document in
                        try? document.data(as: Message.self)
                    }
                    
                    self.allMessages = messages
                    self.categorizeMessages()
                }
            }
    }
    
    /// Returns messages for a specific category
    func messages(for category: MessageCategory) -> [Message] {
        switch category {
        case .urgent:
            return urgentMessages
        case .canWait:
            return canWaitMessages
        case .aiHandled:
            return aiHandledMessages
        }
    }
    
    /// Navigates to a specific chat
    func navigateToChat(_ chatID: String) {
        // Implementation would depend on your navigation system
        // This is a placeholder for the actual navigation logic
        print("Navigate to chat: \(chatID)")
    }
    
    /// Refreshes the message list
    func refresh() {
        loadMessages()
    }
    
    // MARK: - Private Methods
    
    /// Categorizes messages into priority groups
    private func categorizeMessages() {
        urgentMessages = allMessages.filter { message in
            message.categoryPrediction?.category == .urgent
        }
        
        canWaitMessages = allMessages.filter { message in
            message.categoryPrediction?.category == .canWait
        }
        
        aiHandledMessages = allMessages.filter { message in
            message.categoryPrediction?.category == .aiHandled
        }
    }
    
    deinit {
        messageListener?.remove()
    }
}

// MARK: - Priority Settings View Model

@MainActor
class PrioritySettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAICategorizationEnabled = true
    @Published var confidenceThreshold: Double = 0.7
    @Published var urgencyKeywords: [String] = ["urgent", "asap", "emergency", "critical", "important"]
    
    // MARK: - Private Properties
    
    private let priorityDetectionService = PriorityDetectionService()
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// Loads current settings
    func loadSettings() {
        Task {
            do {
                let isEnabled = try await priorityDetectionService.isAICategorizationEnabled()
                await MainActor.run {
                    self.isAICategorizationEnabled = isEnabled
                }
            } catch {
                print("Failed to load settings: \(error)")
            }
        }
    }
    
    /// Saves settings to Firebase
    func saveSettings() {
        Task {
            do {
                let preferences = PriorityPreferences(
                    aiCategorizationEnabled: isAICategorizationEnabled,
                    confidenceThreshold: confidenceThreshold,
                    urgencyKeywords: urgencyKeywords
                )
                
                try await priorityDetectionService.updateUserPreferences(preferences)
            } catch {
                print("Failed to save settings: \(error)")
            }
        }
    }
}
