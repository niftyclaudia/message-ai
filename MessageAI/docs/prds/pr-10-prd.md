# PRD: Group Chat Logic & Multi-User Support

**Feature**: Group Chat Logic & Multi-User Support

**Version**: 1.0

**Status**: COMPLETED

**Agent**: Pete

**Target Release**: Phase 3

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Extend the messaging system to handle multiple participants seamlessly, ensuring all existing features (real-time sync, optimistic UI, offline persistence, read receipts) work correctly with group chats containing 3+ members. This PR builds upon the group chat creation flow from PR #9 to ensure the core messaging functionality scales properly for multi-user conversations.

---

## 2. Problem & Goals

- **What user problem are we solving?** Users need to communicate with multiple people simultaneously in group conversations, but the current messaging system is optimized for 1-on-1 chats only.
- **Why now?** After PR #9 enables group chat creation, we need to ensure the core messaging features work seamlessly with multiple participants.
- **Goals (ordered, measurable):**
  - [ ] G1 — All existing messaging features work identically in group chats (real-time sync, optimistic UI, offline persistence)
  - [ ] G2 — Message delivery latency remains <100ms regardless of group size (3-10 members)
  - [ ] G3 — Read receipts accurately track which group members have read each message

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing group chat creation UI (handled in PR #9)
- [ ] Not adding group management features (rename group, add/remove members, group settings)
- [ ] Not implementing group-specific features (mentions, group typing indicators)
- [ ] Not optimizing for very large groups (100+ members) - focus on 3-10 member groups

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Messages appear instantly in group chats, read receipts show correctly for all members
- **System**: Message delivery latency <100ms for groups up to 10 members, real-time sync works across all devices
- **Quality**: 0 blocking bugs, all acceptance gates pass, crash-free rate >99%

---

## 5. Users & Stories

- As a **group chat participant**, I want to send messages that all group members receive in real-time so that we can communicate effectively as a team.
- As a **group chat participant**, I want to see read receipts showing which group members have read my messages so that I know my message was received.
- As a **group chat participant**, I want messages to appear instantly in my UI even when offline so that I can continue conversations seamlessly.
- As a **group chat participant**, I want to see when other group members are online/offline so that I know who's available to respond.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: Group chats appear in conversation list, tapping opens group chat view
- **Visual behavior**: Message bubbles show sender name in group chats, read receipts show member avatars/names
- **Loading/disabled/error states**: Same as 1-on-1 chats - optimistic UI, error states for failed sends
- **Performance**: See targets in `MessageAI/agents/shared-standards.md` - <100ms message delivery, smooth scrolling

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Real-time message delivery to all group members in <100ms
- **MUST**: Optimistic UI updates work identically in group chats
- **MUST**: Offline persistence and message queuing work for group chats
- **MUST**: Read receipts track all group members accurately
- **MUST**: Online/offline presence indicators work for all group members
- **MUST**: Server timestamps prevent time-sync issues across group members
- **SHOULD**: Message delivery status shows for all group members
- **SHOULD**: Group chat messages display sender name/avatar for clarity

**Acceptance gates per requirement:**
- [Gate] When User A sends message to 5-member group → All 5 members see it in <100ms
- [Gate] Offline: Group messages queue and deliver on reconnect for all members
- [Gate] Read receipts: When 3 of 5 members read message → UI shows "Read by 3 of 5"
- [Gate] Error case: Failed message send shows error state, no partial delivery

---

## 8. Data Model

The existing Firestore schema already supports group chats through the `members` array. No schema changes needed.

**Current Chat Document:**
```swift
{
  id: String,
  members: [String],  // Array of user IDs (2+ for group chats)
  lastMessage: String,
  lastMessageTimestamp: Timestamp,
  isGroupChat: Bool
}
```

**Current Message Document:**
```swift
{
  id: String,
  text: String,
  senderID: String,
  timestamp: Timestamp,
  readBy: [String]  // Array of user IDs who have read it
}
```

- **Validation rules**: Members array must contain 2+ user IDs, all members must be valid users
- **Indexing/queries**: Firestore listeners on messages subcollection, composite indexes for member queries

---

## 9. API / Service Contracts

Extend existing service methods to handle group chats transparently:

```swift
// Message operations (already support group chats)
func sendMessage(chatID: String, text: String) async throws -> String
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
func markMessageAsRead(messageID: String, userID: String) async throws

// Chat operations (already support group chats)
func createChat(members: [String], isGroup: Bool) async throws -> String
func getChatMembers(chatID: String) async throws -> [String]
```

- **Pre/post-conditions**: All methods work identically for 1-on-1 and group chats
- **Error handling strategy**: Same error handling as 1-on-1 chats
- **Parameters and types**: No changes to existing method signatures
- **Return values**: Same return types, behavior scales to group size

---

## 10. UI Components to Create/Modify

**Modify existing components to handle group chats:**

- `Views/Main/ChatView.swift` — Add sender name display for group messages
- `Views/Components/MessageBubbleView.swift` — Show sender info in group chats
- `Views/Components/ReadReceiptView.swift` — Display group member read status
- `ViewModels/ChatViewModel.swift` — Handle group member presence and read receipts
- `Services/MessageService.swift` — Ensure all methods work with group chats
- `Services/ChatService.swift` — Handle group member management

---

## 11. Integration Points

- **Firebase Authentication** — User identity for group members
- **Firestore** — Message storage and real-time listeners for groups
- **Firebase Realtime Database** — Presence indicators for all group members
- **State management** — SwiftUI patterns for group chat state
- **Existing messaging infrastructure** — Leverage all current real-time features

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

**Happy Path:**
- [ ] User sends message to 5-member group
- [ ] All 5 members receive message in <100ms
- [ ] Read receipts show correctly for all members
- [ ] Gate: Message appears instantly for sender, delivered to all recipients

**Edge Cases:**
- [ ] One group member goes offline during message send
- [ ] Network interruption during group message delivery
- [ ] Group member leaves chat during active conversation
- [ ] Gate: Offline members receive message when reconnecting

**Multi-User:**
- [ ] 3+ devices in same group chat
- [ ] Real-time sync <100ms across all devices
- [ ] Concurrent messages from multiple group members
- [ ] Gate: All messages sync correctly across all devices

**Performance (see shared-standards.md):**
- [ ] App load < 2-3s with group chats
- [ ] Smooth 60fps scrolling with 100+ group messages
- [ ] Message latency < 100ms for 10-member groups
- [ ] Gate: Performance targets met regardless of group size

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] Service methods work identically for 1-on-1 and group chats
- [ ] SwiftUI views display group chat information correctly
- [ ] Real-time sync verified across 3+ devices in group chat
- [ ] Offline persistence tested with group chats
- [ ] Read receipts work for all group members
- [ ] All acceptance gates pass
- [ ] Performance targets met for group chats
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: Message delivery latency increases with group size → **Mitigation**: Use Firebase batch writes, optimize Firestore listeners
- **Risk**: Read receipt complexity with many group members → **Mitigation**: Efficient array operations, UI shows summary (e.g., "Read by 3 of 5")
- **Risk**: Offline sync complexity with group chats → **Mitigation**: Leverage existing offline persistence, test thoroughly
- **Risk**: Performance degradation with large groups → **Mitigation**: Focus on 3-10 member groups, optimize queries

