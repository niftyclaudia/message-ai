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

- [x] Create branch `feat/pr-6-real-time-messaging` from develop
- [x] Read PRD thoroughly
- [x] Read `MessageAI/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work
- [x] Review existing MessageService and ChatViewModel from PR #5

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [x] Create NetworkMonitor service
  - Test Gate: Unit test passes for connection state changes
- [x] Implement MessageService.sendMessage() method
  - Test Gate: Unit test passes for valid/invalid cases
- [x] Implement MessageService.observeMessages() method
  - Test Gate: Unit test passes for listener setup/cleanup
- [x] Add offline message queuing methods
  - Test Gate: Unit test passes for queue operations
- [x] Implement message status update methods
  - Test Gate: Unit test passes for status transitions
- [x] Add retry logic for failed messages
  - Test Gate: Unit test passes for retry scenarios

---

## 3. Data Model & Rules

- [x] Extend Message model with offline and retry fields
  - Test Gate: Model serialization/deserialization works
- [x] Create QueuedMessage model for offline storage
  - Test Gate: Model persists correctly in UserDefaults
- [x] Update Firestore security rules for message creation
  - Test Gate: Reads/writes succeed with rules applied
- [x] Add MessageStatus enum with all states
  - Test Gate: Status transitions work correctly

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [x] Create MessageInputView component
  - Test Gate: SwiftUI Preview renders; zero console errors
- [x] Create MessageStatusView component
  - Test Gate: All status states render correctly
- [x] Create OfflineIndicatorView component
  - Test Gate: Shows/hides based on connection status
- [x] Create RetryButtonView component
  - Test Gate: Retry action triggers correctly
- [x] Wire up state management in ChatViewModel
  - Test Gate: Interaction updates state correctly
- [x] Add loading/error/offline states to ChatView
  - Test Gate: All states render correctly

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [x] Firebase service integration for message sending
  - Test Gate: Messages save to Firestore successfully
- [x] Real-time listeners working
  - Test Gate: Data syncs across devices <100ms
- [x] Offline persistence implemented
  - Test Gate: App restarts work offline with cached data
- [x] Network status monitoring
  - Test Gate: Connection changes trigger UI updates
- [x] Message status updates in real-time
  - Test Gate: Status changes reflect immediately

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [x] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/MessageServiceTests.swift`
  - Test Gate: Service logic validated, edge cases covered
- [x] Network Tests (Swift Testing)
  - Path: `MessageAITests/Services/NetworkMonitorTests.swift`
  - Test Gate: Connection state changes tested
- [x] Offline Tests (Swift Testing)
  - Path: `MessageAITests/Services/OfflineQueueTests.swift`
  - Test Gate: Offline queuing and sync tested
- [x] UI Tests (XCTest)
  - Path: `MessageAIUITests/MessageSendingUITests.swift`
  - Test Gate: User flows succeed, navigation works
- [x] Multi-device sync test
  - Test Gate: Use pattern from shared-standards.md
- [x] Visual states verification
  - Test Gate: Empty, loading, error, success render correctly

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [x] Message delivery latency < 100ms
  - Test Gate: Firebase calls measured with instruments
- [x] Real-time sync < 100ms
  - Test Gate: Cross-device message delivery measured
- [x] No UI blocking during message send
  - Test Gate: Main thread stays responsive
- [x] Memory usage stable with listeners
  - Test Gate: No memory leaks detected

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [x] All happy path gates pass
- [x] All edge case gates pass
- [x] All multi-user gates pass
- [x] All performance gates pass

---

## 9. Documentation & PR

- [x] Add inline code comments for complex logic
- [x] Update README if needed
- [x] Create PR description (use format from MessageAI/agents/coder-agent-template.md)
- [x] Verify with user before creating PR
- [x] Open PR targeting develop branch
- [x] Link PRD and TODO in PR description

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
