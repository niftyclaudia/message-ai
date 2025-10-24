//
//  FallbackAction.swift
//  MessageAI
//
//  PR-AI-005: Error Handling & Fallback System
//  Defines fallback actions users can take when AI features fail
//

import Foundation

/// Actions available to users when AI features fail
enum FallbackAction: Equatable {
    /// Open the full thread instead of showing summary
    case openFullThread(threadId: String)
    
    /// Show the last N messages instead of action items
    case showRecentMessages(count: Int)
    
    /// Fall back to keyword search instead of semantic search
    case useKeywordSearch(query: String)
    
    /// Place all messages in neutral inbox instead of categorizing
    case showInbox
    
    /// Skip AI detection and show raw message history
    case skipDetection
    
    /// Prompt user to check calendar manually
    case manualScheduling
    
    /// User-facing button text for this fallback action
    var buttonTitle: String {
        switch self {
        case .openFullThread:
            return "Open Full Thread"
        case .showRecentMessages:
            return "Show Messages"
        case .useKeywordSearch:
            return "Try Basic Search"
        case .showInbox:
            return "View Inbox"
        case .skipDetection:
            return "View History"
        case .manualScheduling:
            return "Check Calendar"
        }
    }
    
    /// Icon name (SF Symbol) for this fallback action
    var iconName: String {
        switch self {
        case .openFullThread:
            return "message.fill"
        case .showRecentMessages:
            return "list.bullet"
        case .useKeywordSearch:
            return "magnifyingglass"
        case .showInbox:
            return "tray.fill"
        case .skipDetection:
            return "clock.fill"
        case .manualScheduling:
            return "calendar"
        }
    }
}

