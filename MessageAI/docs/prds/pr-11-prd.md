# PRD: Online/Offline Presence Indicators

**Feature**: Presence System

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 3

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Implement Firebase Realtime Database-based presence indicators that show when users are online/offline in real-time, providing users with immediate visibility into who is available for messaging.

---

## 2. Problem & Goals

- **User Problem**: Users can't tell if their contacts are online or offline, leading to uncertainty about message delivery timing and availability
- **Why Now**: Essential for Phase 3 group chat functionality where presence awareness improves coordination
- **Goals (ordered, measurable)**:
  - [ ] G1 — Users see real-time online/offline status of all contacts in <100ms
  - [ ] G2 — Presence status persists correctly across app state transitions (foreground/background/terminated)
  - [ ] G3 — System handles 100+ concurrent users without performance degradation

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing "last seen" timestamps (future feature)
- [ ] Not implementing custom status messages (away, busy, etc.)
- [ ] Not implementing presence in group chat member lists (separate PR)
- [ ] Not implementing presence-based message delivery optimization

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Presence status updates in <100ms, 99% accuracy across app state changes
- **System**: Presence sync latency <100ms, Firebase Realtime Database connection stability >99.5%
- **Quality**: 0 blocking bugs, all gates pass, crash-free rate >99%

---

## 5. Users & Stories

- As a **messaging user**, I want to see when my contacts are online so that I know they're available to respond
- As a **group chat participant**, I want to see which members are online so that I can coordinate real-time conversations
- As a **mobile user**, I want my presence status to update automatically when I switch apps or lock my phone so that others see my true availability

---

## 6. Experience Specification (UX)

- **Entry points and flows**: Presence indicators appear in conversation list, chat view, and contact lists
- **Visual behavior**: Green dot for online, gray dot for offline, smooth transitions between states
- **Loading/disabled/error states**: Show "connecting..." during initial load, fallback to offline if connection fails
- **Performance**: See targets in `MessageAI/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Real-time presence updates using Firebase Realtime Database onDisconnect hooks
- **MUST**: Presence status syncs across devices in <100ms per shared-standards.md
- **MUST**: Proper cleanup of presence data on app termination and network disconnection
- **MUST**: Handle app state transitions (foreground/background/terminated) correctly
- **SHOULD**: Optimistic UI updates for immediate visual feedback
- **SHOULD**: Graceful degradation when Realtime Database is unavailable

**Acceptance gates per requirement**:
- [Gate] When User A comes online → User B sees status change in <100ms
- [Gate] When User A force-quits app → User B sees offline status within 30 seconds
- [Gate] When User A switches to background → Status remains online for 30 seconds, then goes offline
- [Gate] Network reconnection → Presence status restores correctly

---

## 8. Data Model

Firebase Realtime Database structure for presence tracking:

```swift
// Realtime Database structure
{
  "presence": {
    "userID": {
      "status": "online" | "offline",
      "lastSeen": timestamp,
      "deviceInfo": {
        "platform": "iOS",
        "version": "1.0.0"
      }
    }
  }
}
```

- **Validation rules**: Only authenticated users can read/write their own presence data
- **Indexing/queries**: Real-time listeners on `/presence/{userID}` for individual user status

---

## 9. API / Service Contracts

Specify concrete service layer methods for presence management:

```swift
// PresenceService methods
func setUserOnline(userID: String) async throws
func setUserOffline(userID: String) async throws
func observeUserPresence(userID: String, completion: @escaping (PresenceStatus) -> Void) -> ListenerRegistration
func observeMultipleUsersPresence(userIDs: [String], completion: @escaping ([String: PresenceStatus]) -> Void) -> ListenerRegistration
func cleanupPresenceData(userID: String) async throws
```

- **Pre/post-conditions**: User must be authenticated, Realtime Database connection must be available
- **Error handling strategy**: Retry on network errors, fallback to offline status on persistent failures
- **Parameters and types**: All methods use String userIDs, return async results
- **Return values**: Void for set operations, ListenerRegistration for observe operations

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Services/PresenceService.swift` — Firebase Realtime Database presence management
- `Models/PresenceStatus.swift` — Data model for presence states
- `Components/PresenceIndicator.swift` — Reusable online/offline status indicator
- `Views/Components/UserRowView.swift` — Add presence indicator to user rows
- `Views/Components/ConversationRowView.swift` — Add presence indicator to conversation rows
- `ViewModels/ContactListViewModel.swift` — Integrate presence data
- `ViewModels/ConversationListViewModel.swift` — Integrate presence data

