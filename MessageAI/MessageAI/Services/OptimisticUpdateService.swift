//
//  OptimisticUpdateService.swift
//  MessageAI
//
//  Service for managing optimistic UI updates
//

import Foundation
import SwiftUI

/// Service for managing optimistic message updates and local tracking
/// - Note: Handles optimistic message state and provides real-time updates to UI
@MainActor
class OptimisticUpdateService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var optimisticMessages: [String: OptimisticMessage] = [:]
    @Published var isProcessing: Bool = false
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let optimisticMessagesKey = "optimistic_messages"
    
    // MARK: - Initialization
    
    init() {
        loadOptimisticMessages()
    }
    
    // MARK: - Public Methods
    
    /// Adds an optimistic message to local tracking
    /// - Parameter message: The optimistic message to track
    func addOptimisticMessage(_ message: OptimisticMessage) {
        optimisticMessages[message.id] = message
        saveOptimisticMessages()
    }
    
    /// Updates the status of an optimistic message
    /// - Parameters:
    ///   - messageID: The message ID to update
    ///   - status: The new status
    func updateOptimisticMessageStatus(_ messageID: String, status: MessageStatus) {
        guard var message = optimisticMessages[messageID] else { return }
        
        message.status = status
        message.lastAttempt = Date()
        
        if status == .failed {
            message.retryCount += 1
        }
        
        optimisticMessages[messageID] = message
        saveOptimisticMessages()
    }
    
    /// Removes an optimistic message from tracking
    /// - Parameter messageID: The message ID to remove
    func removeOptimisticMessage(_ messageID: String) {
        optimisticMessages.removeValue(forKey: messageID)
        saveOptimisticMessages()
    }
    
    /// Clears all optimistic messages for a specific chat
    /// - Parameter chatID: The chat ID to clear messages for
    func clearOptimisticMessages(for chatID: String) {
        optimisticMessages = optimisticMessages.filter { $0.value.chatID != chatID }
        saveOptimisticMessages()
    }
    
    /// Gets all optimistic messages for a specific chat
    /// - Parameter chatID: The chat ID to get messages for
    /// - Returns: Array of optimistic messages for the chat
    func getOptimisticMessages(for chatID: String) -> [OptimisticMessage] {
        return optimisticMessages.values.filter { $0.chatID == chatID }
    }
    
    /// Gets all optimistic messages
    /// - Returns: Array of all optimistic messages
    func getAllOptimisticMessages() -> [OptimisticMessage] {
        return Array(optimisticMessages.values)
    }
    
    /// Checks if a message is optimistic
    /// - Parameter messageID: The message ID to check
    /// - Returns: True if the message is being tracked optimistically
    func isOptimisticMessage(_ messageID: String) -> Bool {
        return optimisticMessages[messageID] != nil
    }
    
    /// Gets the status of an optimistic message
    /// - Parameter messageID: The message ID to check
    /// - Returns: The current status of the optimistic message
    func getOptimisticMessageStatus(_ messageID: String) -> MessageStatus? {
        return optimisticMessages[messageID]?.status
    }
    
    /// Retries a failed optimistic message
    /// - Parameter messageID: The message ID to retry
    func retryOptimisticMessage(_ messageID: String) {
        guard var message = optimisticMessages[messageID] else { return }
        
        message.status = .sending
        message.lastAttempt = Date()
        message.retryCount += 1
        
        optimisticMessages[messageID] = message
        saveOptimisticMessages()
    }
    
    /// Clears all optimistic messages
    func clearAllOptimisticMessages() {
        optimisticMessages.removeAll()
        saveOptimisticMessages()
    }
    
    // MARK: - Private Methods
    
    /// Loads optimistic messages from local storage
    private func loadOptimisticMessages() {
        guard let data = userDefaults.data(forKey: optimisticMessagesKey),
              let messages = try? JSONDecoder().decode([String: OptimisticMessage].self, from: data) else {
            return
        }
        optimisticMessages = messages
    }
    
    /// Saves optimistic messages to local storage
    private func saveOptimisticMessages() {
        do {
            let data = try JSONEncoder().encode(optimisticMessages)
            userDefaults.set(data, forKey: optimisticMessagesKey)
        } catch {
        }
    }
}
