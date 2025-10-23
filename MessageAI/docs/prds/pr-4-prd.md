# PRD: Mobile Lifecycle Management

**Feature**: Mobile Lifecycle Management

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 1

**Links**: [PR Brief](MessageAI/docs/pr-brief/pr-briefs.md#pr-4-mobile-lifecycle-management), [TODO](MessageAI/docs/todos/pr-4-todo.md), [Designs], [Tracking Issue]

---

## 1. Summary

Implement robust mobile lifecycle handling for backgrounding with instant reconnect on foregrounding, add push notification deep-linking to correct message threads, ensure zero message loss during app state transitions, and maintain battery-friendly operation while gracefully handling all iOS app lifecycle events.

---

## 2. Problem & Goals

- **What user problem are we solving?** Users experience message loss during app state transitions (background/foreground), miss important messages when the app is backgrounded, and face poor reconnection experiences when returning to the app. Push notifications don't reliably navigate to the correct conversation.

- **Why now?** This is PR #4 in Phase 1 (Core Messaging Performance). Mobile lifecycle management is essential for a production-ready messaging app and depends on PR #1 (Real-Time Message Delivery) and PR #2 (Offline Persistence & Sync). Without proper lifecycle handling, users will miss messages and experience data loss.

- **Goals (ordered, measurable):**
  - [ ] G1 — Achieve instant reconnect (< 500ms) on foregrounding with zero message loss
  - [ ] G2 — Implement push notification deep-linking that navigates to correct thread in < 400ms
  - [ ] G3 — Ensure zero data loss during all app state transitions (background, foreground, terminate, force-quit)
  - [ ] G4 — Maintain battery-friendly operation with optimized background connection management

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing local push notifications (only remote FCM notifications)
- [ ] Not implementing notification grouping or advanced notification UI (focus on basic deep-linking)
- [ ] Not implementing notification actions (reply from notification, mark as read) - defer to future PR
- [ ] Not implementing custom notification sounds or vibration patterns
- [ ] Not implementing notification badges or app icon customization
- [ ] Not implementing background message sync (focus on foreground reconnection and push notifications)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Instant reconnect on app open, push notifications navigate to correct chat, no visible message loss
- **System**: Reconnect < 500ms on foregrounding, deep-link navigation < 400ms, zero message loss rate
- **Performance**: Battery usage optimized, connection managed efficiently during background transitions
- **Quality**: 0 blocking bugs, all gates pass, crash-free rate >99%

---

## 5. Users & Stories

- As a **mobile user**, I want the app to instantly reconnect when I open it so that I can see the latest messages immediately.
- As a **busy professional**, I want push notifications to take me directly to the relevant conversation so that I can respond quickly.
- As a **mobile user**, I want zero message loss when switching apps or backgrounding so that I don't miss important communications.
- As a **battery-conscious user**, I want the app to manage connections efficiently so that it doesn't drain my battery while in the background.
- As a **iOS user**, I want the app to handle force-quit and terminate scenarios gracefully so that my message history is always preserved.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: 
  - User backgrounds app → connection managed gracefully
  - User foregrounds app → instant reconnect with latest messages
  - User receives push notification → taps to open specific chat thread
  - User force-quits app → all data preserved on next launch

- **Visual behavior**: 
  - Foregrounding: Brief "Syncing..." indicator (< 500ms) then full message display
  - Push notification tap: Direct navigation to chat view with highlighted new message
  - Background transition: Smooth animation with no visual jank
  - No blocking loading screens during lifecycle transitions
  
- **Loading/disabled/error states**: 
  - Reconnecting state shown briefly on foreground (< 500ms)
  - Network error states handled gracefully with retry
  - Push notification tap with invalid data shows appropriate error
  
- **Performance**: See targets in `MessageAI/agents/shared-standards.md`
  - Reconnect < 500ms on foregrounding
  - Deep-link navigation < 400ms
  - Zero message loss during transitions
  - Battery-friendly background connection management

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Instant reconnect (< 500ms) when app foregrounds with full message sync
- **MUST**: Push notifications with deep-linking to correct chat thread
- **MUST**: Zero message loss during all app state transitions (background, foreground, terminate, force-quit)
- **MUST**: Battery-friendly background connection management
- **MUST**: Handle iOS app lifecycle events gracefully (willResignActive, didEnterBackground, willEnterForeground, didBecomeActive)
- **MUST**: Preserve offline message queue during app state transitions (builds on PR #2)
- **MUST**: Deep-link navigation completes in < 400ms from notification tap
- **SHOULD**: Background connection teardown within 2s to conserve battery
- **SHOULD**: Foreground sync prioritizes active chat thread
- **SHOULD**: Push notification displays correct sender and message preview

**Acceptance gates per requirement:**
- [Gate] When app backgrounds → Connection gracefully suspended within 2s
- [Gate] When app foregrounds → Reconnect completes in < 500ms with zero message loss
- [Gate] When user taps push notification → App opens and navigates to correct chat in < 400ms
- [Gate] When app force-quits → All message history and offline queue preserved on relaunch
- [Gate] When app transitions states → No crashes, data corruption, or message loss
- [Gate] When app backgrounds for 30 minutes → Battery usage remains minimal

---

## 8. Data Model

No new Firestore collections required. Enhance existing lifecycle handling:

```swift
// App State Model (local state management)
enum AppLifecycleState {
    case active           // App in foreground, fully connected
    case inactive         // Transitioning between states
    case background       // App backgrounded, connection suspended
    case terminated       // App force-quit or terminated by system
}

// Push Notification Payload (FCM structure)
struct PushNotificationPayload {
    let chatID: String
    let messageID: String
    let senderID: String
    let senderName: String
    let messageText: String
    let timestamp: Date
}

// Deep Link Model
struct DeepLink {
    let type: DeepLinkType
    let chatID: String
    let messageID: String?
    let shouldHighlight: Bool
}

enum DeepLinkType {
    case chat(String)              // Navigate to specific chat
    case message(String, String)   // Navigate to chat and scroll to message
}

// Lifecycle Transition Event (for monitoring)
struct LifecycleTransitionEvent {
    let fromState: AppLifecycleState
    let toState: AppLifecycleState
    let timestamp: Date
    let duration: TimeInterval
    let messagesPending: Int
}
```

- **Validation rules**: Existing Firebase security rules apply
- **Indexing/queries**: 
  - Push notification payloads include chatID and messageID for deep-linking
  - Local state management for app lifecycle tracking
  - Offline message queue persisted through transitions (from PR #2)

---

## 9. API / Service Contracts

Specify concrete service layer methods for lifecycle management:

```swift
// Lifecycle Management Service (NEW)
protocol LifecycleManagementService {
    // App State Management
    func handleAppDidBecomeActive() async
    func handleAppWillResignActive() async
    func handleAppDidEnterBackground() async
    func handleAppWillEnterForeground() async
    func handleAppWillTerminate() async
    
    // Connection Management
    func suspendConnections() async
    func resumeConnections() async -> TimeInterval // Returns reconnect duration
    func teardownConnections() async
    
    // State Observation
    func observeAppState() -> AsyncStream<AppLifecycleState>
    func getCurrentState() -> AppLifecycleState
}

// Push Notification Service (NEW)
protocol PushNotificationService {
    // FCM Registration
    func registerForPushNotifications() async throws -> String // Returns FCM token
    func updateFCMToken(_ token: String) async throws
    func unregisterPushNotifications() async throws
    
    // Notification Handling
    func handlePushNotification(userInfo: [AnyHashable: Any]) async -> DeepLink?
    func parsePushNotificationPayload(userInfo: [AnyHashable: Any]) -> PushNotificationPayload?
    
    // Deep Linking
    func navigateToDeepLink(_ deepLink: DeepLink) async
    func validateDeepLink(_ deepLink: DeepLink) async -> Bool
}

// Enhanced Message Service (modify existing)
protocol MessageService {
    // Lifecycle-aware sync
    func syncOnForeground(priorityChatID: String?) async throws -> Int // Returns synced message count
    func preserveState() async throws
    func restoreState() async throws
}

// Performance Monitoring
func measureReconnectLatency() async -> TimeInterval
func measureDeepLinkNavigation(from notification: PushNotificationPayload) async -> TimeInterval
func trackLifecycleTransition(from: AppLifecycleState, to: AppLifecycleState, duration: TimeInterval)
```

- **Pre/post-conditions**: All lifecycle transitions must preserve data integrity
- **Error handling strategy**: Graceful degradation, retry reconnection, fallback to cached data
- **Parameters and types**: Use async/await for lifecycle operations, proper error handling
- **Return values**: Timing metadata for performance measurement

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

### New Components
- `Services/LifecycleManagementService.swift` — Manages iOS app lifecycle events and connection state
- `Services/PushNotificationService.swift` — Handles FCM registration and push notification processing
- `Services/DeepLinkingService.swift` — Processes deep links and navigation from push notifications
- `Utilities/AppStateObserver.swift` — SwiftUI environment observer for app state changes
- `ViewModels/DeepLinkViewModel.swift` — Manages deep-link navigation state

### Modified Components
- `MessageAIApp.swift` — Integrate lifecycle observers and handle state transitions
- `Services/MessageService.swift` — Add foreground sync and state preservation methods
- `Services/ConnectionService.swift` — Add suspend/resume connection management
- `ViewModels/ChatViewModel.swift` — Handle deep-link navigation and message highlighting
- `Views/Main/ChatView.swift` — Support deep-link message highlighting
- `Views/Main/ConversationListView.swift` — Handle navigation from push notifications
- `Utilities/PerformanceMonitor.swift` — Add lifecycle transition metrics

---

## 11. Integration Points

- **Firebase Authentication** — User identity for FCM token registration
- **Firebase Cloud Messaging (FCM)** — Push notification delivery and payload structure
- **Firestore** — Message sync on foreground, offline queue restoration
- **Firebase Realtime Database** — Connection state management during lifecycle transitions
- **iOS Notification Center** — System-level notification handling and deep-linking
- **SwiftUI App Lifecycle** — Native iOS state transition hooks
- **State management** — @EnvironmentObject for app state, @StateObject for lifecycle observables
- **Performance monitoring** — Track reconnect latency, deep-link navigation time

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] User backgrounds app → Connection suspended within 2s
  - [ ] User foregrounds app → Reconnect completes in < 500ms with latest messages
  - [ ] User taps push notification → App opens to correct chat in < 400ms
  - [ ] Gate: Instant reconnect (< 500ms) on foregrounding
  - [ ] Gate: Push notification deep-linking navigates correctly in < 400ms
  
- **Edge Cases**
  - [ ] App force-quit while online → All data preserved on relaunch
  - [ ] App force-quit while offline → Offline queue preserved on relaunch
  - [ ] Push notification with invalid chatID → Graceful error handling
  - [ ] Push notification while app already open → Navigates to correct chat
  - [ ] Multiple rapid state transitions → No crashes or data corruption
  - [ ] Gate: Zero message loss during all state transitions
  
- **Multi-Device Scenarios**
  - [ ] Push notification on Device A → Message already read on Device B → Shows correct state
  - [ ] Push notification received → User already viewing that chat → No disruptive navigation
  - [ ] Multiple devices backgrounding/foregrounding → Presence states sync correctly
  - [ ] Gate: Push notifications respect read state across devices
  
- **Performance (see shared-standards.md)**
  - [ ] Reconnect latency < 500ms (p95)
  - [ ] Deep-link navigation < 400ms (p95)
  - [ ] Background connection teardown < 2s
  - [ ] Zero message loss rate across all transitions
  - [ ] Battery usage remains minimal during background periods
  - [ ] Gate: All Phase 1 performance targets met

- **iOS Lifecycle Events**
  - [ ] willResignActive → Connections start suspending
  - [ ] didEnterBackground → Connections fully suspended within 2s
  - [ ] willEnterForeground → Connections start resuming
  - [ ] didBecomeActive → Connections fully restored in < 500ms
  - [ ] willTerminate → State saved gracefully (if possible)
  - [ ] Gate: All iOS lifecycle events handled without crashes

- **Push Notification Scenarios**
  - [ ] Notification received while app closed → Opens to correct chat
  - [ ] Notification received while app backgrounded → Foregrounds and navigates
  - [ ] Notification received while app active → Navigates to chat
  - [ ] Multiple notifications stacked → Each navigates correctly when tapped
  - [ ] Gate: Push notifications work in all app states

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] LifecycleManagementService implemented + unit tests (Swift Testing)
- [ ] PushNotificationService implemented + unit tests (Swift Testing)
- [ ] DeepLinkingService implemented + unit tests (Swift Testing)
- [ ] SwiftUI app lifecycle hooks integrated in MessageAIApp.swift
- [ ] Reconnect < 500ms verified across 3+ devices
- [ ] Deep-link navigation < 400ms verified with push notifications
- [ ] Zero message loss tested in all state transitions (background, foreground, force-quit)
- [ ] Battery usage optimized (background connection teardown < 2s)
- [ ] All acceptance gates pass
- [ ] Performance metrics documented with evidence
- [ ] UI tests for push notification navigation
- [ ] Service tests for lifecycle transitions

---

## 14. Risks & Mitigations

- **Risk**: iOS suspends app too quickly, preventing graceful shutdown → **Mitigation**: Use background tasks API for critical operations, minimize work in willTerminate
- **Risk**: Push notification payload structure changes break deep-linking → **Mitigation**: Implement version-aware payload parsing, graceful fallback
- **Risk**: Reconnect latency varies by network conditions → **Mitigation**: Implement progressive sync (prioritize active chat), show loading indicators
- **Risk**: FCM token changes not propagated to backend → **Mitigation**: Implement token refresh detection, automatic backend update
- **Risk**: Deep-link navigation conflicts with user's current view → **Mitigation**: Check current navigation state, smooth transition animations
- **Risk**: Battery drain from aggressive reconnection → **Mitigation**: Implement exponential backoff, respect iOS background execution limits
- **Risk**: Message loss during rapid state transitions → **Mitigation**: Build on PR #2 offline queue, implement state preservation hooks

---

## 15. Rollout & Telemetry

- **Feature flag?** No - this is core infrastructure for mobile app
- **Metrics**: Reconnect latency, deep-link navigation time, message loss rate, battery usage, lifecycle transition duration
- **Manual validation steps**: 
  - Multi-device testing with push notifications
  - Background/foreground transitions (rapid and delayed)
  - Force-quit and termination scenarios
  - Battery usage profiling with Xcode Instruments
  - Push notification testing (app closed, backgrounded, active)

---

## 16. Open Questions

- Q1: Should we implement notification actions (reply from notification)? 
  - **Answer**: Defer to future PR, focus on deep-linking for Phase 1
- Q2: How long should we keep background connection alive before suspending?
  - **Answer**: 2 seconds for graceful teardown, then fully suspend
- Q3: Should push notifications show message preview or just sender name?
  - **Answer**: Show both sender name and first 50 characters of message (privacy-aware)

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Local push notifications (scheduling, custom triggers)
- [ ] Notification grouping by conversation
- [ ] Notification actions (reply, mark as read, archive)
- [ ] Custom notification sounds and vibration patterns
- [ ] Notification badges and app icon customization
- [ ] Background message sync (focus on foreground reconnection only)
- [ ] Rich notifications with images/media
- [ ] Notification center widget integration

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User backgrounds app, receives push notification, taps notification, app foregrounds and navigates to correct chat in < 400ms with zero message loss

2. **Primary user and critical action?** Mobile user managing app state transitions and receiving push notifications

3. **Must-have vs nice-to-have?** 
   - Must-have: Instant reconnect (< 500ms), push notification deep-linking (< 400ms), zero message loss
   - Nice-to-have: Advanced notification features, background sync, notification actions

4. **Real-time requirements?** (see shared-standards.md)
   - Reconnect < 500ms on foregrounding
   - Deep-link navigation < 400ms
   - Background teardown < 2s
   - Zero message loss during transitions

5. **Performance constraints?** (see shared-standards.md)
   - p95 reconnect latency < 500ms
   - p95 deep-link navigation < 400ms
   - Battery-friendly operation (minimize background work)
   - No blocking UI during state transitions

6. **Error/edge cases to handle?**
   - Force-quit scenarios (data preservation)
   - Invalid push notification payloads
   - Rapid state transitions
   - Network failures during reconnect
   - Push notifications with deleted chats/messages
   - Multiple notifications stacked

7. **Data model changes?**
   - No new Firestore collections
   - New local models: AppLifecycleState, PushNotificationPayload, DeepLink
   - FCM token storage in user profile (if not already present)

8. **Service APIs required?**
   - NEW: LifecycleManagementService
   - NEW: PushNotificationService
   - NEW: DeepLinkingService
   - Enhance: MessageService (foreground sync)
   - Enhance: ConnectionService (suspend/resume)

9. **UI entry points and states?**
   - App lifecycle transitions (background, foreground)
   - Push notification tap (deep-link navigation)
   - Reconnecting state indicator
   - Deep-link message highlighting

10. **Security/permissions implications?**
    - Push notification permissions request
    - FCM token storage and privacy
    - Message preview in notifications (privacy considerations)
    - Deep-link validation (prevent unauthorized access)

11. **Dependencies or blocking integrations?**
    - Depends on PR #1 (Real-Time Message Delivery) for fast reconnect
    - Depends on PR #2 (Offline Persistence & Sync) for zero message loss
    - Requires FCM configuration and APNs certificates
    - Requires iOS notification permissions

12. **Rollout strategy and metrics?**
    - Core functionality, no feature flags
    - Measure: reconnect latency, deep-link navigation, message loss rate, battery usage
    - Test: background/foreground transitions, push notifications, force-quit scenarios

13. **What is explicitly out of scope?**
    - Notification actions (reply from notification)
    - Background message sync
    - Notification grouping and customization
    - Rich notifications with media
    - Widget integration

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test all iOS lifecycle events thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
- Build on PR #1 (reconnect speed) and PR #2 (message preservation)
- Focus on battery-friendly operation
- Implement proper FCM token management
- Test push notifications in all app states (closed, backgrounded, active)
- Validate deep-linking with various payload structures
- Measure performance: reconnect < 500ms, deep-link < 400ms
- Zero message loss is non-negotiable

