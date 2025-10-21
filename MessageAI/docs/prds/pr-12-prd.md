# PRD: Message Read Receipts

**Feature**: Message Read Receipts

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 4

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Implement message read receipts logic with client-side and Firestore updates. This PR adds read status tracking for messages, proper Firestore field updates when users view messages, and visual indicators for read receipts. Includes proper UI state management for read status.

---

## 2. Problem & Goals

- **What user problem are we solving?** Users need to know when their messages have been read by recipients to understand communication status and avoid confusion about message delivery.
- **Why now?** This is a core messaging feature that provides essential feedback for user confidence in the messaging system.
- **Goals (ordered, measurable):**
  - [ ] G1 — Users can see read status of their sent messages (read/unread indicators)
  - [ ] G2 — Read status updates in real-time across all devices (<100ms sync)
  - [ ] G3 — Read receipts work seamlessly with existing optimistic UI and offline persistence

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing read receipts for group chats (future PR)
- [ ] Not implementing typing indicators (separate feature)
- [ ] Not implementing message delivery confirmations (already handled by optimistic UI)
- [ ] Not implementing read receipt privacy controls (future enhancement)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Read status updates within 1 second of message being viewed
- **System**: Read receipt sync latency < 100ms across devices
- **Quality**: 0 blocking bugs, all gates pass, crash-free rate >99%

---

## 5. Users & Stories

- As a **message sender**, I want to see when my messages have been read so that I know the recipient has seen my message.
- As a **message recipient**, I want my read status to be automatically tracked so that senders know I've seen their messages.
- As a **user with multiple devices**, I want read receipts to sync across all my devices so that read status is consistent everywhere.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: Read receipts are automatically triggered when a user opens a chat and views messages
- **Visual behavior**: 
  - Single checkmark (✓) for sent messages
  - Double checkmark (✓✓) for read messages
  - Checkmarks appear in blue color
  - Read receipts appear next to message timestamp
- **Loading/disabled/error states**: 
  - Read receipts show immediately for optimistic UI
  - Fallback to single checkmark if read receipt fails to sync
  - No visual feedback during read receipt processing
- **Performance**: See targets in `MessageAI/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Read receipts update automatically when user views messages in chat
- **MUST**: Read receipts sync in real-time across devices (<100ms)
- **MUST**: Read receipts work with existing optimistic UI system
- **MUST**: Read receipts persist offline and sync when reconnected
- **SHOULD**: Read receipts show immediately with optimistic UI
- **SHOULD**: Read receipts handle network failures gracefully

**Acceptance gates per requirement:**
- [Gate] When User A sends message → User B opens chat → User A sees read receipt in <100ms
- [Gate] Offline: Read receipts queue and sync on reconnect
- [Gate] Error case: Read receipt failure doesn't break message display

---

## 8. Data Model

Describe new/changed Firestore collections, schemas, invariants.

Reference examples in `MessageAI/agents/shared-standards.md` for common patterns.

```swift
// Updated Message Document
{
  id: String,
  text: String,
  senderID: String,
  timestamp: Timestamp,
  readBy: [String],  // Array of user IDs who have read this message
  readAt: [String: Timestamp]  // Map of userID -> timestamp when they read it
}

// New ReadReceipt Document (optional - could be embedded in Message)
{
  messageID: String,
  userID: String,
  readAt: Timestamp,
  chatID: String
}
```

- **Validation rules**: Users can only update readBy field for messages in chats they're members of
- **Indexing/queries**: Firestore listeners on messages collection with readBy field changes

---

## 9. API / Service Contracts

Specify concrete service layer methods. Reference examples in `MessageAI/agents/shared-standards.md`.

```swift
// MessageService extensions
func markMessageAsRead(messageID: String, userID: String) async throws
func markChatAsRead(chatID: String, userID: String) async throws
func observeReadReceipts(chatID: String, completion: @escaping ([String: Timestamp]) -> Void) -> ListenerRegistration

