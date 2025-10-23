# PRD: Real-Time Message Delivery Optimization

**Feature**: Real-Time Message Delivery Optimization

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 1

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Optimize message delivery to achieve p95 latency < 200ms from send to acknowledgment to render, implement burst testing for 20+ rapid messages with no lag or out-of-order delivery, and add presence propagation < 500ms across all connected devices. This PR focuses on the core real-time messaging infrastructure that forms the foundation for all other features.

---

## 2. Problem & Goals

- **What user problem are we solving?** Current messaging system may have latency issues that create poor user experience, especially during rapid message exchanges or when multiple users are typing simultaneously. Users expect instant, reliable message delivery in a professional messaging app.

- **Why now?** This is the foundational PR for Phase 1 performance optimization. All subsequent features depend on reliable, fast message delivery. Without this optimization, group chats, offline sync, and other advanced features will perform poorly.

- **Goals (ordered, measurable):**
  - [ ] G1 — Achieve p95 message delivery latency < 200ms (send → ack → render)
  - [ ] G2 — Handle 20+ rapid messages with zero lag or out-of-order delivery
  - [ ] G3 — Implement presence propagation < 500ms across all connected devices

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing offline message queuing (covered in PR #2)
- [ ] Not adding group chat features (covered in PR #3)
- [ ] Not implementing push notifications (covered in PR #4)
- [ ] Not optimizing for 1000+ message scrolling (covered in PR #5)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Message appears in recipient's chat within 200ms of send
- **System**: p95 latency < 200ms, presence updates < 500ms, zero message reordering
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **remote worker**, I want messages to appear instantly so that I can have real-time conversations without delays.
- As a **team member**, I want to see when others are typing in real-time so that I can coordinate communication effectively.
- As a **user**, I want to send multiple messages quickly without them appearing out of order so that my conversation flow makes sense.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: Message sending from ChatView, typing indicators in conversation
- **Visual behavior**: Instant message appearance, smooth typing indicators, presence status updates
- **Loading/disabled/error states**: Optimistic UI with instant feedback, retry on failure
- **Performance**: See targets in `MessageAI/agents/shared-standards.md` - < 200ms latency, 60 FPS animations

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Message delivery with p95 latency < 200ms from send to render
- **MUST**: Handle burst messaging (20+ rapid messages) with zero lag or reordering
- **MUST**: Presence propagation < 500ms across all connected devices
- **MUST**: Real-time typing indicators < 200ms (already implemented, verify performance)
- **SHOULD**: Optimistic UI with instant visual feedback
- **SHOULD**: Graceful error handling with retry mechanisms

**Acceptance gates per requirement:**
- [Gate] When User A sends message → User B sees in < 200ms
- [Gate] 20 rapid messages sent → All appear in correct order with < 200ms each
- [Gate] User starts typing → Other users see indicator in < 200ms
- [Gate] User comes online → All devices show presence in < 500ms

---

## 8. Data Model

No new Firestore collections required. Optimize existing message and presence data:

```swift
// Message document (existing, optimize delivery)
{
  id: String,
  text: String,
  senderID: String,
  timestamp: Timestamp,  // FieldValue.serverTimestamp()
  readBy: [String]  // Array of user IDs
}

// Presence document (existing, optimize propagation)
{
  userID: String,
  isOnline: Bool,
  lastSeen: Timestamp,
  isTyping: Bool,
  typingInChat: String?  // Chat ID where user is typing
}
```

- **Validation rules**: Existing Firebase security rules apply
- **Indexing/queries**: Optimize Firestore listeners for real-time updates, add composite indexes for presence queries

---

## 9. API / Service Contracts

Specify concrete service layer methods for optimization:

```swift
// Message operations (optimize existing)
func sendMessage(chatID: String, text: String) async throws -> String
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
func markMessageAsRead(messageID: String, userID: String) async throws

// Presence operations (optimize existing)
func updatePresence(isOnline: Bool, isTyping: Bool, typingInChat: String?) async throws
func observePresence(userID: String, completion: @escaping (Presence) -> Void) -> ListenerRegistration
func observeTypingInChat(chatID: String, completion: @escaping ([String]) -> Void) -> ListenerRegistration

// Performance monitoring
func measureMessageLatency(messageID: String) async -> TimeInterval
func measurePresenceLatency(userID: String) async -> TimeInterval
```

- **Pre/post-conditions**: All methods must complete within performance targets
- **Error handling strategy**: Retry with exponential backoff, fallback to cached data
- **Parameters and types**: Maintain existing interfaces, add performance monitoring
- **Return values**: Include timing metadata for performance measurement

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Services/MessageService.swift` — Optimize message delivery and real-time sync
- `Services/PresenceService.swift` — Optimize presence propagation and typing indicators
- `Utilities/PerformanceMonitor.swift` — Add latency measurement capabilities
- `ViewModels/ChatViewModel.swift` — Update to use optimized services
- `Views/Main/ChatView.swift` — Ensure optimistic UI and smooth animations

---

## 11. Integration Points

- **Firebase Authentication** - User identity for presence tracking
- **Firestore** - Optimized real-time listeners for messages and presence
- **Firebase Realtime Database** - Fast presence updates (if needed for < 500ms)
- **State management** - SwiftUI patterns for optimistic updates
- **Performance monitoring** - Latency measurement and reporting

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] User sends message → appears in recipient chat < 200ms
  - [ ] User starts typing → indicator appears < 200ms
  - [ ] User comes online → presence updates < 500ms
  
- **Edge Cases**
  - [ ] Network interruption → messages queue and deliver on reconnect
  - [ ] Rapid message sending → all messages appear in order
  - [ ] Multiple users typing → all indicators show correctly
  
- **Multi-User**
  - [ ] Real-time sync < 200ms across 3+ devices
  - [ ] Concurrent typing indicators work smoothly
  - [ ] Presence updates propagate to all connected devices
  
- **Performance (see shared-standards.md)**
  - [ ] Message latency p95 < 200ms
  - [ ] Presence propagation < 500ms
  - [ ] Smooth 60fps animations during message delivery

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] Service methods optimized + unit tests (Swift Testing)
- [ ] Real-time sync verified across 3+ devices with < 200ms latency
- [ ] Burst messaging test passes (20+ messages, no reordering)
- [ ] Presence propagation verified < 500ms
- [ ] All acceptance gates pass
- [ ] Performance metrics documented

---

## 14. Risks & Mitigations

- **Risk**: Firebase latency varies by region → **Mitigation**: Use Firebase performance monitoring, consider regional optimization
- **Risk**: High message volume causes delays → **Mitigation**: Implement message batching and throttling
- **Risk**: Network conditions affect performance → **Mitigation**: Add offline queue and retry logic
- **Risk**: Presence updates conflict → **Mitigation**: Use Firebase Realtime Database for presence, implement conflict resolution

---

## 15. Rollout & Telemetry

- **Feature flag?** No - this is core infrastructure optimization
- **Metrics**: Message delivery latency, presence propagation time, message reordering incidents
- **Manual validation steps**: Multi-device testing, burst messaging scenarios, network interruption testing

---

## 16. Open Questions

- Q1: Should we use Firebase Realtime Database for presence instead of Firestore for < 500ms updates?
- Q2: What's the optimal batch size for rapid message sending?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Message encryption (security enhancement)
- [ ] Message reactions (UI enhancement)
- [ ] Message threading (complexity)

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User sends message, recipient sees it in < 200ms
2. **Primary user and critical action?** Remote worker sending/receiving messages in real-time
3. **Must-have vs nice-to-have?** Must-have: < 200ms latency, no message reordering
4. **Real-time requirements?** < 200ms message delivery, < 500ms presence propagation
5. **Performance constraints?** p95 latency < 200ms, 60 FPS animations
6. **Error/edge cases to handle?** Network interruptions, rapid messaging, concurrent users
7. **Data model changes?** No new collections, optimize existing message/presence data
8. **Service APIs required?** Optimize existing MessageService and PresenceService methods
9. **UI entry points and states?** ChatView message sending, typing indicators, presence status
10. **Security/permissions implications?** Existing Firebase security rules apply
11. **Dependencies or blocking integrations?** None - this is foundational optimization
12. **Rollout strategy and metrics?** Core infrastructure, measure latency and presence propagation
13. **What is explicitly out of scope?** Offline queuing, group chat features, push notifications, scrolling optimization

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
