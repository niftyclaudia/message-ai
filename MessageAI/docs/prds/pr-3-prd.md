# PRD: Group Chat Enhancement

**Feature**: Group Chat Enhancement

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 1

**Links**: [PR Brief](MessageAI/docs/pr-brief/pr-briefs.md#pr-3-group-chat-enhancement), [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Enhance group chat functionality for 3+ users with smooth simultaneous messaging, clear attribution with names and avatars for each message, per-message read receipts for group conversations, and member list with live online status indicators. This PR builds on existing multi-user typing indicators to create a complete group chat experience that meets Phase 1 performance targets.

---

## 2. Problem & Goals

- **What user problem are we solving?** Users in group chats (3+ members) lack clear visual attribution, member status visibility, and performance suffers during simultaneous messaging, making group conversations confusing and laggy.

- **Why now?** This is PR #3 in Phase 1 (Core Messaging Performance). Group chat is a foundational feature that depends on PR #1 (Real-Time Message Delivery Optimization) and must be optimized before PR #4 (Mobile Lifecycle) and PR #5 (Performance & UX).

- **Goals (ordered, measurable):**
  - [ ] G1 — Achieve smooth simultaneous messaging for 3+ users with zero lag or message reordering
  - [ ] G2 — Implement clear visual attribution showing sender name and avatar for each message
  - [ ] G3 — Provide member list with live online/offline status indicators updating in < 500ms
  - [ ] G4 — Maintain p95 message delivery latency < 200ms in group chats with 3-10 members

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing group management features (rename group, add/remove members, leave group) - defer to future PR
- [ ] Not implementing @mentions or tagging functionality - defer to future PR
- [ ] Not implementing group avatars or customization - defer to future PR
- [ ] Not optimizing for very large groups (50+ members) - focus on 3-10 member groups
- [ ] Not implementing message threading or replies - defer to future PR
- [ ] Not implementing group roles or permissions (admin, member) - defer to future PR

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Clear attribution visible on all messages, member list accessible with one tap, no visible lag during simultaneous messaging
- **System**: p95 latency < 200ms for groups up to 10 members, presence propagation < 500ms, typing indicators < 200ms
- **Performance**: Smooth 60 FPS scrolling with 100+ group messages, burst messaging (20+ messages) with no reordering
- **Quality**: 0 blocking bugs, all acceptance gates pass, crash-free rate >99%

---

## 5. Users & Stories

- As a **team member**, I want to see who sent each message in a group chat so that I can follow the conversation easily.
- As a **group chat participant**, I want to see who is currently online so that I know who can respond immediately.
- As a **active user**, I want to send messages rapidly in a group chat without lag or out-of-order delivery so that my conversation flows naturally.
- As a **mobile user**, I want to quickly access the member list to see all group participants and their status so that I can understand who's in the conversation.
- As a **group chat user**, I want to see which members have read my messages so that I know who needs to catch up.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: 
  - Group chat messages show sender avatar and name
  - Tap on group name/header to view member list
  - Member list shows all participants with online/offline status
  - Read receipts show "Read by X of Y" for sender's messages
  - Typing indicators show "Alice & Bob are typing..." (already implemented)

- **Visual behavior**: 
  - Sender avatar (circular, 32x32pt) on left side of each message
  - Sender name displayed above message bubble in secondary text
  - Member list as bottom sheet or modal with live status indicators
  - Green dot for online, gray dot for offline
  - Smooth animations for presence updates and typing indicators
  
- **Loading/disabled/error states**: 
  - Loading state for member list while fetching user data
  - Placeholder avatars for users without profile pictures
  - Graceful handling of deleted/removed users
  
- **Performance**: See targets in `MessageAI/agents/shared-standards.md`
  - p95 latency < 200ms for message delivery
  - Presence propagation < 500ms
  - 60 FPS scrolling with smooth animations

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Display sender name and avatar for each message in group chats
- **MUST**: Provide member list view showing all group participants
- **MUST**: Show real-time online/offline status for each group member
- **MUST**: Maintain p95 message delivery latency < 200ms for 3-10 member groups
- **MUST**: Handle simultaneous messaging from 3+ users without lag or reordering
- **MUST**: Show per-message read receipts for group chats (already implemented, verify performance)
- **MUST**: Support multi-user typing indicators (already implemented, verify performance)
- **SHOULD**: Implement smooth animations for presence status changes
- **SHOULD**: Cache user profile data (names, avatars) for offline viewing
- **SHOULD**: Provide visual feedback when member goes online/offline

**Acceptance gates per requirement:**
- [Gate] When User A sends message in group chat → Message shows sender avatar and name within < 200ms
- [Gate] When 3 users send messages simultaneously → All messages appear in correct order with < 200ms latency each
- [Gate] When user taps group header → Member list appears with < 400ms navigation time
- [Gate] When member comes online → Status indicator updates within < 500ms for all participants
- [Gate] When sender views read receipts → "Read by X of Y" displays correctly for all group members
- [Gate] 20+ rapid messages in group chat → No visible lag or out-of-order delivery

---

## 8. Data Model

Enhance existing Firestore collections with group chat optimizations:

```swift
// Chat document (existing, verify group support)
{
  id: String,
  members: [String],  // Array of user IDs (3+ for groups)
  lastMessage: String,
  lastMessageTimestamp: Timestamp,
  lastMessageSenderID: String,
  isGroupChat: Bool,  // true when members.count > 2
  groupName: String?,  // Group name (optional)
  createdAt: Timestamp,
  createdBy: String
}

// Message document (existing, enhance with attribution)
{
  id: String,
  chatID: String,
  senderID: String,
  text: String,
  timestamp: Timestamp,
  serverTimestamp: Timestamp?,
  readBy: [String],  // Array of user IDs who read the message
  readAt: [String: Timestamp],  // Map of userID to read timestamp
  senderName: String?,  // Cached sender name for attribution
  status: MessageStatus  // sending, sent, delivered, read, failed
}

// User document (existing, ensure profile data available)
{
  uid: String,
  displayName: String,
  email: String,
  photoURL: String?,  // Avatar URL
  createdAt: Timestamp
}

// Presence document (existing, verify multi-user support)
// Stored in Firebase Realtime Database at /presence/{userID}
{
  status: "online" | "offline",
  lastSeen: Timestamp,
  deviceInfo: {
    platform: String,
    version: String,
    model: String?
  }
}
```

- **Validation rules**: Existing Firebase security rules apply, verify group chat permissions
- **Indexing/queries**: 
  - Composite index on (chatID, timestamp) for message ordering
  - Presence tracked in Firebase Realtime Database for < 500ms updates
  - User profile data cached locally for offline access

---

## 9. API / Service Contracts

Specify concrete service layer methods for group chat enhancements:

```swift
// Message operations (existing, verify group chat support)
func sendMessage(chatID: String, text: String, senderName: String?) async throws -> String
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
func markMessageAsRead(messageID: String, userID: String) async throws

// User service operations (NEW for attribution)
func fetchUserProfile(userID: String) async throws -> User
func fetchMultipleUserProfiles(userIDs: [String]) async throws -> [String: User]
func observeUserProfile(userID: String, completion: @escaping (User) -> Void) -> ListenerRegistration

// Presence operations (existing, verify multi-user support)
func observeMultipleUsersPresence(userIDs: [String], completion: @escaping ([String: PresenceStatus]) -> Void) -> [String: DatabaseHandle]
func observeUserPresence(userID: String, completion: @escaping (PresenceStatus) -> Void) -> DatabaseHandle

// Chat operations (existing, verify member list support)
func fetchChatMembers(chatID: String) async throws -> [String]
func fetchChat(chatID: String) async throws -> Chat

// Performance monitoring
func measureGroupMessageLatency(messageID: String, memberCount: Int) async -> TimeInterval
func trackSimultaneousMessaging(chatID: String, messageCount: Int) async
```

- **Pre/post-conditions**: All methods must complete within performance targets (< 200ms for messages, < 500ms for presence)
- **Error handling strategy**: Retry with exponential backoff, fallback to cached data, graceful degradation
- **Parameters and types**: Maintain existing interfaces, add optional parameters for group-specific features
- **Return values**: Include timing metadata for performance measurement

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

### New Components
- `Views/Components/GroupMemberListView.swift` — Modal/sheet showing all group members with online status
- `Views/Components/MessageAttributionView.swift` — Displays sender avatar and name for group messages
- `Views/Components/MemberStatusRow.swift` — Single row in member list showing user profile and presence
- `Views/Components/GroupChatHeaderView.swift` — Enhanced header with group name and member count, tappable for member list

### Modified Components
- `Views/Main/ChatView.swift` — Integrate attribution view for group messages, add member list navigation
- `Views/Components/MessageRowView.swift` — Add attribution support (avatar + name) for group messages
- `ViewModels/ChatViewModel.swift` — Add member list state, user profile caching, presence observation
- `Services/UserService.swift` — Add methods for fetching/caching user profiles (NEW SERVICE)
- `Services/MessageService.swift` — Enhance with group chat performance optimizations
- `Services/PresenceService.swift` — Verify multi-user observation performance
- `Utilities/PerformanceMonitor.swift` — Add group chat specific metrics

---

## 11. Integration Points

- **Firebase Authentication** — User identity for profile data and presence
- **Firestore** — Message storage, chat metadata, user profiles
- **Firebase Realtime Database** — Presence tracking for < 500ms updates
- **Firebase Storage** — Avatar image downloads (if implemented)
- **State management** — SwiftUI @StateObject for member list and presence updates
- **Performance monitoring** — Track group chat specific metrics (simultaneous messages, presence propagation)

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] User sends message in group chat → Attribution shows with avatar and name in < 200ms
  - [ ] User taps group header → Member list opens in < 400ms
  - [ ] Member list displays all participants with correct online/offline status
  - [ ] Gate: Message attribution visible and accurate for all group messages
  - [ ] Gate: Member list shows live presence status updating within < 500ms
  
