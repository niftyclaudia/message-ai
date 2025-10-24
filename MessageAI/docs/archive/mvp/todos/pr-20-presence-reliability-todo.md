# PR-20 TODO — Presence Indicator Reliability

**Branch**: `feat/pr-20-presence-reliability`  
**Source PRD**: `MessageAI/docs/prds/pr-20-presence-reliability-prd.md`  
**Owner**: Cody Agent (Implementation)

---

## 0. Clarifying Questions & Assumptions

**Questions:**
- Should we show "Reconnecting..." indicator during retries?
  - **Answer from PRD**: No (silent retry, Calm Intelligence)
- Backoff intervals: 1s→2s→4s or faster?
  - **Answer from PRD**: Start with 1s→2s→4s, adjust based on data
- Presence for blocked users?
  - **Answer from PRD**: Hide (privacy)

**Assumptions:**
- MVP presence system exists but has reliability issues
- Firebase Realtime Database SDK is available
- PresenceService exists and needs complete rewrite
- ConversationRowView, ChatHeaderView, GroupMemberListView exist

---

## 1. Setup

- [ ] Create branch from develop: `git checkout -b feat/pr-20-presence-reliability`
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm Firebase Realtime Database SDK available
- [ ] Review existing PresenceService implementation (understand current issues)
- [ ] Review existing PresenceIndicator UI component

---

## 1. Data Model & Firebase Setup (30 min)

- [ ] Define `PresenceStatus` struct in Models/
  - Test Gate: Compiles with no errors
- [ ] Create Firebase Realtime Database rules for `/presence/{userID}`
  - Test Gate: Users can write only own presence, read all
- [ ] Add `presenceStatus` and `lastSeen` fields to User model
  - Test Gate: User model compiles

---

## 2. PresenceService Core (60 min)

**REWRITE existing PresenceService with reliability fixes**

- [ ] Implement `setPresence(status:)` with Firebase Realtime Database write
  - Add onDisconnect hook setup
  - Test Gate: Unit test passes (online/offline writes)
  
- [ ] Implement `observePresence(for:completion:)` with real-time listener
  - Handle connection state changes
  - Test Gate: Unit test receives updates <500ms
  
- [ ] Implement `observeMultiplePresence(for:completion:)` for batch subscriptions
  - Optimize for group chats (3-10 users)
  - Test Gate: All user presence statuses update correctly
  
- [ ] Implement `fetchLastSeen(for:)` fallback
  - Test Gate: Returns accurate timestamp

---

## 3. Retry Logic & Connection Monitoring (45 min)

- [ ] Implement `retrySetPresence(status:attempt:)` with exponential backoff
  - Test Gate: Retry delays are 1s→2s→4s (±100ms)
- [ ] Implement `calculateBackoff(for:)` helper
  - Test Gate: Returns correct intervals
- [ ] Implement `observeConnectionStatus(completion:)` 
  - Test Gate: Detects Firebase connect/disconnect <500ms
- [ ] Implement `reconnect(retryCount:)` with max 3 attempts
  - Test Gate: Falls back after 3 failures

---

## 4. Lifecycle Hooks (30 min)

- [ ] Implement `handleAppForeground()` → set online
  - Test Gate: User goes online when app activates
- [ ] Implement `handleAppBackground()` → set offline + lastSeen
  - Test Gate: User goes offline when app backgrounds
- [ ] Implement `initializePresence()` → setup on launch
  - Test Gate: Presence initialized <2s
- [ ] Implement `cleanupPresence()` → teardown on logout
  - Test Gate: Listeners removed, user set offline
- [ ] Add onDisconnect hook for force-quit
  - Test Gate: Force-quit sets user offline automatically

---

## 5. UI Components (45 min)

- [ ] Create `Components/PresenceIndicatorView.swift`
  - Green/gray circle with 200ms fade animation
  - Test Gate: SwiftUI Preview renders correctly
- [ ] Create `Utilities/PresenceMonitor.swift`
  - Connection health monitoring wrapper
  - Test Gate: Publishes connection state changes
- [ ] Update `ConversationRowView.swift`
  - Replace old indicator with PresenceIndicatorView
  - Test Gate: Shows real-time presence
- [ ] Update `ChatHeaderView.swift`
  - Add PresenceIndicatorView next to name
  - Test Gate: Updates within 500ms
- [ ] Update `GroupMemberListView.swift`
  - Add presence for each member
  - Test Gate: Shows status for all members

---

## 6. App Lifecycle Integration (20 min)

