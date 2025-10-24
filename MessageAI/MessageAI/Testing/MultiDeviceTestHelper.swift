//
//  MultiDeviceTestHelper.swift
//  MessageAI
//
//  Helper for multi-device priority detection testing
//

import Foundation

/// Helper for testing priority detection across multiple devices
class MultiDeviceTestHelper {
    
    /// Test scenarios for multi-device testing
    enum TestScenario {
        case sameUserDifferentDevices
        case differentUsersSameChat
        case priorityInboxFiltering
        case realTimeSync
        case offlineOnlineSync
    }
    
    /// Test messages organized by priority
    static let testMessages = [
        "urgent": [
            "URGENT: Server is down, need immediate help!",
            "ASAP: Can you review this document today?",
            "Critical: Database backup failed, need to fix now",
            "Emergency: Client meeting moved to tomorrow"
        ],
        "canWait": [
            "Hey, how was your weekend?",
            "FYI: The report is ready for review",
            "Just wanted to check in on the project",
            "What do you think about the new design?"
        ],
        "aiHandled": [
            "Please schedule a meeting for next week",
            "Can you send me the quarterly report?",
            "What time is the team standup?",
            "Can you help me with the presentation?"
        ]
    ]
    
    /// Run a specific test scenario
    static func runTest(_ scenario: TestScenario) {
        print("🧪 Running test scenario: \(scenario)")
        
        switch scenario {
        case .sameUserDifferentDevices:
            runSameUserTest()
        case .differentUsersSameChat:
            runDifferentUsersTest()
        case .priorityInboxFiltering:
            runPriorityInboxTest()
        case .realTimeSync:
            runRealTimeSyncTest()
        case .offlineOnlineSync:
            runOfflineOnlineTest()
        }
    }
    
    private static func runSameUserTest() {
        print("""
        📱 Same User, Different Devices Test:
        1. Sign in as same user on both devices
        2. Device A: Send urgent message
        3. Device B: Watch for real-time categorization
        4. Verify both devices show same priority badge
        """)
    }
    
    private static func runDifferentUsersTest() {
        print("""
        👥 Different Users, Same Chat Test:
        1. Device A: Sign in as user1@test.com
        2. Device B: Sign in as user2@test.com
        3. Create chat between users
        4. Device A: Send urgent message
        5. Device B: Watch for categorization to appear
        """)
    }
    
    private static func runPriorityInboxTest() {
        print("""
        📋 Priority Inbox Filtering Test:
        1. Send messages of different priorities
        2. Open Priority Inbox on Device B
        3. Filter by: Urgent, Can Wait, AI Handled
        4. Verify filtering works correctly
        """)
    }
    
    private static func runRealTimeSyncTest() {
        print("""
        ⚡ Real-Time Sync Test:
        1. Send message on Device A
        2. Watch for categorization on Device B (< 200ms)
        3. Verify badge appears immediately
        4. Test with 3+ devices for consistency
        """)
    }
    
    private static func runOfflineOnlineTest() {
        print("""
        📶 Offline/Online Sync Test:
        1. Go offline on Device A
        2. Send 3 messages (they should queue)
        3. Go back online
        4. Watch messages get categorized within 5 seconds
        5. Verify all queued messages get proper badges
        """)
    }
    
    /// Get test messages for a specific priority
    static func getTestMessages(for priority: String) -> [String] {
        return testMessages[priority] ?? []
    }
    
    /// Print test instructions
    static func printTestInstructions() {
        print("""
        🧪 Multi-Device Priority Detection Testing
        
        Setup:
        1. Run app on 2+ simulators or 1 simulator + 1 physical device
        2. Sign in with test accounts
        3. Create a chat between users
        
        Test Messages:
        🔴 Urgent: \(testMessages["urgent"]?.first ?? "")
        🟡 Can Wait: \(testMessages["canWait"]?.first ?? "")
        🤖 AI Handled: \(testMessages["aiHandled"]?.first ?? "")
        
        What to Watch For:
        ✅ Priority badges appear within 2 seconds
        ✅ Real-time sync across devices
        ✅ Priority Inbox filtering works
        ✅ Offline/online behavior
        """)
    }
}