- **Edge Cases**
  - [ ] User with no avatar → Shows placeholder avatar
  - [ ] User with no display name → Shows fallback identifier
  - [ ] Deleted/removed user → Gracefully handled in member list
  - [ ] Offline mode → Cached user data displayed
  - [ ] Gate: All edge cases handled gracefully without crashes
  
- **Multi-User Scenarios**
  - [ ] 3 users send messages simultaneously → All appear in order with < 200ms latency each
  - [ ] Member goes online → Status updates within < 500ms for all participants
  - [ ] Multiple members typing → Indicator shows "Alice & Bob are typing..."
  - [ ] Gate: Smooth simultaneous messaging with zero lag or reordering
  
- **Performance (see shared-standards.md)**
  - [ ] Message delivery p95 latency < 200ms in 3-10 member groups
  - [ ] Presence propagation < 500ms across all members
  - [ ] Member list navigation < 400ms
  - [ ] 60 FPS scrolling with 100+ group messages
  - [ ] Burst messaging (20+ messages) with no visible lag
  - [ ] Gate: All Phase 1 performance targets met

- **Read Receipts (existing feature, verify)**
  - [ ] Sender sees "Read by X of Y" for their messages
  - [ ] Read count updates in real-time as members read messages
  - [ ] Gate: Read receipts accurate for all group members

