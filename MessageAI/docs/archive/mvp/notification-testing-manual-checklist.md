# Notification Testing Manual Checklist

**Purpose:** Manual testing procedures for scenarios that are difficult or impossible to fully automate, particularly terminated app state testing.

**Target:** PR-15 Notification Testing & Validation

**Last Updated:** October 22, 2025

---

## Prerequisites

- [ ] Physical iPhone device (iOS 16+ recommended)
- [ ] Xcode project built and installed on device
- [ ] Firebase project configured with APNs
- [ ] Two test accounts created
- [ ] Firebase Cloud Functions deployed
- [ ] Stopwatch or timer app

---

## T1: Terminated State Notification Delivery

**Goal:** Verify notifications appear within 2 seconds when app is force-quit

### Steps:

1. **Setup:**
   - [ ] Install app on Device A (recipient)
   - [ ] Install app on Device B (sender) or use Firebase Console
   - [ ] Sign in to different accounts on each device
   - [ ] Ensure notification permissions granted on Device A

2. **Force Quit App (Device A):**
   - [ ] Open app on Device A
   - [ ] Swipe up to app switcher
   - [ ] Swipe up on MessageAI to force quit
   - [ ] Verify app is completely closed (not in background)
   - [ ] Lock device or go to home screen

3. **Send Message (Device B or Console):**
   - [ ] Start stopwatch
   - [ ] Send message from Device B to Device A's account
   - [ ] OR: Use Firebase Console to trigger test notification

4. **Observe Notification (Device A):**
   - [ ] **PASS:** Notification appears on lock screen or banner within 2 seconds
   - [ ] **FAIL:** No notification OR notification delayed >2 seconds

5. **Record Results:**
   - Delivery time: _____ seconds
   - Notification appeared: ☐ Yes ☐ No
   - Notification content correct: ☐ Yes ☐ No
   - Screenshots attached: ☐ Yes

---

## T2: Cold Start Navigation from Notification

**Goal:** Verify app cold starts and navigates to conversation within 2 seconds

### Steps:

1. **Setup (Force Quit):**
   - [ ] Force quit app on Device A (as in T1)
   - [ ] Wait for notification to appear (from T1 or send new message)

2. **Tap Notification:**
   - [ ] Start stopwatch
   - [ ] Tap notification banner on Device A
   - [ ] Observe app launch sequence

3. **Verify Navigation:**
   - [ ] **Time to conversation:** _____ seconds (target: <2s)
   - [ ] **PASS:** App launches AND navigates to correct conversation within 2s
   - [ ] **FAIL:** App crashes OR wrong conversation OR >2s delay

4. **Verify App State:**
   - [ ] User authenticated (no re-login required)
   - [ ] Correct conversation loaded
   - [ ] Message visible in conversation
   - [ ] Can send reply immediately

5. **Record Results:**
   - Cold start time: _____ seconds
   - Navigation successful: ☐ Yes ☐ No
   - Correct conversation: ☐ Yes ☐ No
   - App state valid: ☐ Yes ☐ No

---

## T3: App State Initialization After Cold Start

**Goal:** Verify app properly initializes all state after cold start from notification

### Steps:

1. **Cold Start from Notification:**
   - [ ] Force quit app
   - [ ] Receive notification
   - [ ] Tap notification to launch app

2. **Verify Authentication State:**
   - [ ] User is logged in (no auth screen shown)
   - [ ] User profile loaded correctly
   - [ ] FCM token registered

3. **Verify Data State:**
   - [ ] Conversation list accessible
   - [ ] Messages in conversation loaded
   - [ ] User can navigate between views
   - [ ] Can send messages immediately

4. **Verify Notification State:**
   - [ ] Notification badge updated/cleared
   - [ ] Can receive new notifications
   - [ ] Notification permissions still granted

5. **Record Results:**
   - Authentication state: ☐ Valid ☐ Invalid
   - Data loaded: ☐ Yes ☐ No
   - Navigation works: ☐ Yes ☐ No
   - Can send messages: ☐ Yes ☐ No

---

## Multi-Device Group Chat Testing

**Goal:** Verify sender exclusion in group chats with 5 members

### Prerequisites:
- [ ] 5 physical devices OR 4 devices + Firebase Console
- [ ] 5 test accounts created
- [ ] Group chat created with all 5 members

