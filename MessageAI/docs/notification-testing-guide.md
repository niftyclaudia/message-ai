# Notification Testing Guide

**Version:** 1.0  
**Last Updated:** October 22, 2025  
**Owner:** Cody Agent  
**Related PRD:** [pr-15-prd.md](prds/pr-15-prd.md)

---

## Table of Contents

1. [Overview](#overview)
2. [Test Architecture](#test-architecture)
3. [Running Tests](#running-tests)
4. [Test Categories](#test-categories)
5. [Manual Testing](#manual-testing)
6. [Performance Benchmarks](#performance-benchmarks)
7. [Troubleshooting](#troubleshooting)
8. [Regression Testing](#regression-testing)

---

## Overview

This guide covers comprehensive testing of the MessageAI push notification system, including:

- **Unit Tests:** Notification service methods and payload parsing
- **Integration Tests:** Multi-user scenarios and sender exclusion
- **UI Tests:** Foreground, background, and navigation behavior
- **Performance Tests:** Latency measurements and benchmarks
- **Manual Tests:** Terminated state and physical device validation

### Critical Success Criteria

- ✅ **0 self-notifications** — Sender NEVER receives notification for own messages
- ✅ **Performance targets met** — 95% of notifications meet latency targets
- ✅ **0 crashes** — Graceful handling of all edge cases
- ✅ **100% navigation accuracy** — Notifications navigate to correct chat

---

## Test Architecture

### Test Structure

```
MessageAITests/
├── Helpers/
│   ├── NotificationTestService.swift      # Test helper utilities
│   └── TestNotificationPayload.swift      # Test data structures
├── Mocks/
│   └── MockNotificationCenter.swift       # Mock notification center
├── Services/
│   └── NotificationServiceTests.swift     # Unit tests (Swift Testing)
├── Integration/
│   └── NotificationIntegrationTests.swift # Multi-user & edge cases
└── Performance/
    └── NotificationPerformanceTests.swift # Performance validation

MessageAIUITests/
├── NotificationForegroundUITests.swift    # Foreground UI tests
├── NotificationBackgroundUITests.swift    # Background UI tests
└── NotificationNavigationUITests.swift    # Navigation validation
```

### Frameworks Used

- **Swift Testing** (`@Test`) — Unit tests, service tests, integration tests
- **XCTest** (`XCTestCase`) — UI tests and app lifecycle tests

---

## Running Tests

### Prerequisites

1. **Xcode 15+** installed
2. **Physical iPhone device** (iOS 16+) for real notification testing
3. **Firebase project configured** with APNs
4. **Cloud Functions deployed** (for end-to-end testing)
5. **Test accounts created** (at least 2 for multi-user tests)

### Run All Tests (Xcode)

```bash
# Open project
cd /path/to/MessageAI
open MessageAI.xcodeproj

# In Xcode:
# 1. Select scheme: MessageAI
# 2. Product → Test (⌘U)
```

### Run Specific Test Suites

#### Unit Tests Only
```bash
xcodebuild test \
  -scheme MessageAI \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:MessageAITests/NotificationServiceTests
```

#### Integration Tests Only
```bash
xcodebuild test \
  -scheme MessageAI \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:MessageAITests/NotificationIntegrationTests
```

#### UI Tests Only
```bash
xcodebuild test \
  -scheme MessageAI \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:MessageAIUITests
```

#### Performance Tests Only
```bash
xcodebuild test \
  -scheme MessageAI \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:MessageAITests/NotificationPerformanceTests
```

### Run Tests on Physical Device

```bash
# Connect iPhone via USB
# Select device in Xcode
# Product → Test (⌘U)

# Or via command line:
xcodebuild test \
  -scheme MessageAI \
  -destination 'platform=iOS,id=<DEVICE_UDID>'
```

---

## Test Categories

### 1. Unit Tests (`NotificationServiceTests.swift`)

**Coverage:**
- ✅ Notification payload parsing (valid/invalid)
- ✅ Edge cases (empty fields, special characters, long text)
- ✅ Type safety (wrong types, nil values)
- ✅ Error handling (NotificationError descriptions)
- ✅ Test helper integration (TestNotificationPayload)

**Key Tests:**
- `parseValidNotificationPayloadReturnsNotificationPayload()`
- `parseInvalidNotificationPayloadReturnsNil()`
- `parseNotificationPayloadWithSpecialCharactersInMessageText()`
- `parseNotificationPayloadWithVeryLongMessageText()`
- `parseNotificationPayloadWithUnicodeCharacters()`

**Run Time:** ~2 seconds  
**Expected Pass Rate:** 100%

---

### 2. Integration Tests (`NotificationIntegrationTests.swift`)

**Coverage:**
- ✅ Multi-user scenarios (MU1, MU2, MU3)
- ✅ Sender exclusion validation (CRITICAL)
- ✅ Edge cases (EC1-EC6)
- ✅ Group chat notifications
- ✅ Performance baselines

**Critical Tests:**
- `oneOnOneChatOnlyRecipientReceivesNotificationNotSender()` — MU1
- `groupChatSenderExcludedFourRecipientsNotified()` — MU2 (CRITICAL)
- `multipleSimultaneousMessagesCorrectSenderNamesInEach()` — MU3
- `malformedPayloadMissingChatIDNoCrashErrorLogged()` — EC1
- `rapidFireNotificationsAllProcessed()` — EC6

**Run Time:** ~5 seconds  
**Expected Pass Rate:** 100%  
**Critical Gate:** 0 self-notifications

---

### 3. UI Tests

#### Foreground Tests (`NotificationForegroundUITests.swift`)

**Coverage:**
- ✅ FG1: Banner displays <500ms
- ✅ FG2: Tap banner navigates to conversation
- ✅ FG3: Multiple notifications display correctly

**Key Tests:**
- `testForegroundNotification_DisplaysBannerQuickly()`
- `testForegroundNotification_TapBannerNavigatesToConversation()`
- `testForegroundNotification_MultipleNotificationsDisplayCorrectly()`

**Run Time:** ~30 seconds  
**Expected Pass Rate:** 100%

#### Background Tests (`NotificationBackgroundUITests.swift`)

**Coverage:**
- ✅ BG1: Notification appears when app in background
- ✅ BG2: Tap notification resumes app <1s
- ✅ BG3: Navigation works after resume

**Key Tests:**
- `testBackgroundNotification_AppResumesCorrectly()`
- `testBackgroundNotification_TapResumesAppQuickly()`
- `testBackgroundNotification_NavigationAfterResumeWorks()`

**Run Time:** ~45 seconds  
**Expected Pass Rate:** 100%

#### Navigation Tests (`NotificationNavigationUITests.swift`)

**Coverage:**
- ✅ N1: Navigate to correct chat (verify chatID)
- ✅ N2: Multiple notifications each navigate correctly
- ✅ N3: Invalid chatID fallback (no crash)

**Key Tests:**
- `testNotificationNavigation_NavigatesToCorrectChat()`
- `testNotificationNavigation_MultipleNotificationsEachNavigatesCorrectly()`
- `testNotificationNavigation_InvalidChatIDFallsBackToList()`

**Run Time:** ~40 seconds  
**Expected Pass Rate:** 100%

---

### 4. Performance Tests (`NotificationPerformanceTests.swift`)

**Coverage:**
- ✅ P1: End-to-end latency <2s (p95)
- ✅ P2: Foreground display <500ms
- ✅ P3: Background resume <1s
- ✅ P4: Cold start <2s

**Key Tests:**
- `endToEndNotificationLatencyBaseline()` — P1
- `foregroundNotificationDisplayTimeUnder500ms()` — P2
- `backgroundNotificationResumeTimeUnder1s()` — P3
- `coldStartNavigationTimeUnder2s()` — P4

**Run Time:** ~10 seconds  
**Expected Pass Rate:** 95% (allows for network variability)

---

## Manual Testing

### Why Manual Testing?

Some scenarios cannot be fully automated:
1. **Terminated state notifications** — iOS Simulator doesn't support notifications
2. **Physical device behavior** — APNs requires real devices
3. **Cloud Function validation** — Requires Firebase Console inspection
4. **Multi-device coordination** — Requires multiple physical iPhones

### Manual Testing Checklist

**Full checklist:** [notification-testing-manual-checklist.md](notification-testing-manual-checklist.md)

**Key Manual Tests:**
- ✅ T1: Terminated state notification delivery (<2s)
- ✅ T2: Cold start navigation (<2s)
- ✅ T3: App state initialization after cold start
- ✅ Multi-device group chat (5 members, sender exclusion)
- ✅ Performance validation on physical devices

**Required Equipment:**
- 2+ physical iPhones (iOS 16+)
- Stopwatch or timer
- Firebase Console access

---

## Performance Benchmarks

### Target Metrics (from PRD)

| Metric | Target | P95 Acceptable |
|--------|--------|----------------|
| End-to-end latency | <2s | <2.5s |
| Foreground display | <500ms | <750ms |
| Background resume | <1s | <1.5s |
| Cold start navigation | <2s | <3s |
| Cloud Function (warm) | <500ms | <1s |
| Cloud Function (cold) | <3s | <5s |

### Baseline Performance (Expected)

Based on Firebase and APNs typical performance:

- **Foreground:** 100-300ms average
- **Background:** 0.5-1s average
- **Cold start:** 1-2s average
- **End-to-end:** 1-2s average (including network)

### Measuring Performance

#### In Tests:
```swift
let startTime = Date()
// ... perform action ...
let duration = Date().timeIntervalSince(startTime)
#expect(duration < targetLatency)
```

#### On Physical Devices:
1. Use external stopwatch
2. Record 10 measurements
3. Calculate average and p95
4. Compare to targets

---

## Troubleshooting

### Tests Failing: "Notification payload returns nil"

**Cause:** Malformed test data or incorrect userInfo dictionary

**Solution:**
```swift
// Ensure all required fields present:
let userInfo: [AnyHashable: Any] = [
    "chatID": "test-chat",       // ✓ Required
    "senderID": "user-123",      // ✓ Required
    "senderName": "Test User",   // ✓ Required
    "messageText": "Hello"       // ✓ Required
]
```

### UI Tests Failing: "Element not found"

**Cause:** Accessibility identifiers not set or element not visible

**Solution:**
1. Verify accessibility identifiers in SwiftUI views:
   ```swift
   .accessibilityIdentifier("conversationList")
   ```
2. Increase timeout:
   ```swift
   XCTAssertTrue(element.waitForExistence(timeout: 10))
   ```

### Performance Tests Failing: "Latency exceeds target"

**Cause:** Network variability, simulator performance, or Firebase cold start

**Solution:**
1. Run tests 3 times and use median
2. Use p95 instead of hard limits
3. Test on physical device for accurate results
4. Warm up Firebase with a test call first

### Manual Tests: Notifications Not Appearing

**Checklist:**
- [ ] APNs certificate uploaded to Firebase
- [ ] Notification permissions granted on device
- [ ] Device connected to internet
- [ ] Cloud Functions deployed
- [ ] FCM token registered in Firestore
- [ ] Check Firebase Console logs for errors

### Self-Notification Received (CRITICAL BUG)

**This should NEVER happen!**

**Debug Steps:**
1. Check Cloud Function logs in Firebase Console
2. Verify sender exclusion logic:
   ```typescript
   const recipientTokens = members
     .filter(member => member.id !== senderID) // ← This line CRITICAL
     .map(member => member.fcmToken)
   ```
3. Add logging to trace sender ID through entire flow
4. Re-run multi-user integration tests

---

## Regression Testing

### Before Each Release

Run full test suite:

```bash
# 1. Automated tests
xcodebuild test -scheme MessageAI \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# 2. Manual checklist
# Follow: notification-testing-manual-checklist.md

# 3. Performance validation
# Run performance tests on physical device
```

### Regression Test Checklist

- [ ] All automated tests pass (100%)
- [ ] Manual terminated state tests pass (T1, T2, T3)
- [ ] Multi-device sender exclusion verified (0 self-notifications)
- [ ] Performance benchmarks within targets
- [ ] No new crashes or errors in Firebase logs
- [ ] Test on iOS 16, 17, 18 if possible

### When to Regress

Run regression tests when:
- ✅ Notification code changes
- ✅ Firebase configuration changes
- ✅ Cloud Functions updated
- ✅ Major iOS update released
- ✅ Before production release

---

## Test Results Documentation

### Test Run Template

```markdown
## Notification Test Run — [Date]

**Tester:** [Your Name]
**Device(s):** iPhone 15 Pro (iOS 17.5), iPhone 13 (iOS 16.6)
**Environment:** Staging

### Automated Tests:
- Unit Tests: ✅ 35/35 passed
- Integration Tests: ✅ 18/18 passed
- UI Tests: ✅ 24/24 passed
- Performance Tests: ✅ 12/12 passed

### Manual Tests:
- T1 (Terminated): ✅ Pass — 1.2s delivery
- T2 (Cold Start): ✅ Pass — 1.8s navigation
- T3 (State Init): ✅ Pass — All state valid
- Multi-Device: ✅ Pass — 0 self-notifications (5/5)

### Performance:
- Foreground: 280ms avg
- Background: 0.9s avg
- Cold start: 1.7s avg
- End-to-end: 1.4s avg

### Issues Found:
- None

### Confidence Level:
✅ High — Ready for production
```

---

## Common Testing Patterns

### Pattern 1: Test Sender Exclusion

```swift
@Test("Verify sender excluded from recipients")
func verifySenderExcluded() async throws {
    let testService = NotificationTestService()
    let result = await testService.verifySenderExclusion(
        chatID: "test-chat",
        senderID: "user-sender",
        expectedRecipients: ["user1", "user2", "user3"]
    )
    
    #expect(result.passed == true)
    #expect(!result.actualRecipients.contains("user-sender"))
}
```

### Pattern 2: Test Navigation

```swift
func testNavigationToChat() throws {
    authenticateTestUser()
    
    let conversationList = app.tables["conversationList"]
    XCTAssertTrue(conversationList.waitForExistence(timeout: 5))
    
    let firstCell = conversationList.cells.element(boundBy: 0)
    firstCell.tap()
    
    let conversationView = app.otherElements["conversationView"]
    XCTAssertTrue(conversationView.waitForExistence(timeout: 3))
}
```

### Pattern 3: Test Performance

```swift
@Test("Measure operation latency")
func measureLatency() async throws {
    let startTime = Date()
    
    // Perform operation
    _ = await testService.simulateNotification(
        payload: payload,
        appState: .foreground
    )
    
    let latency = Date().timeIntervalSince(startTime)
    #expect(latency < 0.5) // 500ms target
}
```

---

## Appendix: Test Data

### Sample Notification Payload

```json
{
  "chatID": "chat-abc-123",
  "senderID": "user-456",
  "senderName": "John Doe",
  "messageText": "Hello, how are you?"
}
```

### Sample Test Users

```swift
let testUsers = [
    ("test1@example.com", "user-001"),
    ("test2@example.com", "user-002"),
    ("test3@example.com", "user-003"),
    ("test4@example.com", "user-004"),
    ("test5@example.com", "user-005")
]
```

---

## Questions & Support

**For testing questions:**
- Review this guide
- Check [PR-15 PRD](prds/pr-15-prd.md) for requirements
- Inspect test code for examples

**For bugs found during testing:**
1. Document reproduction steps
2. Capture screenshots/logs
3. Note iOS version and device
4. Check Firebase Console logs
5. Create issue with all details

---

**Last Updated:** October 22, 2025  
**Next Review:** Before each major release

