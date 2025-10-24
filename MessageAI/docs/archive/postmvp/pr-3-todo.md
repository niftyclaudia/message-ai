# PR-3 TODO — Group Chat Enhancement

**Branch**: `feat/pr-3-group-chat-enhancement`  
**Source PRD**: `MessageAI/docs/prds/pr-3-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should we show avatars for all messages or only the first in a sequence from the same sender?
    - **Answer from PRD**: Show avatar for all group messages for maximum clarity (can optimize later)
  - Should member list show "last seen" timestamp for offline users?
    - **Answer from PRD**: Defer to future PR, focus on online/offline status only for Phase 1
  - Maximum supported group size for Phase 1?
    - **Answer from PRD**: Focus on 3-10 members, test up to 20 for validation

- **Assumptions (confirm in PR if needed)**:
  - PR #1 (Real-Time Message Delivery Optimization) is complete and working
  - Existing typing indicators and read receipts are functional
  - Existing PresenceService supports multi-user observation
  - User profile data (name, avatar) is available in Firestore
  - Group chat creation flow (from MVP) is complete and functional

---

## 1. Setup

- [ ] Create branch `feat/pr-3-group-chat-enhancement` from develop
- [ ] Read PRD thoroughly (`MessageAI/docs/prds/pr-3-prd.md`)
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Review existing group chat implementation (Chat model, ChatService)
- [ ] Review existing PresenceService and TypingService implementations
- [ ] Review existing ReadReceiptView implementation

---

## 2. Service Layer - UserService (NEW)

Implement new UserService for profile fetching and caching.

- [ ] Create `Services/UserService.swift`
  - Test Gate: File compiles with no errors

- [ ] Implement `fetchUserProfile(userID: String) async throws -> User`
  - Test Gate: Unit test passes for valid user ID
  
- [ ] Implement `fetchMultipleUserProfiles(userIDs: [String]) async throws -> [String: User]`
  - Test Gate: Unit test passes for multiple user IDs
  
- [ ] Implement `observeUserProfile(userID: String, completion: @escaping (User) -> Void) -> ListenerRegistration`
  - Test Gate: Real-time updates work for profile changes
  
- [ ] Add local caching for user profiles
  - Test Gate: Cache returns data without Firebase call on second fetch
  
- [ ] Add error handling for missing/deleted users
  - Test Gate: Gracefully handles non-existent users

---

## 3. Service Layer - Message Attribution

Enhance MessageService for group chat attribution.

- [ ] Update `MessageService.sendMessage()` to include senderName parameter
  - Test Gate: Messages save with senderName in Firestore
  
- [ ] Verify existing message fetching includes senderName
  - Test Gate: Messages load with senderName from Firestore
  
- [ ] Add method to update existing messages with senderName if missing
  - Test Gate: Migration logic works for existing data

---

## 4. Service Layer - Presence (VERIFY)

Verify existing PresenceService supports multi-user observation.

- [ ] Test `observeMultipleUsersPresence()` with 3-10 user IDs
  - Test Gate: All user presence statuses update correctly
  
- [ ] Verify presence propagation < 500ms for group members
  - Test Gate: Measured with PerformanceMonitor
  
- [ ] Test presence updates during app lifecycle transitions
  - Test Gate: Online/offline status accurate after background/foreground

---

## 5. Data Model Updates

Enhance existing models for group chat support.

- [ ] Verify Chat model supports isGroupChat and groupName
  - Test Gate: Group chats load correctly with metadata
  
- [ ] Verify Message model has senderName field
  - Test Gate: Messages decode/encode with senderName
  
- [ ] Verify User model has displayName and photoURL fields
  - Test Gate: User profiles load with all required fields
  
- [ ] Review Firebase security rules for group chat access
  - Test Gate: All group members can read/write messages

---

## 6. UI Components - Message Attribution (NEW)

Create message attribution view for group messages.

- [ ] Create `Views/Components/MessageAttributionView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
  
- [ ] Add circular avatar view (32x32pt) with async image loading
  - Test Gate: Avatar loads and displays correctly
  
- [ ] Add sender name text above message bubble
  - Test Gate: Name displays in secondary text style
  
- [ ] Add placeholder avatar for users without photos
  - Test Gate: Placeholder shows when photoURL is nil
  
