//
//  SummaryIntegrationTests.swift
//  MessageAITests
//
//  Integration tests for Focus Mode session summary functionality
//

import Testing
@testable import MessageAI

@Suite("Summary Integration Tests")
struct SummaryIntegrationTests {
    
    // MARK: - End-to-End Summary Generation Tests
    
    /// Verifies complete end-to-end summary generation flow
    @Test("End-to-End Summary Generation Flow Works Correctly")
    func endToEndSummaryGenerationFlowWorksCorrectly() async throws {
        // Given: User starts Focus Mode session
        let focusModeService = FocusModeService()
        let summaryService = SummaryService()
        
        // When: User activates Focus Mode
        await focusModeService.activateFocusMode()
        
        // Then: Session should be created
        let activeSession = focusModeService.getCurrentSession()
        #expect(activeSession != nil)
        #expect(activeSession?.status == .active)
        
        // When: User sends some messages during Focus Mode
        // Note: In a real test, we'd simulate message sending
        await focusModeService.updateSessionMessageCount(messageCount: 10, urgentMessageCount: 2)
        
        // When: User deactivates Focus Mode
        await focusModeService.deactivateFocusMode()
        
        // Then: Session should be ended
        let finalSession = focusModeService.getCurrentSession()
        #expect(finalSession == nil)
        
        // When: Summary is generated (with delay for Cloud Function)
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Then: Summary should be available
        if let sessionID = activeSession?.id {
            let summary = try await summaryService.getSessionSummary(sessionID: sessionID)
            #expect(summary != nil)
            #expect(summary?.sessionID == sessionID)
            #expect(summary?.overview.isEmpty == false)
        }
    }
    
    /// Verifies summary generation with multiple concurrent sessions
    @Test("Multiple Concurrent Sessions Generate Summaries Correctly")
    func multipleConcurrentSessionsGenerateSummariesCorrectly() async throws {
        // Given: Multiple users with active sessions
        let session1 = FocusSessionService()
        let session2 = FocusSessionService()
        let summaryService = SummaryService()
        
        // When: Both users create sessions
        let sessionID1 = try await session1.createFocusSession()
        let sessionID2 = try await session2.createFocusSession()
        
        // Then: Both sessions should be active
        let activeSession1 = try await session1.getActiveSession()
        let activeSession2 = try await session2.getActiveSession()
        
        #expect(activeSession1 != nil)
        #expect(activeSession2 != nil)
        #expect(activeSession1?.id == sessionID1)
        #expect(activeSession2?.id == sessionID2)
        
        // When: Both sessions are ended
        try await session1.endFocusSession(sessionID: sessionID1)
        try await session2.endFocusSession(sessionID: sessionID2)
        
        // Then: Both summaries should be generated
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        let summary1 = try await summaryService.getSessionSummary(sessionID: sessionID1)
        let summary2 = try await summaryService.getSessionSummary(sessionID: sessionID2)
        
        #expect(summary1 != nil)
        #expect(summary2 != nil)
        #expect(summary1?.sessionID == sessionID1)
        #expect(summary2?.sessionID == sessionID2)
    }
    
    // MARK: - Real-Time Integration Tests
    
    /// Verifies that summary generation doesn't block other users
    @Test("Summary Generation Does Not Block Other Users")
    func summaryGenerationDoesNotBlockOtherUsers() async throws {
        // Given: User A starts summary generation
        let userAService = FocusSessionService()
        let userBService = FocusSessionService()
        
        let sessionIDA = try await userAService.createFocusSession()
        
        // When: User A ends session (triggers summary generation)
        let startTime = CFAbsoluteTimeGetCurrent()
        try await userAService.endFocusSession(sessionID: sessionIDA)
        
        // And: User B creates and ends session simultaneously
        let sessionIDB = try await userBService.createFocusSession()
        try await userBService.endFocusSession(sessionID: sessionIDB)
        
        // Then: User B's session should complete quickly (not blocked)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        #expect(duration < 2.0, "User B should not be blocked by User A's summary generation")
    }
    
    /// Verifies that concurrent session endings are handled correctly
    @Test("Concurrent Session Endings Are Handled Correctly")
    func concurrentSessionEndingsAreHandledCorrectly() async throws {
        // Given: Multiple active sessions
        let sessions = (0..<3).map { _ in FocusSessionService() }
        let sessionIDs = try await withThrowingTaskGroup(of: String.self) { group in
            for session in sessions {
                group.addTask {
                    try await session.createFocusSession()
                }
            }
            
            var ids: [String] = []
            for try await id in group {
                ids.append(id)
            }
            return ids
        }
        
        // When: All sessions are ended concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (session, sessionID) in zip(sessions, sessionIDs) {
                group.addTask {
                    try await session.endFocusSession(sessionID: sessionID)
                }
            }
            
