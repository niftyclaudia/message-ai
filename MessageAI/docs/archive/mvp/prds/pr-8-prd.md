# PRD: Firestore Offline Persistence

**Feature**: Offline Message Persistence & Sync

**Version**: 1.0

**Status**: COMPLETED

**Agent**: Pete

**Target Release**: Phase 2

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Implement comprehensive offline message persistence and synchronization to enable seamless messaging even without internet connectivity. Users can read all previous messages and send new ones that queue and sync automatically when reconnecting.

---

## 2. Problem & Goals

- **User Problem**: Users lose access to messages when offline, can't send messages without internet, and experience data loss on app restart without connectivity
- **Why Now**: Core messaging functionality (PR #6, #7) is complete, but users need reliable offline experience for production readiness
- **Goals (ordered, measurable):**
  - [ ] G1 — Users can read all previously loaded messages while offline
  - [ ] G2 — Users can send messages while offline that queue and deliver on reconnect
  - [ ] G3 — App restarts work offline with full message history available

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing offline photo/media uploads (future PR)
- [ ] Not implementing offline contact discovery (future PR)
- [ ] Not implementing offline presence indicators (covered in PR #11)
- [ ] Not implementing offline group chat creation (future PR)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Messages load instantly offline, sent messages queue reliably, 100% message history available offline
- **System**: Offline cache size < 50MB, sync completion < 5 seconds on reconnect, zero message loss
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **mobile user**, I want to read my message history while offline so that I can reference previous conversations without internet
- As a **commuter**, I want to send messages while offline so that they deliver automatically when I reconnect
- As a **user with poor connectivity**, I want my app to work seamlessly offline so that I don't lose functionality during network issues

---

## 6. Experience Specification (UX)

- **Entry points and flows**: Automatic - works transparently when network is unavailable
- **Visual behavior**: 
  - Offline indicator shows when disconnected
  - Queued messages show "pending" status
  - Sent messages appear instantly (optimistic UI)
- **Loading/disabled/error states**: 
  - Offline indicator with sync status
  - Pending message indicators
  - Sync progress when reconnecting
  - Test button for simulating offline scenarios (simulator only)
- **Performance**: See targets in `MessageAI/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Enable Firestore offline persistence with `isPersistenceEnabled = true`
- **MUST**: Implement message queuing for offline sends with automatic retry
- **MUST**: Cache all previously loaded messages locally for offline access
- **MUST**: Sync queued messages on network reconnection
- **SHOULD**: Show offline status indicator
- **SHOULD**: Provide sync progress feedback
- **SHOULD**: Include test interface for offline scenarios (simulator only)

**Acceptance gates per requirement:**
- [Gate] Offline: User can read all previously loaded messages instantly
- [Gate] Offline: User can send messages that queue and deliver on reconnect
- [Gate] App restart: All message history available without network
- [Gate] Sync: Queued messages deliver within 5 seconds of reconnection
- [Gate] Error case: Network failures don't cause message loss

---

## 8. Data Model

No new Firestore collections needed. Enhancements to existing models:

```swift
// Enhanced Message model for offline support
struct Message {
    let id: String
    let text: String
    let senderID: String
    let timestamp: Date
    let readBy: [String]
    let status: MessageStatus  // NEW: .sending, .sent, .delivered, .failed
    let isQueued: Bool         // NEW: true if queued for offline send
}

enum MessageStatus {
    case sending    // Optimistic UI state
    case sent      // Delivered to Firestore
    case delivered // Read by recipient
    case failed    // Send failed, will retry
}
```

- **Validation rules**: Existing Firestore security rules apply
- **Indexing/queries**: Use existing Firestore listeners with offline cache

---

## 9. API / Service Contracts

Specify concrete service layer methods. Reference examples in `MessageAI/agents/shared-standards.md`.

```swift
// Enhanced MessageService for offline support
func sendMessage(chatID: String, text: String) async throws -> String
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
func retryFailedMessages() async throws
func getQueuedMessages() -> [Message]
func clearQueuedMessages() async throws

// Network monitoring
func startNetworkMonitoring()
func stopNetworkMonitoring()
func isNetworkAvailable() -> Bool
```

- **Pre/post-conditions**: Messages queue when offline, sync when online
- **Error handling strategy**: Retry failed messages, show user feedback
- **Parameters and types**: Existing message types with status enhancement
- **Return values**: Message IDs for tracking, status updates

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Services/MessageService.swift` — Add offline persistence and queuing logic
- `Services/NetworkMonitor.swift` — Monitor network connectivity status
- `Models/Message.swift` — Add status and queuing fields
- `Views/Components/OfflineIndicatorView.swift` — Show offline status
- `Views/Components/MessageStatusView.swift` — Show message delivery status
- `Views/Components/RetryButtonView.swift` — Retry failed messages
- `Views/Components/OfflineTestButtonView.swift` — Test offline scenarios in simulator
- `ViewModels/ChatViewModel.swift` — Handle offline state and queuing

---

## 11. Integration Points

- **Firebase Authentication**: Existing auth state management
- **Firestore**: Enable offline persistence, configure cache settings
- **Firebase Realtime Database**: Not applicable (presence handled in PR #11)
- **FCM**: Not applicable (push notifications in PR #13)
- **State management**: Enhanced SwiftUI patterns for offline states

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] User can read messages while offline
  - [ ] User can send messages while offline
  - [ ] Messages sync on reconnect
  - [ ] Gate: All previously loaded messages available offline

- **Edge Cases**
  - [ ] App restart works offline
  - [ ] Network interruptions handled gracefully
  - [ ] Multiple offline messages queue correctly
  - [ ] Gate: Zero message loss during network failures

- **Multi-User**
  - [ ] Offline messages sync to all participants
  - [ ] Concurrent offline sends handled correctly
  - [ ] Gate: All users receive queued messages on reconnect

- **Performance (see shared-standards.md)**
  - [ ] Offline cache size < 50MB
  - [ ] Sync completion < 5 seconds
  - [ ] Message loading < 100ms offline
  - [ ] Gate: Smooth performance with 1000+ cached messages

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] Service methods implemented + unit tests (Swift Testing)
- [ ] SwiftUI views with offline states
- [ ] Firestore offline persistence enabled and tested
- [ ] Message queuing and sync verified
- [ ] All acceptance gates pass
- [ ] Multi-device offline testing completed
- [ ] Performance targets met
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: Large offline cache impacts performance → **Mitigation**: Implement cache size limits and cleanup
- **Risk**: Message queuing causes memory issues → **Mitigation**: Limit queue size, persist to disk
- **Risk**: Sync conflicts on reconnect → **Mitigation**: Use Firestore server timestamps, handle conflicts gracefully
- **Risk**: Network detection unreliable → **Mitigation**: Use multiple network monitoring approaches

---

## 15. Rollout & Telemetry

- **Feature flag?** No - core functionality, always enabled
- **Metrics**: Offline usage, sync success rate, cache size, message queue length
- **Manual validation steps**: Test offline scenarios, network transitions, app restarts

---

## 16. Open Questions

- Q1: Should we implement cache size limits? (Answer: Yes, 50MB limit)
- Q2: How long should failed messages retry? (Answer: Exponential backoff, max 24 hours)

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Offline photo/media uploads
- [ ] Offline contact discovery
- [ ] Advanced cache management
- [ ] Offline group chat creation

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User can read messages and send new ones while offline
2. **Primary user and critical action?** Mobile user sending messages without internet
3. **Must-have vs nice-to-have?** Must: offline read/send, Should: sync progress indicators
4. **Real-time requirements?** Messages sync within 5 seconds of reconnection
5. **Performance constraints?** Cache size < 50MB, sync < 5 seconds, smooth offline performance
6. **Error/edge cases to handle?** Network failures, app restarts, sync conflicts
7. **Data model changes?** Add status and queuing fields to Message model
8. **Service APIs required?** Enhanced MessageService with offline methods
9. **UI entry points and states?** Offline indicator, message status, retry buttons
10. **Security/permissions implications?** Existing Firestore security rules apply
11. **Dependencies or blocking integrations?** Depends on PR #6 (real-time messaging)
12. **Rollout strategy and metrics?** Always enabled, monitor offline usage and sync success
13. **What is explicitly out of scope?** Photo uploads, contact discovery, group creation

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
