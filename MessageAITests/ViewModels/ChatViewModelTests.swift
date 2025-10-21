//
//  ChatViewModelTests.swift
//  MessageAITests
//
//  Unit tests for ChatViewModel functionality
//

import Testing
@testable import MessageAI

@Suite("Chat ViewModel Tests")
struct ChatViewModelTests {
    
    /// Verifies that ChatViewModel initializes correctly
    @Test("ChatViewModel Initializes With Current User ID")
    func chatViewModelInitializesWithCurrentUserID() {
        // Given
        let userID = "test-user-123"
        
        // When
        let viewModel = ChatViewModel(currentUserID: userID)
        
        // Then
        #expect(viewModel.currentUserID == userID)
        #expect(viewModel.messages.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
    }
    
    /// Verifies that message sender detection works correctly
    @Test("Is Message From Current User Returns Correct Value")
    func isMessageFromCurrentUserReturnsCorrectValue() {
        // Given
        let currentUserID = "user-123"
        let otherUserID = "user-456"
        let viewModel = ChatViewModel(currentUserID: currentUserID)
        
        let currentUserMessage = Message(
            id: "1",
            chatID: "chat1",
            senderID: currentUserID,
            text: "Hello",
            timestamp: Date()
        )
        
        let otherUserMessage = Message(
            id: "2",
            chatID: "chat1",
            senderID: otherUserID,
            text: "Hi there",
            timestamp: Date()
        )
        
        // When/Then
        #expect(viewModel.isMessageFromCurrentUser(message: currentUserMessage) == true)
        #expect(viewModel.isMessageFromCurrentUser(message: otherUserMessage) == false)
    }
    
    /// Verifies that timestamp formatting works correctly
    @Test("Format Timestamp Returns User-Friendly String")
    func formatTimestampReturnsUserFriendlyString() {
        // Given
        let viewModel = ChatViewModel(currentUserID: "user-123")
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        // When
        let formattedNow = viewModel.formatTimestamp(date: now)
        let formattedPast = viewModel.formatTimestamp(date: oneMinuteAgo)
        
        // Then
        #expect(!formattedNow.isEmpty)
        #expect(!formattedPast.isEmpty)
        #expect(formattedNow != formattedPast)
    }
    
    /// Verifies that sender display name works correctly
    @Test("Get Sender Display Name Returns Correct Name")
    func getSenderDisplayNameReturnsCorrectName() {
        // Given
        let currentUserID = "user-123"
        let otherUserID = "user-456"
        let viewModel = ChatViewModel(currentUserID: currentUserID)
        
        let currentUserMessage = Message(
            id: "1",
            chatID: "chat1",
            senderID: currentUserID,
            text: "Hello",
            timestamp: Date()
        )
        
        let otherUserMessage = Message(
            id: "2",
            chatID: "chat1",
            senderID: otherUserID,
            text: "Hi",
            timestamp: Date(),
            senderName: "John Doe"
        )
        
        // When/Then
        #expect(viewModel.getSenderDisplayName(message: currentUserMessage) == "You")
        #expect(viewModel.getSenderDisplayName(message: otherUserMessage) == "John Doe")
    }
}
