# PR-9 TODO — Create New Chat Flow

**Branch**: `feat/pr-9-create-new-chat-flow`  
**Source PRD**: `MessageAI/docs/prds/pr-9-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should we prevent users from creating chats with themselves?
  - What's the maximum number of members for a group chat?
- **Assumptions (confirm in PR if needed)**:
  - Users can only create chats with contacts they have access to
  - Group chats require minimum 3 members (including creator)
  - One-on-one chats require exactly 2 members

---

## 1. Setup

- [ ] Create branch `feat/pr-9-create-new-chat-flow` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Implement `createChat(members: [String], isGroup: Bool) async throws -> String`
  - Test Gate: Unit test passes for valid/invalid cases
- [ ] Implement `checkForExistingChat(members: [String]) async throws -> String?`
  - Test Gate: Unit test passes for duplicate detection
- [ ] Implement `fetchContacts() async throws -> [User]`
  - Test Gate: Unit test passes for contact retrieval
- [ ] Implement `searchContacts(query: String) async throws -> [User]`
  - Test Gate: Unit test passes for search functionality
- [ ] Add validation logic for member selection
  - Test Gate: Edge cases handled correctly (empty members, invalid users)

---

## 3. Data Model & Rules

- [ ] Update Chat model with `createdAt: Timestamp` and `createdBy: String` fields
- [ ] Update Firestore schema documentation
- [ ] Add Firebase security rules for chat creation
  - Test Gate: Reads/writes succeed with rules applied
- [ ] Implement duplicate chat prevention logic
  - Test Gate: Cannot create multiple chats with same members

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create `Views/Main/CreateNewChatView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Create `Views/Components/ContactSelectionView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Create `Views/Components/ChatCreationButton.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Create `ViewModels/CreateChatViewModel.swift`
  - Test Gate: Interaction updates state correctly
- [ ] Add loading/error/empty states to all views
  - Test Gate: All states render correctly
- [ ] Wire up state management (@State, @StateObject, etc.)
  - Test Gate: Contact selection updates UI correctly

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Firebase service integration for chat creation
  - Test Gate: Auth/Firestore configured properly
- [ ] Real-time listeners for new chat appearance
  - Test Gate: Data syncs across devices <100ms
- [ ] Offline persistence for chat creation
  - Test Gate: App restarts work offline with cached data
- [ ] Integration with existing ConversationListScreen
  - Test Gate: New chats appear in conversation list immediately

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/CreateChatViewModelTests.swift`
  - Test Gate: Service logic validated, edge cases covered
  
- [ ] UI Tests (XCUITest)
  - Path: `MessageAIUITests/CreateNewChatUITests.swift`
  - Test Gate: User flows succeed, navigation works
  
- [ ] Service Tests (Swift Testing)
  - Path: `MessageAITests/Services/ChatServiceTests.swift`
  - Test Gate: Firebase operations tested
  
- [ ] Multi-device sync test
  - Test Gate: Use pattern from shared-standards.md
  
- [ ] Visual states verification
  - Test Gate: Empty, loading, error, success render correctly

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Contact list loads in <2 seconds
  - Test Gate: Cold start to interactive measured
- [ ] Chat creation completes in <2 seconds
  - Test Gate: Firebase calls measured
- [ ] Smooth 60fps scrolling through 100+ contacts
  - Test Gate: Use LazyVStack, verify with instruments
- [ ] Real-time sync <100ms for new chat appearance
  - Test Gate: Multi-device sync verified

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass (1-on-1 and group chat creation)
- [ ] All edge case gates pass (no selection, network errors, offline)
- [ ] All multi-user gates pass (real-time sync, concurrent creation)
- [ ] All performance gates pass (contact loading, creation speed, scrolling)

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex logic
- [ ] Update README if needed
- [ ] Create PR description (use format from MessageAI/agents/coder-agent-template.md)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Services implemented + unit tests (Swift Testing)
- [ ] SwiftUI views implemented with state management
- [ ] Firebase integration tested (real-time sync, offline)
- [ ] UI tests pass (XCUITest)
- [ ] Multi-device sync verified (<100ms)
- [ ] Performance targets met (see shared-standards.md)
- [ ] All acceptance gates pass
- [ ] Code follows shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for common patterns and solutions
