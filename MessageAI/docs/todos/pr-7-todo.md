# PR-7 TODO — Optimistic UI & Server Timestamps

**Branch**: `feat/pr-7-optimistic-ui`  
**Source PRD**: `MessageAI/docs/prds/pr-7-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - PR #6 (Real-Time Message Sending/Receiving) is complete
  - Firebase project is configured and accessible
  - Server timestamps are available from Firestore
  - Local storage (UserDefaults) is sufficient for optimistic message tracking
  - SwiftUI animations perform well on target devices

---

## 1. Setup

- [ ] Create branch `feat/pr-7-optimistic-ui` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Review existing MessageService and ChatViewModel from PR #6
- [ ] Verify Firebase server timestamp availability

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Create OptimisticUpdateService
  - Test Gate: Unit test passes for optimistic message management
- [ ] Implement MessageService.sendMessageOptimistic() method
  - Test Gate: Unit test passes for optimistic message creation
- [ ] Implement MessageService.updateMessageWithServerTimestamp() method
  - Test Gate: Unit test passes for server timestamp handling
- [ ] Add optimistic message management methods
  - Test Gate: Unit test passes for optimistic message operations
- [ ] Implement message ordering by server timestamp
  - Test Gate: Unit test passes for consistent ordering
- [ ] Add optimistic update failure handling
  - Test Gate: Unit test passes for error scenarios

---

## 3. Data Model & Rules

- [ ] Extend Message model with server timestamp and optimistic fields
  - Test Gate: Model serialization/deserialization works
- [ ] Create OptimisticMessage model for local tracking
  - Test Gate: Model persists correctly in UserDefaults
- [ ] Update Firestore schema for server timestamps
  - Test Gate: Server timestamps save correctly to Firestore
- [ ] Add message ordering logic by server timestamp
  - Test Gate: Messages sort correctly by server timestamp
- [ ] Implement fallback to client timestamp
  - Test Gate: Fallback works when server timestamp missing

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create OptimisticMessageRowView component
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Create MessageStatusIndicatorView component
  - Test Gate: All status states render correctly with animations
- [ ] Create MessageTimestampView component
  - Test Gate: Server timestamp display works correctly
- [ ] Create OptimisticUpdateView component
  - Test Gate: Optimistic update management works
- [ ] Wire up optimistic state management in ChatViewModel
  - Test Gate: Optimistic updates trigger UI changes correctly
- [ ] Add optimistic message handling to ChatView
  - Test Gate: Optimistic messages appear instantly
- [ ] Implement smooth message appearance animations
  - Test Gate: Animations are smooth and responsive

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Firebase service integration for optimistic updates
  - Test Gate: Optimistic messages save to Firestore successfully
- [ ] Real-time listeners with optimistic message handling
  - Test Gate: Optimistic updates don't interfere with real-time sync
- [ ] Server timestamp synchronization
  - Test Gate: Server timestamps sync across devices correctly
- [ ] Optimistic update error handling
  - Test Gate: Failed optimistic updates show error state
- [ ] Message status updates in real-time
  - Test Gate: Status changes reflect immediately with animations

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/MessageServiceTests.swift`
  - Test Gate: Optimistic methods validated, edge cases covered
- [ ] Optimistic Update Tests (Swift Testing)
  - Path: `MessageAITests/Services/OptimisticUpdateServiceTests.swift`
  - Test Gate: Optimistic update logic tested
- [ ] Server Timestamp Tests (Swift Testing)
  - Path: `MessageAITests/Services/ServerTimestampTests.swift`
  - Test Gate: Server timestamp handling tested
- [ ] UI Tests (XCTest)
  - Path: `MessageAIUITests/OptimisticUIUITests.swift`
  - Test Gate: Optimistic UI flows succeed
- [ ] Animation Tests (XCTest)
  - Path: `MessageAIUITests/MessageAnimationUITests.swift`
  - Test Gate: Animations work correctly
- [ ] Multi-device sync test with server timestamps
  - Test Gate: Use pattern from shared-standards.md
- [ ] Visual states verification
  - Test Gate: Optimistic, loading, error, success states render correctly

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Optimistic UI response < 50ms
  - Test Gate: Message appears instantly when sent
- [ ] Status update animations smooth
  - Test Gate: Status changes animate smoothly
- [ ] No UI blocking during optimistic updates
  - Test Gate: Main thread stays responsive
- [ ] Animation performance with many messages
  - Test Gate: Animations remain smooth with 100+ messages
- [ ] Memory usage stable with optimistic messages
  - Test Gate: No memory leaks detected

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass
- [ ] All edge case gates pass
- [ ] All multi-user gates pass
- [ ] All performance gates pass

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex optimistic logic
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
- [ ] SwiftUI views implemented with optimistic updates
- [ ] Firebase integration tested (server timestamps, optimistic sync)
- [ ] UI tests pass (XCTest)
- [ ] Multi-device sync verified with server timestamps
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
- Focus on optimistic UI requirements from shared-standards.md
- Test server timestamp consistency thoroughly
- Ensure smooth animations and responsive UI
- Test optimistic update failure scenarios
- Verify message ordering across devices
