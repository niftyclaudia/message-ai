# PR-6 TODO — Real-Time Message Sending/Receiving

**Branch**: `feat/pr-6-real-time-messaging`  
**Source PRD**: `MessageAI/docs/prds/pr-6-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - Firebase project is configured and accessible
  - PR #5 (Chat View Screen) is complete and provides message display
  - Network connectivity can be monitored reliably
  - Offline storage (UserDefaults) is sufficient for message queuing

---

## 1. Setup

- [ ] Create branch `feat/pr-6-real-time-messaging` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Review existing MessageService and ChatViewModel from PR #5

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Create NetworkMonitor service
  - Test Gate: Unit test passes for connection state changes
- [ ] Implement MessageService.sendMessage() method
  - Test Gate: Unit test passes for valid/invalid cases
- [ ] Implement MessageService.observeMessages() method
  - Test Gate: Unit test passes for listener setup/cleanup
- [ ] Add offline message queuing methods
  - Test Gate: Unit test passes for queue operations
- [ ] Implement message status update methods
  - Test Gate: Unit test passes for status transitions
- [ ] Add retry logic for failed messages
  - Test Gate: Unit test passes for retry scenarios

---

## 3. Data Model & Rules

- [ ] Extend Message model with offline and retry fields
  - Test Gate: Model serialization/deserialization works
- [ ] Create QueuedMessage model for offline storage
  - Test Gate: Model persists correctly in UserDefaults
- [ ] Update Firestore security rules for message creation
  - Test Gate: Reads/writes succeed with rules applied
- [ ] Add MessageStatus enum with all states
  - Test Gate: Status transitions work correctly

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create MessageInputView component
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Create MessageStatusView component
  - Test Gate: All status states render correctly
- [ ] Create OfflineIndicatorView component
  - Test Gate: Shows/hides based on connection status
- [ ] Create RetryButtonView component
  - Test Gate: Retry action triggers correctly
- [ ] Wire up state management in ChatViewModel
  - Test Gate: Interaction updates state correctly
- [ ] Add loading/error/offline states to ChatView
  - Test Gate: All states render correctly

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Firebase service integration for message sending
  - Test Gate: Messages save to Firestore successfully
- [ ] Real-time listeners working
  - Test Gate: Data syncs across devices <100ms
- [ ] Offline persistence implemented
  - Test Gate: App restarts work offline with cached data
- [ ] Network status monitoring
  - Test Gate: Connection changes trigger UI updates
- [ ] Message status updates in real-time
  - Test Gate: Status changes reflect immediately

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/MessageServiceTests.swift`
  - Test Gate: Service logic validated, edge cases covered
- [ ] Network Tests (Swift Testing)
  - Path: `MessageAITests/Services/NetworkMonitorTests.swift`
  - Test Gate: Connection state changes tested
- [ ] Offline Tests (Swift Testing)
  - Path: `MessageAITests/Services/OfflineQueueTests.swift`
  - Test Gate: Offline queuing and sync tested
- [ ] UI Tests (XCTest)
  - Path: `MessageAIUITests/MessageSendingUITests.swift`
  - Test Gate: User flows succeed, navigation works
- [ ] Multi-device sync test
  - Test Gate: Use pattern from shared-standards.md
- [ ] Visual states verification
  - Test Gate: Empty, loading, error, success render correctly

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Message delivery latency < 100ms
  - Test Gate: Firebase calls measured with instruments
- [ ] Real-time sync < 100ms
  - Test Gate: Cross-device message delivery measured
- [ ] No UI blocking during message send
  - Test Gate: Main thread stays responsive
- [ ] Memory usage stable with listeners
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
- Focus on real-time messaging requirements from shared-standards.md
- Test offline scenarios thoroughly
- Ensure proper cleanup of Firestore listeners
