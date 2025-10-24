# PR-4 TODO — Mobile Lifecycle Management

**Branch**: `feat/pr-4-mobile-lifecycle`  
**Source PRD**: `MessageAI/docs/prds/pr-4-prd.md`  
**Owner (Agent)**: Pete → Cody

---

## 0. Clarifying Questions & Assumptions

- Questions:
  - Confirm FCM is already configured with APNs certificates
  - Verify existing ConnectionService architecture (or need to create)
  - Confirm GoogleService-Info.plist has correct FCM configuration

- Assumptions (confirm in PR if needed):
  - Firebase Cloud Messaging (FCM) already configured
  - iOS push notification permissions handled in existing auth flow
  - PR #1 (Real-Time Delivery) provides fast connection establishment
  - PR #2 (Offline Persistence) provides message queue infrastructure
  - Xcode project configured with Push Notifications capability

---

## 1. Setup

- [ ] Create branch `feat/pr-4-mobile-lifecycle` from develop
- [ ] Read PRD thoroughly (`MessageAI/docs/prds/pr-4-prd.md`)
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Verify FCM configuration in Firebase Console
- [ ] Verify APNs certificates uploaded to Firebase
- [ ] Confirm Xcode Push Notifications capability enabled
- [ ] Review PR #1 and PR #2 implementation for dependencies

**Acceptance Gate**: Environment ready, FCM configured, branch created

---

## 2. Data Models & Types

Define Swift types for lifecycle management.

- [ ] Create `Models/AppLifecycleState.swift`
  - Define `AppLifecycleState` enum (active, inactive, background, terminated)
  - Test Gate: Enum covers all iOS lifecycle states

- [ ] Create `Models/PushNotificationPayload.swift`
  - Define `PushNotificationPayload` struct with chatID, messageID, senderID, senderName, messageText
  - Implement Codable conformance for JSON parsing
  - Test Gate: Can parse valid FCM payload, handles invalid data gracefully

- [ ] Create `Models/DeepLink.swift`
  - Define `DeepLink` struct with type, chatID, messageID, shouldHighlight
  - Define `DeepLinkType` enum (chat, message)
  - Test Gate: Model supports all deep-link scenarios

- [ ] Create `Models/LifecycleTransitionEvent.swift`
  - Define struct for monitoring state transitions
  - Include fromState, toState, timestamp, duration, messagesPending
  - Test Gate: Can track and log lifecycle transitions

**Acceptance Gate**: All models defined, type-safe, testable

---

## 3. Service Layer - Lifecycle Management

Implement core lifecycle service (< 30 min per task).

### 3.1 LifecycleManagementService

- [ ] Create `Services/LifecycleManagementService.swift`
  - Define protocol with lifecycle methods
  - Test Gate: Protocol compiles, methods well-defined

- [ ] Implement `handleAppDidBecomeActive()`
  - Trigger connection resume
  - Sync messages if needed
  - Update app state to .active
  - Test Gate: Unit test verifies state transition and connection resume

- [ ] Implement `handleAppWillResignActive()`
  - Update app state to .inactive
  - Prepare for background transition
  - Test Gate: Unit test verifies state transition

- [ ] Implement `handleAppDidEnterBackground()`
  - Suspend connections gracefully (< 2s)
  - Save pending state
  - Update app state to .background
  - Test Gate: Unit test verifies connection suspension within 2s

- [ ] Implement `handleAppWillEnterForeground()`
  - Prepare for reconnection
  - Update app state to .inactive
  - Test Gate: Unit test verifies state transition

- [ ] Implement `handleAppWillTerminate()`
  - Save critical state if time allows
  - Update app state to .terminated
  - Test Gate: Unit test verifies graceful shutdown

- [ ] Implement connection management methods
  - `suspendConnections()` - teardown Firebase listeners
  - `resumeConnections()` - re-establish Firebase listeners, return duration
  - `teardownConnections()` - full cleanup
  - Test Gate: Unit tests verify connection lifecycle, measure reconnect time < 500ms

- [ ] Implement state observation
  - `observeAppState()` returns AsyncStream<AppLifecycleState>
  - `getCurrentState()` returns current state
  - Test Gate: Unit tests verify state publishing and observation

