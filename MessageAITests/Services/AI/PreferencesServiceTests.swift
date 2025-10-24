//
//  PreferencesServiceTests.swift
//  MessageAITests
//
//  Unit tests for PreferencesService
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for PreferencesService
/// - Note: Tests CRUD operations, validation, and learning data logging
struct PreferencesServiceTests {
    
    // MARK: - Test Data
    
    private let mockUserID = "test-user-123"
    
    private func createMockPreferences() -> UserPreferences {
        UserPreferences(
            id: UserPreferences.documentId,
            focusHours: FocusHours(
                enabled: true,
                startTime: "10:00",
                endTime: "14:00",
                daysOfWeek: [1, 2, 3, 4, 5]
            ),
            urgentContacts: ["contact1", "contact2"],
            urgentKeywords: ["urgent", "critical", "asap", "emergency"],
            priorityRules: PriorityRules(
                mentionsWithDeadlines: true,
                fyiMessages: true,
                questionsNeedingResponse: false,
                approvalsAndDecisions: true
            ),
            communicationTone: .friendly,
            createdAt: Date(),
            updatedAt: Date(),
            version: 1
        )
    }
    
    // MARK: - Validation Tests
    
    @Test("Valid Preferences Pass Validation")
    func validPreferencesPassValidation() {
        // Given: Valid preferences
        let preferences = createMockPreferences()
        
        // Then: Should be valid
        #expect(preferences.isValid)
        #expect(preferences.validationError == nil)
    }
    
    @Test("Too Many Contacts Fail Validation")
    func tooManyContactsFailValidation() {
        // Given: Preferences with 21 contacts (max is 20)
        var preferences = createMockPreferences()
        preferences.urgentContacts = Array(1...21).map { "contact\($0)" }
        
        // Then: Should be invalid
        #expect(!preferences.isValid)
        #expect(preferences.validationError != nil)
        #expect(preferences.validationError?.contains("20") == true)
    }
    
    @Test("Too Few Keywords Fail Validation")
    func tooFewKeywordsFailValidation() {
        // Given: Preferences with only 2 keywords (min is 3)
        var preferences = createMockPreferences()
        preferences.urgentKeywords = ["urgent", "critical"]
        
        // Then: Should be invalid
        #expect(!preferences.isValid)
        #expect(preferences.validationError != nil)
        #expect(preferences.validationError?.contains("3") == true)
    }
    
    @Test("Too Many Keywords Fail Validation")
    func tooManyKeywordsFailValidation() {
        // Given: Preferences with 51 keywords (max is 50)
        var preferences = createMockPreferences()
        preferences.urgentKeywords = Array(1...51).map { "keyword\($0)" }
        
        // Then: Should be invalid
        #expect(!preferences.isValid)
        #expect(preferences.validationError != nil)
        #expect(preferences.validationError?.contains("50") == true)
    }
    
    @Test("Invalid Focus Hours Fail Validation")
    func invalidFocusHoursFailValidation() {
        // Given: Preferences with invalid focus hours (start >= end)
        var preferences = createMockPreferences()
        preferences.focusHours = FocusHours(
            enabled: true,
            startTime: "14:00",
            endTime: "10:00", // End before start
            daysOfWeek: [1, 2, 3]
        )
        
        // Then: Should be invalid
        #expect(!preferences.isValid)
        #expect(!preferences.focusHours.isValid)
    }
    
    // MARK: - Focus Hours Tests
    
    @Test("Focus Hours Validation With Valid Times")
    func focusHoursValidationWithValidTimes() {
        // Given: Valid focus hours
        let focusHours = FocusHours(
            enabled: true,
            startTime: "09:00",
            endTime: "17:00",
            daysOfWeek: [1, 2, 3, 4, 5]
        )
        
        // Then: Should be valid
        #expect(focusHours.isValid)
    }
    
    @Test("Focus Hours Validation With Invalid Times")
    func focusHoursValidationWithInvalidTimes() {
        // Given: Invalid focus hours (start >= end)
        let focusHours = FocusHours(
            enabled: true,
            startTime: "17:00",
            endTime: "09:00",
            daysOfWeek: [1, 2, 3, 4, 5]
        )
        
        // Then: Should be invalid
        #expect(!focusHours.isValid)
    }
    
    @Test("Focus Hours Validation With Invalid Days")
    func focusHoursValidationWithInvalidDays() {
        // Given: Focus hours with invalid day numbers
        let focusHours = FocusHours(
            enabled: true,
            startTime: "09:00",
            endTime: "17:00",
            daysOfWeek: [0, 1, 7, 8] // 7 and 8 are invalid
        )
        
        // Then: Should be invalid
        #expect(!focusHours.isValid)
    }
    
    // MARK: - Default Preferences Tests
    
    @Test("Default Preferences Are Valid")
    func defaultPreferencesAreValid() {
        // Given: Default preferences
        let preferences = UserPreferences.defaultPreferences
        
        // Then: Should be valid
        #expect(preferences.isValid)
        #expect(preferences.urgentKeywords.count >= 3)
        #expect(preferences.urgentContacts.isEmpty)
        #expect(preferences.communicationTone == .friendly)
        #expect(!preferences.focusHours.enabled)
    }
    
