//
//  NotificationPayload.swift
//  MessageAI
//
//  Notification data structure for push notifications
//

import Foundation

/// Notification payload structure for push notifications
/// - Note: Parses from notification userInfo dictionary
struct NotificationPayload: Codable {
    /// Chat ID to navigate to when notification is tapped
    let chatID: String
    
    /// ID of the user who sent the message
    let senderID: String
    
    /// Display name of the sender
    let senderName: String
    
    /// Text content of the message (first 100 characters)
    let messageText: String
    
    /// Timestamp when notification was created
    let timestamp: Date
    
    // MARK: - Initialization
    
    /// Parse notification payload from userInfo dictionary
    /// - Parameter userInfo: Notification dictionary from UNNotificationResponse
    /// - Returns: NotificationPayload if valid, nil if malformed
    init?(userInfo: [AnyHashable: Any]) {
        guard let chatID = userInfo["chatID"] as? String,
              let senderID = userInfo["senderID"] as? String,
              let senderName = userInfo["senderName"] as? String,
              let messageText = userInfo["messageText"] as? String
        else { 
            return nil 
        }
        
        self.chatID = chatID
        self.senderID = senderID
        self.senderName = senderName
        self.messageText = messageText
        self.timestamp = Date()
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case chatID
        case senderID
        case senderName
        case messageText
        case timestamp
    }
}