- [ ] Add fallback name for users without displayName
  - Test Gate: Shows user ID prefix if displayName missing
  
- [ ] Wire up with UserService for profile data
  - Test Gate: Fetches and displays user profile correctly

---

## 7. UI Components - Group Member List (NEW)

Create member list view with live presence indicators.

- [ ] Create `Views/Components/MemberStatusRow.swift`
  - Test Gate: SwiftUI Preview renders single member row
  
- [ ] Add avatar, name, and presence indicator to row
  - Test Gate: All elements display correctly
  
- [ ] Add online/offline color coding (green/gray)
  - Test Gate: Colors match PresenceState correctly
  
- [ ] Create `Views/Components/GroupMemberListView.swift`
  - Test Gate: SwiftUI Preview renders member list
  
- [ ] Implement member list as bottom sheet or modal
  - Test Gate: Sheet presents and dismisses correctly
  
- [ ] Add loading state for member list
  - Test Gate: Loading indicator shows while fetching data
  
- [ ] Add empty state if no members found
  - Test Gate: Empty state displays appropriately
  
- [ ] Wire up PresenceService for live status updates
  - Test Gate: Status indicators update in < 500ms
  
- [ ] Wire up UserService for member profiles
  - Test Gate: All member names and avatars load correctly

---

## 8. UI Components - Group Chat Header (NEW)

Create enhanced header for group chats.

- [ ] Create `Views/Components/GroupChatHeaderView.swift`
  - Test Gate: SwiftUI Preview renders header
  
- [ ] Display group name (or member names for unnamed groups)
  - Test Gate: Group name displays correctly
  
- [ ] Display member count (e.g., "5 members")
  - Test Gate: Count updates when members change
  
- [ ] Make header tappable to open member list
  - Test Gate: Tap gesture opens member list sheet
  
- [ ] Add navigation styling consistent with app theme
  - Test Gate: Header matches existing design system

---

## 9. UI Components - Modify ChatView

Integrate attribution and member list into ChatView.

- [ ] Add state for showing member list sheet
  - Test Gate: State toggles correctly on header tap
  
- [ ] Replace existing header with GroupChatHeaderView (for groups only)
  - Test Gate: Group chats show new header, 1-on-1 unchanged
  
- [ ] Update message rows to show MessageAttributionView (for groups only)
  - Test Gate: Group messages show attribution, 1-on-1 unchanged
  
- [ ] Add member list sheet presentation
  - Test Gate: Sheet presents with smooth animation
  
- [ ] Verify typing indicators still work with attribution
  - Test Gate: Typing indicators appear below last message

---

## 10. UI Components - Modify MessageRowView

Add attribution support to message rows.

- [ ] Add isGroupChat parameter to MessageRowView
  - Test Gate: Parameter passes correctly from ChatView
  
- [ ] Conditionally show MessageAttributionView for group messages
  - Test Gate: Attribution appears for groups, not for 1-on-1
  
- [ ] Adjust message bubble layout for attribution space
  - Test Gate: Messages don't overlap with avatars/names
  
- [ ] Ensure avatar appears on left for all messages
  - Test Gate: Layout consistent for sent/received messages
  
- [ ] Verify read receipts still work with attribution
  - Test Gate: Read receipts display correctly below messages

---

## 11. ViewModels - ChatViewModel

Enhance ChatViewModel for group chat features.

- [ ] Add @Published var for member list state
  - Test Gate: State updates trigger view updates
  
- [ ] Add @Published var for group members: [User]
  - Test Gate: Member list populates correctly
  
- [ ] Add @Published var for member presence: [String: PresenceStatus]
  - Test Gate: Presence map updates in real-time
  
- [ ] Implement fetchGroupMembers() method
  - Test Gate: Fetches all member profiles for chat
  
- [ ] Implement observeGroupMemberPresence() method
  - Test Gate: Observes presence for all members < 500ms
  
- [ ] Add cleanup for presence observers on view disappear
  - Test Gate: No memory leaks or dangling listeners
  
- [ ] Cache user profiles in ChatViewModel
  - Test Gate: Profiles load from cache on subsequent views

---

## 12. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Verify Firebase service integration for group chats
  - Test Gate: Auth/Firestore configured correctly
  
