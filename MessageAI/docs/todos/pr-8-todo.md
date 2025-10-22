# PR-8 TODO — Firestore Offline Persistence

**Branch**: `feat/pr-8-offline-persistence`  
**Source PRD**: `MessageAI/docs/prds/pr-8-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - PRD is comprehensive
- **Assumptions (confirm in PR if needed)**:
  - Firestore offline persistence will be enabled globally
  - Message queuing will use in-memory storage with disk persistence
  - Network monitoring will use Reachability framework
  - Cache size limit of 50MB is acceptable

---

## 1. Setup

- [ ] Create branch `feat/pr-8-offline-persistence` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Review existing MessageService and ChatViewModel implementations

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Enhance MessageService with offline persistence
  - Test Gate: Unit test passes for offline message queuing
- [ ] Implement NetworkMonitor service
  - Test Gate: Unit test passes for network state detection
- [ ] Add message retry logic with exponential backoff
  - Test Gate: Unit test passes for retry scenarios
- [ ] Implement cache management (size limits, cleanup)
  - Test Gate: Unit test passes for cache size enforcement

---

## 3. Data Model & Rules

- [ ] Add MessageStatus enum to Message model
  - Test Gate: Swift compilation succeeds, enum cases work
- [ ] Add isQueued field to Message model
  - Test Gate: Model serialization/deserialization works
- [ ] Update Firestore security rules (if needed)
  - Test Gate: Reads/writes succeed with rules applied
- [ ] Configure Firestore offline persistence settings
  - Test Gate: Offline cache enabled and working

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create OfflineIndicatorView
  - Test Gate: SwiftUI Preview renders; shows offline status correctly
- [ ] Create MessageStatusView
  - Test Gate: SwiftUI Preview renders; shows message status correctly
- [ ] Create RetryButtonView
  - Test Gate: SwiftUI Preview renders; retry action works
- [ ] Create OfflineTestButtonView (simulator only)
  - Test Gate: SwiftUI Preview renders; test scenarios work
- [ ] Enhance ChatViewModel with offline state management
  - Test Gate: Offline state updates UI correctly
- [ ] Add offline states to ChatView
  - Test Gate: All offline states render correctly

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Enable Firestore offline persistence
  - Test Gate: App works offline with cached data
- [ ] Implement message queuing system
  - Test Gate: Messages queue when offline, send when online
- [ ] Add network monitoring integration
  - Test Gate: Network state changes trigger UI updates
- [ ] Implement automatic sync on reconnection
  - Test Gate: Queued messages sync within 5 seconds of reconnect

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/MessageServiceOfflineTests.swift`
  - Test Gate: Offline message queuing, retry logic, cache management validated
  
- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/NetworkMonitorTests.swift`
  - Test Gate: Network state detection, connectivity changes tested
  
- [ ] UI Tests (XCTest)
  - Path: `MessageAIUITests/OfflineMessagingUITests.swift`
  - Test Gate: Offline message sending, status indicators, retry functionality
  
- [ ] Service Tests (Swift Testing)
  - Path: `MessageAITests/Services/MessageServiceOfflineTests.swift`
  - Test Gate: Firebase offline operations, message queuing tested
  
- [ ] Multi-device offline test
  - Test Gate: Use pattern from shared-standards.md for offline sync
  
- [ ] Visual states verification
  - Test Gate: Offline, online, syncing states render correctly

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Offline cache size < 50MB
  - Test Gate: Cache size measured and enforced
- [ ] Message sync completion < 5 seconds
  - Test Gate: Sync time measured on reconnection
- [ ] Offline message loading < 100ms
  - Test Gate: Cached messages load instantly
- [ ] Smooth performance with 1000+ cached messages
  - Test Gate: Use LazyVStack, verify with instruments

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass
- [ ] All edge case gates pass
- [ ] All multi-user gates pass
- [ ] All performance gates pass

---

## 9. Documentation & PR

- [ ] Add inline code comments for offline persistence logic
- [ ] Update README with offline capabilities
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
- [ ] SwiftUI views implemented with offline state management
- [ ] Firestore offline persistence enabled and tested
- [ ] Message queuing and sync verified
- [ ] UI tests pass (XCUITest)
- [ ] Multi-device offline sync verified
- [ ] Performance targets met (cache < 50MB, sync < 5s)
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
- Focus on offline-first architecture
- Test thoroughly with network interruptions
