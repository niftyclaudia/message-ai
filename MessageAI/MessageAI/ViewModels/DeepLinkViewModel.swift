//
//  DeepLinkViewModel.swift
//  MessageAI
//
//  ViewModel for managing deep link navigation state
//  PR #4: Mobile Lifecycle Management
//

import Foundation
import SwiftUI
import Combine

/// ViewModel for managing deep link navigation from push notifications
/// - Note: Coordinates navigation timing and state management
@MainActor
class DeepLinkViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Active deep link to navigate to
    @Published var activeDeepLink: DeepLink?
    
    /// Whether deep link navigation is in progress
    @Published var isNavigating: Bool = false
    
    /// Error that occurred during navigation
    @Published var navigationError: String?
    
    /// Whether to show error alert
    @Published var showErrorAlert: Bool = false
    
    // MARK: - Private Properties
    
    private let deepLinkingService: DeepLinkingService
    private let notificationService: NotificationService
    private var cancellables = Set<AnyCancellable>()
    private var navigationStartTime: Date?
    
    // MARK: - Initialization
    
    init(
        deepLinkingService: DeepLinkingService = DeepLinkingService(),
        notificationService: NotificationService
    ) {
        self.deepLinkingService = deepLinkingService
        self.notificationService = notificationService
        setupObservers()
    }
    
    // MARK: - Setup
    
    /// Observes notification service for new deep links
    private func setupObservers() {
        // Observe deep links from notification service
        notificationService.$activeDeepLink
            .sink { [weak self] deepLink in
                if let deepLink = deepLink {
                    self?.processDeepLink(deepLink)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Deep Link Processing
    
    /// Process and validate a deep link
    /// - Parameter deepLink: The deep link to process
    func processDeepLink(_ deepLink: DeepLink) {
        Task {
            navigationStartTime = Date()
            isNavigating = true
            PerformanceMonitor.shared.startDeepLinkNavigation()
            
            // Validate deep link
            let isValid = await deepLinkingService.validateDeepLink(deepLink)
            
            if isValid {
                // Set active deep link for navigation
                activeDeepLink = deepLink
            } else {
                navigationError = "Unable to open the requested content. It may have been deleted."
                showErrorAlert = true
            }
            
            isNavigating = false
            PerformanceMonitor.shared.endDeepLinkNavigation()
        }
    }
    
    /// Clear the active deep link after navigation completes
    func clearDeepLink() {
        activeDeepLink = nil
        notificationService.clearDeepLink()
        navigationError = nil
        showErrorAlert = false
    }
    
    /// Manually trigger deep link navigation (for testing)
    /// - Parameter deepLink: The deep link to navigate to
    func navigateTo(deepLink: DeepLink) {
        processDeepLink(deepLink)
    }
    
    // MARK: - Navigation Helpers
    
    /// Check if there's an active deep link
    var hasActiveDeepLink: Bool {
        activeDeepLink != nil
    }
    
    /// Get the chat ID from active deep link
    var activeChatID: String? {
        activeDeepLink?.chatID
    }
    
    /// Get the message ID from active deep link (for scrolling)
    var activeMessageID: String? {
        activeDeepLink?.messageID
    }
    
    /// Check if the message should be highlighted
    var shouldHighlightMessage: Bool {
        activeDeepLink?.shouldHighlight ?? false
    }
}

