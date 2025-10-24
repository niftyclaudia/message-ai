# PRD: Presence Indicator Reliability (PR #20)

**Status**: Ready for Development | **Agent**: Pete | **Phase**: Agent A - P0

---

## 1. Summary

Fix presence indicators to achieve 100% accuracy and <500ms propagation. Implement retry logic with exponential backoff (1s→2s→4s), connection health monitoring, lastSeen fallback, and smooth 200ms fade animations across all app surfaces.

---

## 2. Problem & Goals

**Problem:** Presence indicators sometimes don't update, show incorrect status, or get stuck. Users can't trust if contacts are actually online.

**Goals:**
- [x] 100% accuracy across conversation list, chat header, group member list
- [x] <500ms propagation latency (p95)
- [x] Zero stuck states
- [x] Survives app lifecycle (background→terminated→foreground)

---

## 3. Out of Scope

- ❌ Group presence polish ("3 of 5 online" header) → PR #25
- ❌ Last seen timestamps UI → PR #25
- ❌ Typing indicators → Separate feature
- ❌ Custom status messages → Future
- ❌ Manual "appear offline" mode → Future

---

## 4. Success Metrics

**Performance:**
- p50 latency: <200ms
- p95 latency: <500ms
- p99 latency: <1000ms
- Retry success rate: >95%
- 60 FPS animations

**Quality:**
- 100% accuracy (no false positives/negatives)
- Zero stuck states
- Survives all lifecycle transitions
- No memory leaks

---

## 5. User Stories

1. **As a user**, I want accurate online/offline status for contacts so I know when they're available
2. **As a user**, I want presence to update within 500ms so I have real-time awareness
3. **As User A**, when User B goes online, I see their green indicator within 500ms across all UI surfaces

---

## 6. Experience (UX)

### Display Locations
1. Conversation List — Circle next to avatar
2. Chat Header — Status next to name
3. Group Member List — Status for each member

### Visual States
- **Online**: Green `#34C759`, opacity 1.0, fade in 200ms
- **Offline**: Gray `#8E8E93`, opacity 0.6, fade out 200ms
- **Loading**: Gray (default until first data arrives)

### Animations
```swift
withAnimation(.easeInOut(duration: 0.2)) {
    indicatorColor = isOnline ? .green : .gray
    opacity = isOnline ? 1.0 : 0.6
}
```

---

## 7. Requirements

### MUST
- **M1:** Retry logic with exponential backoff (1s→2s→4s, max 3 attempts)
- **M2:** Connection health monitoring (detect disconnects <500ms)
- **M3:** Fallback to lastSeen when real-time unavailable
- **M4:** 200ms fade animations, 60 FPS
- **M5:** Multi-surface consistency (<50ms delta across all 3 surfaces)
- **M6:** App lifecycle resilience (foreground↔background↔terminated)
- **M7:** Firebase Realtime Database with onDisconnect hooks
- **M8:** Offline queue for presence changes

### SHOULD
- **S1:** Cache presence locally (30s TTL)
- **S2:** Debounce rapid changes (2s before showing offline)
- **S3:** Batch subscriptions for performance

### Edge Cases
- Network flapping (debounce)
- App force-quit (onDisconnect hook)
- Airplane Mode (graceful degradation)
- 1000+ contacts (virtualized list)

---

## 8. Data Model

### Firebase Realtime Database Schema
```
presence/
  {userID}/
    status: "online" | "offline"
    lastChanged: <timestamp>
    lastSeen: <timestamp>
```

### Swift Model
```swift
struct PresenceStatus: Codable {
    let userID: String
    let status: PresenceState
    let lastChanged: Date
    let lastSeen: Date
    
    enum PresenceState: String, Codable {
        case online, offline
    }
}
```

### Security Rules
```json
{
  "presence": {
    "$uid": {
      ".read": "auth != null",
      ".write": "$uid === auth.uid"
    }
  }
}
```

