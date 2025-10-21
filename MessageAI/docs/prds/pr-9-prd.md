# PRD: Create New Chat Flow

**Feature**: Create New Chat Flow

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 3

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Implement the "Create New Chat" flow that allows users to select 1 or 3+ users to start conversations, supporting both one-on-one and group chat creation with proper contact list integration and chat creation logic.

---

## 2. Problem & Goals

- **User Problem**: Users need an intuitive way to start new conversations with individuals or groups from their contact list
- **Why Now**: Core messaging infrastructure (PR #4, PR #6) is complete, enabling chat creation functionality
- **Goals (ordered, measurable)**:
  - [ ] G1 — Users can access "Create New Chat" from conversation list screen
  - [ ] G2 — Users can select 1 user for one-on-one chat or 3+ users for group chat
  - [ ] G3 — Chat creation completes in <2 seconds with proper Firestore integration

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing chat naming/renaming (future PR)
- [ ] Not implementing chat member management (future PR)
- [ ] Not implementing chat deletion (future PR)
- [ ] Not implementing contact search/filtering (future PR)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Chat creation flow completes in <10 seconds, 3 taps or fewer
- **System**: Chat creation API call completes in <2 seconds, real-time sync <100ms
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **user**, I want to tap a "+" button to start a new chat so that I can begin conversations with my contacts
- As a **user**, I want to select one contact for a private conversation so that I can have one-on-one chats
- As a **user**, I want to select multiple contacts for group conversations so that I can have group discussions
- As a **collaborator**, I want to see the new chat appear in my conversation list in real-time so that I can participate immediately

---

## 6. Experience Specification (UX)

- **Entry points and flows**: 
  - Main entry: "+" button in ConversationListScreen navigation bar
  - Flow: ConversationList → CreateNewChatView → ContactSelectionView → ChatCreation → Return to ConversationList
- **Visual behavior**: 
  - Search bar for filtering contacts
  - Checkbox selection for multiple users
  - "Create Chat" button enabled when 1+ users selected
  - Loading state during chat creation
- **Loading/disabled/error states**: 
  - Loading spinner during chat creation
  - Disabled state for "Create Chat" when no users selected
  - Error alert for creation failures
- **Performance**: See targets in `MessageAI/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Create deterministic service method `createChat(members: [String], isGroup: Bool) async throws -> String`
- **MUST**: Real-time delivery per MessageAI/agents/shared-standards.md (<100ms sync)
- **MUST**: Offline persistence and queue for chat creation
- **SHOULD**: Optimistic UI - chat appears immediately in conversation list
- **SHOULD**: Prevent duplicate chats with same members

**Acceptance gates per requirement**:
- [Gate] When User A creates chat with User B → Chat appears in both users' conversation lists in <100ms
- [Gate] Offline: Chat creation queues and completes on reconnect
- [Gate] Error case: Invalid member selection shows alert; no partial chat creation
- [Gate] Duplicate prevention: Same members cannot create multiple chats

---

## 8. Data Model

Reference examples in `MessageAI/agents/shared-standards.md` for common patterns.

```swift
// Chat Document (existing, enhanced)
{
  id: String,
  members: [String],  // Array of user IDs
  lastMessage: String,
  lastMessageTimestamp: Timestamp,
  isGroupChat: Bool,
  createdAt: Timestamp,  // New field for creation tracking
  createdBy: String      // New field for creator user ID
}
```

- **Validation rules**: 
  - Members array must contain 2+ valid user IDs
  - Current user must be included in members array
  - isGroupChat = true when members.count > 2
- **Indexing/queries**: 
  - Firestore listeners on chats collection for real-time updates
  - Composite index on (members, createdAt) for efficient querying

---

## 9. API / Service Contracts

Specify concrete service layer methods. Reference examples in `MessageAI/agents/shared-standards.md`.

```swift
// Chat creation
func createChat(members: [String], isGroup: Bool) async throws -> String
func checkForExistingChat(members: [String]) async throws -> String?

// Contact operations
func fetchContacts() async throws -> [User]
func searchContacts(query: String) async throws -> [User]
```

- **Pre/post-conditions for each method**:
  - `createChat`: Pre: members.count >= 2, all members valid; Post: chat created in Firestore, ID returned
  - `checkForExistingChat`: Pre: members array provided; Post: existing chat ID or nil returned
- **Error handling strategy**: Network errors, invalid members, duplicate chat prevention
- **Parameters and types**: All parameters explicitly typed, return values clearly defined

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Views/Main/CreateNewChatView.swift` — Main chat creation interface with contact list
- `Views/Components/ContactSelectionView.swift` — Individual contact row with selection checkbox
- `Views/Components/ChatCreationButton.swift` — Create chat button with loading states
- `Services/ChatService.swift` — Enhanced with createChat and duplicate checking methods
- `ViewModels/CreateChatViewModel.swift` — State management for chat creation flow

---

## 11. Integration Points

- Firebase Authentication (current user context)
- Firestore (chat creation, real-time listeners)
- State management (SwiftUI patterns for contact selection)
- Navigation (SwiftUI NavigationView integration)

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] User selects 1 contact → One-on-one chat created successfully
  - [ ] User selects 3+ contacts → Group chat created successfully
  - [ ] Gate: Chat appears in conversation list within 100ms
  