- [ ] Real-time message sync with attribution < 200ms
  - Test Gate: Messages with attribution appear within 200ms
  
- [ ] Real-time presence updates < 500ms
  - Test Gate: Member status changes propagate to all devices
  
- [ ] Offline caching for user profiles
  - Test Gate: Cached profiles display when offline
  
- [ ] Test simultaneous messaging (3+ users)
  - Test Gate: All messages appear in order with correct attribution

---

## 13. Tests - Unit Tests (Swift Testing)

Follow patterns from `MessageAI/agents/shared-standards.md`.

- [ ] Create `MessageAITests/Services/UserServiceTests.swift`
  - [ ] Test fetchUserProfile() with valid user ID
  - [ ] Test fetchUserProfile() with invalid user ID (error handling)
  - [ ] Test fetchMultipleUserProfiles() with 3-10 user IDs
  - [ ] Test profile caching mechanism
  - Test Gate: All service methods validated

- [ ] Create `MessageAITests/Services/MessageServiceGroupAttributionTests.swift`
  - [ ] Test sendMessage() includes senderName for group chats
  - [ ] Test message fetching includes attribution data
  - Test Gate: Attribution logic works correctly

- [ ] Update `MessageAITests/Services/PresenceServiceTests.swift`
  - [ ] Test observeMultipleUsersPresence() with 3-10 users
  - [ ] Test presence propagation timing < 500ms
  - Test Gate: Multi-user presence observation works

---

## 14. Tests - UI Tests (XCTest)

Create UI tests for group chat enhancement.

- [ ] Create `MessageAIUITests/GroupChatAttributionUITests.swift`
  - [ ] Test message attribution appears in group chats
  - [ ] Test avatars load and display correctly
  - [ ] Test sender names display above messages
  - Test Gate: Attribution UI works end-to-end

- [ ] Create `MessageAIUITests/GroupMemberListUITests.swift`
  - [ ] Test tapping group header opens member list
  - [ ] Test member list shows all participants
  - [ ] Test presence indicators display correctly
  - [ ] Test member list dismisses correctly
  - Test Gate: Member list UI works end-to-end

- [ ] Update `MessageAIUITests/GroupChatUITests.swift` (if exists)
  - [ ] Test simultaneous messaging with attribution
  - [ ] Test read receipts with attribution
  - [ ] Test typing indicators with attribution
  - Test Gate: All group features work together

---

## 15. Tests - Multi-Device & Performance

Test multi-user scenarios and performance targets.

- [ ] Multi-device test: 3 users send messages simultaneously
  - Test Gate: All messages appear in order with attribution < 200ms
  
- [ ] Multi-device test: Member goes online/offline
  - Test Gate: Status updates propagate to all devices < 500ms
  
- [ ] Performance test: Message delivery latency in 5-member group
  - Test Gate: p95 latency < 200ms measured
  
- [ ] Performance test: Member list load time
  - Test Gate: Member list opens and loads data < 400ms
  
- [ ] Performance test: Burst messaging (20+ messages in group)
  - Test Gate: No lag or reordering, all messages appear correctly
  
- [ ] Performance test: Scrolling with 100+ attributed messages
  - Test Gate: Smooth 60 FPS scrolling maintained

---

## 16. Acceptance Gates

Check every gate from PRD Section 12:

**Happy Path**
- [ ] User sends message in group chat → Attribution shows with avatar and name in < 200ms
- [ ] User taps group header → Member list opens in < 400ms
- [ ] Member list displays all participants with correct online/offline status
- [ ] Message attribution visible and accurate for all group messages
- [ ] Member list shows live presence status updating within < 500ms

**Edge Cases**
- [ ] User with no avatar → Shows placeholder avatar
- [ ] User with no display name → Shows fallback identifier
- [ ] Deleted/removed user → Gracefully handled in member list
- [ ] Offline mode → Cached user data displayed
- [ ] All edge cases handled gracefully without crashes

**Multi-User Scenarios**
- [ ] 3 users send messages simultaneously → All appear in order with < 200ms latency each
- [ ] Member goes online → Status updates within < 500ms for all participants
- [ ] Multiple members typing → Indicator shows "Alice & Bob are typing..."
- [ ] Smooth simultaneous messaging with zero lag or reordering

