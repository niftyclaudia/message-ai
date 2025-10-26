//
//  FocusModeService.swift
//  MessageAI
//
//  Service for managing Focus Mode state and filtering
//

import Foundation
import Combine
import SwiftUI

/// Service for managing Focus Mode state and filtering messages
/// - Note: Manages local Focus Mode state with UserDefaults persistence
@MainActor
class FocusModeService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether Focus Mode is currently active
    @Published var isActive: Bool {
        didSet {
            saveToUserDefaults()
        }
    }
    
    /// Whether summary modal should be presented
    @Published var shouldShowSummary: Bool = false
    
    /// Current session ID for summary generation
    @Published var currentSessionID: String?
    
    // MARK: - Private Properties
    
    /// Current Focus Mode state
    private var focusMode: FocusMode
    
    /// Active Focus Session
    private var activeSession: FocusSessionSummary?
    
    /// UserDefaults key for persistence
    private let userDefaultsKey = "FocusModeState"
    
    /// Array to store session history (for future use)
    private var sessionHistory: [FocusSessionSummary] = []
    
    /// Focus Session Service for session management
    private let focusSessionService = FocusSessionService()
    
    /// Summary Service for summary generation
    private let summaryService = SummaryService()
    
    // MARK: - Initialization
    
    init() {
        // Load state from UserDefaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(FocusMode.self, from: data) {
            self.focusMode = decoded
            self.isActive = decoded.isActive
        } else {
            // Default state
            self.focusMode = FocusMode(isActive: false)
            self.isActive = false
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggles Focus Mode on/off
    func toggleFocusMode() async {
        if isActive {
            await deactivateFocusMode()
        } else {
            await activateFocusMode()
        }
    }
    
    /// Activates Focus Mode
    func activateFocusMode() async {
        guard !isActive else { return }
        
        isActive = true
        let sessionId = UUID().uuidString
        let now = Date()
        
        focusMode.isActive = true
        focusMode.activatedAt = now
        focusMode.sessionId = sessionId
        
        // Create new session in Firestore
        do {
            let createdSessionID = try await focusSessionService.createFocusSession()
            currentSessionID = createdSessionID
            
            // Create local session for immediate use
            activeSession = FocusSessionSummary(
                id: createdSessionID,
                userID: "", // Will be set by the service
                startTime: now
            )
            
            print("✅ Focus Mode activated with session: \(createdSessionID)")
        } catch {
            print("❌ Failed to create Focus Mode session: \(error)")
            // Fallback to local session
            activeSession = FocusSessionSummary(
                id: sessionId,
                userID: "",
                startTime: now
            )
            currentSessionID = sessionId
        }
    }
    
    /// Deactivates Focus Mode
    func deactivateFocusMode() async {
        guard isActive else { return }
        
        isActive = false
        let now = Date()
        
        // End current session if exists
        if var session = activeSession {
            session.endTime = now
            sessionHistory.append(session)
            activeSession = nil
        }
        
        // End session in Firestore and trigger summary generation
        if let sessionID = currentSessionID {
            do {
                try await focusSessionService.endFocusSession(sessionID: sessionID)
                
                // Trigger summary generation
                await generateSummaryForSession(sessionID: sessionID)
                
            } catch {
                print("❌ Failed to end Focus Mode session: \(error)")
            }
        }
        
        focusMode.isActive = false
        focusMode.activatedAt = nil
        focusMode.sessionId = nil
        currentSessionID = nil
        
        print("✅ Focus Mode deactivated")
    }
    
    /// Filters chats into priority and holding sections
    /// - Parameters:
    ///   - chats: Array of chats to filter
    ///   - aiClassificationService: Service to check for urgent messages
    ///   - currentUserID: The current user's ID to check read status
    /// - Returns: Tuple with (priority chats, holding chats)
    func filterChats(_ chats: [Chat], aiClassificationService: AIClassificationService? = nil, currentUserID: String? = nil) -> (priority: [Chat], holding: [Chat]) {
        // If Focus Mode is inactive, return all chats as priority
        guard isActive else {
            return (priority: chats, holding: [])
        }
        
        
        var priorityChats: [Chat] = []
        var holdingChats: [Chat] = []
        
        for chat in chats {
            // Check if chat has any unread messages
            let hasUnreadMessages = hasUnreadMessagesInChat(chat, currentUserID: currentUserID)
            
            // Only process chats with unread messages
            if hasUnreadMessages {
                // Check if this chat has any unread urgent messages (not just any urgent messages)
                let hasUnreadUrgentMessages = hasUnreadUrgentMessagesInChat(chat, aiClassificationService: aiClassificationService, currentUserID: currentUserID)
                
                if hasUnreadUrgentMessages {
                    // Chat has unread urgent messages - add to Priority section
                    priorityChats.append(chat)
                } else {
                    // Chat has unread messages but they're all non-urgent - add to Holding section
                    holdingChats.append(chat)
                }
            }
            // Chats with no unread messages are skipped (don't show in Focus Mode)
        }
        
        // Print summary in the format requested
        print("===== FOCUS MODE SUMMARY =====")
        print("Current User ID: \(currentUserID ?? "nil")")
        for chat in chats {
            let unreadCount = chat.unreadCount[currentUserID ?? ""] ?? 0
            let hasUnread = unreadCount > 0
            let hasUnreadUrgent = hasUnreadUrgentMessagesInChat(chat, aiClassificationService: aiClassificationService, currentUserID: currentUserID)
            
            print("Chat \(chat.id): unreadCount=\(unreadCount), hasUnread=\(hasUnread), hasUnreadUrgent=\(hasUnreadUrgent)")
            
            if hasUnreadUrgent {
                print("[\(chat.id)] UNREAD PRIORITY (unread + most recent message is urgent)")
            } else if hasUnread {
                print("[\(chat.id)] UNREAD NONPRIORITY (unread but most recent message is not urgent)")
            } else {
                print("[\(chat.id)] READ NONPRIORITY (no unread messages)")
            }
        }
        print("TOTAL PRIORITY: \(priorityChats.count)")
        print("HOLDING: \(holdingChats.count)")
        print("=============================")
        
        return (priority: priorityChats, holding: holdingChats)
    }
    
    /// Checks if a chat has any unread messages
    /// - Parameters:
    ///   - chat: The chat to check
    ///   - currentUserID: The current user's ID to check read status
    /// - Returns: True if the chat has any unread messages
    private func hasUnreadMessagesInChat(_ chat: Chat, currentUserID: String?) -> Bool {
        guard let currentUserID = currentUserID else {
            // If no current user ID, check if there are any unread messages
            return chat.unreadCount.values.reduce(0, +) > 0
        }
        
        // Check if the current user has any unread messages in this chat
        return (chat.unreadCount[currentUserID] ?? 0) > 0
    }
    
    
    /// Checks if a chat has any unread urgent messages
    /// - Parameters:
    ///   - chat: The chat to check
    ///   - aiClassificationService: Service to check classification status
    ///   - currentUserID: The current user's ID to check read status
    /// - Returns: True if the chat has unread urgent messages
    private func hasUnreadUrgentMessagesInChat(_ chat: Chat, aiClassificationService: AIClassificationService?, currentUserID: String?) -> Bool {
        // If no AI classification service available, fall back to unread count
        guard let aiService = aiClassificationService else {
            let hasUnreadMessages = chat.unreadCount.values.reduce(0, +) > 0
            return hasUnreadMessages
        }
        
        // If no current user ID provided, return false (need user to check read status)
        guard let currentUserID = currentUserID else { 
            return false 
        }
        
        // Check if the current user has any unread messages
        let hasUnreadMessages = (chat.unreadCount[currentUserID] ?? 0) > 0
        if !hasUnreadMessages {
            return false
        }
        
        // Get all urgent message IDs in this chat
        let urgentMessageIds = aiService.getUrgentMessageIdsInChat(chatID: chat.id)
        
        // If no urgent messages at all, return false
        guard !urgentMessageIds.isEmpty else { 
            return false 
        }
        
        // For now, we'll use a simplified approach:
        // Check if the most recent message (lastMessageID) is urgent
        // This is a reasonable approximation for determining if unread messages are urgent
        
        if let lastMessageID = chat.lastMessageID {
            // Check if the most recent message is urgent
            let isLastMessageUrgent = urgentMessageIds.contains(lastMessageID)
            return isLastMessageUrgent
        }
        
        // If no lastMessageID, fall back to checking if any urgent messages exist
        return true
    }
    
    /// Gets the current active Focus Session
    /// - Returns: Current FocusSessionSummary if active, nil otherwise
    func getCurrentSession() -> FocusSessionSummary? {
        return activeSession
    }
    
    // MARK: - Private Methods
    
    /// Generates summary for a completed session
    /// - Parameter sessionID: ID of the session to summarize
    private func generateSummaryForSession(sessionID: String) async {
        do {
            // Generate summary
            let summary = try await summaryService.generateSessionSummary(sessionID: sessionID)
            
            // Show summary modal
            currentSessionID = sessionID
            shouldShowSummary = true
            
            print("✅ Summary generated for session: \(sessionID)")
            
        } catch {
            print("❌ Failed to generate summary for session \(sessionID): \(error)")
            // Still show summary modal but with error state
            currentSessionID = sessionID
            shouldShowSummary = true
        }
    }
    
    /// Dismisses the summary modal
    func dismissSummary() {
        shouldShowSummary = false
        currentSessionID = nil
    }
    
    /// Saves Focus Mode state to UserDefaults
    private func saveToUserDefaults() {
        do {
            let data = try JSONEncoder().encode(focusMode)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            // Silently handle save errors
        }
    }
}

// MARK: - Error Handling

extension FocusModeService {
    
    /// Handles errors and falls back to safe state
    /// - Parameter error: The error that occurred
    private func handleError(_ error: Error) {
        // Fallback: deactivate Focus Mode
        Task { @MainActor in
            isActive = false
            focusMode.isActive = false
            activeSession = nil
        }
    }
}