- **Edge Cases**
  - [ ] No contacts selected → Create button disabled
  - [ ] Network error during creation → Error alert shown
  - [ ] Offline creation → Queued and completed on reconnect
  
- **Multi-User**
  - [ ] Real-time sync <100ms across all participants
  - [ ] Concurrent chat creation handled gracefully
  
- **Performance (see shared-standards.md)**
  - [ ] Contact list loads in <2 seconds
  - [ ] Chat creation completes in <2 seconds
  - [ ] Smooth scrolling through 100+ contacts

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] Service methods implemented + unit tests (Swift Testing)
- [ ] SwiftUI views with all states (loading, error, success)
- [ ] Real-time sync verified across 2+ devices
- [ ] Offline persistence tested
- [ ] All acceptance gates pass
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: Duplicate chats created → **Mitigation**: Check for existing chats before creation
- **Risk**: Performance slow with large contact lists → **Mitigation**: Implement search/filtering, use LazyVStack
- **Risk**: Real-time sync delays → **Mitigation**: Optimize Firestore queries, use batch writes

---

## 15. Rollout & Telemetry

- **Feature flag?** No (core functionality)
- **Metrics**: Chat creation success rate, creation time, duplicate prevention rate
- **Manual validation steps**: Test with 2+ devices, verify real-time sync

---

## 16. Open Questions

- Q1: Should we prevent users from creating chats with themselves?
- Q2: What's the maximum number of members for a group chat?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Chat naming and customization
- [ ] Member management (add/remove)
- [ ] Chat deletion
- [ ] Advanced contact search and filtering

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User can create a new chat with selected contacts
2. **Primary user and critical action?** User selecting contacts and creating chat
3. **Must-have vs nice-to-have?** Must-have: basic chat creation; Nice-to-have: advanced filtering
4. **Real-time requirements?** Chat must appear in all participants' lists in <100ms
5. **Performance constraints?** Contact list must load quickly, creation must be responsive
6. **Error/edge cases to handle?** Network failures, invalid selections, duplicate prevention
7. **Data model changes?** Add createdAt and createdBy fields to Chat model
8. **Service APIs required?** createChat, checkForExistingChat, fetchContacts
9. **UI entry points and states?** + button → contact selection → creation → return to list
10. **Security/permissions implications?** Users can only create chats they're members of
11. **Dependencies or blocking integrations?** Requires PR #4 (ConversationList) and PR #6 (Real-time messaging)
12. **Rollout strategy and metrics?** Direct rollout, track creation success and performance
13. **What is explicitly out of scope?** Chat management, advanced search, chat customization

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