**Acceptance Gate**: LifecycleManagementService complete, all methods tested, reconnect < 500ms

---

## 4. Service Layer - Push Notifications

Implement push notification handling (< 30 min per task).

### 4.1 PushNotificationService

- [ ] Create `Services/PushNotificationService.swift`
  - Define protocol with push notification methods
  - Test Gate: Protocol compiles, methods well-defined

- [ ] Implement FCM token registration
  - `registerForPushNotifications()` - request permissions, get token
  - `updateFCMToken(_ token: String)` - save to Firestore user profile
  - `unregisterPushNotifications()` - cleanup on logout
  - Test Gate: Unit tests verify token management, Firestore update

- [ ] Implement notification payload parsing
  - `parsePushNotificationPayload(userInfo:)` - extract chatID, messageID, sender info
  - Handle invalid payloads gracefully
  - Test Gate: Unit tests with valid/invalid payloads, edge cases

- [ ] Implement notification handling
  - `handlePushNotification(userInfo:)` - parse and create DeepLink
  - Validate chatID and messageID exist
  - Test Gate: Unit tests verify deep-link creation from notification

**Acceptance Gate**: PushNotificationService complete, payload parsing robust, tested

---

## 5. Service Layer - Deep Linking

Implement deep-link navigation (< 30 min per task).

### 5.1 DeepLinkingService

- [ ] Create `Services/DeepLinkingService.swift`
  - Define protocol with deep-link methods
  - Test Gate: Protocol compiles, methods well-defined

- [ ] Implement deep-link validation
  - `validateDeepLink(_ deepLink:)` - verify chatID/messageID exist in Firestore
  - Handle deleted chats/messages gracefully
  - Test Gate: Unit tests verify validation logic

- [ ] Implement deep-link navigation
  - `navigateToDeepLink(_ deepLink:)` - coordinate with navigation system
  - Support chat-only and message-specific navigation
  - Measure navigation time (target < 400ms)
  - Test Gate: Unit tests verify navigation logic, timing measured

**Acceptance Gate**: DeepLinkingService complete, navigation < 400ms, tested

---

## 6. Service Layer - Message Service Enhancement

Enhance existing MessageService for lifecycle support (< 30 min per task).

- [ ] Add foreground sync method to `MessageService.swift`
  - `syncOnForeground(priorityChatID:)` - fast sync on app foreground
  - Prioritize active chat if provided
  - Return count of synced messages
  - Test Gate: Unit test verifies fast sync (< 500ms), priority handling

- [ ] Add state preservation methods
  - `preserveState()` - save pending operations before background
  - `restoreState()` - restore pending operations on foreground
  - Test Gate: Unit tests verify state persistence through app lifecycle

**Acceptance Gate**: MessageService enhanced, lifecycle-aware, tested

---

## 7. Utilities & Observers

Create utility components (< 30 min per task).

- [ ] Create `Utilities/AppStateObserver.swift`
  - SwiftUI-friendly observer for app state changes
  - Publish state changes as @Published property
  - Test Gate: SwiftUI preview renders, state updates trigger UI changes

- [ ] Update `Utilities/PerformanceMonitor.swift`
  - Add lifecycle transition tracking methods
  - Add reconnect latency measurement
  - Add deep-link navigation time tracking
  - Test Gate: Can measure and log lifecycle performance metrics

**Acceptance Gate**: Utilities created, integrated with services, tested

---

## 8. App Integration - MessageAIApp.swift

Integrate lifecycle hooks into main app (< 30 min per task).

- [ ] Add lifecycle observers to `MessageAIApp.swift`
  - Import Combine, Firebase, services
  - Initialize LifecycleManagementService
  - Initialize PushNotificationService
  - Test Gate: App compiles, services initialized

- [ ] Implement SwiftUI lifecycle hooks
  - Add `.onAppear { }` - handle initial app launch
  - Add `.onChange(of: scenePhase)` - detect background/foreground transitions
  - Map scenePhase to lifecycle service calls
  - Test Gate: Lifecycle methods called on state transitions

- [ ] Configure push notification handling
  - Set up UNUserNotificationCenterDelegate
  - Handle notification received in foreground
  - Handle notification tap (background/closed)
  - Test Gate: Notifications received, delegate methods called