---

## 15. Rollout & Telemetry

- **Feature flag?** No - group chat logic is transparent extension
- **Metrics**: Message delivery latency by group size, read receipt accuracy, offline sync success
- **Manual validation steps**: Test with 3, 5, and 10-member groups across multiple devices

---

## 16. Open Questions

- **Q1**: Should we limit group size to prevent performance issues?
- **Q2**: How should we handle read receipts UI for large groups (show all names or summary)?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Group management features (add/remove members, rename group)
- [ ] Group typing indicators
- [ ] Group mentions (@username)
- [ ] Group admin roles
- [ ] Large group optimizations (50+ members)

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** Send message to group chat, all members receive it in real-time
2. **Primary user and critical action?** Group chat participant sending messages to multiple recipients
3. **Must-have vs nice-to-have?** Must-have: real-time delivery, read receipts, offline sync
4. **Real-time requirements?** <100ms delivery to all group members, see shared-standards.md
5. **Performance constraints?** Smooth performance with 3-10 member groups, see shared-standards.md
6. **Error/edge cases to handle?** Offline members, network interruptions, concurrent messages
7. **Data model changes?** None - existing schema supports group chats
8. **Service APIs required?** Extend existing methods to handle group chats transparently
9. **UI entry points and states?** Group chats in conversation list, group chat view with sender names
10. **Security/permissions implications?** Same as 1-on-1 chats - all group members can read/send
11. **Dependencies or blocking integrations?** Depends on PR #9 (group chat creation)
12. **Rollout strategy and metrics?** Transparent extension, monitor group chat performance
13. **What is explicitly out of scope?** Group management, large group optimizations, group-specific features

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