- [ ] Update `MessageAIApp.swift`
  - Call `initializePresence()` on launch
  - Call `handleAppForeground()` on `.onAppear`
  - Call `handleAppBackground()` on `.scenePhase` change
  - Test Gate: Lifecycle hooks triggered correctly

---

## 7. Testing Validation

**Note**: Manual testing validation per `MessageAI/agents/shared-standards.md`

### 7.1 Configuration Testing

- [ ] Firebase Realtime Database connection for presence
  - Test Gate: PresenceService connects successfully
- [ ] Firebase security rules deployed and enforced
  - Test Gate: Users can only write own presence, read all
- [ ] PresenceService initialized in MessageAIApp.swift
  - Test Gate: No runtime errors about missing dependencies
- [ ] All Firebase config set (GoogleService-Info.plist)
  - Test Gate: App connects to correct Firebase project

### 7.2 Happy Path Testing

**Basic Presence Updates:**
- [ ] User A launches app → User A goes online in Realtime DB within 500ms
  - Test Gate: onDisconnect hook set correctly
- [ ] User B sees User A's green indicator within 500ms in conversation list
  - Test Gate: Real-time presence update works
- [ ] User A closes app → User A goes offline within 500ms
  - Test Gate: onDisconnect hook fires correctly
- [ ] User B sees User A's gray indicator within 500ms
  - Test Gate: Offline transition propagates

**Fade Animations:**
- [ ] Online → Offline transition shows smooth 200ms fade
  - Test Gate: Green fades to gray smoothly (no jarring flash)
- [ ] Offline → Online transition shows smooth 200ms fade
  - Test Gate: Gray fades to green smoothly
- [ ] Animation maintains 60 FPS (no dropped frames)
  - Test Gate: Use Xcode Instruments to verify

**Multi-Surface Consistency:**
- [ ] Green indicator renders correctly in ConversationRowView
  - Test Gate: Visual appearance matches design specs
- [ ] Green indicator renders correctly in ChatHeaderView (1-on-1)
  - Test Gate: Header indicator displays properly
- [ ] Green indicator renders correctly in GroupMemberListView
  - Test Gate: Group member indicators work
- [ ] All three surfaces update simultaneously (<100ms delta)
  - Test Gate: No stale states across surfaces

**Retry Logic:**
- [ ] Simulate network failure during setPresence
  - Test Gate: Retry #1 after 1s, Retry #2 after 2s, Retry #3 after 4s
- [ ] After 3 failures → Fallback to lastSeen timestamp
  - Test Gate: UI shows "Last seen X ago" instead of real-time status
- [ ] Network restored → Retry succeeds and resumes real-time updates
  - Test Gate: Recovers gracefully without requiring app restart

### 7.3 Edge Cases Testing

**Connection Issues:**
- [ ] Airplane Mode enabled mid-session → Shows cached presence
  - Test Gate: Cached state displays, no crashes
- [ ] Network flapping (rapid on/off 5x in 10s) → Debounces correctly
  - Test Gate: 2s delay before showing offline prevents flicker
- [ ] Firebase Realtime Database unavailable → Fallback to lastSeen
  - Test Gate: Graceful degradation, no crashes
- [ ] Poor connection (high latency) → Retry logic works
  - Test Gate: Exponential backoff prevents overload

**App Lifecycle:**
- [ ] Foreground → Background → Foreground cycle
  - Test Gate: User goes offline when backgrounded, online when foregrounded
- [ ] App force-quit (swipe up from app switcher)
  - Test Gate: onDisconnect hook sets user offline
- [ ] App force-quit → Relaunch
  - Test Gate: User goes online within 2s of launch
- [ ] Background for 30+ seconds → Network drop simulation
  - Test Gate: Reconnects and syncs on foreground

**Invalid Data:**
- [ ] Invalid user ID → Default offline state, no crash
  - Test Gate: Error handled gracefully
- [ ] Presence data missing from Realtime DB → Shows offline
  - Test Gate: Missing data doesn't break UI
- [ ] Malformed presence data → Falls back to lastSeen
  - Test Gate: Data validation works

**Large Scale:**
- [ ] 1000+ contacts in conversation list
  - Test Gate: Virtualized list unsubscribes from off-screen presence
- [ ] Memory usage with 1000+ contacts < 50MB for presence
  - Test Gate: Use Xcode Memory Graph Debugger to verify
- [ ] Scroll performance remains 60 FPS with 100+ visible indicators
  - Test Gate: Use Instruments to measure frame rate

### 7.4 Multi-Device Testing

- [ ] Device 1: User A goes online → Device 2: User B sees green within 500ms
  - Test Gate: Multi-device presence sync works
- [ ] Device 1: User A goes offline → Device 2: User B sees gray within 500ms
  - Test Gate: Multi-device offline sync works
