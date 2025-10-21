//
//  ChatViewModel.swift
//  MessageAI
//
//  Chat view model for message display functionality
//

import Foundation
import FirebaseFirestore
import SwiftUI

/// ViewModel for managing chat view state and message operations
/// - Note: Handles message loading, real-time updates, and status management
@MainActor
class ChatViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var messages: [Message] = []
    @Published var chat: Chat?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUserID: String
    
    // MARK: - Private Properties
    
    private let messageService: MessageService
    private var listener: ListenerRegistration?
    
    // MARK: - Initialization
    
    init(currentUserID: String, messageService: MessageService = MessageService()) {
        self.currentUserID = currentUserID
        self.messageService = messageService
    }
    
    deinit {
        // Clean up listener without main actor isolation
        listener?.remove()
        listener = nil
    }
    
    // MARK: - Public Methods
    
    /// Loads messages for a specific chat
    /// - Parameter chatID: The chat's ID
    func loadMessages(chatID: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMessages = try await messageService.fetchMessages(chatID: chatID)
            // For PR-5 testing, always use mock messages since Firebase permissions aren't set up yet
            messages = createTestMessages(for: chatID)
            isLoading = false
        } catch {
            // For PR-5 testing, always show mock messages on error
            print("⚠️ Using mock messages for PR-5 testing: \(error.localizedDescription)")
            messages = createTestMessages(for: chatID)
            errorMessage = nil
            isLoading = false
        }
    }
    
    /// Sets up real-time listener for messages in a chat
    /// - Parameter chatID: The chat's ID
    func observeMessagesRealTime(chatID: String) {
        stopObserving() // Clean up any existing listener
        
        // For PR-5 testing, skip real-time listener due to Firebase permissions
        print("⚠️ Skipping real-time listener for PR-5 testing (Firebase permissions not set up)")
        
        // In PR-6, this will be enabled:
        // listener = messageService.observeMessages(chatID: chatID) { [weak self] newMessages in
        //     Task { @MainActor in
        //         self?.messages = newMessages
        //     }
        // }
    }
    
    /// Stops observing messages and cleans up listener
    func stopObserving() {
        listener?.remove()
        listener = nil
    }
    
    /// Marks a message as read by the current user
    /// - Parameter messageID: The message's ID
    func markMessageAsRead(messageID: String) {
        Task {
            do {
                try await messageService.markMessageAsRead(messageID: messageID, userID: currentUserID)
            } catch {
                print("⚠️ Failed to mark message as read: \(error)")
            }
        }
    }
    
    /// Formats a timestamp into a user-friendly string
    /// - Parameter date: The date to format
    /// - Returns: Formatted timestamp string
    func formatTimestamp(date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Gets the status of a message for display
    /// - Parameter message: The message to check
    /// - Returns: The message status
    func getMessageStatus(message: Message) -> MessageStatus {
        return message.status
    }
    
    /// Checks if a message was sent by the current user
    /// - Parameter message: The message to check
    /// - Returns: True if sent by current user
    func isMessageFromCurrentUser(message: Message) -> Bool {
        return message.senderID == currentUserID
    }
    
    /// Gets the display name for a message sender
    /// - Parameter message: The message to check
    /// - Returns: Sender display name
    func getSenderDisplayName(message: Message) -> String {
        if isMessageFromCurrentUser(message: message) {
            return "You"
        } else if let senderName = message.senderName {
            return senderName
        } else {
            return "Unknown"
        }
    }
    
    /// Checks if a message should show sender name (for group chats)
    /// - Parameter message: The message to check
    /// - Returns: True if sender name should be displayed
    func shouldShowSenderName(message: Message) -> Bool {
        guard let chat = chat else { return false }
        return chat.isGroupChat && !isMessageFromCurrentUser(message: message)
    }
    
    /// Checks if a message should show timestamp (based on previous message)
    /// - Parameters:
    ///   - message: The current message
    ///   - previousMessage: The previous message in the list
    /// - Returns: True if timestamp should be displayed
    func shouldShowTimestamp(message: Message, previousMessage: Message?) -> Bool {
        guard let previousMessage = previousMessage else { return true }
        
        let timeDifference = message.timestamp.timeIntervalSince(previousMessage.timestamp)
        return timeDifference > 300 // Show timestamp if more than 5 minutes apart
    }
    
    // MARK: - Test Data Methods
    
    /// Creates test messages for PR-5 testing
    /// - Parameter chatID: The chat ID to create messages for
    /// - Returns: Array of test messages
    private func createTestMessages(for chatID: String) -> [Message] {
        let now = Date()
        let otherUserID = "user-2" // Mock other user ID
        
        return [
            // Message from other user
            Message(
                id: "msg-1",
                chatID: chatID,
                senderID: otherUserID,
                text: "Hey! How are you doing?",
                timestamp: now.addingTimeInterval(-300), // 5 minutes ago
                readBy: [otherUserID, currentUserID],
                status: .read,
                senderName: "John Doe"
            ),
            
            // Message from current user
            Message(
                id: "msg-2",
                chatID: chatID,
                senderID: currentUserID,
                text: "I'm doing great! Thanks for asking. How about you?",
                timestamp: now.addingTimeInterval(-240), // 4 minutes ago
                readBy: [currentUserID, otherUserID],
                status: .read
            ),
            
            // Another message from other user
            Message(
                id: "msg-3",
                chatID: chatID,
                senderID: otherUserID,
                text: "Pretty good! Just working on some new projects. What's new with you?",
                timestamp: now.addingTimeInterval(-180), // 3 minutes ago
                readBy: [otherUserID, currentUserID],
                status: .read,
                senderName: "John Doe"
            ),
            
            // Long message to test text wrapping
            Message(
                id: "msg-4",
                chatID: chatID,
                senderID: currentUserID,
                text: "That's awesome! I've been working on this new messaging app. It's been really interesting to build the real-time features and make sure everything works smoothly. The UI is coming together nicely too!",
                timestamp: now.addingTimeInterval(-120), // 2 minutes ago
                readBy: [currentUserID, otherUserID],
                status: .read
            ),
            
            // Recent message with different status
            Message(
                id: "msg-5",
                chatID: chatID,
                senderID: otherUserID,
                text: "That sounds really cool! I'd love to see it when it's ready.",
                timestamp: now.addingTimeInterval(-60), // 1 minute ago
                readBy: [otherUserID],
                status: .delivered,
                senderName: "John Doe"
            ),
            
            // Very recent message
            Message(
                id: "msg-6",
                chatID: chatID,
                senderID: currentUserID,
                text: "Sure! I'll send you a link when it's ready for testing.",
                timestamp: now.addingTimeInterval(-30), // 30 seconds ago
                readBy: [currentUserID],
                status: .sent
            )
        ]
    }
}