- [ ] Add FCM token handling
  - Register for remote notifications in AppDelegate
  - Handle FCM token refresh
  - Update token in Firestore user profile
  - Test Gate: FCM token received and stored

**Acceptance Gate**: App lifecycle integrated, push notifications working, tested

---

## 9. ViewModel Updates

Update ViewModels for lifecycle and deep-linking support (< 30 min per task).

### 9.1 DeepLinkViewModel

- [ ] Create `ViewModels/DeepLinkViewModel.swift`
  - ObservableObject managing deep-link navigation state
  - Properties: activeDeepLink, isNavigating, navigationError
  - Methods: processDeepLink, clearDeepLink
  - Test Gate: ViewModel state management works correctly

- [ ] Integrate DeepLinkViewModel with navigation
  - Coordinate with ConversationListViewModel for chat navigation
  - Coordinate with ChatViewModel for message highlighting
  - Test Gate: Deep-link triggers correct navigation in UI

### 9.2 ChatViewModel Enhancement

- [ ] Add deep-link message highlighting to `ChatViewModel.swift`
  - Property: highlightedMessageID
  - Method: scrollToMessage(messageID:, highlight:)
  - Highlight animation (2s duration, fade out)
  - Test Gate: Message scrolling and highlighting works

**Acceptance Gate**: ViewModels updated, deep-linking functional, tested

---

## 10. UI Components

Create/modify UI components for lifecycle features (< 30 min per task).

### 10.1 Connection Status Indicators

- [ ] Create `Views/Components/ReconnectingIndicator.swift`
  - Shows brief "Syncing..." during foreground reconnect
  - Auto-hides after < 500ms or when sync completes
  - Test Gate: SwiftUI preview renders, auto-hide works

### 10.2 ChatView Enhancement

- [ ] Update `Views/Main/ChatView.swift` for message highlighting
  - Add scrollToMessage functionality using ScrollViewReader
  - Add highlight animation for deep-linked message
  - Test Gate: Can navigate to specific message, highlight visible

### 10.3 ConversationListView Enhancement

- [ ] Update `Views/Main/ConversationListView.swift` for deep-link navigation
  - Observe DeepLinkViewModel activeDeepLink
  - Navigate to chat when deep-link detected
  - Test Gate: Push notification tap navigates to correct chat

**Acceptance Gate**: UI components updated, deep-linking works end-to-end

---

## 11. Integration & Real-Time

Connect services with Firebase (< 30 min per task).

- [ ] Configure FCM in Firebase Console
  - Upload APNs certificates (development and production)
  - Configure notification message format
  - Test Gate: Firebase Console shows active APNs configuration

- [ ] Update Firebase security rules for FCM tokens
  - Allow users to update their own fcmToken field
  - Test Gate: Token updates succeed with proper permissions

- [ ] Test connection suspend/resume with Firebase
  - Verify Firestore listeners detach on background
  - Verify Firestore listeners reattach on foreground
  - Measure reconnect time (< 500ms)
  - Test Gate: Reconnect measured, < 500ms achieved

- [ ] Test push notification delivery
  - Send test notification from Firebase Console
  - Verify notification received on device
  - Verify deep-link navigation works
  - Test Gate: End-to-end push notification flow works

**Acceptance Gate**: Firebase integration complete, push notifications working

---

## 12. Tests - Unit Tests (Swift Testing)

Write comprehensive unit tests (< 30 min per task).

- [ ] Create `MessageAITests/Services/LifecycleManagementServiceTests.swift`
  - Test all lifecycle state transitions
  - Test connection suspend/resume timing
  - Test reconnect latency < 500ms
  - Test Gate: All lifecycle scenarios covered, timing verified

- [ ] Create `MessageAITests/Services/PushNotificationServiceTests.swift`
  - Test FCM token registration
  - Test payload parsing (valid/invalid)
  - Test deep-link creation from notification
  - Test Gate: All push notification scenarios covered

- [ ] Create `MessageAITests/Services/DeepLinkingServiceTests.swift`
  - Test deep-link validation
  - Test navigation timing < 400ms
  - Test invalid deep-link handling
  - Test Gate: All deep-linking scenarios covered, timing verified

- [ ] Create `MessageAITests/ViewModels/DeepLinkViewModelTests.swift`
  - Test deep-link state management
  - Test navigation coordination
  - Test Gate: ViewModel behavior correct