**Performance (see shared-standards.md)**
- [ ] Message delivery p95 latency < 200ms in 3-10 member groups
- [ ] Presence propagation < 500ms across all members
- [ ] Member list navigation < 400ms
- [ ] 60 FPS scrolling with 100+ group messages
- [ ] Burst messaging (20+ messages) with no visible lag
- [ ] All Phase 1 performance targets met

**Read Receipts (existing feature, verify)**
- [ ] Sender sees "Read by X of Y" for their messages
- [ ] Read count updates in real-time as members read messages
- [ ] Read receipts accurate for all group members

**Typing Indicators (existing feature, verify)**
- [ ] Single user typing → Shows "Alice is typing..."
- [ ] Multiple users typing → Shows "Alice & Bob are typing..."
- [ ] Typing appears < 200ms after user starts typing
- [ ] Multi-user typing indicators work smoothly

---

## 17. Performance Verification

Verify all Phase 1 targets from `MessageAI/agents/shared-standards.md`.

- [ ] Message delivery p95 < 200ms for 3-10 member groups
  - Test Gate: Measured with PerformanceMonitor
  
- [ ] Presence propagation < 500ms across all members
  - Test Gate: Measured across multiple devices
  
- [ ] Member list navigation < 400ms
  - Test Gate: Measured from tap to full render
  
- [ ] 60 FPS scrolling with 100+ attributed messages
  - Test Gate: Verified with Instruments profiler
  
- [ ] Avatar loading doesn't block message rendering
  - Test Gate: Messages appear immediately, avatars load async
  
- [ ] Burst messaging (20+ messages) with no visible lag
  - Test Gate: All messages appear correctly ordered

---

## 18. Documentation & PR

- [ ] Add inline code comments for UserService
- [ ] Add inline code comments for attribution logic
- [ ] Add inline code comments for member list implementation
- [ ] Update README with group chat enhancement details
- [ ] Document performance improvements and metrics
- [ ] Create PR description with screenshots/videos
  - Include: Member list screenshot
  - Include: Message attribution screenshot
  - Include: Performance metrics (latency, presence propagation)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
## PR #3: Group Chat Enhancement

**Branch**: `feat/pr-3-group-chat-enhancement`  
**PRD**: `MessageAI/docs/prds/pr-3-prd.md`  
**TODO**: `MessageAI/docs/todos/pr-3-todo.md`

### Implementation Checklist
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] UserService implemented + unit tests (Swift Testing)
- [ ] Message attribution UI implemented (avatar + name)
- [ ] Group member list implemented with live presence
- [ ] ChatView enhanced for group chat features
- [ ] SwiftUI views implemented with state management
- [ ] Firebase integration tested (real-time sync, offline caching)
- [ ] UI tests pass (XCUITest)
- [ ] Multi-device sync verified (3+ users, < 200ms latency)
- [ ] Presence propagation verified (< 500ms)
- [ ] Performance targets met (see shared-standards.md)
- [ ] All acceptance gates pass
- [ ] Code follows shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated

### Performance Metrics
- Message delivery p95 latency: ___ ms (target: < 200ms)
- Presence propagation: ___ ms (target: < 500ms)
- Member list load time: ___ ms (target: < 400ms)
- Scrolling FPS with 100+ messages: ___ (target: 60 FPS)
- Burst messaging test: ___ messages (target: 20+ with no lag)

### Screenshots/Videos
- [ ] Message attribution in group chat
- [ ] Member list with live presence indicators
- [ ] Simultaneous messaging demo (3+ users)
- [ ] Performance metrics dashboard

### Dependencies
- Depends on: PR #1 (Real-Time Message Delivery Optimization)
- Foundation for: PR #4 (Mobile Lifecycle), PR #5 (Performance & UX)
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially within each section
- Check off after completion
- Document blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for common patterns and solutions
- Focus on 3-10 member groups for Phase 1 (test up to 20 for validation)
- Build on existing typing indicators and read receipts (verify they work)
- Prioritize performance: < 200ms latency, < 500ms presence propagation
- Aggressive caching for user profiles and avatars
- Use Firebase Realtime Database for presence (not Firestore)
- Test extensively with multi-device scenarios (3+ participants)

