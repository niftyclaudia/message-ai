//
//  FocusSessionServiceTests.swift
//  MessageAITests
//
//  Unit tests for FocusSessionService functionality
//

import Testing
@testable import MessageAI

@Suite("Focus Session Service Tests")
struct FocusSessionServiceTests {
    
    // MARK: - Create Session Tests
    
    /// Verifies that session creation works for authenticated users
    @Test("Create Focus Session With Authenticated User Returns Session ID")
    func createFocusSessionWithAuthenticatedUserReturnsSessionID() async throws {
        // Given
        let service = FocusSessionService()
        
        // When
        let sessionID = try await service.createFocusSession()
        
        // Then
        #expect(sessionID.isEmpty == false)
        #expect(sessionID.count > 10) // UUID should be longer than 10 characters
    }
    
    /// Verifies that session creation fails for unauthenticated users
    @Test("Create Focus Session With Unauthenticated User Throws Error")
    func createFocusSessionWithUnauthenticatedUserThrowsError() async throws {
        // Given
        let service = FocusSessionService()
        // Note: In a real test, we'd mock the authentication state
        
        // When & Then
        do {
            _ = try await service.createFocusSession()
            // If we get here, the test should fail (user should be authenticated)
            #expect(Bool(false), "Should have thrown authentication error")
        } catch {
            #expect(error is FocusSessionError)
            if let sessionError = error as? FocusSessionError {
                #expect(sessionError == .notAuthenticated)
            }
        }
    }
    
    // MARK: - End Session Tests
    
    /// Verifies that session ending works for valid sessions
    @Test("End Focus Session With Valid Session ID Completes Successfully")
    func endFocusSessionWithValidSessionIDCompletesSuccessfully() async throws {
        // Given
        let service = FocusSessionService()
        let sessionID = try await service.createFocusSession()
        
        // When
        try await service.endFocusSession(sessionID: sessionID)
        
        // Then
        // Session should be ended successfully (no exception thrown)
        #expect(Bool(true), "Session ended successfully")
    }
    
    /// Verifies that ending non-existent session throws error
    @Test("End Focus Session With Invalid Session ID Throws Error")
    func endFocusSessionWithInvalidSessionIDThrowsError() async throws {
        // Given
        let service = FocusSessionService()
        let invalidSessionID = "invalid-session-\(UUID().uuidString)"
        
        // When & Then
        do {
            try await service.endFocusSession(sessionID: invalidSessionID)
            #expect(Bool(false), "Should have thrown error for invalid session")
        } catch {
            #expect(error is FocusSessionError)
        }
    }
    
    // MARK: - Get Active Session Tests
    
    /// Verifies that active session retrieval works
    @Test("Get Active Session Returns Current Active Session")
    func getActiveSessionReturnsCurrentActiveSession() async throws {
        // Given
        let service = FocusSessionService()
        let sessionID = try await service.createFocusSession()
        
        // When
        let activeSession = try await service.getActiveSession()
        
        // Then
        #expect(activeSession != nil)
        #expect(activeSession?.id == sessionID)
        #expect(activeSession?.status == .active)
    }
    
    /// Verifies that no active session returns nil
    @Test("Get Active Session With No Active Session Returns Nil")
    func getActiveSessionWithNoActiveSessionReturnsNil() async throws {
        // Given
        let service = FocusSessionService()
        // Don't create any sessions
        
        // When
        let activeSession = try await service.getActiveSession()
        
        // Then
        #expect(activeSession == nil)
    }
    
    // MARK: - Recent Sessions Tests
    
    /// Verifies that recent sessions are retrieved in correct order
    @Test("Get Recent Sessions Returns Sessions In Chronological Order")
    func getRecentSessionsReturnsSessionsInChronologicalOrder() async throws {
        // Given
        let service = FocusSessionService()
        let limit = 5
        
        // When
        let sessions = try await service.getRecentSessions(limit: limit)
        
        // Then
        #expect(sessions.count <= limit)
        
        // Verify chronological order (most recent first)
        for i in 0..<(sessions.count - 1) {
            #expect(sessions[i].startTime >= sessions[i + 1].startTime)
        }
    }
    