- [ ] Device 1: User A force-quits → Device 2: User B sees offline within 500ms
  - Test Gate: onDisconnect propagates across devices
- [ ] Test with 3+ devices simultaneously
  - Test Gate: Multi-device consistency maintained
- [ ] All devices on different networks (WiFi, LTE, 5G)
  - Test Gate: Network type doesn't affect sync speed

### 7.5 Offline Behavior Testing

- [ ] Offline: Cached presence state displays (last known status)
  - Test Gate: Shows cached green/gray indicator
- [ ] Offline: LastSeen timestamp shows when real-time unavailable
  - Test Gate: "Last seen X ago" displays correctly
- [ ] Reconnect after 1 minute offline → Syncs within 1s
  - Test Gate: Reconnection fast and reliable
- [ ] Messages sent offline → Presence changes queue locally
  - Test Gate: Offline queue syncs on reconnect
- [ ] Cold start while offline → Shows cached state immediately
  - Test Gate: No loading spinner for cached presence

### 7.6 Performance Testing

**Latency Measurement:**
- [ ] Measure p50 propagation latency over 100 presence changes
  - Use PerformanceMonitor.swift to track
  - Test Gate: p50 < 200ms
- [ ] Measure p95 propagation latency
  - Test Gate: p95 < 500ms
- [ ] Measure p99 propagation latency
  - Test Gate: p99 < 1000ms
- [ ] Retry success rate over 50 simulated failures
  - Test Gate: >95% success within 3 attempts

**Rendering Performance:**
- [ ] Chat list with 50+ contacts renders at 60 FPS
  - Use Xcode Instruments to measure frame rate
  - Test Gate: Smooth scrolling, no frame drops
- [ ] 10+ presence indicators on screen simultaneously
  - Test Gate: No performance degradation
- [ ] Animation performance with 20+ indicators transitioning
  - Test Gate: All animations maintain 60 FPS
- [ ] Memory usage with 100+ presence subscriptions
  - Use Xcode Memory Graph Debugger
  - Test Gate: Memory overhead < 50MB

**Connection Monitoring:**
- [ ] Connection state changes detected within 500ms
  - Measure with PerformanceMonitor
  - Test Gate: Fast detection of connect/disconnect
- [ ] Reconnection time after network restore < 1s
  - Test Gate: Quick recovery from network drops
- [ ] Battery impact minimal during 1-hour session
  - Use Xcode Energy Log
  - Test Gate: Presence doesn't drain battery excessively

### 7.7 Unit Tests (Swift Testing)

- [ ] Create `MessageAITests/Services/PresenceServiceTests.swift`
  - [ ] Test setPresence() with online/offline states
    - Test Gate: Writes to correct Firebase path
  - [ ] Test observePresence() receives updates
    - Test Gate: Callback fires on presence changes
  - [ ] Test retry logic with exponential backoff
    - Test Gate: Delays are 1s→2s→4s (±100ms)
  - [ ] Test calculateBackoff() returns correct intervals
    - Test Gate: Attempt 1=1s, 2=2s, 3=4s
  - [ ] Test connection monitoring detects state changes
    - Test Gate: Connected/disconnected events fire
  - [ ] Test lifecycle hooks (foreground/background)
    - Test Gate: Presence updates on app state changes
  - [ ] Test cleanup on logout
    - Test Gate: Listeners removed, user set offline

### 7.8 UI Tests (XCTest)

- [ ] Create `MessageAIUITests/PresenceIndicatorUITests.swift`
  - [ ] Test presence indicator appears in conversation list
    - Test Gate: Green/gray circle visible
  - [ ] Test presence indicator appears in chat header
    - Test Gate: Header shows correct status
  - [ ] Test 200ms fade animation
    - Test Gate: Smooth transition visible
  - [ ] Test indicator updates when user goes online/offline
    - Test Gate: UI reflects status changes
  - [ ] Test multiple indicators on screen simultaneously
    - Test Gate: All indicators render correctly

### 7.9 Integration Tests

- [ ] Create `MessageAITests/Integration/PresenceIntegrationTests.swift`
  - [ ] Test 2-device sync <500ms
    - Test Gate: Device 1 change → Device 2 sees update
  - [ ] Test force-quit → relaunch cycle
    - Test Gate: onDisconnect → offline → relaunch → online
  - [ ] Test background→foreground cycle
    - Test Gate: Offline when backgrounded, online when foregrounded
  - [ ] Test Firebase Realtime Database integration
    - Test Gate: Data writes/reads correctly
  - [ ] Test security rules enforcement
    - Test Gate: Users can only write own presence

