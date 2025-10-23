//
//  DeepLinkingService.swift
//  MessageAI
//
//  Service for handling deep links and navigation from push notifications
//  PR #4: Mobile Lifecycle Management
//

import Foundation
import FirebaseFirestore
import SwiftUI

/// Service for managing deep link navigation
/// - Note: Validates deep links and coordinates navigation timing (< 400ms target)
class DeepLinkingService {
    
    // MARK: - Properties
    
    private let firestore: Firestore
    private var navigationStartTime: Date?
    
    // MARK: - Initialization
    
    init() {
        self.firestore = FirebaseService.shared.getFirestore()
    }
    
    // MARK: - Deep Link Validation
    
    /// Validates that a deep link points to existing content
    /// - Parameter deepLink: The deep link to validate
    /// - Returns: True if valid, false if chat/message doesn't exist
    func validateDeepLink(_ deepLink: DeepLink) async -> Bool {
        do {
            // Validate chat exists
            let chatDoc = try await firestore.collection("chats")
                .document(deepLink.chatID)
                .getDocument()
            
            guard chatDoc.exists else {
                return false
            }
            
            // If messageID is provided, validate message exists
            if let messageID = deepLink.messageID {
                let messageDoc = try await firestore.collection("chats")
                    .document(deepLink.chatID)
                    .collection("messages")
                    .document(messageID)
                    .getDocument()
                
                guard messageDoc.exists else {
                    return false
                }
            }
            
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Navigation
    
    /// Initiates deep link navigation
    /// - Parameter deepLink: The deep link to navigate to
    /// - Note: Tracks navigation timing to ensure < 400ms (PR #4 requirement)
    func navigateToDeepLink(_ deepLink: DeepLink) async {
        // Start tracking navigation time
        navigationStartTime = Date()
        PerformanceMonitor.shared.startNavigation(from: "push_notification")
        
        // Validate deep link first
        let isValid = await validateDeepLink(deepLink)
        
        guard isValid else {
            return
        }
        
        // Navigation will be handled by DeepLinkViewModel and SwiftUI navigation
        // This service just validates and tracks timing
        
        // Calculate navigation time
        if let startTime = navigationStartTime {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceMonitor.shared.endNavigation(to: "chat_view")
        }
    }
    
    /// Creates a deep link from notification payload
    /// - Parameter payload: Push notification payload
    /// - Returns: DeepLink if payload is valid
    func createDeepLink(from payload: NotificationPayload) -> DeepLink {
        return DeepLink(from: payload, shouldHighlight: true)
    }
    
    // MARK: - Timing Measurement
    
    /// Measures the time taken for deep link navigation
    /// - Parameter deepLink: The deep link that was navigated to
    /// - Returns: Navigation duration in milliseconds
    func measureNavigationTime(for deepLink: DeepLink) -> TimeInterval {
        guard let startTime = navigationStartTime else { return 0 }
        
        let duration = Date().timeIntervalSince(startTime)
        navigationStartTime = nil
        
        return duration * 1000  // Convert to milliseconds
    }
}

/// Errors that can occur during deep linking
enum DeepLinkError: LocalizedError {
    case chatNotFound
    case messageNotFound
    case invalidDeepLink
    case navigationFailed
    
    var errorDescription: String? {
        switch self {
        case .chatNotFound:
            return "The requested chat could not be found"
        case .messageNotFound:
            return "The requested message could not be found"
        case .invalidDeepLink:
            return "The deep link is invalid or malformed"
        case .navigationFailed:
            return "Navigation to the deep link failed"
        }
    }
}

