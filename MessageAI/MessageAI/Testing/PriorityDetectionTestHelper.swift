//
//  PriorityDetectionTestHelper.swift
//  MessageAI
//
//  Test helper for priority message detection
//

import Foundation

/// Helper class for testing priority message detection
class PriorityDetectionTestHelper {
    
    /// Test messages for different priority categories
    static let testMessages = [
        // Urgent messages
        "URGENT: Server is down, need immediate help!",
        "ASAP: Can you review this document today?",
        "Critical: Database backup failed, need to fix now",
        "Emergency: Client meeting moved to tomorrow",
        "Deadline: Need this by 5pm today",
        
        // Can Wait messages
        "Hey, how was your weekend?",
        "FYI: The report is ready for review",
        "Just wanted to check in on the project",
        "What do you think about the new design?",
        "Thanks for the update",
        
        // AI Handled messages
        "Please schedule a meeting for next week",
        "Can you send me the quarterly report?",
        "What time is the team standup?",
        "Can you help me with the presentation?",
        "Please send me the latest version"
    ]
    
    /// Expected categories for test messages
    static let expectedCategories: [MessageCategory] = [
        .urgent, .urgent, .urgent, .urgent, .urgent,
        .canWait, .canWait, .canWait, .canWait, .canWait,
        .aiHandled, .aiHandled, .aiHandled, .aiHandled, .aiHandled
    ]
    
    /// Test priority detection with sample messages
    static func runPriorityDetectionTest() async {
        print("🧪 Starting Priority Detection Test...")
        
        for (index, message) in testMessages.enumerated() {
            print("\n📝 Testing message: \"\(message)\"")
            print("🎯 Expected category: \(expectedCategories[index].displayName)")
            
            // You can add actual categorization logic here
            // let prediction = try await priorityDetectionService.categorizeMessage(message)
            // print("✅ Actual category: \(prediction.category.displayName)")
            // print("📊 Confidence: \(Int(prediction.confidence * 100))%")
        }
        
        print("\n✅ Priority Detection Test Complete!")
    }
}