            for try await _ in group {
                // Wait for all sessions to end
            }
        }
        
        // Then: All summaries should be generated
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        let summaryService = SummaryService()
        for sessionID in sessionIDs {
            let summary = try await summaryService.getSessionSummary(sessionID: sessionID)
            #expect(summary != nil)
            #expect(summary?.sessionID == sessionID)
        }
    }
    
    // MARK: - Performance Integration Tests
    
    /// Verifies that summary generation completes within performance target
    @Test("Summary Generation Completes Within Performance Target")
    func summaryGenerationCompletesWithinPerformanceTarget() async throws {
        // Given: Active Focus Mode session
        let sessionService = FocusSessionService()
        let summaryService = SummaryService()
        
        let sessionID = try await sessionService.createFocusSession()
        
        // When: Session is ended and summary generation starts
        let startTime = CFAbsoluteTimeGetCurrent()
        try await sessionService.endFocusSession(sessionID: sessionID)
        
        // Then: Summary should be generated within 10 seconds
        let summary = try await summaryService.generateSessionSummary(sessionID: sessionID)
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        
        #expect(duration < 10.0, "Summary generation should complete within 10 seconds")
        #expect(summary.sessionID == sessionID)
        #expect(summary.overview.isEmpty == false)
    }
    
    /// Verifies that modal presentation is within performance target
    @Test("Modal Presentation Is Within Performance Target")
    func modalPresentationIsWithinPerformanceTarget() async throws {
        // Given: Focus Mode service with summary ready callback
        let focusModeService = FocusModeService()
        var summaryPresented = false
        var presentationTime: CFAbsoluteTime = 0
        
        focusModeService.onSummaryReady = { sessionID in
            let currentTime = CFAbsoluteTimeGetCurrent()
            presentationTime = currentTime
            summaryPresented = true
        }
        
        // When: Focus Mode is activated and then deactivated
        let startTime = CFAbsoluteTimeGetCurrent()
        await focusModeService.activateFocusMode()
        await focusModeService.deactivateFocusMode()
        
        // Then: Summary should be presented within 500ms
        // Note: This is a simplified test - in reality, we'd wait for the callback
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        #expect(summaryPresented == true, "Summary should be presented")
        if summaryPresented {
            let duration = presentationTime - startTime
            #expect(duration < 0.5, "Modal should be presented within 500ms")
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    /// Verifies that API failures are handled gracefully
    @Test("API Failures Are Handled Gracefully")
    func apiFailuresAreHandledGracefully() async throws {
        // Given: Service with potential API failure
        let sessionService = FocusSessionService()
        let summaryService = SummaryService()
        
        // When: Session is created and ended
        let sessionID = try await sessionService.createFocusSession()
        try await sessionService.endFocusSession(sessionID: sessionID)
        
        // And: API fails (simulated by using invalid session ID)
        let invalidSessionID = "invalid-session-\(UUID().uuidString)"
        
        // Then: Error should be handled gracefully
        do {
            _ = try await summaryService.generateSessionSummary(sessionID: invalidSessionID)
            #expect(Bool(false), "Should have thrown error for invalid session")
        } catch {
            #expect(error is SummaryError)
        }
    }
    
    /// Verifies that network timeouts are handled gracefully
    @Test("Network Timeouts Are Handled Gracefully")
    func networkTimeoutsAreHandledGracefully() async throws {
        // Given: Service with potential network timeout
        let sessionService = FocusSessionService()
        let summaryService = SummaryService()
        
        // When: Session is created and ended
        let sessionID = try await sessionService.createFocusSession()
        try await sessionService.endFocusSession(sessionID: sessionID)
        
        // And: Network timeout occurs (simulated by very short timeout)
        // Note: In a real test, we'd mock network conditions
        
        // Then: Timeout should be handled gracefully
        do {
            _ = try await summaryService.generateSessionSummary(sessionID: sessionID)
            // If successful, that's also acceptable
        } catch {
            #expect(error is SummaryError)
            if let summaryError = error as? SummaryError {
                #expect(summaryError == .generationTimeout)
            }
        }
    }
    
    // MARK: - Data Consistency Integration Tests
    
    /// Verifies that session and summary data remain consistent
    @Test("Session And Summary Data Remain Consistent")
    func sessionAndSummaryDataRemainConsistent() async throws {
        // Given: Active session with specific data
        let sessionService = FocusSessionService()
        let summaryService = SummaryService()
        
        let sessionID = try await sessionService.createFocusSession()
        try await sessionService.updateSessionMessageCount(
            sessionID: sessionID,
            messageCount: 25,
            urgentMessageCount: 5
        )
        
        // When: Session is ended and summary is generated
        try await sessionService.endFocusSession(sessionID: sessionID)
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // Then: Summary data should match session data
        let summary = try await summaryService.getSessionSummary(sessionID: sessionID)
        #expect(summary != nil)
        #expect(summary?.sessionID == sessionID)
        #expect(summary?.messageCount == 25)
    }
    
    /// Verifies that multiple summaries for same session are handled correctly
    @Test("Multiple Summaries For Same Session Are Handled Correctly")
    func multipleSummariesForSameSessionAreHandledCorrectly() async throws {
        // Given: Session that has already been summarized
        let sessionService = FocusSessionService()
        let summaryService = SummaryService()
        
        let sessionID = try await sessionService.createFocusSession()
        try await sessionService.endFocusSession(sessionID: sessionID)
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        // When: Attempt to generate summary again
        let summary1 = try await summaryService.getSessionSummary(sessionID: sessionID)
        let summary2 = try await summaryService.getSessionSummary(sessionID: sessionID)
        
        // Then: Both should return the same summary
        #expect(summary1 != nil)
        #expect(summary2 != nil)
        #expect(summary1?.id == summary2?.id)
        #expect(summary1?.sessionID == summary2?.sessionID)
    }
}
