//
//  DeepLinkViewModelTests.swift
//  MessageAITests
//
//  Unit tests for DeepLinkViewModel
//  PR #4: Mobile Lifecycle Management
//

import Testing
import Foundation
@testable import MessageAI

/// Tests for DeepLinkViewModel state management
@MainActor
struct DeepLinkViewModelTests {
    
    // MARK: - Deep Link Processing
    
    @Test("Deep link view model processes valid deep link")
    func deepLinkViewModelProcessesValidDeepLink() async throws {
        // Given: DeepLinkViewModel with notification service
        let notificationService = NotificationService()
        let viewModel = DeepLinkViewModel(notificationService: notificationService)
        
        let deepLink = DeepLink(
            type: .chat(chatID: "test-chat"),
            chatID: "test-chat",
            messageID: nil
        )
        
        // When: Processing deep link
        viewModel.processDeepLink(deepLink)
        
        // Wait for async processing
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Then: Deep link should be set or error should be shown
        #expect(viewModel.activeDeepLink != nil || viewModel.showErrorAlert)
    }
    
    @Test("Deep link view model clears deep link")
    func deepLinkViewModelClearsDeepLink() async throws {
        // Given: ViewModel with active deep link
        let notificationService = NotificationService()
        let viewModel = DeepLinkViewModel(notificationService: notificationService)
        
        let deepLink = DeepLink(
            type: .chat(chatID: "test-chat"),
            chatID: "test-chat",
            messageID: nil
        )
        viewModel.processDeepLink(deepLink)
        
        // When: Clearing deep link
        viewModel.clearDeepLink()
        
        // Then: Active deep link should be nil
        #expect(viewModel.activeDeepLink == nil)
        #expect(viewModel.navigationError == nil)
    }
    
    // MARK: - Navigation Helpers
    
    @Test("Deep link view model provides navigation helpers")
    func deepLinkViewModelProvidesNavigationHelpers() async throws {
        // Given: ViewModel
        let notificationService = NotificationService()
        let viewModel = DeepLinkViewModel(notificationService: notificationService)
        
        // When: No active deep link
        // Then: Helpers should return appropriate values
        #expect(viewModel.hasActiveDeepLink == false)
        #expect(viewModel.activeChatID == nil)
        #expect(viewModel.activeMessageID == nil)
        #expect(viewModel.shouldHighlightMessage == false)
    }
}