### 7.10 Performance Tests

- [ ] Create `MessageAITests/Performance/PresencePerformanceTests.swift`
  - [ ] Measure propagation latencies (p50/p95/p99)
    - Test Gate: Meet all latency targets
  - [ ] Test 1000+ contacts performance
    - Test Gate: Memory < 50MB, 60 FPS scrolling
  - [ ] Test connection monitoring latency
    - Test Gate: State changes detected < 500ms
  - [ ] Test retry success rate
    - Test Gate: >95% success within 3 attempts

---

## 8. Visual Polish

- [ ] Verify presence indicator design specs
  - **Online**: Green `#34C759`, opacity 1.0, 12pt diameter
  - **Offline**: Gray `#8E8E93`, opacity 0.6, 12pt diameter
  - **Position**: Bottom-right of avatar (overlapping)
  - Test Gate: Matches design specifications
  
- [ ] Verify fade animation specs
  - **Duration**: 200ms
  - **Easing**: easeInOut
  - **Smoothness**: 60 FPS (no dropped frames)
  - Test Gate: Animations smooth, not jarring
  
- [ ] Verify indicators don't overlap or clip avatars
  - Test Gate: Layout clean and professional
  
- [ ] Test dark mode appearance
  - Indicators visible and aesthetically pleasing
  - Green/gray colors work in dark theme
  - Test Gate: Dark mode support verified
  
- [ ] Test on different device sizes
  - iPhone SE (small screen)
  - iPhone 15 Pro Max (large screen)
  - iPad (tablet layout)
  - Test Gate: Indicators scale correctly on all devices

---

## 9. Edge Cases & Optimization (30 min)

- [ ] Add debouncing for network flapping (2s delay)
  - Test Gate: Rapid on/off doesn't flicker
- [ ] Add presence caching (30s TTL)
  - Test Gate: Cached state shown immediately on launch
- [ ] Optimize for 1000+ contacts (virtualized list)
  - Test Gate: 60 FPS scrolling, <50MB memory
- [ ] Add error logging for debugging
  - Log retry attempts, connection state changes
  - Test Gate: Console logs helpful for troubleshooting

---

## 10. Acceptance Gates

Check every gate from PRD Section 12:

### Presence Update Gates:
- [ ] When User A goes online → User B sees green indicator within 500ms
  - Test Gate: Real-time propagation works
- [ ] When User A goes offline → User B sees gray indicator within 500ms
  - Test Gate: Offline propagation works
- [ ] Presence updates correctly in ConversationRowView, ChatHeaderView, GroupMemberListView
  - Test Gate: All three surfaces show correct status
- [ ] Multiple presence indicators on screen (10+) render smoothly at 60fps
  - Test Gate: No performance degradation

### Retry & Connection Gates:
- [ ] Network failure → Retries with 1s→2s→4s backoff
  - Test Gate: Exponential backoff timing correct
- [ ] After 3 retry failures → Falls back to lastSeen timestamp
  - Test Gate: Fallback mechanism works
- [ ] Connection monitoring detects disconnects within 500ms
  - Test Gate: Fast disconnect detection
- [ ] Network restored → Reconnects within 1s
  - Test Gate: Quick recovery

### Animation Gates:
- [ ] Online→Offline transition: Smooth 200ms fade (green→gray)
  - Test Gate: No jarring transitions
- [ ] Offline→Online transition: Smooth 200ms fade (gray→green)
  - Test Gate: No jarring transitions
- [ ] All animations maintain 60 FPS
  - Test Gate: Use Instruments to verify

### Lifecycle Gates:
- [ ] Background→Foreground cycle: User goes online within 500ms
  - Test Gate: Foreground hook works
- [ ] Foreground→Background cycle: User goes offline within 500ms
  - Test Gate: Background hook works
- [ ] Force-quit: onDisconnect sets user offline automatically
  - Test Gate: Force-quit handling works
- [ ] App relaunch after force-quit: User goes online within 2s
  - Test Gate: Initialization works

### Offline Gates:
- [ ] Airplane Mode: Cached presence state displays
  - Test Gate: Shows last known status
- [ ] Offline: LastSeen timestamp shows when real-time unavailable
  - Test Gate: "Last seen X ago" fallback works
- [ ] Reconnect after offline: Syncs within 1s
  - Test Gate: Fast reconnection

### Performance Gates:
- [ ] p50 propagation latency < 200ms
  - Test Gate: Measured with PerformanceMonitor
- [ ] p95 propagation latency < 500ms
  - Test Gate: Measured with PerformanceMonitor
- [ ] p99 propagation latency < 1000ms
  - Test Gate: Measured with PerformanceMonitor
