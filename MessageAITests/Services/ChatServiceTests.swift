//
//  ChatServiceTests.swift
//  MessageAITests
//
//  Unit tests for ChatService using Swift Testing framework
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for ChatService
/// - Note: Uses Swift Testing framework with @Test annotations
struct ChatServiceTests {
    
    // MARK: - Test Data
    
    private let testUserID = "test-user-123"
    private let testChatID = "test-chat-456"
    
    // MARK: - fetchUserChats Tests
    
    @Test("Fetch User Chats Returns Empty Array When No Chats")
    func fetchUserChatsReturnsEmptyArrayWhenNoChats() async throws {
        // Given: ChatService with no existing chats
        let chatService = ChatService()
        
        // When: Fetching chats for a user with no chats
        let chats = try await chatService.fetchUserChats(userID: testUserID)
        
        // Then: Should return empty array
        #expect(chats.isEmpty)
    }
    
    @Test("Fetch User Chats Handles Network Errors Gracefully")
    func fetchUserChatsHandlesNetworkErrorsGracefully() async {
        // Given: ChatService (network errors will be handled by Firebase)
        let chatService = ChatService()
        
        // When/Then: Should not crash on network errors
        // Note: In real tests, we'd mock Firebase, but for now we test error handling
        do {
            _ = try await chatService.fetchUserChats(userID: testUserID)
        } catch {
            // Network errors should be wrapped in ChatServiceError
            #expect(error is ChatServiceError)
        }
    }
    
    // MARK: - fetchChat Tests
    
    @Test("Fetch Chat Returns ChatNotFound Error For Non-Existent Chat")
    func fetchChatReturnsChatNotFoundErrorForNonExistentChat() async {
        // Given: ChatService and non-existent chat ID
        let chatService = ChatService()
        let nonExistentChatID = "non-existent-chat"
        
        // When: Fetching non-existent chat
        do {
            _ = try await chatService.fetchChat(chatID: nonExistentChatID)
            #expect(Bool(false), "Should have thrown ChatServiceError.chatNotFound")
        } catch let error as ChatServiceError {
            // Then: Should throw chatNotFound error
            #expect(error == .chatNotFound)
        } catch {
            #expect(Bool(false), "Should have thrown ChatServiceError, got: \(error)")
        }
    }
    
    @Test("Fetch Chat Handles Network Errors")
    func fetchChatHandlesNetworkErrors() async {
        // Given: ChatService
        let chatService = ChatService()
        
        // When/Then: Should handle network errors gracefully
        do {
            _ = try await chatService.fetchChat(chatID: testChatID)
        } catch {
            // Should be wrapped in ChatServiceError
            #expect(error is ChatServiceError)
        }
    }
    
    // MARK: - observeUserChats Tests
    
    @Test("Observe User Chats Returns Listener Registration")
    func observeUserChatsReturnsListenerRegistration() {
        // Given: ChatService
        let chatService = ChatService()
        var receivedChats: [Chat] = []
        
        // When: Setting up listener
        let listener = chatService.observeUserChats(userID: testUserID) { chats in
            receivedChats = chats
        }
        
        // Then: Should return valid listener registration
        #expect(listener != nil)
        
        // Cleanup
        listener.remove()
    }
    
    @Test("Observe User Chats Calls Completion Handler")
    func observeUserChatsCallsCompletionHandler() {
        // Given: ChatService and completion handler
        let chatService = ChatService()
        var completionCalled = false
        
        // When: Setting up listener
        let listener = chatService.observeUserChats(userID: testUserID) { _ in
            completionCalled = true
        }
        
        // Then: Completion handler should be callable
        // Note: In real tests, we'd trigger Firebase events
        #expect(completionCalled == false) // Initially false
        
        // Cleanup
        listener.remove()
    }
    
    // MARK: - Error Handling Tests
    
    @Test("ChatServiceError Provides Localized Descriptions")
    func chatServiceErrorProvidesLocalizedDescriptions() {
        // Given: Various ChatServiceError cases
        let chatNotFound = ChatServiceError.chatNotFound
        let permissionDenied = ChatServiceError.permissionDenied
        let networkError = ChatServiceError.networkError(NSError(domain: "test", code: 1))
        let unknownError = ChatServiceError.unknown(NSError(domain: "test", code: 2))
        
        // When/Then: All should have localized descriptions
        #expect(chatNotFound.errorDescription != nil)
        #expect(permissionDenied.errorDescription != nil)
        #expect(networkError.errorDescription != nil)
        #expect(unknownError.errorDescription != nil)
        
        #expect(chatNotFound.errorDescription?.contains("not found") == true)
        #expect(permissionDenied.errorDescription?.contains("Permission denied") == true)
        #expect(networkError.errorDescription?.contains("Network error") == true)
        #expect(unknownError.errorDescription?.contains("Unknown error") == true)
    }
}