    // MARK: - Learning Data Entry Tests
    
    @Test("Learning Data Entry Creation")
    func learningDataEntryCreation() {
        // Given: Learning data entry
        let messageContext = MessageContext(
            senderUserId: "sender123",
            messagePreview: "This is a test message",
            hadDeadline: true,
            hadMention: true,
            matchedKeywords: ["urgent", "asap"]
        )
        
        let now = Date()
        let entry = LearningDataEntry(
            id: "entry123",
            messageId: "msg123",
            chatId: "chat123",
            originalCategory: .urgent,
            userCategory: .canWait,
            timestamp: now,
            messageContext: messageContext,
            createdAt: now
        )
        
        // Then: Should have correct properties
        #expect(entry.id == "entry123")
        #expect(entry.messageId == "msg123")
        #expect(entry.originalCategory == .urgent)
        #expect(entry.userCategory == .canWait)
        #expect(entry.messageContext.senderUserId == "sender123")
        #expect(entry.messageContext.hadDeadline == true)
        #expect(entry.messageContext.matchedKeywords.count == 2)
    }
    
    @Test("Message Context Truncates Long Previews")
    func messageContextTruncatesLongPreviews() {
        // Given: Message context with long preview (>100 chars)
        let longMessage = String(repeating: "a", count: 200)
        let context = MessageContext(
            senderUserId: "sender123",
            messagePreview: longMessage,
            hadDeadline: false,
            hadMention: false,
            matchedKeywords: []
        )
        
        // Then: Preview should be truncated to 100 characters
        #expect(context.messagePreview.count == 100)
        #expect(context.messagePreview == String(repeating: "a", count: 100))
    }
    
    // MARK: - Communication Tone Tests
    
    @Test("Communication Tone Display Names")
    func communicationToneDisplayNames() {
        // Then: Each tone should have correct display name
        #expect(CommunicationTone.professional.displayName == "Professional")
        #expect(CommunicationTone.friendly.displayName == "Friendly")
        #expect(CommunicationTone.supportive.displayName == "Supportive")
    }
    
    @Test("Communication Tone Descriptions")
    func communicationToneDescriptions() {
        // Then: Each tone should have description
        #expect(!CommunicationTone.professional.description.isEmpty)
        #expect(!CommunicationTone.friendly.description.isEmpty)
        #expect(!CommunicationTone.supportive.description.isEmpty)
    }
    
    // MARK: - Message Category Tests
    
    @Test("Message Category Display Names")
    func messageCategoryDisplayNames() {
        // Then: Each category should have correct display name
        #expect(MessageCategory.urgent.displayName == "Urgent")
        #expect(MessageCategory.canWait.displayName == "Can Wait")
        #expect(MessageCategory.aiHandled.displayName == "AI Handled")
    }
    
    // MARK: - Priority Rules Tests
    
    @Test("Default Priority Rules")
    func defaultPriorityRules() {
        // Given: Default rules
        let rules = PriorityRules.defaultRules
        
        // Then: Should have sensible defaults
        #expect(rules.mentionsWithDeadlines == true)
        #expect(rules.fyiMessages == true)
        #expect(rules.questionsNeedingResponse == false)
        #expect(rules.approvalsAndDecisions == true)
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Exactly 3 Keywords Pass Validation")
    func exactlyThreeKeywordsPassValidation() {
        // Given: Preferences with exactly 3 keywords (minimum)
        var preferences = createMockPreferences()
        preferences.urgentKeywords = ["urgent", "critical", "asap"]
        
        // Then: Should be valid
        #expect(preferences.isValid)
    }
    
    @Test("Exactly 20 Contacts Pass Validation")
    func exactlyTwentyContactsPassValidation() {
        // Given: Preferences with exactly 20 contacts (maximum)
        var preferences = createMockPreferences()
        preferences.urgentContacts = Array(1...20).map { "contact\($0)" }
        
        // Then: Should be valid
        #expect(preferences.isValid)
    }
    
    @Test("Exactly 50 Keywords Pass Validation")
    func exactlyFiftyKeywordsPassValidation() {
        // Given: Preferences with exactly 50 keywords (maximum)
        var preferences = createMockPreferences()
        preferences.urgentKeywords = Array(1...50).map { "keyword\($0)" }
        
        // Then: Should be valid
        #expect(preferences.isValid)
    }
    
    @Test("Empty Urgent Contacts Are Valid")
    func emptyUrgentContactsAreValid() {
        // Given: Preferences with no urgent contacts
        var preferences = createMockPreferences()
        preferences.urgentContacts = []
        
        // Then: Should still be valid (contacts are optional)
        #expect(preferences.isValid)
    }
    
    @Test("Disabled Focus Hours Are Valid")
    func disabledFocusHoursAreValid() {
        // Given: Preferences with disabled focus hours
        var preferences = createMockPreferences()
        preferences.focusHours.enabled = false
        
        // Then: Should be valid regardless of time validation
        #expect(preferences.isValid)
    }
}

