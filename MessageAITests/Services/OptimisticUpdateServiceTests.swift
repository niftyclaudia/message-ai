//
//  OptimisticUpdateServiceTests.swift
//  MessageAITests
//
//  Unit tests for OptimisticUpdateService
//

import Testing
import Foundation
@testable import MessageAI

/// Unit tests for OptimisticUpdateService
struct OptimisticUpdateServiceTests {
    
    // MARK: - Test Properties
    
    private var service: OptimisticUpdateService!
    private let testChatID = "test-chat-123"
    private let testUserID = "test-user-123"
    
    // MARK: - Setup
    
    init() {
        service = OptimisticUpdateService()
    }
    
    // MARK: - Add Optimistic Message Tests
    
    @Test("Add Optimistic Message Successfully")
    func addOptimisticMessageSuccessfully() async throws {
        // Given
        let message = createTestOptimisticMessage()
        
        // When
        await service.addOptimisticMessage(message)
        
        // Then
        let optimisticMessages = await service.getOptimisticMessages(for: testChatID)
        #expect(optimisticMessages.count == 1)
        #expect(optimisticMessages.first?.id == message.id)
        #expect(optimisticMessages.first?.text == message.text)
        #expect(optimisticMessages.first?.status == .sending)
    }
    
    @Test("Add Multiple Optimistic Messages")
    func addMultipleOptimisticMessages() async throws {
        // Given
        let message1 = createTestOptimisticMessage(id: "msg1")
        let message2 = createTestOptimisticMessage(id: "msg2")
        
        // When
        await service.addOptimisticMessage(message1)
        await service.addOptimisticMessage(message2)
        
        // Then
        let optimisticMessages = await service.getOptimisticMessages(for: testChatID)
        #expect(optimisticMessages.count == 2)
        #expect(optimisticMessages.contains { $0.id == "msg1" })
        #expect(optimisticMessages.contains { $0.id == "msg2" })
    }
    
    // MARK: - Update Status Tests
    
    @Test("Update Optimistic Message Status")
    func updateOptimisticMessageStatus() async throws {
        // Given
        let message = createTestOptimisticMessage()
        await service.addOptimisticMessage(message)
        
        // When
        await service.updateOptimisticMessageStatus(message.id, status: .sent)
        
        // Then
        let optimisticMessages = await service.getOptimisticMessages(for: testChatID)
        #expect(optimisticMessages.first?.status == .sent)
        #expect(optimisticMessages.first?.lastAttempt != nil)
    }
    
    @Test("Update Status to Failed Increases Retry Count")
    func updateStatusToFailedIncreasesRetryCount() async throws {
        // Given
        let message = createTestOptimisticMessage()
        await service.addOptimisticMessage(message)
        
        // When
        await service.updateOptimisticMessageStatus(message.id, status: .failed)
        
        // Then
        let optimisticMessages = await service.getOptimisticMessages(for: testChatID)
        #expect(optimisticMessages.first?.status == .failed)
        #expect(optimisticMessages.first?.retryCount == 1)
    }
    
    // MARK: - Remove Message Tests
    
    @Test("Remove Optimistic Message")
    func removeOptimisticMessage() async throws {
        // Given
        let message = createTestOptimisticMessage()
        await service.addOptimisticMessage(message)
        
        // When
        await service.removeOptimisticMessage(message.id)
        
        // Then
        let optimisticMessages = await service.getOptimisticMessages(for: testChatID)
        #expect(optimisticMessages.isEmpty)
    }
    
    @Test("Remove Non-Existent Message Does Not Crash")
    func removeNonExistentMessageDoesNotCrash() async throws {
        // When
        await service.removeOptimisticMessage("non-existent-id")
        
        // Then
        let optimisticMessages = await service.getOptimisticMessages(for: testChatID)
        #expect(optimisticMessages.isEmpty)
    }
    
    // MARK: - Clear Messages Tests
    
    @Test("Clear Optimistic Messages for Chat")
    func clearOptimisticMessagesForChat() async throws {
        // Given
        let message1 = createTestOptimisticMessage(id: "msg1", chatID: testChatID)
        let message2 = createTestOptimisticMessage(id: "msg2", chatID: "other-chat")
        await service.addOptimisticMessage(message1)
        await service.addOptimisticMessage(message2)
        
        // When
        await service.clearOptimisticMessages(for: testChatID)
        
        // Then
        let testChatMessages = await service.getOptimisticMessages(for: testChatID)
        let otherChatMessages = await service.getOptimisticMessages(for: "other-chat")
        #expect(testChatMessages.isEmpty)
        #expect(otherChatMessages.count == 1)
    }
    
    @Test("Clear All Optimistic Messages")
    func clearAllOptimisticMessages() async throws {
        // Given
        let message1 = createTestOptimisticMessage(id: "msg1")
        let message2 = createTestOptimisticMessage(id: "msg2")
        await service.addOptimisticMessage(message1)
        await service.addOptimisticMessage(message2)
        
        // When
        await service.clearAllOptimisticMessages()
        
        // Then
        let allMessages = await service.getAllOptimisticMessages()
        #expect(allMessages.isEmpty)
    }
    
    // MARK: - Check Message Tests
    
    @Test("Check if Message is Optimistic")
    func checkIfMessageIsOptimistic() async throws {
        // Given
        let message = createTestOptimisticMessage()
        await service.addOptimisticMessage(message)
        
        // When & Then
        let isOptimistic = await service.isOptimisticMessage(message.id)
        #expect(isOptimistic == true)
        
        let isNotOptimistic = await service.isOptimisticMessage("non-existent-id")
        #expect(isNotOptimistic == false)
    }
    
    @Test("Get Optimistic Message Status")
    func getOptimisticMessageStatus() async throws {
        // Given
        let message = createTestOptimisticMessage()
        await service.addOptimisticMessage(message)
        
        // When
        let status = await service.getOptimisticMessageStatus(message.id)
        
        // Then
        #expect(status == .sending)
    }
    
    @Test("Get Status for Non-Existent Message Returns Nil")
    func getStatusForNonExistentMessageReturnsNil() async throws {
        // When
        let status = await service.getOptimisticMessageStatus("non-existent-id")
        
        // Then
        #expect(status == nil)
    }
    
    // MARK: - Retry Message Tests
    
    @Test("Retry Optimistic Message")
    func retryOptimisticMessage() async throws {
        // Given
        let message = createTestOptimisticMessage()
        await service.addOptimisticMessage(message)
        await service.updateOptimisticMessageStatus(message.id, status: .failed)
        
        // When
        await service.retryOptimisticMessage(message.id)
        
        // Then
        let optimisticMessages = await service.getOptimisticMessages(for: testChatID)
        #expect(optimisticMessages.first?.status == .sending)
        #expect(optimisticMessages.first?.retryCount == 2) // 1 from failed + 1 from retry
    }
    
    // MARK: - Helper Methods
    
    private func createTestOptimisticMessage(
        id: String = "test-message-123",
        chatID: String = "test-chat-123",
        text: String = "Test message",
        status: MessageStatus = .sending
    ) -> OptimisticMessage {
        return OptimisticMessage(
            id: id,
            chatID: chatID,
            text: text,
            timestamp: Date(),
            senderID: testUserID,
            status: status
        )
    }
}