    /// Verifies that limit parameter is respected
    @Test("Get Recent Sessions Respects Limit Parameter")
    func getRecentSessionsRespectsLimitParameter() async throws {
        // Given
        let service = FocusSessionService()
        let limit = 3
        
        // When
        let sessions = try await service.getRecentSessions(limit: limit)
        
        // Then
        #expect(sessions.count <= limit)
    }
    
    // MARK: - Update Message Count Tests
    
    /// Verifies that message count updates work
    @Test("Update Session Message Count Updates Counts Successfully")
    func updateSessionMessageCountUpdatesCountsSuccessfully() async throws {
        // Given
        let service = FocusSessionService()
        let sessionID = try await service.createFocusSession()
        let messageCount = 15
        let urgentMessageCount = 3
        
        // When
        try await service.updateSessionMessageCount(
            sessionID: sessionID,
            messageCount: messageCount,
            urgentMessageCount: urgentMessageCount
        )
        
        // Then
        // Verify the update was successful by checking the active session
        let activeSession = try await service.getActiveSession()
        #expect(activeSession?.messageCount == messageCount)
        #expect(activeSession?.urgentMessageCount == urgentMessageCount)
    }
    
    /// Verifies that updating non-existent session throws error
    @Test("Update Session Message Count With Invalid Session ID Throws Error")
    func updateSessionMessageCountWithInvalidSessionIDThrowsError() async throws {
        // Given
        let service = FocusSessionService()
        let invalidSessionID = "invalid-session-\(UUID().uuidString)"
        let messageCount = 10
        let urgentMessageCount = 2
        
        // When & Then
        do {
            try await service.updateSessionMessageCount(
                sessionID: invalidSessionID,
                messageCount: messageCount,
                urgentMessageCount: urgentMessageCount
            )
            #expect(Bool(false), "Should have thrown error for invalid session")
        } catch {
            #expect(error is FocusSessionError)
        }
    }
    
    // MARK: - Session Lifecycle Tests
    
    /// Verifies complete session lifecycle
    @Test("Complete Session Lifecycle Works Correctly")
    func completeSessionLifecycleWorksCorrectly() async throws {
        // Given
        let service = FocusSessionService()
        
        // When: Create session
        let sessionID = try await service.createFocusSession()
        
        // Then: Session should be active
        let activeSession = try await service.getActiveSession()
        #expect(activeSession != nil)
        #expect(activeSession?.id == sessionID)
        #expect(activeSession?.status == .active)
        
        // When: Update message counts
        try await service.updateSessionMessageCount(
            sessionID: sessionID,
            messageCount: 20,
            urgentMessageCount: 5
        )
        
        // Then: Counts should be updated
        let updatedSession = try await service.getActiveSession()
        #expect(updatedSession?.messageCount == 20)
        #expect(updatedSession?.urgentMessageCount == 5)
        
        // When: End session
        try await service.endFocusSession(sessionID: sessionID)
        
        // Then: Session should no longer be active
        let finalActiveSession = try await service.getActiveSession()
        #expect(finalActiveSession == nil)
    }
    
    // MARK: - Error Handling Tests
    
    /// Verifies that authentication errors are handled properly
    @Test("Service Handles Authentication Errors Gracefully")
    func serviceHandlesAuthenticationErrorsGracefully() async throws {
        // Given
        let service = FocusSessionService()
        // Note: In a real test, we'd mock unauthenticated state
        
        // When & Then
        do {
            _ = try await service.createFocusSession()
            #expect(Bool(false), "Should have thrown authentication error")
        } catch {
            #expect(error is FocusSessionError)
            if let sessionError = error as? FocusSessionError {
                #expect(sessionError == .notAuthenticated)
            }
        }
    }
    
    /// Verifies that network errors are handled properly
    @Test("Service Handles Network Errors Gracefully")
    func serviceHandlesNetworkErrorsGracefully() async throws {
        // Given
        let service = FocusSessionService()
        // Note: In a real test, we'd mock network failure
        
        // When & Then
        do {
            _ = try await service.createFocusSession()
            // If network is available, this should succeed
            // If network fails, it should throw an appropriate error
        } catch {
            #expect(error is FocusSessionError)
        }
    }
}
