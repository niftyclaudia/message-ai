//
//  SlackThread.swift
//  MessageAI
//
//  PR-011: Mock Slack Integration Demo
//  Phase 1: Proof of concept with mock data
//

import Foundation

/// Represents a Slack message in a thread
struct SlackMessage: Identifiable, Codable {
    let id: String
    let userId: String
    let username: String
    let userAvatar: String?
    let text: String
    let timestamp: Date
    let isThreadParent: Bool
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        username: String,
        userAvatar: String? = nil,
        text: String,
        timestamp: Date,
        isThreadParent: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.username = username
        self.userAvatar = userAvatar
        self.text = text
        self.timestamp = timestamp
        self.isThreadParent = isThreadParent
    }
}

/// Represents a Slack thread with multiple messages
struct SlackThread: Identifiable, Codable {
    let id: String
    let channelId: String
    let channelName: String
    let workspaceName: String
    let messages: [SlackMessage]
    let participantCount: Int
    let createdAt: Date
    
    var participants: [String] {
        Array(Set(messages.map { $0.username }))
    }
    
    var messageCount: Int {
        messages.count
    }
    
    init(
        id: String = UUID().uuidString,
        channelId: String,
        channelName: String,
        workspaceName: String,
        messages: [SlackMessage],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.channelId = channelId
        self.channelName = channelName
        self.workspaceName = workspaceName
        self.messages = messages
        self.participantCount = Set(messages.map { $0.userId }).count
        self.createdAt = createdAt
    }
}

// MARK: - Mock Data for Demo

extension SlackThread {
    /// Mock Slack thread for demo purposes
    static var mockProjectThread: SlackThread {
        let now = Date()
        let calendar = Calendar.current
        
        let messages = [
            SlackMessage(
                userId: "U001",
                username: "Sarah Chen",
                text: "Hey team! Quick sync on the Q4 product roadmap. We need to finalize priorities by Friday.",
                timestamp: calendar.date(byAdding: .hour, value: -2, to: now)!,
                isThreadParent: true
            ),
            SlackMessage(
                userId: "U002",
                username: "Mike Rodriguez",
                text: "Sounds good! I think the calendar integration should be top priority. Our users have been asking for it.",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-3000)
            ),
            SlackMessage(
                userId: "U003",
                username: "Alex Kim",
                text: "Agreed. The AI features are getting great engagement. We should double down there.",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-2400)
            ),
            SlackMessage(
                userId: "U001",
                username: "Sarah Chen",
                text: "Perfect! So thinking: 1) Calendar integration 2) Smart notifications 3) Team collaboration features. Thoughts?",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-1800)
            ),
            SlackMessage(
                userId: "U004",
                username: "Jordan Lee",
                text: "Love it! Question: Are we doing Google Calendar first or also supporting Outlook?",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-1200)
            ),
            SlackMessage(
                userId: "U002",
                username: "Mike Rodriguez",
                text: "Google Calendar first makes sense. We can add Outlook in Q1 next year based on demand.",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-900)
            ),
            SlackMessage(
                userId: "U003",
                username: "Alex Kim",
                text: "The Slack integration demo looks amazing btw. Really shows off the AI capabilities.",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-600)
            ),
            SlackMessage(
                userId: "U001",
                username: "Sarah Chen",
                text: "Thanks Alex! Okay, let's lock this in. I'll create the PRD and share by end of day. Meeting again Friday 2pm?",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-300)
            ),
            SlackMessage(
                userId: "U004",
                username: "Jordan Lee",
                text: "Friday 2pm works for me! 👍",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!.addingTimeInterval(-120)
            ),
            SlackMessage(
                userId: "U002",
                username: "Mike Rodriguez",
                text: "Same here. See you all then! 🚀",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!
            )
        ]
        
        return SlackThread(
            channelId: "C12345",
            channelName: "product-planning",
            workspaceName: "MessageAI Team",
            messages: messages,
            createdAt: messages.first?.timestamp ?? now
        )
    }
    
    /// Another mock thread for variety
    static var mockTechDiscussion: SlackThread {
        let now = Date()
        let calendar = Calendar.current
        
        let messages = [
            SlackMessage(
                userId: "U005",
                username: "Taylor Swift",
                text: "Anyone else seeing increased latency on the semantic search endpoint?",
                timestamp: calendar.date(byAdding: .hour, value: -4, to: now)!,
                isThreadParent: true
            ),
            SlackMessage(
                userId: "U006",
                username: "Chris Evans",
                text: "Yeah, noticed it this morning. P95 went from 800ms to 1.2s. Looking into it now.",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-2700)
            ),
            SlackMessage(
                userId: "U007",
                username: "Maya Patel",
                text: "Might be related to the Pinecone index size. We're at 2M vectors now.",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-2100)
            ),
            SlackMessage(
                userId: "U006",
                username: "Chris Evans",
                text: "Good catch! Let me check the query performance metrics.",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-1500)
            ),
            SlackMessage(
                userId: "U005",
                username: "Taylor Swift",
                text: "Should we consider sharding the index by date range? Older messages could go to a separate index.",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-900)
            ),
            SlackMessage(
                userId: "U007",
                username: "Maya Patel",
                text: "That's a solid approach. We could also implement a cache layer for frequent queries.",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-600)
            ),
            SlackMessage(
                userId: "U006",
                username: "Chris Evans",
                text: "Both good ideas. Let me write up a quick proposal and we can review tomorrow?",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!.addingTimeInterval(-300)
            ),
            SlackMessage(
                userId: "U005",
                username: "Taylor Swift",
                text: "Perfect. Thanks for jumping on this! 🙌",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!
            )
        ]
        
        return SlackThread(
            channelId: "C67890",
            channelName: "engineering",
            workspaceName: "MessageAI Team",
            messages: messages,
            createdAt: messages.first?.timestamp ?? now
        )
    }
}