- **Typing Indicators (existing feature, verify)**
  - [ ] Single user typing → Shows "Alice is typing..."
  - [ ] Multiple users typing → Shows "Alice & Bob are typing..."
  - [ ] Typing appears < 200ms after user starts typing
  - [ ] Gate: Multi-user typing indicators work smoothly

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] UserService implemented for profile fetching + unit tests (Swift Testing)
- [ ] GroupMemberListView with live presence indicators
- [ ] MessageAttributionView showing avatar and name
- [ ] ChatView integrated with attribution and member list
- [ ] Real-time sync verified across 3+ devices with < 200ms latency
- [ ] Simultaneous messaging tested (3+ users, 20+ messages, no lag)
- [ ] Presence propagation verified < 500ms in group context
- [ ] All acceptance gates pass
- [ ] Performance metrics documented with evidence
- [ ] UI tests for member list and attribution
- [ ] Service tests for multi-user operations

---

## 14. Risks & Mitigations

- **Risk**: Performance degrades with 10+ member groups → **Mitigation**: Focus on 3-10 members, implement list virtualization, lazy load user profiles
- **Risk**: Presence updates flood network with many members → **Mitigation**: Batch presence updates, implement throttling, use Firebase Realtime Database
- **Risk**: Avatar loading slows message rendering → **Mitigation**: Aggressive caching, placeholder avatars, async image loading
- **Risk**: User profile data unavailable (network issues) → **Mitigation**: Cache profile data locally, show fallback identifiers
- **Risk**: Simultaneous messages cause race conditions → **Mitigation**: Use server timestamps for ordering, implement optimistic concurrency control
- **Risk**: Member list becomes stale → **Mitigation**: Real-time listeners for presence, auto-refresh on app foreground

