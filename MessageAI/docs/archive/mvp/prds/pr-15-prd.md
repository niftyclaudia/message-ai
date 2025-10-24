# PRD: Notification Testing & Validation

**Feature**: Comprehensive Notification System Testing

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 4

**Links**: [PR Brief: PR #15](../pr-brief/pr-briefs.md), [TODO: pr-15-todo.md](../todos/pr-15-todo.md), [Dependencies: PR #13](pr-13-prd.md), [PR #14](pr-14-prd.md)

---

## 1. Summary

Create comprehensive test suites to validate the complete push notification system across all app states (foreground, background, terminated) and ensure proper end-to-end notification delivery. This PR establishes confidence that notifications work reliably in all scenarios before production release.

---

## 2. Problem & Goals

**Problem:** The notification infrastructure (PR #13) and Cloud Functions (PR #14) are implemented but not comprehensively tested. Without thorough testing across all app states and edge cases, we risk shipping critical bugs.

**Why Now:** Phase 4, immediately following PR #13 and PR #14. All notification code is implemented; now we must validate it works correctly.

**Goals:**
- [x] G1 — Create test suites covering 100% of notification scenarios (foreground, background, terminated, edge cases)
- [x] G2 — Validate notification delivery time <2 seconds in 95% of test cases
- [x] G3 — Verify 0 critical bugs (crashes, self-notifications, navigation failures)

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing new notification features (only testing existing)
- [ ] Not implementing notification customization settings
- [ ] Not implementing multi-device token management
- [ ] Not implementing rich media notifications

---

## 4. Success Metrics

**User-visible:**
- Notification delivery success rate: >99% across all app states
- Notification tap → conversation load time: <1 second
- 0 self-notifications sent
- 0 crashes when handling notifications

**System:**
- End-to-end latency: <2s (p95) from message send to notification display
- Foreground display: <500ms from FCM receipt
- Background resume: <1s from tap to conversation
- Cold start: <2s from tap to conversation view

**Quality:**
- 0 blocking bugs identified
- All acceptance gates pass
- Crash-free rate >99.9%

---

## 5. Users & Stories

- As a user, I want to receive notifications reliably whether my app is open, in background, or closed so I never miss messages.
- As a user, I want to tap a notification and be taken directly to the conversation so I can respond immediately.
- As a developer, I want comprehensive test coverage so I can confidently deploy and maintain the notification system.

---

## 6. Experience Specification (UX)

### Testing Flows

**Foreground:** User in app → notification arrives → banner displays <500ms → tap navigates to conversation

**Background:** User on Home screen → notification arrives <2s → tap resumes app <1s → conversation loads

**Terminated:** App force-quit → notification arrives <2s → tap cold starts app → conversation loads <2s

**Group Chat:** 5 members → sender sends message → 4 recipients get notifications (sender excluded)

### Performance Targets

- End-to-end: <2s | Foreground: <500ms | Background: <1s | Cold start: <2s | Main thread never blocked >50ms

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**M1: App State Testing**
- MUST test foreground notification display and navigation
- MUST test background notification delivery and app resume
- MUST test terminated state notification and cold start
- **[Gate M1]** All app states tested; all pass with latency targets met

**M2: Multi-User Testing**
- MUST test 1-on-1 chat (only recipient receives notification)
- MUST test group chat (sender excluded, all others receive)
- MUST verify sender NEVER receives self-notification
- **[Gate M2]** 0 self-notifications; correct sender exclusion in 100% of tests

**M3: Edge Case Testing**
- MUST test malformed notification payload (no crash)
- MUST test notification for non-existent chat (graceful fallback)
- MUST test missing FCM tokens (skip user, log, continue)
- MUST test invalid/expired tokens (cleanup triggered)
- MUST test rapid-fire notifications (10+ sequential)
- **[Gate M3]** All edge cases handled gracefully; 0 crashes; proper error logging

**M4: Performance Validation**
- MUST measure end-to-end latency (message send → notification display)
- MUST measure foreground display time
- MUST measure background resume time
- MUST measure cold start navigation time
- **[Gate M4]** 95% of tests meet performance targets; outliers documented

**M5: Navigation Validation**
- MUST test tapping notification navigates to correct chat (verify chatID)
- MUST test navigation from all app states
- MUST test navigation fallback if chatID invalid (show conversation list)
- **[Gate M5]** 100% navigation accuracy; 0 navigation crashes

**M6: Cloud Function Testing**
- MUST test Cloud Function triggers on new message
- MUST test sender exclusion in recipient list
- MUST test handling of missing tokens
- MUST test error logging
- **[Gate M6]** Sender excluded 100%; errors logged with context

### SHOULD Requirements

**S1: Automated Coverage**
- SHOULD create automated UI tests for foreground/background scenarios
- SHOULD create unit tests for NotificationService methods
- SHOULD document manual testing procedures for terminated state

**S2: Multi-Device Testing**
- SHOULD test with 2+ physical devices simultaneously
- SHOULD test with different iOS versions (15, 16, 17+)

---

## 8. Data Model

### Test Data Structures

```swift
struct TestNotificationPayload {
    let chatID: String
    let senderID: String
    let senderName: String
    let messageText: String
    let testID: String  // For tracking
    let expectedRecipients: [String]
}

struct NotificationTestResult {
    let testID: String
    let testName: String
    let appState: AppState  // .foreground, .background, .terminated
    let passed: Bool
    let actualLatency: TimeInterval
    let error: String?
}
```

---

## 9. API / Service Contracts

### NotificationTestService.swift (NEW)

```swift
class NotificationTestService {
    /// Simulate notification arrival in specific app state
    func simulateNotification(
        payload: TestNotificationPayload, 
        appState: AppState
    ) async -> NotificationTestResult
    
    /// Measure notification delivery latency
    func measureNotificationLatency(
        messageID: String, 
        startTime: Date
    ) async -> TimeInterval
    
    /// Verify sender exclusion in group chat
    func verifySenderExclusion(
        chatID: String, 
        senderID: String, 
        expectedRecipients: [String]
    ) async -> (passed: Bool, actualRecipients: [String])
    
    /// Test navigation from notification tap
    func testNotificationNavigation(
        toChatID chatID: String, 
        fromState appState: AppState
    ) async -> Bool
}
```

---

## 10. UI Components to Create/Modify

### New Files

**Testing:**
- `MessageAITests/Services/NotificationServiceTests.swift` — Unit tests (Swift Testing)
- `MessageAITests/Integration/NotificationIntegrationTests.swift` — End-to-end tests (Swift Testing)
- `MessageAIUITests/NotificationForegroundUITests.swift` — UI tests for foreground (XCTest)
- `MessageAIUITests/NotificationBackgroundUITests.swift` — UI tests for background (XCTest)
- `MessageAIUITests/NotificationNavigationUITests.swift` — Navigation tests (XCTest)

**Helpers:**
- `MessageAITests/Helpers/NotificationTestService.swift` — Test helper class
- `MessageAITests/Mocks/MockNotificationCenter.swift` — Mock UNUserNotificationCenter

**Documentation:**
- `MessageAI/docs/notification-testing-guide.md` — Testing procedures and checklist

### Modified Files

None (testing-focused PR, no production code changes unless bugs found)

---

## 11. Integration Points

- **Firebase Cloud Functions** — Test function triggers and execution
- **FCM** — Test notification delivery
- **APNs** — Test on physical devices (required)
- **Firestore** — Verify token storage/retrieval
- **iOS User Notifications** — Test delegate methods in all app states

---

## 12. Test Plan & Acceptance Gates

### Foreground Tests
- [ ] **FG1:** Notification arrives → banner displays <500ms
- [ ] **FG2:** Tap banner → navigates to conversation
- [ ] **FG3:** Multiple notifications → all display correctly

### Background Tests
- [ ] **BG1:** App in background → notification appears <2s
- [ ] **BG2:** Tap notification → app resumes <1s
- [ ] **BG3:** Navigation to correct conversation works

### Terminated Tests
- [ ] **T1:** App force-quit → notification appears <2s
- [ ] **T2:** Tap → cold starts app to conversation <2s
- [ ] **T3:** App state properly initialized

### Multi-User Tests
- [ ] **MU1:** 1-on-1 chat → only recipient notified, not sender
- [ ] **MU2:** Group chat (5 members) → sender excluded, 4 notified
- [ ] **MU3:** Multiple simultaneous messages → correct sender names

### Edge Cases
- [ ] **EC1:** Malformed payload → no crash, error logged
- [ ] **EC2:** Non-existent chat → fallback to conversation list
- [ ] **EC3:** Missing FCM token → skip user, continue
- [ ] **EC4:** Invalid token → cleanup triggered
- [ ] **EC5:** Empty message text → placeholder displayed
- [ ] **EC6:** Rapid-fire (10+ notifications) → all processed

### Performance
- [ ] **P1:** End-to-end <2s (95% of tests)
- [ ] **P2:** Foreground display <500ms average
- [ ] **P3:** Background resume <1s average
- [ ] **P4:** Cold start <2s average
- [ ] **P5:** Cloud Function cold start <3s
- [ ] **P6:** Cloud Function warm execution <500ms

### Navigation
- [ ] **N1:** Tap → correct chat (chatID matches)
- [ ] **N2:** Multiple notifications → each navigates correctly
- [ ] **N3:** Invalid chatID → fallback to list

### Cloud Function
- [ ] **CF1:** New message → function triggers <1s
- [ ] **CF2:** Sender excluded from recipient list
- [ ] **CF3:** Missing tokens handled gracefully
- [ ] **CF4:** Structured error logging present

---

## 13. Definition of Done

**Testing:**
- [ ] All test files created and passing
- [ ] Foreground tests pass (3/3)
- [ ] Background tests pass (3/3)
- [ ] Terminated tests pass (3/3)
- [ ] Multi-user tests pass (3/3)
- [ ] Edge case tests pass (6/6)
- [ ] Performance tests pass (6/6)
- [ ] Navigation tests pass (3/3)
- [ ] Cloud Function tests pass (4/4)

**Performance:**
- [ ] All latency targets validated and met
- [ ] Performance benchmarks documented

**Quality:**
- [ ] 0 critical bugs found
- [ ] All edge cases handled gracefully
- [ ] Test results documented

**Documentation:**
- [ ] Testing guide created
- [ ] Regression checklist created
- [ ] Known issues documented

**Physical Device:**
- [ ] Tested on physical iPhone (notifications don't work in simulator)
- [ ] Tested on iOS 16+ at minimum

---

## 14. Risks & Mitigations

**R1: Physical Device Required** → Document requirement; use TestFlight if needed  
**R2: Terminated State Hard to Automate** → Create manual testing checklist  
**R3: Network Timing Variability** → Use p95 metrics; test under controlled conditions  
**R4: Cloud Function Cold Starts** → Measure cold/warm separately; document variance  
**R5: iOS Version Differences** → Test on multiple iOS versions; document differences

---

## 15. Rollout & Telemetry

**Testing Rollout:**
1. Create test suite structure and helpers
2. Implement foreground tests (automated)
3. Implement background tests (UI + manual)
4. Implement terminated state tests (manual checklist)
5. Implement edge case and performance tests
6. Run full suite on physical devices
7. Document results and create regression checklist

**Metrics:**
- Test pass rate (target: 100%)
- Performance benchmarks (for future comparison)
- Bug discovery rate (target: 0 critical bugs)

**Manual Validation:**
1. Test all app states on physical device
2. Verify sender exclusion in group chats
3. Test edge cases (malformed payload, missing chat, etc.)
4. Measure performance with timer
5. Verify Cloud Function logs in Firebase Console

---

## 16. Open Questions

**Q1: Automated vs Manual for Terminated State?** → Manual with comprehensive checklist; automate what's possible

**Q2: How to Handle Flaky Tests?** → Use p95 metrics; controlled network; rerun 3x before marking failed

**Q3: Test Data Cleanup?** → Use prefixes; cleanup in tearDown(); provide manual cleanup script

---

## 17. Appendix: Out-of-Scope Backlog

- [ ] Automated multi-device testing infrastructure
- [ ] Notification delivery analytics dashboard
- [ ] Advanced performance profiling with Instruments
- [ ] Notification stress testing (1000+ rapid notifications)
- [ ] Accessibility testing (VoiceOver, Dynamic Type)

---

## Authoring Notes

- This is a **testing and validation PR**, not a feature implementation
- Focus on comprehensive coverage across all scenarios
- Physical device testing mandatory (simulator doesn't support notifications)
- Create reusable test helpers for future notification testing
- Document any bugs found and fix before PR #16 (final polish)
