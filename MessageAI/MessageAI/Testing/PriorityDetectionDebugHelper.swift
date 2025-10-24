//
//  PriorityDetectionDebugHelper.swift
//  MessageAI
//
//  Debug helper for priority detection issues
//

import Foundation

/// Debug helper for priority detection
class PriorityDetectionDebugHelper {
    
    /// Test simple keyword detection
    static func testKeywordDetection() {
        print("🧪 Testing Keyword Detection...")
        
        let testMessages = [
            "URGENT: Server is down!",
            "urgent help needed",
            "ASAP please",
            "Hey, how are you?",
            "Please schedule a meeting"
        ]
        
        for message in testMessages {
            let keywords = extractKeywords(from: message)
            let hasUrgency = ["urgent", "asap", "deadline", "today", "tomorrow", "immediately", "critical", "emergency"].contains(where: { message.lowercased().contains($0) })
            
            print("📝 Message: \"\(message)\"")
            print("🔍 Keywords: \(keywords)")
            print("⚡ Has Urgency: \(hasUrgency)")
            print("🎯 Expected: \(getExpectedCategory(for: message))")
            print("---")
        }
    }
    
    /// Get expected category for a message
    private static func getExpectedCategory(for message: String) -> String {
        let lowercased = message.lowercased()
        
        if ["urgent", "asap", "deadline", "today", "tomorrow", "immediately", "critical", "emergency"].contains(where: { lowercased.contains($0) }) {
            return "🔴 URGENT"
        } else if ["please", "need", "request", "ask", "help"].contains(where: { lowercased.contains($0) }) {
            return "🤖 AI HANDLED"
        } else {
            return "🟡 CAN WAIT"
        }
    }
    
    /// Extract keywords from message text
    private static func extractKeywords(from text: String) -> [String] {
        let urgencyKeywords = ["urgent", "asap", "deadline", "today", "tomorrow", "immediately", "critical", "emergency"]
        let questionKeywords = ["?", "how", "what", "when", "where", "why", "who"]
        let actionKeywords = ["please", "need", "request", "ask", "help"]
        
        let lowercasedText = text.lowercased()
        var keywords: [String] = []
        
        // Check for urgency keywords
        for keyword in urgencyKeywords {
            if lowercasedText.contains(keyword) {
                keywords.append(keyword)
            }
        }
        
        // Check for question indicators
        for keyword in questionKeywords {
            if lowercasedText.contains(keyword) {
                keywords.append("question")
                break
            }
        }
        
        // Check for action keywords
        for keyword in actionKeywords {
            if lowercasedText.contains(keyword) {
                keywords.append("action")
                break
            }
        }
        
        return keywords
    }
    
    /// Debug message categorization
    static func debugMessageCategorization(_ message: String) {
        print("🔍 Debugging Message: \"\(message)\"")
        
        let lowercased = message.lowercased()
        let urgencyKeywords = ["urgent", "asap", "deadline", "today", "tomorrow", "immediately", "critical", "emergency"]
        let actionKeywords = ["please", "need", "request", "ask", "help"]
        
        print("📝 Lowercased: \"\(lowercased)\"")
        
        // Check urgency
        for keyword in urgencyKeywords {
            if lowercased.contains(keyword) {
                print("⚡ Found urgency keyword: '\(keyword)'")
            }
        }
        
        // Check action
        for keyword in actionKeywords {
            if lowercased.contains(keyword) {
                print("🎯 Found action keyword: '\(keyword)'")
            }
        }
        
        print("🎯 Expected category: \(getExpectedCategory(for: message))")
    }
}
