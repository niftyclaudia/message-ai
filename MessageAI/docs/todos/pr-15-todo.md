# PR-15 TODO — Notification Testing & Validation

**Branch**: `test/pr-15-notification-testing`  
**Source PRD**: `MessageAI/docs/prds/pr-15-prd.md`  
**Owner (Agent)**: Cody  
**Dependencies**: PR #13 (APNs/FCM Setup), PR #14 (Cloud Functions)

---

## 0. Setup

- [ ] Confirm PR #13 and PR #14 are complete and deployed
- [ ] Read PRD thoroughly (`pr-15-prd.md`)
- [ ] Read `MessageAI/agents/shared-standards.md` for testing patterns
- [ ] Ensure physical iPhone available (notifications don't work in simulator)
- [ ] Verify Firebase project has notifications enabled

---

## 1. Test Infrastructure Setup

- [ ] Create test helper class: `MessageAITests/Helpers/NotificationTestService.swift`
  - Methods for simulating notifications, measuring latency, validating payloads
  - Test Gate: Helper compiles and provides all needed methods
  
- [ ] Create test data structures: `MessageAITests/Helpers/TestNotificationPayload.swift`
  - `TestNotificationPayload`, `NotificationTestResult` structs
  - Test Gate: Structs properly defined with all fields
  
- [ ] Create mock: `MessageAITests/Mocks/MockNotificationCenter.swift`
  - Mock UNUserNotificationCenter for unit testing
  - Test Gate: Mock allows testing without actual notifications

---

## 2. Unit Tests (Swift Testing)

- [ ] Create `MessageAITests/Services/NotificationServiceTests.swift`
  - Test `requestPermission()` with granted/denied scenarios
  - Test `registerForNotifications()` with valid user ID
  - Test `updateToken()` for token refresh
  - Test `removeToken()` on logout
  - Test `handleForegroundNotification()` returns correct presentation options
  - Test `parseNotificationPayload()` with valid/invalid payloads
  - Test Gate: All unit tests pass; 100% method coverage

---

## 3. Foreground Notification Tests (XCTest)

- [ ] Create `MessageAIUITests/NotificationForegroundUITests.swift`
  - **FG1:** Test notification banner displays when app in foreground
  - **FG2:** Test tapping banner navigates to conversation
  - **FG3:** Test multiple sequential notifications display correctly
  - Test Gate: All foreground tests pass; banner displays <500ms

---

## 4. Background Notification Tests (XCTest + Manual)

- [ ] Create `MessageAIUITests/NotificationBackgroundUITests.swift`
  - **BG1:** Test notification appears when app in background
  - **BG2:** Test tapping notification resumes app to conversation
  - **BG3:** Test multiple notifications while in background
  - Test Gate: All background tests pass; resume time <1s
  
- [ ] Manual testing checklist for background scenarios
  - Test on physical device: background notifications appear
  - Measure resume time with stopwatch
  - Test Gate: Manual tests documented with pass/fail results

---

## 5. Terminated State Tests (Manual + Partial Automation)

- [ ] Create manual testing checklist
  - **T1:** Force quit app → send message → verify notification appears <2s
  - **T2:** Tap notification → app cold starts → navigates to conversation <2s
  - **T3:** Verify app state properly initialized (user authenticated, data loaded)
  - Test Gate: All terminated tests pass; documented with screenshots
  
- [ ] Automate what's possible: app launch from notification
  - Test app launches when tapping notification
  - Test Gate: Automated portion passes

---

## 6. Multi-User & Group Chat Tests (Swift Testing)

- [ ] Create `MessageAITests/Integration/NotificationIntegrationTests.swift`
  - **MU1:** Test 1-on-1 chat → only recipient receives notification (not sender)
  - **MU2:** Test group chat (5 members) → sender excluded, 4 recipients notified
  - **MU3:** Test multiple simultaneous messages → correct sender names in each
  - Test Gate: **CRITICAL** - 0 self-notifications; sender always excluded

---

## 7. Edge Case Tests (Swift Testing + XCTest)

- [ ] Add edge case tests to integration test file
  - **EC1:** Malformed payload (missing chatID) → no crash, error logged
  - **EC2:** Notification for non-existent chat → fallback to conversation list
  - **EC3:** User has no FCM token → skip user, log, continue to others
  - **EC4:** Invalid/expired token → token cleanup triggered
  - **EC5:** Empty message text → placeholder displayed
  - **EC6:** Rapid-fire notifications (10+ sequential) → all processed
  - Test Gate: All edge cases handled gracefully; 0 crashes

---

## 8. Performance Validation Tests

- [ ] Add performance tests to integration file
  - **P1:** Measure end-to-end latency (message send → notification display)
  - **P2:** Measure foreground display time (FCM receipt → banner)
  - **P3:** Measure background resume time (tap → conversation)
  - **P4:** Measure cold start navigation time (tap → conversation loaded)
  - Test Gate: 95% of measurements meet targets; outliers documented
  
- [ ] Document performance benchmarks
  - Create results table with actual measurements
  - Test Gate: Benchmarks saved for future regression testing

---

## 9. Navigation Validation Tests (XCTest)

- [ ] Create `MessageAIUITests/NotificationNavigationUITests.swift`
  - **N1:** Test tapping notification navigates to correct chat (verify chatID)
  - **N2:** Test multiple notifications → tapping each navigates correctly
  - **N3:** Test invalid chatID → fallback to conversation list (no crash)
  - Test Gate: 100% navigation accuracy; 0 crashes

---

## 10. Cloud Function Integration Tests

- [ ] Test Cloud Function behavior via Firebase Console
  - **CF1:** Send test message → verify function triggers <1s (check logs)
  - **CF2:** Verify sender excluded from recipient list in logs
  - **CF3:** Test with user who has no token → verify graceful handling
  - **CF4:** Verify structured error logging with context
  - Test Gate: Function logs show correct behavior; sender always excluded

- [ ] Automated Cloud Function validation (if possible)
  - Query Cloud Function logs programmatically
  - Verify execution time, sender exclusion, error handling
  - Test Gate: Automated checks pass

---

## 11. Multi-Device Physical Testing

- [ ] Test with 2+ physical iPhones
  - Device A sends message → Device B receives notification <2s
  - Group chat: 3 devices → sender not notified, others are
  - Test different app states simultaneously (A in foreground, B in background, C terminated)
  - Test Gate: All devices receive notifications correctly; sender never notified
  
- [ ] Test on different iOS versions (if devices available)
  - iOS 16 and iOS 17+ at minimum
  - Document any version-specific behavior
  - Test Gate: Works on all tested iOS versions

---

## 12. Documentation

- [ ] Create `MessageAI/docs/notification-testing-guide.md`
  - Testing procedures for all scenarios
  - Manual testing checklist with pass/fail criteria
  - Performance benchmark targets
  - Common issues and troubleshooting steps
  - Test Gate: Comprehensive guide ready for future regression testing
  
- [ ] Document test results
  - Summary of all test categories with pass/fail status
  - Performance measurements table
  - Screenshots of key scenarios
  - Known issues and limitations
  - Test Gate: Complete results documented

---

## 13. Bug Fixes (If Any Found)

- [ ] Document any bugs discovered during testing
  - Create list with severity, reproduction steps, proposed fix
  
- [ ] Fix critical bugs found during testing
  - Fix in separate commits for traceability
  - Re-run affected tests after fixes
  - Test Gate: All critical bugs fixed and verified
  
- [ ] Update test cases if bugs exposed gaps in coverage
  - Add regression tests for bugs found
  - Test Gate: New tests pass

---

## 14. Final Validation

- [ ] Run complete test suite one final time
  - All unit tests pass (Swift Testing)
  - All UI tests pass (XCTest)
  - All manual tests checked off
  - All integration tests pass
  - Test Gate: 100% test pass rate
  
- [ ] Verify all acceptance gates from PRD Section 12
  - [ ] Foreground: 3/3 tests pass
  - [ ] Background: 3/3 tests pass
  - [ ] Terminated: 3/3 tests pass
  - [ ] Multi-user: 3/3 tests pass
  - [ ] Edge cases: 6/6 tests pass
  - [ ] Performance: 6/6 targets met
  - [ ] Navigation: 3/3 tests pass
  - [ ] Cloud Function: 4/4 tests pass
  
- [ ] Create test results summary report
  - Overall pass rate
  - Performance benchmarks
  - Known issues
  - Recommendations for future work
  - Test Gate: Summary report complete

---

## 15. Handoff & Review

- [ ] Commit all test files and documentation
  - Verify all new files included
  - No commented-out code
  - No debug logs left in
  
- [ ] Review checklist:
  - [ ] All test files created and passing
  - [ ] Physical device testing complete
  - [ ] Performance benchmarks documented
  - [ ] 0 critical bugs remaining
  - [ ] Testing guide created
  - [ ] Test results summary complete
  
- [ ] Present results to user
  - Summary of testing effort (X tests, Y categories)
  - Pass rate and performance results
  - Any bugs found and fixed
  - Confidence level for production deployment

---

## Quick Reference: Test Files to Create

```
MessageAITests/
├── Helpers/
│   ├── NotificationTestService.swift       (NEW)
│   └── TestNotificationPayload.swift       (NEW)
├── Mocks/
│   └── MockNotificationCenter.swift        (NEW)
├── Services/
│   └── NotificationServiceTests.swift      (NEW - Swift Testing)
└── Integration/
    └── NotificationIntegrationTests.swift  (NEW - Swift Testing)

MessageAIUITests/
├── NotificationForegroundUITests.swift     (NEW - XCTest)
├── NotificationBackgroundUITests.swift     (NEW - XCTest)
└── NotificationNavigationUITests.swift     (NEW - XCTest)

MessageAI/docs/
└── notification-testing-guide.md           (NEW)
```

---

## Notes

- **Physical Device Required:** Notifications don't work in iOS Simulator - must use real iPhone
- **Manual Testing Essential:** Terminated state and some background scenarios difficult to fully automate
- **Sender Exclusion Critical:** This is the most important test - sender must NEVER receive self-notification
- **Performance Metrics:** Use p95 instead of hard limits; network variance is expected
- **Test Data Cleanup:** Use test user prefixes; cleanup in tearDown(); provide manual script if needed
- **Cloud Function Logs:** Use Firebase Console to verify function execution and sender exclusion