---

## 9. API / Service Contracts

```swift
// Core methods
func setPresence(status: PresenceState) async throws
func observePresence(for userID: String, completion: @escaping (PresenceStatus) -> Void) -> ListenerRegistration
func observeMultiplePresence(for userIDs: [String], completion: @escaping ([String: PresenceStatus]) -> Void) -> ListenerRegistration
func fetchLastSeen(for userID: String) async throws -> Date?

// Connection monitoring
func observeConnectionStatus(completion: @escaping (Bool) -> Void) -> ListenerRegistration
func reconnect(retryCount: Int) async throws -> Bool

// Lifecycle hooks
func handleAppForeground() async throws
func handleAppBackground() async throws
func initializePresence() async throws
func cleanupPresence() async throws

// Retry logic
func retrySetPresence(status: PresenceState, attempt: Int) async throws
func calculateBackoff(for attempt: Int) -> TimeInterval

// Error types
enum PresenceError: Error {
    case notAuthenticated, connectionFailed, maxRetriesExceeded, invalidUserID, firebaseError(String)
}
```

---

## 10. UI Components

### New
- `Components/PresenceIndicatorView.swift` — Reusable indicator with 200ms fade
- `Utilities/PresenceMonitor.swift` — Connection health monitoring

### Modified
- `Services/PresenceService.swift` — Complete rewrite with retry/monitoring/lifecycle
- `Views/ConversationList/ConversationRowView.swift` — Use new PresenceIndicatorView
- `Views/Chat/ChatHeaderView.swift` — Real-time presence with fallback
- `Views/GroupChat/GroupMemberListView.swift` — Presence for all members
- `MessageAIApp.swift` — Add lifecycle hooks (foreground/background/launch)

---

## 11. Test Plan

### Happy Path
- [ ] User goes online → propagates <500ms
- [ ] User goes offline → propagates <500ms
- [ ] Smooth 200ms fade animation
- [ ] Multi-surface consistency (<100ms delta)

### Edge Cases
- [ ] Network flapping → debounces correctly
- [ ] Retry logic → 1s→2s→4s, fallback after 3 attempts
- [ ] Connection loss → detects <500ms, reconnects on restore
- [ ] Lifecycle → Background→Terminated→Foreground = correct status
- [ ] Force-quit → onDisconnect sets offline

### Performance
- [ ] p50 <200ms, p95 <500ms, p99 <1000ms
- [ ] 1000+ contacts → 60 FPS, <50MB memory

### Multi-User
- [ ] 3-device sync <500ms
- [ ] Group chat (5 members) → all correct

---

## 12. Definition of Done

- [x] PresenceService rewritten
- [x] PresenceIndicatorView with animations
- [x] Lifecycle hooks in MessageAIApp.swift
- [x] Unit tests (Swift Testing): PresenceServiceTests.swift
- [x] UI tests (XCTest): PresenceIndicatorUITests.swift
- [x] Integration tests: PresenceIntegrationTests.swift
- [x] Performance tests: PresencePerformanceTests.swift
- [x] All acceptance gates pass
- [x] No memory leaks (Instruments)
- [x] Firebase schema deployed

---

## 13. Risks & Mitigations

1. **Firebase quota limits** → Debounce changes, batch subscriptions, monitor usage
2. **Battery drain** → Firebase optimized, offline when backgrounded
3. **Race conditions** → Serialize with async/await, use actor
4. **Performance with 1000+ contacts** → Virtualized list, pagination

---

## 14. Open Questions

1. **Show "Reconnecting..." UI?** → Recommend NO (silent retry, Calm Intelligence)
2. **Backoff intervals?** → Start with 1s→2s→4s, adjust based on data
3. **Presence for blocked users?** → Hide (privacy)
4. **Presence for archived chats?** → No (performance)

---

**Created:** Oct 24, 2025 | **Pete Agent**