**Acceptance Gate**: Unit tests pass, > 80% coverage, timing verified

---

## 13. Tests - UI Tests (XCTest)

Write UI automation tests (< 30 min per task).

- [ ] Create `MessageAIUITests/LifecycleTransitionUITests.swift`
  - Test backgrounding → foregrounding flow
  - Test reconnect indicator appears and hides
  - Test messages sync on foreground
  - Test Gate: UI responds correctly to lifecycle transitions

- [ ] Create `MessageAIUITests/PushNotificationNavigationUITests.swift`
  - Test notification tap → app opens to correct chat
  - Test notification tap → message highlighted
  - Test notification tap with app already open
  - Test Gate: Push notification navigation works in all app states

- [ ] Create `MessageAIUITests/MessageLossPrevention UITests.swift`
  - Test force-quit → relaunch preserves messages
  - Test background → foreground preserves messages
  - Test rapid state transitions preserve messages
  - Test Gate: Zero message loss verified

**Acceptance Gate**: UI tests pass, all user flows validated

---

## 14. Performance Validation

Verify performance targets from PRD (< 30 min per task).

- [ ] Measure reconnect latency on foreground
  - Test across 10+ foreground events
  - Calculate p95 latency
  - Target: < 500ms
  - Test Gate: p95 < 500ms achieved, evidence collected

- [ ] Measure deep-link navigation time
  - Test across 10+ notification taps
  - Calculate p95 navigation time
  - Target: < 400ms
  - Test Gate: p95 < 400ms achieved, evidence collected

- [ ] Measure background connection teardown
  - Test connection suspension timing
  - Target: < 2s
  - Test Gate: Teardown < 2s verified

- [ ] Verify zero message loss rate
  - Test 100+ state transitions (background, foreground, force-quit)
  - Count message loss incidents
  - Target: 0% message loss
  - Test Gate: Zero message loss verified across all scenarios

- [ ] Measure battery usage
  - Use Xcode Instruments Energy Log
  - Compare baseline vs lifecycle management
  - Target: Minimal impact from lifecycle handling
  - Test Gate: Battery usage acceptable, no regressions

**Acceptance Gate**: All performance targets met, evidence documented

---

## 15. Multi-Device Testing

Test across devices and scenarios (< 30 min per task).

- [ ] Test push notifications on physical device
  - Install on iOS device with proper provisioning profile
  - Send test notification from Firebase Console
  - Verify notification received and deep-linking works
  - Test Gate: Push notifications work on real device

- [ ] Test lifecycle transitions on physical device
  - Background → foreground transitions
  - Force-quit and relaunch
  - Network transitions during state changes
  - Test Gate: All scenarios work on real device

- [ ] Test multi-device push notification sync
  - Device A receives notification
  - Device B already has message marked as read
  - Verify notification state is correct
  - Test Gate: Push notifications respect cross-device state

**Acceptance Gate**: Multi-device testing complete, all scenarios validated

---

## 16. Acceptance Gates Verification

Check every gate from PRD Section 12:

- [ ] ✅ App backgrounds → Connection suspended within 2s
- [ ] ✅ App foregrounds → Reconnect completes in < 500ms with latest messages
- [ ] ✅ User taps push notification → App opens to correct chat in < 400ms
- [ ] ✅ App force-quits → All data preserved on relaunch
- [ ] ✅ App transitions states → No crashes, data corruption, or message loss
- [ ] ✅ App backgrounds for 30 minutes → Battery usage minimal
- [ ] ✅ All iOS lifecycle events handled without crashes
- [ ] ✅ Push notifications work in all app states (closed, backgrounded, active)
- [ ] ✅ Zero message loss rate across all transitions

**Acceptance Gate**: All PRD acceptance gates pass

---

## 17. Documentation & PR

- [ ] Add inline code comments for lifecycle logic
  - Explain state transition rationale
  - Document FCM token handling
  - Document deep-link navigation flow
  - Test Gate: Code well-documented, easy to understand

- [ ] Update README if needed
  - Document push notification setup (APNs certificates)
  - Document FCM configuration requirements
  - Test Gate: Setup instructions clear