### Steps:

1. **Setup Group Chat:**
   - [ ] Create group chat with 5 members (user1, user2, user3, user4, user5)
   - [ ] Install app on all 5 devices
   - [ ] Sign in with different accounts on each device

2. **Test Sender Exclusion (User1 sends):**
   - [ ] User1: Send message in group chat
   - [ ] User1: **VERIFY NO NOTIFICATION** (sender should never notify self)
   - [ ] User2: Receive notification ☐ Yes ☐ No
   - [ ] User3: Receive notification ☐ Yes ☐ No
   - [ ] User4: Receive notification ☐ Yes ☐ No
   - [ ] User5: Receive notification ☐ Yes ☐ No

3. **Test Sender Exclusion (User3 sends):**
   - [ ] User3: Send message in group chat
   - [ ] User3: **VERIFY NO NOTIFICATION**
   - [ ] User1: Receive notification ☐ Yes ☐ No
   - [ ] User2: Receive notification ☐ Yes ☐ No
   - [ ] User4: Receive notification ☐ Yes ☐ No
   - [ ] User5: Receive notification ☐ Yes ☐ No

4. **Repeat for all members:**
   - [ ] Test with each member as sender (User2, User4, User5)
   - [ ] **CRITICAL:** Sender NEVER receives notification

5. **Record Results:**
   - Total tests: 5 (one per member as sender)
   - Sender exclusion passed: ___/5
   - All recipients notified: ___/5
   - **CRITICAL GATE:** Sender exclusion must be 5/5

---

## Performance Validation with Physical Devices

**Goal:** Measure actual notification latency on physical devices

### Equipment:
- [ ] 2 physical iPhones
- [ ] Stopwatch app or external timer
- [ ] Screen recording enabled (optional)

### Test Scenarios:

#### Scenario 1: Foreground Notification
1. [ ] Device A: Open app, stay in conversation view
2. [ ] Device B: Send message
3. [ ] **Measure:** Time from send tap to notification banner appearance
4. [ ] **Target:** <500ms
5. [ ] **Actual:** _____ ms

#### Scenario 2: Background Notification
1. [ ] Device A: Open app, press Home button (background)
2. [ ] Device B: Send message
3. [ ] **Measure:** Time from send tap to notification appearance
4. [ ] **Target:** <2s
5. [ ] **Actual:** _____ seconds

#### Scenario 3: Background Resume
1. [ ] Device A: Notification appears (background state)
2. [ ] Device A: Tap notification
3. [ ] **Measure:** Time from tap to conversation loaded
4. [ ] **Target:** <1s
5. [ ] **Actual:** _____ seconds

#### Scenario 4: Cold Start
1. [ ] Device A: Force quit app
2. [ ] Device B: Send message
3. [ ] Device A: Wait for notification, tap it
4. [ ] **Measure:** Time from tap to conversation fully loaded
5. [ ] **Target:** <2s
6. [ ] **Actual:** _____ seconds

### Performance Results:
- Foreground: _____ ms (target: <500ms)
- Background delivery: _____ s (target: <2s)
- Background resume: _____ s (target: <1s)
- Cold start: _____ s (target: <2s)

---

## Edge Case Manual Testing

### EC-M1: Airplane Mode During Notification
1. [ ] Enable airplane mode on Device A
2. [ ] Send message from Device B
3. [ ] Wait 30 seconds
4. [ ] Disable airplane mode on Device A
5. [ ] **VERIFY:** Notification appears within 5s of reconnection

### EC-M2: Low Battery Mode
1. [ ] Enable Low Power Mode on Device A
2. [ ] Send message from Device B
3. [ ] **VERIFY:** Notification still appears
4. [ ] **Measure:** Latency (may be slightly higher)

### EC-M3: Multiple Rapid Notifications
1. [ ] Send 10 messages rapidly from Device B (within 10 seconds)
2. [ ] **VERIFY:** All 10 notifications appear on Device A
3. [ ] **VERIFY:** No notifications lost
4. [ ] **VERIFY:** Correct sender names in all notifications

### EC-M4: Notification During Phone Call
1. [ ] Device A: Make or receive phone call
2. [ ] Device B: Send message
3. [ ] **VERIFY:** Notification appears (may be silent)
4. [ ] After call ends: Notification visible in notification center

