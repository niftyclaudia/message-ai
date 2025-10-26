//
//  FocusSessionService.swift
//  MessageAI
//
//  Service for managing Focus Mode session lifecycle and Firestore integration
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Service for managing Focus Mode session lifecycle
@MainActor
class FocusSessionService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current active session
    @Published var activeSession: FocusSessionSummary?
    
    /// Session history
    @Published var sessionHistory: [FocusSessionSummary] = []
    
    /// Loading state for session operations
    @Published var isLoading: Bool = false
    
    /// Error state for session operations
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    /// Firestore database instance
    private let db = Firestore.firestore()
    
    /// Current user ID
    private var currentUserID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    /// Listener for active session changes
    private var sessionListener: ListenerRegistration?
    
    // MARK: - Initialization
    
    init() {
        // Start listening for session changes
        startSessionListener()
    }
    
    deinit {
        sessionListener?.remove()
    }
    
    // MARK: - Public Methods
    
    /// Creates a new Focus Mode session
    /// - Returns: Session ID of the created session
    func createFocusSession() async throws -> String {
        guard let userID = currentUserID else {
            throw FocusSessionError.notAuthenticated
        }
        
        isLoading = true
        error = nil
        
        do {
            let sessionID = UUID().uuidString
            let now = Date()
            
            let session = FocusSessionSummary(
                id: sessionID,
                userID: userID,
                startTime: now,
                status: .active
            )
            
            // Save to Firestore
            try await db.collection(FocusSessionSummary.collectionName)
                .document(sessionID)
                .setData(try session.toFirestoreData())
            
            // Update local state
            activeSession = session
            
            isLoading = false
            return sessionID
            
        } catch {
            isLoading = false
            self.error = error
            throw error
        }
    }
    
    /// Ends a Focus Mode session
    /// - Parameter sessionID: ID of the session to end
    func endFocusSession(sessionID: String) async throws {
        guard let userID = currentUserID else {
            throw FocusSessionError.notAuthenticated
        }
        
        isLoading = true
        error = nil
        
        do {
            let now = Date()
            
            // Update session in Firestore
            try await db.collection(FocusSessionSummary.collectionName)
                .document(sessionID)
                .updateData([
                    "endTime": Timestamp(date: now),
                    "status": FocusSessionStatus.completed.rawValue
                ])
            
            // Update local state
            if var session = activeSession, session.id == sessionID {
                session.endTime = now
                session.status = .completed
                sessionHistory.append(session)
                activeSession = nil
            }
            
            isLoading = false
            
        } catch {
            isLoading = false
            self.error = error
            throw error
        }
    }
    
    /// Gets the current active session
    /// - Returns: Active session if exists, nil otherwise
    func getActiveSession() async throws -> FocusSessionSummary? {
        guard let userID = currentUserID else {
            throw FocusSessionError.notAuthenticated
        }
        
        do {
            let snapshot = try await db.collection(FocusSessionSummary.collectionName)
                .whereField("userID", isEqualTo: userID)
                .whereField("status", isEqualTo: FocusSessionStatus.active.rawValue)
                .limit(to: 1)
                .getDocuments()
            
            if let document = snapshot.documents.first {
                let session = try document.data(as: FocusSessionSummary.self)
                activeSession = session
                return session
            } else {
                activeSession = nil
                return nil
            }
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Gets recent session history
    /// - Parameter limit: Maximum number of sessions to retrieve
    /// - Returns: Array of recent sessions
    func getRecentSessions(limit: Int = 10) async throws -> [FocusSessionSummary] {
        guard let userID = currentUserID else {
            throw FocusSessionError.notAuthenticated
        }
        
        do {
            let snapshot = try await db.collection(FocusSessionSummary.collectionName)
                .whereField("userID", isEqualTo: userID)
                .order(by: "startTime", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            let sessions = try snapshot.documents.compactMap { document in
                try document.data(as: FocusSessionSummary.self)
            }
            
            sessionHistory = sessions
            return sessions
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    /// Updates session message count
    /// - Parameters:
    ///   - sessionID: ID of the session to update
    ///   - messageCount: New message count
    ///   - urgentMessageCount: New urgent message count
    func updateSessionMessageCount(sessionID: String, messageCount: Int, urgentMessageCount: Int) async throws {
        guard currentUserID != nil else {
            throw FocusSessionError.notAuthenticated
        }
        
        do {
            try await db.collection(FocusSessionSummary.collectionName)
                .document(sessionID)
                .updateData([
                    "messageCount": messageCount,
                    "urgentMessageCount": urgentMessageCount
                ])
            
            // Update local state
            if var session = activeSession, session.id == sessionID {
                session.messageCount = messageCount
                session.urgentMessageCount = urgentMessageCount
                activeSession = session
            }
            
        } catch {
            self.error = error
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Starts listening for session changes
    private func startSessionListener() {
        guard let userID = currentUserID else { return }
        
        sessionListener = db.collection(FocusSessionSummary.collectionName)
            .whereField("userID", isEqualTo: userID)
            .whereField("status", isEqualTo: FocusSessionStatus.active.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    if let error = error {
                        self?.error = error
                        return
                    }
                    
                    guard let snapshot = snapshot else { return }
                    
                    if let document = snapshot.documents.first {
                        do {
                            let session = try document.data(as: FocusSessionSummary.self)
                            self?.activeSession = session
                        } catch {
                            self?.error = error
                        }
                    } else {
                        self?.activeSession = nil
                    }
                }
            }
    }
}

// MARK: - Error Types

enum FocusSessionError: LocalizedError {
    case notAuthenticated
    case sessionNotFound
    case invalidSessionState
    case firestoreError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .sessionNotFound:
            return "Session not found"
        case .invalidSessionState:
            return "Invalid session state"
        case .firestoreError(let message):
            return "Firestore error: \(message)"
        }
    }
}

// MARK: - FocusSession Extensions

extension FocusSessionSummary {
    /// Converts FocusSessionSummary to Firestore-compatible data
    func toFirestoreData() throws -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "userID": userID,
            "startTime": Timestamp(date: startTime),
            "messageCount": messageCount,
            "urgentMessageCount": urgentMessageCount,
            "status": status.rawValue
        ]
        
        if let endTime = endTime {
            data["endTime"] = Timestamp(date: endTime)
        }
        
        if let summaryID = summaryID {
            data["summaryID"] = summaryID
        }
        
        if let summaryGeneratedAt = summaryGeneratedAt {
            data["summaryGeneratedAt"] = Timestamp(date: summaryGeneratedAt)
        }
        
        if let summaryError = summaryError {
            data["summaryError"] = summaryError
        }
        
        if let summaryFailedAt = summaryFailedAt {
            data["summaryFailedAt"] = Timestamp(date: summaryFailedAt)
        }
        
        return data
    }
}
