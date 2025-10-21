//
//  MockDataService.swift
//  MessageAI
//
//  Mock data service for testing real-time messaging scenarios
//

import Foundation

/// Mock data service for testing real-time messaging scenarios
/// - Note: Only available in debug builds for testing purposes
class MockDataService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var mockMessages: [Message] = []
    @Published var mockConnectionStatus: ConnectionStatus = .connected
    @Published var mockUserID = "current_user"
    @Published var mockChatID = "test_chat"
    
    private var mockMessageCount = 0
    private var mockTimer: Timer?
    
    // MARK: - Connection Status
    
    enum ConnectionStatus: String, CaseIterable {
        case connected = "Connected"
        case offline = "Offline"
        case reconnecting = "Reconnecting"
        case slow = "Slow Connection"
    }
    
    // MARK: - Mock Message Generation
    
    /// Generate a mock message with specified parameters
    func generateMockMessage(
        isFromCurrentUser: Bool,
        text: String? = nil,
        status: MessageStatus = .delivered
    ) -> Message {
        mockMessageCount += 1
        
        let messageText = text ?? (isFromCurrentUser ? 
            "Mock sent message \(mockMessageCount)" : 
            "Mock received message \(mockMessageCount)")
        
        return Message(
            id: "mock_\(mockMessageCount)",
            chatID: mockChatID,
            senderID: isFromCurrentUser ? mockUserID : "other_user",
            text: messageText,
            timestamp: Date(),
            readBy: isFromCurrentUser ? [mockUserID] : [],
            status: status,
            senderName: isFromCurrentUser ? nil : "Other User"
        )
    }
    
    /// Add a mock message to the collection
    func addMockMessage(
        isFromCurrentUser: Bool,
        text: String? = nil,
        status: MessageStatus = .delivered
    ) {
        let message = generateMockMessage(
            isFromCurrentUser: isFromCurrentUser,
            text: text,
            status: status
        )
        
        mockMessages.append(message)
    }
    
    // MARK: - Mock Scenarios
    
    /// Simulate real-time message receiving
    func simulateRealTimeMessage() {
        addMockMessage(isFromCurrentUser: false)
    }
    
    /// Simulate message sending with status updates
    func simulateMessageSending(text: String) {
        let message = generateMockMessage(
            isFromCurrentUser: true,
            text: text,
            status: .sending
        )
        mockMessages.append(message)
        
        // Simulate status updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateMessageStatus(message.id, status: .sent)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateMessageStatus(message.id, status: .delivered)
        }
    }
    
    /// Simulate send failure
    func simulateSendFailure() {
        let message = generateMockMessage(
            isFromCurrentUser: true,
            text: "This message failed to send",
            status: .failed
        )
        mockMessages.append(message)
    }
    
    /// Simulate offline mode with queued messages
    func simulateOfflineMode() {
        mockConnectionStatus = .offline
        
        // Add a queued message
        let message = generateMockMessage(
            isFromCurrentUser: true,
            text: "This message is queued for offline",
            status: .queued
        )
        mockMessages.append(message)
    }
    
    /// Simulate reconnection and message sync
    func simulateReconnection() {
        mockConnectionStatus = .reconnecting
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.mockConnectionStatus = .connected
            
            // Update queued messages to sent
            for index in self.mockMessages.indices {
                if self.mockMessages[index].status == .queued {
                    self.mockMessages[index].status = .sent
                }
            }
        }
    }
    
    /// Simulate rapid message exchange
    func simulateRapidMessaging(count: Int = 5) {
        for i in 1...count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                self.addMockMessage(isFromCurrentUser: i % 2 == 0)
            }
        }
    }
    
    /// Simulate slow connection
    func simulateSlowConnection() {
        mockConnectionStatus = .slow
        
        // Add messages with delays
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.addMockMessage(isFromCurrentUser: false)
        }
    }
    
    // MARK: - Message Status Updates
    
    /// Update message status
    func updateMessageStatus(_ messageID: String, status: MessageStatus) {
        if let index = mockMessages.firstIndex(where: { $0.id == messageID }) {
            mockMessages[index].status = status
        }
    }
    
    /// Mark message as read
    func markMessageAsRead(_ messageID: String) {
        if let index = mockMessages.firstIndex(where: { $0.id == messageID }) {
            if !mockMessages[index].readBy.contains(mockUserID) {
                mockMessages[index].readBy.append(mockUserID)
            }
            mockMessages[index].status = .read
        }
    }
    
    // MARK: - Auto Message Generation
    
    /// Start auto-generating messages
    func startAutoMessaging(interval: TimeInterval = 3.0) {
        stopAutoMessaging()
        
        mockTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            self.simulateRealTimeMessage()
        }
    }
    
    /// Stop auto-generating messages
    func stopAutoMessaging() {
        mockTimer?.invalidate()
        mockTimer = nil
    }
    
    // MARK: - Data Management
    
    /// Clear all mock data
    func clearAllMockData() {
        mockMessages.removeAll()
        mockMessageCount = 0
        mockConnectionStatus = .connected
        stopAutoMessaging()
    }
    
    /// Get messages for specific chat
    func getMessagesForChat(_ chatID: String) -> [Message] {
        return mockMessages.filter { $0.chatID == chatID }
    }
    
    /// Get recent messages
    func getRecentMessages(limit: Int = 10) -> [Message] {
        return Array(mockMessages.suffix(limit))
    }
}

// MARK: - Mock Data Presets

extension MockDataService {
    
    /// Load preset conversation for testing
    func loadPresetConversation() {
        clearAllMockData()
        
        let presetMessages = [
            ("Hello! How are you?", false),
            ("I'm doing great, thanks for asking!", true),
            ("That's wonderful to hear!", false),
            ("Are you working on anything interesting?", false),
            ("Yes, I'm building a messaging app with real-time features", true),
            ("That sounds exciting! Tell me more about it", false),
            ("It uses Firebase for real-time sync and SwiftUI for the interface", true),
            ("Wow, that's impressive! I'd love to see it when it's ready", false)
        ]
        
        for (_, (text, isFromCurrentUser)) in presetMessages.enumerated() {
            let message = generateMockMessage(
                isFromCurrentUser: isFromCurrentUser,
                text: text,
                status: .delivered
            )
            mockMessages.append(message)
        }
    }
    
    /// Load error scenarios for testing
    func loadErrorScenarios() {
        clearAllMockData()
        
        // Add various error scenarios
        addMockMessage(isFromCurrentUser: true, text: "This message failed", status: .failed)
        addMockMessage(isFromCurrentUser: true, text: "This message is queued", status: .queued)
        addMockMessage(isFromCurrentUser: true, text: "This message is sending", status: .sending)
        addMockMessage(isFromCurrentUser: false, text: "This message was delivered", status: .delivered)
        addMockMessage(isFromCurrentUser: false, text: "This message was read", status: .read)
    }
}