---

## Cloud Function Validation (Firebase Console)

**Goal:** Verify Cloud Function behavior through Firebase logs

### Steps:

1. **Access Firebase Console:**
   - [ ] Open Firebase Console → Functions → Logs
   - [ ] Set time filter to "Last 30 minutes"

2. **Send Test Message:**
   - [ ] Send message from Device A to Device B
   - [ ] Wait 5 seconds for function execution

3. **Verify Function Logs:**
   - [ ] Function triggered within 1s: ☐ Yes ☐ No
   - [ ] Sender ID logged correctly: ☐ Yes ☐ No
   - [ ] Sender EXCLUDED from recipient list: ☐ Yes ☐ No *(CRITICAL)*
   - [ ] FCM tokens retrieved: ☐ Yes ☐ No
   - [ ] Notification sent successfully: ☐ Yes ☐ No

4. **Check Error Logs:**
   - [ ] No errors logged: ☐ Yes ☐ No
   - [ ] If errors exist, document: _______________

5. **Group Chat Function Test:**
   - [ ] Send message in group chat (5 members)
   - [ ] Verify function logs show:
     - Sender ID: ___________
     - Recipients (should be 4, excluding sender): ___________
     - **CRITICAL:** Sender NOT in recipient list

---

## iOS Version Compatibility

**Goal:** Test on multiple iOS versions if devices available

### iOS 16:
- [ ] T1: Terminated state: ☐ Pass ☐ Fail
- [ ] T2: Cold start: ☐ Pass ☐ Fail
- [ ] Foreground notifications: ☐ Pass ☐ Fail
- [ ] Background notifications: ☐ Pass ☐ Fail

### iOS 17:
- [ ] T1: Terminated state: ☐ Pass ☐ Fail
- [ ] T2: Cold start: ☐ Pass ☐ Fail
- [ ] Foreground notifications: ☐ Pass ☐ Fail
- [ ] Background notifications: ☐ Pass ☐ Fail

### iOS 18 (if available):
- [ ] T1: Terminated state: ☐ Pass ☐ Fail
- [ ] T2: Cold start: ☐ Pass ☐ Fail
- [ ] Foreground notifications: ☐ Pass ☐ Fail
- [ ] Background notifications: ☐ Pass ☐ Fail

---

## Final Validation Checklist

Before marking PR-15 complete, verify:

### Automated Tests:
- [ ] All unit tests pass (Swift Testing)
- [ ] All UI tests pass (XCTest)
- [ ] All integration tests pass
- [ ] All performance tests pass

### Manual Tests (This Checklist):
- [ ] T1: Terminated state notification delivery ✓
- [ ] T2: Cold start navigation ✓
- [ ] T3: App state initialization ✓
- [ ] Multi-device group chat sender exclusion ✓ *(CRITICAL - 5/5 passed)*
- [ ] Performance validation on physical devices ✓

### Critical Gates:
- [ ] **0 self-notifications in all tests** *(CRITICAL)*
- [ ] All performance targets met (95% of tests)
- [ ] No crashes in any test scenario
- [ ] Firebase Cloud Function logs show sender exclusion

### Documentation:
- [ ] All test results documented
- [ ] Screenshots attached for key scenarios
- [ ] Performance measurements recorded
- [ ] Known issues documented (if any)

---

## Test Results Summary

**Date Tested:** _______________  
**Tester:** _______________  
**Device(s):** _______________  
**iOS Version(s):** _______________

### Pass/Fail Summary:
- Terminated State Tests: ___ / 3
- Multi-Device Tests: ___ / 5
- Performance Tests: ___ / 4
- Edge Cases: ___ / 4
- **Overall Pass Rate:** ___ / 16

### Critical Issues Found:
_(List any critical issues discovered during manual testing)_

1. 
2. 
3. 

### Recommendations:
_(Any recommendations for future improvements or additional testing)_

1. 
2. 
3. 

---

## Notes

- **Physical device required:** Notifications do NOT work in iOS Simulator
- **Firebase Cloud Functions:** Must be deployed to staging/production environment
- **Network variability:** Performance may vary based on network conditions
- **Test multiple times:** Run critical tests 3x to account for variability
- **Document outliers:** If a test fails once but passes twice, document it

**Questions or Issues?** Document in test results summary and notify team.