// ReadReceiptService (new)
func updateReadStatus(messageID: String, userID: String) async throws
func getReadStatus(messageID: String) async throws -> [String: Timestamp]
```

- **Pre/post-conditions**: User must be authenticated and member of chat
- **Error handling strategy**: Network failures queue read receipts for retry
- **Parameters and types**: All parameters validated before Firestore operations
- **Return values**: Void for updates, read status data for queries

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Views/Components/ReadReceiptIndicatorView.swift` — Display read receipt status (single/double checkmark)
- `Views/Components/MessageRowView.swift` — Add read receipt indicator to existing message row
- `Services/ReadReceiptService.swift` — Handle read receipt logic and Firestore updates
- `Models/ReadReceipt.swift` — Data model for read receipt information
- `ViewModels/ChatViewModel.swift` — Add read receipt state management

---

## 11. Integration Points

- **Firebase Authentication** — Verify user identity for read receipt updates
- **Firestore** — Store and sync read receipt data
- **Firebase Realtime Database** — Not used for this feature
- **FCM** — Not used for this feature (read receipts are local to chat)
- **State management** — SwiftUI @StateObject for read receipt state

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] User opens chat → messages marked as read → read receipts appear
  - [ ] Gate: Read receipts visible within 1 second of viewing messages
  
- **Edge Cases**
  - [ ] Network failure during read receipt update → queued for retry
  - [ ] User leaves and rejoins chat → read receipts persist
  - [ ] Multiple users read same message → all read receipts show
  
- **Multi-User**
  - [ ] Real-time read receipt sync <100ms across devices
  - [ ] Concurrent read receipt updates handled correctly
  
- **Performance (see shared-standards.md)**
  - [ ] Read receipt updates don't impact message scrolling performance
  - [ ] Read receipt sync latency < 100ms
  - [ ] No UI blocking during read receipt processing

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] ReadReceiptService implemented + unit tests (Swift Testing)
- [ ] ReadReceiptIndicatorView with all states (read/unread/loading)
- [ ] Real-time read receipt sync verified across 2+ devices
- [ ] Offline read receipt persistence tested
- [ ] All acceptance gates pass
- [ ] Integration with existing MessageService and ChatViewModel

---

## 14. Risks & Mitigations

- **Risk**: Read receipt updates impact message performance → **Mitigation**: Batch read receipt updates, use background queue
- **Risk**: Read receipts fail to sync in poor network conditions → **Mitigation**: Queue read receipts for retry, show optimistic UI
- **Risk**: Read receipt updates cause Firestore quota issues → **Mitigation**: Batch updates, implement rate limiting

---

## 15. Rollout & Telemetry

- **Feature flag?** No (core messaging feature)
- **Metrics**: Read receipt sync latency, read receipt update success rate, user engagement with read receipts
- **Manual validation steps**: Test read receipts across multiple devices and network conditions

---

## 16. Open Questions

- Q1: Should read receipts be batched for performance optimization?
- Q2: Should we implement read receipt privacy controls in this PR?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Read receipt privacy controls (hide read receipts from specific users)
- [ ] Group chat read receipts (different implementation needed)
- [ ] Read receipt analytics and insights

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User sends message, recipient opens chat, sender sees read receipt
2. **Primary user and critical action?** Message recipient viewing messages to trigger read receipts
3. **Must-have vs nice-to-have?** Must-have: basic read receipts. Nice-to-have: read receipt timestamps
4. **Real-time requirements?** Read receipts must sync <100ms across devices
5. **Performance constraints?** Read receipt updates must not impact message scrolling performance
6. **Error/edge cases to handle?** Network failures, offline scenarios, concurrent updates
7. **Data model changes?** Add readBy and readAt fields to Message document
8. **Service APIs required?** ReadReceiptService with markAsRead and observeReadReceipts methods
9. **UI entry points and states?** Read receipt indicators in message rows
10. **Security/permissions implications?** Users can only update read receipts for messages in their chats
11. **Dependencies or blocking integrations?** Depends on existing MessageService and ChatViewModel
12. **Rollout strategy and metrics?** No feature flag needed, track read receipt sync performance
13. **What is explicitly out of scope?** Group chat read receipts, privacy controls, read receipt analytics

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