- [ ] Create PR description
  - Summarize lifecycle management implementation
  - List all acceptance gates passed
  - Include performance metrics (reconnect < 500ms, deep-link < 400ms)
  - Add screenshots/videos of push notification flow
  - Test Gate: PR description comprehensive

- [ ] Verify with user before creating PR
  - Review implementation approach
  - Confirm all requirements met
  - Test Gate: User approves implementation

- [ ] Open PR targeting develop branch
  - Link PRD and TODO in PR description
  - Add performance evidence
  - Test Gate: PR created, ready for review

**Acceptance Gate**: Documentation complete, PR ready for review

---

## Copyable Checklist (for PR description)

```markdown
## PR #4: Mobile Lifecycle Management

### Implementation Summary
- ✅ LifecycleManagementService with iOS state transition handling
- ✅ PushNotificationService with FCM integration and deep-linking
- ✅ DeepLinkingService for navigation from push notifications
- ✅ MessageService enhanced with foreground sync
- ✅ SwiftUI app lifecycle hooks integrated
- ✅ Zero message loss across all app state transitions

### Performance Targets
- ✅ Reconnect < 500ms on foregrounding (p95: ___ ms)
- ✅ Deep-link navigation < 400ms (p95: ___ ms)
- ✅ Background teardown < 2s
- ✅ Zero message loss rate verified (100+ transitions)
- ✅ Battery-friendly operation validated

### Testing
- ✅ Unit tests (Swift Testing) for all services
- ✅ UI tests (XCTest) for lifecycle and push notification flows
- ✅ Multi-device testing on physical devices
- ✅ Force-quit and state transition scenarios
- ✅ Performance measurement and evidence collection

### Acceptance Gates (from PRD)
- ✅ App backgrounds → Connection suspended within 2s
- ✅ App foregrounds → Reconnect completes in < 500ms
- ✅ Push notification tap → Navigates to correct chat in < 400ms
- ✅ Force-quit → All data preserved on relaunch
- ✅ Zero message loss during all state transitions
- ✅ iOS lifecycle events handled gracefully

### Dependencies
- ✅ Builds on PR #1 (Real-Time Message Delivery Optimization)
- ✅ Builds on PR #2 (Offline Persistence & Sync System)

### Evidence
- [ ] Screenshot: Push notification on lock screen
- [ ] Video: Push notification → deep-link navigation (< 400ms)
- [ ] Video: Background → foreground reconnect (< 500ms)
- [ ] Xcode Instruments: Battery usage profiling
- [ ] Performance metrics: Reconnect latency histogram (p95 < 500ms)

### Files Changed
- New: Services/LifecycleManagementService.swift
- New: Services/PushNotificationService.swift
- New: Services/DeepLinkingService.swift
- New: Models/AppLifecycleState.swift, PushNotificationPayload.swift, DeepLink.swift
- New: ViewModels/DeepLinkViewModel.swift
- Modified: MessageAIApp.swift (lifecycle hooks)
- Modified: Services/MessageService.swift (foreground sync)
- Modified: Views/Main/ChatView.swift (message highlighting)
- Modified: Views/Main/ConversationListView.swift (deep-link navigation)

### Notes
- FCM configured with APNs certificates (development + production)
- Firebase security rules updated for FCM token storage
- Tested on physical iOS devices (iPhone ___)
- Zero message loss verified across 100+ lifecycle transitions
```

---

## Notes

- Break tasks into < 30 min chunks
- Complete tasks sequentially within each section
- Check off after completion
- Document blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for common patterns
- Build on PR #1 (reconnect speed) and PR #2 (message preservation)
- Test on physical devices for push notifications
- Measure performance continuously: reconnect < 500ms, deep-link < 400ms
- Zero message loss is non-negotiable - test thoroughly
- Battery usage must remain minimal - profile with Xcode Instruments

---

## Dependencies Reminder

**PR #4 depends on:**
- ✅ PR #1: Real-Time Message Delivery Optimization (fast reconnection infrastructure)
- ✅ PR #2: Offline Persistence & Sync System (message queue and state preservation)

**Key integration points:**
- Use PR #1's optimized connection establishment for fast foreground reconnect
- Use PR #2's offline queue to preserve messages during state transitions
- Extend PR #2's state preservation for force-quit scenarios

