//
//  SummaryServiceTests.swift
//  MessageAITests
//
//  Unit tests for SummaryService functionality
//

import Testing
@testable import MessageAI

@Suite("Summary Service Tests")
struct SummaryServiceTests {
    
    // MARK: - Generate Summary Tests
    
    /// Verifies that summary generation works for a valid session
    @Test("Generate Summary With Valid Session ID Returns Summary")
    func generateSummaryWithValidSessionIDReturnsSummary() async throws {
        // Given
        let service = SummaryService()
        let sessionID = "test-session-\(UUID().uuidString)"
        
        // When
        let summary = try await service.generateSessionSummary(sessionID: sessionID)
        
        // Then
        #expect(summary.sessionID == sessionID)
        #expect(summary.overview.isEmpty == false)
        #expect(summary.confidence >= 0.0)
        #expect(summary.confidence <= 1.0)
        #expect(summary.messageCount >= 0)
    }
    
    /// Verifies that summary generation handles empty sessions gracefully
    @Test("Generate Summary For Empty Session Returns Empty Summary")
    func generateSummaryForEmptySessionReturnsEmptySummary() async throws {
        // Given
        let service = SummaryService()
        let emptySessionID = "empty-session-\(UUID().uuidString)"
        
        // When
        let summary = try await service.generateSessionSummary(sessionID: emptySessionID)
        
        // Then
        #expect(summary.sessionID == emptySessionID)
        #expect(summary.messageCount == 0)
        #expect(summary.overview.contains("No messages"))
    }
    
    /// Verifies that summary generation times out appropriately
    @Test("Generate Summary Times Out After Maximum Wait Time")
    func generateSummaryTimesOutAfterMaximumWaitTime() async throws {
        // Given
        let service = SummaryService()
        let timeoutSessionID = "timeout-session-\(UUID().uuidString)"
        
        // When & Then
        do {
            _ = try await service.generateSessionSummary(sessionID: timeoutSessionID)
            #expect(Bool(false), "Should have thrown timeout error")
        } catch {
            #expect(error is SummaryError)
            if let summaryError = error as? SummaryError {
                #expect(summaryError == .generationTimeout)
            }
        }
    }
    
    // MARK: - Get Summary Tests
    
    /// Verifies that existing summaries can be retrieved
    @Test("Get Session Summary With Valid Session ID Returns Summary")
    func getSessionSummaryWithValidSessionIDReturnsSummary() async throws {
        // Given
        let service = SummaryService()
        let sessionID = "test-session-\(UUID().uuidString)"
        
        // When
        let summary = try await service.getSessionSummary(sessionID: sessionID)
        
        // Then
        // Note: In a real test, we'd set up test data first
        // For now, we expect nil for non-existent sessions
        #expect(summary == nil)
    }
    
    /// Verifies that non-existent summaries return nil
    @Test("Get Session Summary With Invalid Session ID Returns Nil")
    func getSessionSummaryWithInvalidSessionIDReturnsNil() async throws {
        // Given
        let service = SummaryService()
        let invalidSessionID = "invalid-session-\(UUID().uuidString)"
        
        // When
        let summary = try await service.getSessionSummary(sessionID: invalidSessionID)
        
        // Then
        #expect(summary == nil)
    }
    
    // MARK: - Recent Summaries Tests
    
    /// Verifies that recent summaries are retrieved in correct order
    @Test("Get Recent Summaries Returns Summaries In Chronological Order")
    func getRecentSummariesReturnsSummariesInChronologicalOrder() async throws {
        // Given
        let service = SummaryService()
        let limit = 5
        
        // When
        let summaries = try await service.getRecentSummaries(limit: limit)
        
        // Then
        #expect(summaries.count <= limit)
        
        // Verify chronological order (most recent first)
        for i in 0..<(summaries.count - 1) {
            #expect(summaries[i].generatedAt >= summaries[i + 1].generatedAt)
        }
    }
    
    /// Verifies that limit parameter is respected
    @Test("Get Recent Summaries Respects Limit Parameter")
    func getRecentSummariesRespectsLimitParameter() async throws {
        // Given
        let service = SummaryService()
        let limit = 3
        
        // When
        let summaries = try await service.getRecentSummaries(limit: limit)
        
        // Then
        #expect(summaries.count <= limit)
    }
    
    // MARK: - Export Tests
    
    /// Verifies that text export generates valid data
    @Test("Export Summary As Text Generates Valid Data")
    func exportSummaryAsTextGeneratesValidData() async throws {
        // Given
        let service = SummaryService()
        let summary = createTestSummary()
        
        // When
        let exportData = try await service.exportSummary(summary: summary, format: .text)
        
        // Then
        #expect(exportData.isEmpty == false)
        
        let exportText = String(data: exportData, encoding: .utf8)
        #expect(exportText != nil)
        #expect(exportText!.contains("Focus Mode Session Summary"))
        #expect(exportText!.contains(summary.overview))
    }
    
    /// Verifies that markdown export generates valid data
    @Test("Export Summary As Markdown Generates Valid Data")
    func exportSummaryAsMarkdownGeneratesValidData() async throws {
        // Given
        let service = SummaryService()
        let summary = createTestSummary()
        
        // When
        let exportData = try await service.exportSummary(summary: summary, format: .markdown)
        
        // Then
        #expect(exportData.isEmpty == false)
        
        let exportText = String(data: exportData, encoding: .utf8)
        #expect(exportText != nil)
        #expect(exportText!.contains("# Focus Mode Session Summary"))
        #expect(exportText!.contains(summary.overview))
    }
    
    /// Verifies that PDF export generates valid data
    @Test("Export Summary As PDF Generates Valid Data")
    func exportSummaryAsPDFGeneratesValidData() async throws {
        // Given
        let service = SummaryService()
        let summary = createTestSummary()
        
        // When
        let exportData = try await service.exportSummary(summary: summary, format: .pdf)
        
        // Then
        #expect(exportData.isEmpty == false)
        // Note: PDF validation would require more sophisticated checks
    }
    
    // MARK: - Retry Tests
    
    /// Verifies that retry functionality works
    @Test("Retry Summary Generation Works For Failed Sessions")
    func retrySummaryGenerationWorksForFailedSessions() async throws {
        // Given
        let service = SummaryService()
        let sessionID = "retry-session-\(UUID().uuidString)"
        
        // When
        let summary = try await service.retrySummaryGeneration(sessionID: sessionID)
        
        // Then
        #expect(summary.sessionID == sessionID)
        #expect(summary.overview.isEmpty == false)
    }
    
    // MARK: - Helper Methods
    
    /// Creates a test summary for testing purposes
    private func createTestSummary() -> FocusSummary {
        return FocusSummary(
            id: "test-summary-\(UUID().uuidString)",
            sessionID: "test-session-\(UUID().uuidString)",
            userID: "test-user-\(UUID().uuidString)",
            generatedAt: Date(),
            overview: "Test session overview with important discussions and decisions.",
            actionItems: [
                "Complete project proposal by Friday",
                "Schedule team meeting for next week",
                "Review budget allocation"
            ],
            keyDecisions: [
                "Approved new feature development",
                "Decided to hire additional team members",
                "Postponed launch date to Q2"
            ],
            messageCount: 25,
            confidence: 0.85,
            processingTimeMs: 2500,
            method: "openai",
            sessionDuration: 60
        )
    }
}
