//
//  DeepLinkingServiceTests.swift
//  MessageAITests
//
//  Unit tests for DeepLinkingService
//  PR #4: Mobile Lifecycle Management
//

import Testing
import Foundation
@testable import MessageAI

/// Tests for DeepLinkingService validation and navigation
struct DeepLinkingServiceTests {
    
    // MARK: - Deep Link Creation
    
    @Test("Deep link created from notification payload")
    func deepLinkCreatedFromNotificationPayload() async throws {
        // Given: DeepLinking service and notification payload
        let service = DeepLinkingService()
        let userInfo: [AnyHashable: Any] = [
            "chatID": "test-chat-123",
            "senderID": "sender-456",
            "senderName": "Test Sender",
            "messageText": "Hello World",
            "messageID": "message-789"
        ]
        
        guard let payload = NotificationPayload(userInfo: userInfo) else {
            throw TestError.payloadCreationFailed
        }
        
        // When: Creating deep link from payload
        let deepLink = service.createDeepLink(from: payload)
        
        // Then: Deep link should be created correctly
        #expect(deepLink.chatID == "test-chat-123")
        #expect(deepLink.messageID == "message-789")
        #expect(deepLink.shouldHighlight == true)
    }
    
    @Test("Deep link without messageID creates chat-only link")
    func deepLinkWithoutMessageIDCreatesChatOnlyLink() async throws {
        // Given: Payload without messageID
        let userInfo: [AnyHashable: Any] = [
            "chatID": "test-chat-123",
            "senderID": "sender-456",
            "senderName": "Test Sender",
            "messageText": "Hello World"
        ]
        
        guard let payload = NotificationPayload(userInfo: userInfo) else {
            throw TestError.payloadCreationFailed
        }
        
        let service = DeepLinkingService()
        
        // When: Creating deep link
        let deepLink = service.createDeepLink(from: payload)
        
        // Then: Should be chat-only type
        #expect(deepLink.messageID == nil)
        if case .chat = deepLink.type {
            #expect(true)
        } else {
            #expect(false, "Expected chat-only deep link type")
        }
    }
    
    // MARK: - Deep Link Validation
    
    @Test("Deep link validation handles invalid chatID gracefully")
    func deepLinkValidationHandlesInvalidChatIDGracefully() async throws {
        // Given: Deep link with invalid chat ID
        let service = DeepLinkingService()
        let deepLink = DeepLink(
            type: .chat(chatID: "nonexistent-chat"),
            chatID: "nonexistent-chat",
            messageID: nil
        )
        
        // When: Validating deep link
        let isValid = await service.validateDeepLink(deepLink)
        
        // Then: Should return false for nonexistent chat
        #expect(isValid == false)
    }
    
    // MARK: - Performance
    
    @Test("Deep link navigation timing measured")
    func deepLinkNavigationTimingMeasured() async throws {
        // Given: DeepLinking service
        let service = DeepLinkingService()
        let deepLink = DeepLink(
            type: .chat(chatID: "test-chat"),
            chatID: "test-chat",
            messageID: nil
        )
        
        // When: Navigating to deep link
        await service.navigateToDeepLink(deepLink)
        
        // Then: Timing should be measured
        let timing = service.measureNavigationTime(for: deepLink)
        #expect(timing >= 0)
    }
}

// MARK: - Test Error

enum TestError: Error {
    case payloadCreationFailed
    case validationFailed
}