---

## 15. Rollout & Telemetry

- **Feature flag?** No - this is core group chat functionality
- **Metrics**: Group message latency, presence propagation time, member list load time, simultaneous message handling
- **Manual validation steps**: 
  - Multi-device testing with 3+ participants
  - Simultaneous messaging scenarios (rapid fire, burst testing)
  - Presence transitions (online/offline/app state changes)
  - Member list interactions (open, scroll, refresh)

---

## 16. Open Questions

- Q1: Should we show avatars for all messages or only the first in a sequence from the same sender?
  - **Answer**: Show avatar for all group messages for maximum clarity (can optimize later)
- Q2: Should member list show "last seen" timestamp for offline users?
  - **Answer**: Defer to future PR, focus on online/offline status only for Phase 1
- Q3: Maximum supported group size for Phase 1?
  - **Answer**: Focus on 3-10 members, test up to 20 for validation

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Group management (rename, add/remove members, leave group)
- [ ] @mentions and tagging functionality
- [ ] Group avatars and customization
- [ ] Message threading and replies
- [ ] Group roles and permissions
- [ ] "Last seen" timestamps for offline users
- [ ] Group settings and preferences
- [ ] Group notifications customization
- [ ] Message reactions in group context

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User sends message in group chat, sees clear attribution (avatar + name), and can view member list with live status indicators

2. **Primary user and critical action?** Group chat participant sending messages and viewing member presence

3. **Must-have vs nice-to-have?** 
   - Must-have: Attribution (avatar + name), member list with presence, performance < 200ms
   - Nice-to-have: Avatar caching optimizations, smooth animations, advanced presence features

4. **Real-time requirements?** (see shared-standards.md)
   - Message delivery p95 < 200ms
   - Presence propagation < 500ms
   - Typing indicators < 200ms
   - Member list load < 400ms

5. **Performance constraints?** (see shared-standards.md)
   - p95 latency < 200ms for 3-10 member groups
   - 60 FPS scrolling with 100+ messages
   - Smooth simultaneous messaging (20+ rapid messages)
   - Zero message reordering

6. **Error/edge cases to handle?**
   - Missing avatars (placeholder)
   - Missing display names (fallback)
   - Deleted/removed users
   - Network failures (cached data)
   - Simultaneous messaging (server timestamps)

7. **Data model changes?**
   - No new collections
   - Enhance Message model with senderName caching
   - Verify User profile schema
   - Presence tracking in Realtime Database

8. **Service APIs required?**
   - NEW: UserService for profile fetching
   - Enhance: MessageService for group attribution
   - Verify: PresenceService multi-user observation

9. **UI entry points and states?**
   - Group chat message view (attribution on each message)
   - Group header (tap to open member list)
   - Member list modal (live presence indicators)

10. **Security/permissions implications?**
    - User profile data privacy
    - Group membership validation
    - Presence data access control

11. **Dependencies or blocking integrations?**
    - Depends on PR #1 (Real-Time Message Delivery Optimization)
    - Uses existing typing indicators and read receipts
    - Foundation for PR #4 (Mobile Lifecycle) and PR #5 (Performance & UX)

12. **Rollout strategy and metrics?**
    - Core functionality, no feature flags
    - Measure: message latency, presence propagation, member list performance
    - Test: 3-10 member groups, simultaneous messaging, multi-device sync

13. **What is explicitly out of scope?**
    - Group management features
    - @mentions and advanced features
    - Group customization (avatars, settings)
    - Very large groups (50+ members)
    - Message threading

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
- Focus on 3-10 member groups for Phase 1
- Build on existing typing indicators and read receipts
- Prioritize performance: < 200ms latency, < 500ms presence propagation
- Aggressive caching for user profiles and avatars
- Use Firebase Realtime Database for presence (not Firestore)

