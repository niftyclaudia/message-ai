//
//  DeepLink.swift
//  MessageAI
//
//  Deep link model for navigation from push notifications
//  PR #4: Mobile Lifecycle Management
//

import Foundation

/// Represents a deep link for navigation within the app
/// - Note: Created from push notification payloads to navigate to specific content
struct DeepLink: Equatable {
    /// Type of deep link
    let type: DeepLinkType
    
    /// Chat ID to navigate to
    let chatID: String
    
    /// Optional message ID to scroll to and highlight
    let messageID: String?
    
    /// Whether to highlight the target message
    let shouldHighlight: Bool
    
    /// Timestamp when deep link was created
    let timestamp: Date
    
    // MARK: - Initialization
    
    /// Create a deep link from notification payload
    /// - Parameters:
    ///   - payload: Push notification payload
    ///   - shouldHighlight: Whether to highlight the message (default: true)
    init(from payload: NotificationPayload, shouldHighlight: Bool = true) {
        self.chatID = payload.chatID
        self.messageID = payload.messageID
        self.shouldHighlight = shouldHighlight
        self.timestamp = payload.timestamp
        
        // Determine type based on available data
        if let messageID = payload.messageID {
            self.type = .message(chatID: payload.chatID, messageID: messageID)
        } else {
            self.type = .chat(chatID: payload.chatID)
        }
    }
    
    /// Create a deep link directly
    /// - Parameters:
    ///   - type: Deep link type
    ///   - chatID: Chat ID
    ///   - messageID: Optional message ID
    ///   - shouldHighlight: Whether to highlight the message
    init(type: DeepLinkType, chatID: String, messageID: String? = nil, shouldHighlight: Bool = true) {
        self.type = type
        self.chatID = chatID
        self.messageID = messageID
        self.shouldHighlight = shouldHighlight
        self.timestamp = Date()
    }
}

/// Type of deep link navigation
enum DeepLinkType: Equatable {
    /// Navigate to a specific chat
    case chat(chatID: String)
    
    /// Navigate to a specific message within a chat
    case message(chatID: String, messageID: String)
    
    /// Human-readable description
    var description: String {
        switch self {
        case .chat(let chatID):
            return "Chat: \(chatID)"
        case .message(let chatID, let messageID):
            return "Message: \(messageID) in Chat: \(chatID)"
        }
    }
}

