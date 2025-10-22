# PR-4 TODO — Conversation List Screen

**Branch**: `feat/pr-4-conversation-list`  
**Source PRD**: `MessageAI/docs/prds/pr-4-prd.md`  
**Owner (Agent)**: Cody

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - ChatView placeholder navigation will be implemented in PR #5
  - User avatars and names come from existing User model (PR #3)
  - Real-time updates use Firestore listeners, not polling

---

## 1. Setup

- [x] Create branch `feat/pr-4-conversation-list` from develop
- [x] Read PRD thoroughly
- [x] Read `MessageAI/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work

---

## 2. Data Models (Step 1)

- [x] Create Chat model with Codable conformance
  - Test Gate: Model serializes/deserializes correctly
- [x] Create Message model with Codable conformance  
  - Test Gate: Model serializes/deserializes correctly
- [x] Add getOtherUserID method to Chat model
  - Test Gate: Returns correct user ID for 1-on-1 chats
- [x] Define Firestore collection structure
  - Test Gate: Document structure matches PRD specification

---

## 3. ChatService Implementation (Step 2)

- [x] Implement fetchUserChats method
  - Test Gate: Returns chats for authenticated user
- [x] Implement observeUserChats method with ListenerRegistration
  - Test Gate: Real-time updates work correctly
- [x] Implement fetchChat method
  - Test Gate: Returns specific chat by ID
- [x] Add ChatServiceError enum with proper cases
  - Test Gate: All error scenarios handled
- [x] Add proper async/await error handling
  - Test Gate: Network errors don't crash app

---

## 4. Service Layer Testing (Step 3)

- [x] Write unit tests for fetchUserChats
  - Test Gate: Swift Testing framework, valid/invalid cases covered
- [x] Write unit tests for observeUserChats
  - Test Gate: Listener lifecycle and cleanup tested
- [x] Write unit tests for fetchChat
  - Test Gate: Error scenarios and edge cases covered
- [x] Test error handling scenarios
  - Test Gate: All ChatServiceError cases tested

---

## 5. ConversationListViewModel (Step 4)

- [x] Create ConversationListViewModel with @Published properties
  - Test Gate: State management works correctly
- [x] Implement loadChats method
  - Test Gate: Loads chats and updates UI state
- [x] Implement observeChatsRealTime method
  - Test Gate: Real-time updates trigger UI changes
- [x] Implement stopObserving method
  - Test Gate: Listener cleanup prevents memory leaks
- [x] Implement getOtherUser method
  - Test Gate: Returns correct user for 1-on-1 chats
- [x] Implement formatTimestamp method
  - Test Gate: Returns user-friendly time format

---

## 6. Real-Time Listeners (Step 5)

- [x] Implement Firestore listener with proper cleanup
  - Test Gate: Listener updates UI in real-time
- [x] Add memory management for listeners
  - Test Gate: No memory leaks detected
- [x] Implement listener lifecycle handling
  - Test Gate: Proper cleanup on view disappear
- [x] Add error handling for listener failures
  - Test Gate: Network issues don't crash app

---

## 7. ViewModel Testing (Step 6)

- [x] Write unit tests for loadChats
  - Test Gate: Swift Testing framework, state changes verified
- [x] Write unit tests for real-time updates
  - Test Gate: Listener updates trigger correct state changes
- [x] Write unit tests for stopObserving
  - Test Gate: Listener cleanup verified
- [x] Test getOtherUser and formatTimestamp methods
  - Test Gate: Edge cases and formatting verified

---

## 8. ConversationRowView (Step 7)

- [x] Create ConversationRowView with proper layout
  - Test Gate: SwiftUI Preview renders correctly
- [x] Implement avatar display (40pt)
  - Test Gate: Avatar loads and displays correctly
- [x] Implement name and message preview display
  - Test Gate: Text truncation works for long messages
- [x] Implement "You: " prefix logic
  - Test Gate: Shows prefix only for current user's messages
- [x] Implement timestamp display
  - Test Gate: Shows relative time format (5m, 2h, etc.)
- [x] Add proper accessibility labels
  - Test Gate: VoiceOver works correctly

---

## 9. ConversationListView (Step 8)

- [x] Create ConversationListView with LazyVStack
  - Test Gate: List renders with proper performance
- [x] Implement loading state
  - Test Gate: Loading spinner displays during fetch
- [x] Implement empty state
  - Test Gate: "No conversations yet" shows when list is empty
- [x] Implement error state
  - Test Gate: Error message displays on failure
- [x] Add proper state management
  - Test Gate: State changes update UI correctly
- [x] Implement tap navigation to ChatView placeholder
  - Test Gate: Navigation works (placeholder for PR #5)

---

## 10. MainTabView Integration (Step 9)

- [x] Integrate ConversationListView into MainTabView
  - Test Gate: Conversation list appears in main app
- [x] Replace EmptyStateView with ConversationListView
  - Test Gate: No more empty state in main tab
- [x] Add proper navigation structure
  - Test Gate: Navigation flow works correctly
- [x] Update MainTabView state management
  - Test Gate: Tab switching works with conversation list

---

## 11. Navigation & States (Step 10)

- [x] Implement navigation to ChatView placeholder
  - Test Gate: Tap on conversation navigates correctly
- [x] Add proper empty state handling
  - Test Gate: Empty state shows when no conversations
- [x] Add loading state handling
  - Test Gate: Loading state shows during data fetch
- [x] Add error state handling
  - Test Gate: Error state shows on failure
- [x] Implement proper state transitions
  - Test Gate: States transition smoothly

---

## 12. UI Testing (Step 11)

- [x] Write UI tests for conversation list display
  - Test Gate: XCTest framework, list renders correctly
- [x] Write UI tests for user interactions
  - Test Gate: Tap navigation works
- [x] Write UI tests for state changes
  - Test Gate: Loading/empty/error states display
- [x] Write UI tests for real-time updates
  - Test Gate: New messages update list
- [x] Test accessibility features
  - Test Gate: VoiceOver navigation works

---

## 13. Performance & Final Testing (Step 12)

- [x] Real-time sync performance test
  - Test Gate: Updates sync in <100ms
- [x] Memory leak testing
  - Test Gate: No memory leaks detected
- [x] App load time test
  - Test Gate: List loads in <1s

---

## 14. Firebase Security Rules

- [x] Add Firestore security rules for chats collection
  - Test Gate: Rules allow read for chat members only
- [x] Test security rules with different user scenarios
  - Test Gate: Unauthorized access blocked
- [x] Verify rules work with real-time listeners
  - Test Gate: Listeners respect security rules

---

## 15. Acceptance Gates

Check every gate from PRD Section 9:
- [x] List loads in < 1s
- [x] Empty state shows when no chats
- [x] Shows other user's avatar and name
- [x] "You: " prefix for own messages
- [x] Long messages truncated
- [x] Timestamps formatted correctly
- [x] New message → Row updates < 100ms, moves to top
- [x] Profile photo update → Avatar updates
- [x] Listener cleans up on disappear
- [x] No memory leaks

---

## 16. Documentation & PR

- [x] Add inline code comments for complex logic
- [x] Update README if needed
- [x] Create PR description (use format from MessageAI/agents/cody-agent-template.md)
- [x] Verify with user before creating PR
- [x] Open PR targeting develop branch
- [x] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [x] Branch created from develop
- [x] All TODO tasks completed
- [x] Chat and Message models implemented
- [x] ChatService implemented + unit tests (Swift Testing)
- [x] ConversationListViewModel implemented + unit tests
- [x] ConversationRowView and ConversationListView implemented
- [x] MainTabView integration completed
- [x] Real-time Firestore listeners working
- [x] UI tests pass (XCTest)
- [x] All acceptance gates pass
- [x] Firebase security rules implemented
- [x] Code follows shared-standards.md patterns
- [x] No console warnings
- [x] Documentation updated
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially (Steps 1-12)
- Check off after completion
- Document blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for common patterns and solutions
- Focus on real-time performance and memory management
- Test with multiple devices for sync verification