---

## 11. Integration Points

- **Firebase Authentication** — User identity for presence tracking
- **Firebase Realtime Database** — Primary presence storage and real-time sync
- **Firestore** — User profile data for display names
- **State management** — SwiftUI @StateObject for presence state
- **App lifecycle** — Handle foreground/background/terminated states

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] User comes online → Status updates in <100ms
  - [ ] User goes offline → Status updates in <100ms
  - [ ] Multiple users online → All statuses display correctly
  
- **Edge Cases**
  - [ ] Network disconnection → Graceful fallback to offline
  - [ ] App termination → onDisconnect hook triggers correctly
  - [ ] Rapid app state changes → No duplicate presence entries
  
- **Multi-User**
  - [ ] Real-time sync <100ms across 3+ devices
  - [ ] Concurrent presence updates handled correctly
  
- **Performance (see shared-standards.md)**
  - [ ] App load < 2-3s with presence initialization
  - [ ] Smooth 60fps with 100+ presence indicators
  - [ ] Presence updates < 100ms latency

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] PresenceService implemented + unit tests (Swift Testing)
- [ ] SwiftUI presence indicators with all states
- [ ] Real-time sync verified across 2+ devices
- [ ] App lifecycle handling tested (foreground/background/terminated)
- [ ] All acceptance gates pass
- [ ] Firebase Realtime Database rules deployed
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: Realtime Database connection instability → **Mitigation**: Implement retry logic and fallback to offline status
- **Risk**: onDisconnect hooks not firing → **Mitigation**: Add periodic cleanup jobs and manual offline detection
- **Risk**: Performance with many users → **Mitigation**: Implement presence batching and selective listening
- **Risk**: App state transition edge cases → **Mitigation**: Comprehensive testing of all iOS app lifecycle events

---

## 15. Rollout & Telemetry

- **Feature flag?** No (core functionality)
- **Metrics**: Presence update latency, connection stability, onDisconnect hook success rate
- **Manual validation steps**: Test with 2+ devices, verify app state transitions, check network failure scenarios

---

## 16. Open Questions

- Q1: Should we implement presence batching for large user lists?
- Q2: How to handle users with multiple devices (show online if any device online)?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] "Last seen" timestamps
- [ ] Custom status messages (away, busy, etc.)
- [ ] Presence-based message delivery optimization
- [ ] Group chat member presence lists

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User sees online/offline status of contacts in real-time
2. **Primary user and critical action?** Messaging user checking if contact is available
3. **Must-have vs nice-to-have?** Must-have: real-time status updates, nice-to-have: device info
4. **Real-time requirements?** <100ms presence sync per shared-standards.md
5. **Performance constraints?** Handle 100+ concurrent users, smooth UI updates
6. **Error/edge cases to handle?** Network failures, app termination, rapid state changes
7. **Data model changes?** New Realtime Database structure for presence
8. **Service APIs required?** PresenceService with set/observe/cleanup methods
9. **UI entry points and states?** Presence indicators in conversation list, chat view, contact lists
10. **Security/permissions implications?** Users can only read/write their own presence data
11. **Dependencies or blocking integrations?** Firebase Realtime Database setup, user authentication
12. **Rollout strategy and metrics?** No feature flag needed, monitor presence sync latency
13. **What is explicitly out of scope?** Last seen timestamps, custom status messages, group presence lists

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
