//
//  FocusSummaryUITests.swift
//  MessageAIUITests
//
//  UI tests for Focus Mode session summary functionality
//

import XCTest

final class FocusSummaryUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Summary Modal Tests
    
    /// Verifies that summary modal appears when Focus Mode is deactivated
    func testFocusModeDeactivationShowsSummaryModal() throws {
        // Given: User is in Focus Mode
        // Navigate to Focus Mode (assuming there's a Focus Mode button)
        let focusModeButton = app.buttons["Focus Mode"]
        if focusModeButton.exists {
            focusModeButton.tap()
        }
        
        // Wait for Focus Mode to be active
        let focusModeActive = app.staticTexts["Focus Mode Active"]
        XCTAssertTrue(focusModeActive.waitForExistence(timeout: 5))
        
        // When: User deactivates Focus Mode
        let deactivateButton = app.buttons["Deactivate Focus Mode"]
        XCTAssertTrue(deactivateButton.exists)
        deactivateButton.tap()
        
        // Then: Summary modal should appear
        let summaryModal = app.navigationBars["Session Summary"]
        XCTAssertTrue(summaryModal.waitForExistence(timeout: 10))
    }
    
    /// Verifies that summary modal displays loading state
    func testSummaryModalShowsLoadingState() throws {
        // Given: User deactivates Focus Mode
        // (Setup similar to previous test)
        
        // When: Summary modal appears
        let summaryModal = app.navigationBars["Session Summary"]
        XCTAssertTrue(summaryModal.waitForExistence(timeout: 10))
        
        // Then: Loading state should be visible initially
        let loadingText = app.staticTexts["Generating Summary..."]
        XCTAssertTrue(loadingText.exists)
        
        let progressView = app.progressIndicators.firstMatch
        XCTAssertTrue(progressView.exists)
    }
    
    /// Verifies that summary content displays correctly
    func testSummaryModalDisplaysContentCorrectly() throws {
        // Given: Summary has been generated
        // (Setup similar to previous tests)
        
        // When: Summary modal is displayed
        let summaryModal = app.navigationBars["Session Summary"]
        XCTAssertTrue(summaryModal.waitForExistence(timeout: 15))
        
        // Then: Summary content should be visible
        let overviewSection = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Overview'")).firstMatch
        XCTAssertTrue(overviewSection.exists)
        
        let actionItemsSection = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Action Items'")).firstMatch
        XCTAssertTrue(actionItemsSection.exists)
        
        let keyDecisionsSection = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Key Decisions'")).firstMatch
        XCTAssertTrue(keyDecisionsSection.exists)
    }
    
    /// Verifies that summary modal can be dismissed
    func testSummaryModalCanBeDismissed() throws {
        // Given: Summary modal is displayed
        // (Setup similar to previous tests)
        
        // When: User taps close button
        let closeButton = app.buttons["Close"]
        XCTAssertTrue(closeButton.exists)
        closeButton.tap()
        
        // Then: Modal should be dismissed
        let summaryModal = app.navigationBars["Session Summary"]
        XCTAssertFalse(summaryModal.exists)
    }
    
    // MARK: - Export Functionality Tests
    
    /// Verifies that export menu appears when export button is tapped
    func testExportButtonShowsExportMenu() throws {
        // Given: Summary modal is displayed with content
        // (Setup similar to previous tests)
        
        // When: User taps export button
        let exportButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(exportButton.exists)
        exportButton.tap()
        
        // Then: Export menu should appear
        let exportMenu = app.menus.firstMatch
        XCTAssertTrue(exportMenu.exists)
        
        // Verify export options
        let textExport = app.menuItems["Export as Text"]
        XCTAssertTrue(textExport.exists)
        
        let markdownExport = app.menuItems["Export as Markdown"]
        XCTAssertTrue(markdownExport.exists)
        
        let pdfExport = app.menuItems["Export as PDF"]
        XCTAssertTrue(pdfExport.exists)
    }
    
    /// Verifies that text export works
    func testTextExportWorks() throws {
        // Given: Export menu is displayed
        // (Setup similar to previous test)
        
        // When: User selects text export
        let textExport = app.menuItems["Export as Text"]
        XCTAssertTrue(textExport.exists)
        textExport.tap()
        
        // Then: Share sheet should appear
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 5))
    }
    
    /// Verifies that markdown export works
    func testMarkdownExportWorks() throws {
        // Given: Export menu is displayed
        // (Setup similar to previous test)
        
        // When: User selects markdown export
        let markdownExport = app.menuItems["Export as Markdown"]
        XCTAssertTrue(markdownExport.exists)
        markdownExport.tap()
        
        // Then: Share sheet should appear
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 5))
    }
    
    /// Verifies that PDF export works
    func testPDFExportWorks() throws {
        // Given: Export menu is displayed
        // (Setup similar to previous test)
        
        // When: User selects PDF export
        let pdfExport = app.menuItems["Export as PDF"]
        XCTAssertTrue(pdfExport.exists)
        pdfExport.tap()
        
        // Then: Share sheet should appear
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 5))
    }
    
    // MARK: - Error Handling Tests
    
    /// Verifies that error state is displayed when summary generation fails
    func testSummaryGenerationErrorShowsErrorState() throws {
        // Given: Network is unavailable or API fails
        // Note: This would require mocking network conditions
        
        // When: User deactivates Focus Mode
        // (Setup similar to previous tests)
        
        // Then: Error state should be displayed
        let errorIcon = app.images["exclamationmark.triangle"]
        XCTAssertTrue(errorIcon.waitForExistence(timeout: 15))
        
        let errorTitle = app.staticTexts["Summary Generation Failed"]
        XCTAssertTrue(errorTitle.exists)
        
        let retryButton = app.buttons["Retry"]
        XCTAssertTrue(retryButton.exists)
    }
    
    /// Verifies that retry button works
    func testRetryButtonWorks() throws {
        // Given: Error state is displayed
        // (Setup similar to previous test)
        
        // When: User taps retry button
        let retryButton = app.buttons["Retry"]
        XCTAssertTrue(retryButton.exists)
        retryButton.tap()
        
        // Then: Loading state should appear again
        let loadingText = app.staticTexts["Generating Summary..."]
        XCTAssertTrue(loadingText.waitForExistence(timeout: 5))
    }
    
    // MARK: - Empty State Tests
    
    /// Verifies that empty state is displayed for sessions with no messages
    func testEmptySessionShowsEmptyState() throws {
        // Given: Focus Mode session with no messages
        // Note: This would require setting up a session with no messages
        
        // When: User deactivates Focus Mode
        // (Setup similar to previous tests)
        
        // Then: Empty state should be displayed
        let emptyIcon = app.images["doc.text"]
        XCTAssertTrue(emptyIcon.waitForExistence(timeout: 15))
        
        let emptyTitle = app.staticTexts["No Summary Available"]
        XCTAssertTrue(emptyTitle.exists)
        
        let emptyMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Unable to generate'")).firstMatch
        XCTAssertTrue(emptyMessage.exists)
    }
    
    // MARK: - Performance Tests
    
    /// Verifies that summary modal appears within performance target
    func testSummaryModalAppearsWithinPerformanceTarget() throws {
        // Given: User is in Focus Mode
        // (Setup similar to previous tests)
        
        // When: User deactivates Focus Mode
        let startTime = CFAbsoluteTimeGetCurrent()
        let deactivateButton = app.buttons["Deactivate Focus Mode"]
        deactivateButton.tap()
        
        // Then: Modal should appear within 500ms
        let summaryModal = app.navigationBars["Session Summary"]
        XCTAssertTrue(summaryModal.waitForExistence(timeout: 1))
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        XCTAssertLessThan(duration, 0.5, "Modal should appear within 500ms")
    }
    
    /// Verifies that summary generation completes within performance target
    func testSummaryGenerationCompletesWithinPerformanceTarget() throws {
        // Given: User deactivates Focus Mode
        // (Setup similar to previous tests)
        
        // When: Summary generation starts
        let startTime = CFAbsoluteTimeGetCurrent()
        let deactivateButton = app.buttons["Deactivate Focus Mode"]
        deactivateButton.tap()
        
        // Then: Summary should be generated within 10 seconds
        let summaryContent = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Overview'")).firstMatch
        XCTAssertTrue(summaryContent.waitForExistence(timeout: 10))
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime
        XCTAssertLessThan(duration, 10.0, "Summary should be generated within 10 seconds")
    }
}
