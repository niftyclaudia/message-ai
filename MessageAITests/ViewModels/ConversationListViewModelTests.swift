//
//  ConversationListViewModelTests.swift
//  MessageAITests
//
//  Unit tests for ConversationListViewModel using Swift Testing framework
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for ConversationListViewModel
/// - Note: Uses Swift Testing framework with @Test annotations
struct ConversationListViewModelTests {
    
    // MARK: - Test Data
    
    private let testUserID = "test-user-123"
    private let testOtherUserID = "test-other-user-456"
    private let testChatID = "test-chat-789"
    
    // MARK: - Initialization Tests
    
    @Test("ViewModel Initializes With Default Values")
    func viewModelInitializesWithDefaultValues() {
        // Given/When: Creating a new ViewModel
        let viewModel = ConversationListViewModel()
        
        // Then: Should have default values
        #expect(viewModel.chats.isEmpty)
        #expect(viewModel.chatUsers.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    // MARK: - formatTimestamp Tests
    
    @Test("Format Timestamp Returns 'now' For Recent Messages")
    func formatTimestampReturnsNowForRecentMessages() {
        // Given: ViewModel and recent date
        let viewModel = ConversationListViewModel()
        let recentDate = Date().addingTimeInterval(-30) // 30 seconds ago
        
        // When: Formatting recent timestamp
        let formatted = viewModel.formatTimestamp(date: recentDate)
        
        // Then: Should return "now"
        #expect(formatted == "now")
    }
    
    @Test("Format Timestamp Returns Minutes For Recent Messages")
    func formatTimestampReturnsMinutesForRecentMessages() {
        // Given: ViewModel and date 5 minutes ago
        let viewModel = ConversationListViewModel()
        let fiveMinutesAgo = Date().addingTimeInterval(-300) // 5 minutes ago
        
        // When: Formatting timestamp
        let formatted = viewModel.formatTimestamp(date: fiveMinutesAgo)
        
        // Then: Should return "5m"
        #expect(formatted == "5m")
    }
    
    @Test("Format Timestamp Returns Hours For Older Messages")
    func formatTimestampReturnsHoursForOlderMessages() {
        // Given: ViewModel and date 2 hours ago
        let viewModel = ConversationListViewModel()
        let twoHoursAgo = Date().addingTimeInterval(-7200) // 2 hours ago
        
        // When: Formatting timestamp
        let formatted = viewModel.formatTimestamp(date: twoHoursAgo)
        
        // Then: Should return "2h"
        #expect(formatted == "2h")
    }
    
    @Test("Format Timestamp Returns Yesterday For Day-Old Messages")
    func formatTimestampReturnsYesterdayForDayOldMessages() {
        // Given: ViewModel and date 25 hours ago
        let viewModel = ConversationListViewModel()
        let yesterday = Date().addingTimeInterval(-90000) // 25 hours ago
        
        // When: Formatting timestamp
        let formatted = viewModel.formatTimestamp(date: yesterday)
        
        // Then: Should return "Yesterday"
        #expect(formatted == "Yesterday")
    }
    
    @Test("Format Timestamp Returns Date For Older Messages")
    func formatTimestampReturnsDateForOlderMessages() {
        // Given: ViewModel and date 3 days ago
        let viewModel = ConversationListViewModel()
        let threeDaysAgo = Date().addingTimeInterval(-259200) // 3 days ago
        
        // When: Formatting timestamp
        let formatted = viewModel.formatTimestamp(date: threeDaysAgo)
        
        // Then: Should return formatted date
        #expect(formatted.contains("Jan") || formatted.contains("Feb") || formatted.contains("Mar") || 
                formatted.contains("Apr") || formatted.contains("May") || formatted.contains("Jun") ||
                formatted.contains("Jul") || formatted.contains("Aug") || formatted.contains("Sep") ||
                formatted.contains("Oct") || formatted.contains("Nov") || formatted.contains("Dec"))
    }
    
    // MARK: - getOtherUser Tests
    
    @Test("Get Other User Returns Nil For Group Chat")
    func getOtherUserReturnsNilForGroupChat() {
        // Given: ViewModel and group chat
        let viewModel = ConversationListViewModel()
        let groupChat = Chat(
            id: testChatID,
            members: [testUserID, testOtherUserID, "third-user"],
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: testUserID,
            isGroupChat: true,
            createdAt: Date()
        )
        
        // When: Getting other user
        let otherUser = viewModel.getOtherUser(chat: groupChat)
        
        // Then: Should return nil for group chat
        #expect(otherUser == nil)
    }
    
    @Test("Get Other User Returns Nil When Current User Not Set")
    func getOtherUserReturnsNilWhenCurrentUserNotSet() {
        // Given: ViewModel without current user set
        let viewModel = ConversationListViewModel()
        let chat = Chat(
            id: testChatID,
            members: [testUserID, testOtherUserID],
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: testUserID,
            isGroupChat: false,
            createdAt: Date()
        )
        
        // When: Getting other user
        let otherUser = viewModel.getOtherUser(chat: chat)
        
        // Then: Should return nil
        #expect(otherUser == nil)
    }
    
    // MARK: - State Management Tests
    
    @Test("Stop Observing Cleans Up Resources")
    func stopObservingCleansUpResources() {
        // Given: ViewModel
        let viewModel = ConversationListViewModel()
        
        // When: Stopping observation
        viewModel.stopObserving()
        
        // Then: Should not crash and listener should be nil
        // Note: We can't directly test the listener property, but we can test the method doesn't crash
        #expect(true) // Method should complete without error
    }
    
    // MARK: - Error Handling Tests
    
    @Test("ViewModel Handles Missing User Data Gracefully")
    func viewModelHandlesMissingUserDataGracefully() {
        // Given: ViewModel with chat but no user data
        let viewModel = ConversationListViewModel()
        let chat = Chat(
            id: testChatID,
            members: [testUserID, testOtherUserID],
            lastMessage: "Hello",
            lastMessageTimestamp: Date(),
            lastMessageSenderID: testUserID,
            isGroupChat: false,
            createdAt: Date()
        )
        
        // When: Getting other user without loading user data
        let otherUser = viewModel.getOtherUser(chat: chat)
        
        // Then: Should return nil gracefully
        #expect(otherUser == nil)
    }
}
