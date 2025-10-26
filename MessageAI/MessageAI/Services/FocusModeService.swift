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
    /// - Parameter chats: Array of chats to filter
    /// - Returns: Tuple with (priority chats, holding chats)
    func filterChats(_ chats: [Chat]) -> (priority: [Chat], holding: [Chat]) {
        // If Focus Mode is inactive, return all chats as priority
        guard isActive else {
            return (priority: chats, holding: [])
        }
        
        var priorityChats: [Chat] = []
        var holdingChats: [Chat] = []
        
        for chat in chats {
            // For now, use unread count as a proxy for urgency
            // TODO: Update to use actual message priority once available
            let hasUnreadMessages = chat.unreadCount.values.reduce(0, +) > 0
            
            if hasUnreadMessages {
                priorityChats.append(chat)
            } else {
                holdingChats.append(chat)
            }
        }
        
        return (priority: priorityChats, holding: holdingChats)
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
            print("❌ Failed to save Focus Mode state: \(error)")
        }
    }
}

// MARK: - Error Handling

extension FocusModeService {
    
    /// Handles errors and falls back to safe state
    /// - Parameter error: The error that occurred
    private func handleError(_ error: Error) {
        print("❌ FocusModeService error: \(error)")
        
        // Fallback: deactivate Focus Mode
        Task { @MainActor in
            isActive = false
            focusMode.isActive = false
            activeSession = nil
        }
    }
}