- [ ] Retry success rate > 95% within 3 attempts
  - Test Gate: Measured over 50 simulated failures
- [ ] 60 FPS scrolling with 100+ indicators
  - Test Gate: Measured with Instruments
- [ ] Memory usage < 50MB with 1000+ contacts
  - Test Gate: Measured with Memory Graph Debugger

### Error Handling Gates:
- [ ] Presence query fails → Show offline state, no crash
  - Test Gate: Graceful error handling
- [ ] Invalid user data → Default to offline, no crash
  - Test Gate: Data validation works
- [ ] Firebase Realtime Database unavailable → Falls back to lastSeen
  - Test Gate: Service degradation handled

### Multi-Device Gates:
- [ ] 3-device sync: All devices see status changes within 500ms
  - Test Gate: Multi-device consistency
- [ ] Different networks (WiFi, LTE, 5G): All sync correctly
  - Test Gate: Network type doesn't affect reliability

---

## 11. Documentation & PR

- [ ] Add inline comments for retry/backoff logic
- [ ] Document PresenceService API with pre/post-conditions
- [ ] Update README if needed
- [ ] Create PR description with screenshots/videos
  - Include: Multi-device presence demo video
  - Include: Latency measurement screenshots
  - Include: Performance metrics (p50/p95/p99)
- [ ] Verify with user before creating PR
- [ ] Create PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
## PR #20: Presence Indicator Reliability

**Branch**: `feat/pr-20-presence-reliability`  
**PRD**: `MessageAI/docs/prds/pr-20-presence-reliability-prd.md`  
**TODO**: `MessageAI/docs/todos/pr-20-presence-reliability-todo.md`

### Implementation Checklist
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] PresenceService rewritten with retry logic + unit tests (Swift Testing)
- [ ] Connection health monitoring implemented
- [ ] PresenceIndicatorView with 200ms fade animations
- [ ] Lifecycle hooks in MessageAIApp.swift (foreground/background/launch)
- [ ] Firebase Realtime Database schema and security rules deployed
- [ ] UI tests pass (XCUITest)
- [ ] Multi-device sync verified (3+ devices, <500ms)
- [ ] Performance targets met (see shared-standards.md)
- [ ] All acceptance gates pass
- [ ] Code follows shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated

### Performance Metrics (Measured)
- p50 propagation latency: ___ ms (target: <200ms)
- p95 propagation latency: ___ ms (target: <500ms)
- p99 propagation latency: ___ ms (target: <1000ms)
- Retry success rate: ___% (target: >95%)
- Connection monitoring latency: ___ ms (target: <500ms)
- 60 FPS animations: ✅ / ❌
- Memory leaks: None (verified with Instruments)

### Evidence
- [ ] Demo video: Multi-device presence updates
- [ ] Screenshots: Presence in conversation list, chat header, group member list
- [ ] Performance measurements: Latency histograms (p50/p95/p99)
- [ ] Lifecycle testing: Background→Terminated→Foreground cycle
- [ ] Force-quit test: onDisconnect hook verified

### Dependencies
- None (builds on existing MVP)
- Foundation for: PR #25 (Timestamp & Group Presence Polish)
```

---

## Estimated Time

- Setup: 30 min
- Data Model: 30 min
- Service Layer: 2.5 hours
- UI Components: 45 min
- Testing: 1 hour
- Edge Cases: 30 min
- Manual Validation: 30 min
- Documentation: 20 min

**Total: ~6.5 hours**

---

## Notes

**Technical Guidance:**
- Use Firebase Realtime Database for presence (NOT Firestore) for <500ms updates
- Implement onDisconnect hooks early - critical for force-quit handling
- Test presence propagation with PerformanceMonitor from the start
- Exponential backoff prevents Firebase overload: 1s → 2s → 4s
- Debounce network flapping (2s delay before showing offline)
- Batch subscriptions for group chats (don't create 100 individual listeners)
- Virtualized list unsubscribes from off-screen contacts (memory management)
- Use Swift actor for PresenceService (thread-safe)

**Testing Strategy:**
- Multi-device testing is critical (3+ devices)
- Test all app lifecycle transitions (background, terminated, foreground)
- Force-quit testing validates onDisconnect hooks
- Measure latencies early and often (p50/p95/p99)
- Instruments verification for memory leaks

**Calm Intelligence:**
- Silent retries (no aggressive "Reconnecting..." banners)
- Smooth 200ms fade animations (not jarring)
- Gentle fallback to lastSeen when unavailable
- No red/urgent colors - use green/gray

---

**Created:** Oct 24, 2025 | **Pete Agent**

