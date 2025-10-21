# PR-11 TODO — Online/Offline Presence Indicators

**Branch**: `feat/pr-11-presence-indicators`  
**Source PRD**: `MessageAI/docs/prds/pr-11-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - PRD is comprehensive
- **Assumptions (confirm in PR if needed)**:
  - Firebase Realtime Database is already configured in the project
  - User authentication is working (from PR #1)
  - App lifecycle handling is standard iOS behavior

---

## 1. Setup

- [ ] Create branch `feat/pr-11-presence-indicators` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm Firebase Realtime Database is configured
- [ ] Verify test runner works with new service tests

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Create `Services/PresenceService.swift`
  - Test Gate: Service compiles and basic structure is in place
- [ ] Implement `setUserOnline(userID: String) async throws`
  - Test Gate: Unit test passes for valid userID, handles authentication errors
- [ ] Implement `setUserOffline(userID: String) async throws`
  - Test Gate: Unit test passes for valid userID, handles network errors
- [ ] Implement `observeUserPresence(userID: String, completion: @escaping (PresenceStatus) -> Void) -> ListenerRegistration`
  - Test Gate: Unit test verifies listener registration and callback execution
- [ ] Implement `observeMultipleUsersPresence(userIDs: [String], completion: @escaping ([String: PresenceStatus]) -> Void) -> ListenerRegistration`
  - Test Gate: Unit test verifies multiple user observation
- [ ] Implement `cleanupPresenceData(userID: String) async throws`
  - Test Gate: Unit test verifies cleanup removes presence data
- [ ] Add error handling and retry logic
  - Test Gate: Network failures handled gracefully, retry attempts work

---

## 3. Data Model & Rules

- [ ] Create `Models/PresenceStatus.swift` with status enum and device info
  - Test Gate: Model compiles and can be serialized/deserialized
- [ ] Define Firebase Realtime Database structure in comments
  - Test Gate: Structure documented and validated
- [ ] Add Firebase Realtime Database security rules
  - Test Gate: Rules deployed, authenticated users can read/write their own presence
- [ ] Create Firebase Realtime Database indexes if needed
  - Test Gate: Queries perform efficiently

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create `Components/PresenceIndicator.swift`
  - Test Gate: SwiftUI Preview renders online/offline states correctly
- [ ] Modify `Views/Components/UserRowView.swift` to include presence indicator
  - Test Gate: User rows show presence status, updates in real-time
- [ ] Modify `Views/Components/ConversationRowView.swift` to include presence indicator
  - Test Gate: Conversation rows show presence status for other participants
- [ ] Update `ViewModels/ContactListViewModel.swift` to integrate presence data
  - Test Gate: Contact list shows presence status, updates when users come online/offline
- [ ] Update `ViewModels/ConversationListViewModel.swift` to integrate presence data
  - Test Gate: Conversation list shows presence status for participants
- [ ] Add loading/error/empty states for presence indicators
  - Test Gate: All states render correctly, smooth transitions

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Firebase Realtime Database integration
  - Test Gate: Connection established, onDisconnect hooks configured
- [ ] Real-time presence listeners working
  - Test Gate: Presence updates sync across devices <100ms
- [ ] App lifecycle handling (foreground/background/terminated)
  - Test Gate: Presence status updates correctly on app state changes
- [ ] Network disconnection handling
  - Test Gate: App gracefully handles network failures, shows offline status
- [ ] onDisconnect hook implementation
  - Test Gate: User goes offline when app terminates or network disconnects

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/PresenceServiceTests.swift`
  - Test Gate: All service methods tested, edge cases covered, error handling verified
  
- [ ] UI Tests (XCTest)
  - Path: `MessageAIUITests/PresenceIndicatorUITests.swift`
  - Test Gate: Presence indicators display correctly, user interactions work
  
- [ ] Multi-device sync test
  - Path: `MessageAITests/Integration/PresenceSyncTests.swift`
  - Test Gate: Use pattern from shared-standards.md for 3+ device testing
  
- [ ] App lifecycle tests
  - Path: `MessageAITests/Integration/PresenceLifecycleTests.swift`
  - Test Gate: Foreground/background/terminated states handled correctly
  
- [ ] Visual states verification
  - Test Gate: Online, offline, connecting, error states render correctly

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] App load time < 2-3 seconds with presence initialization
  - Test Gate: Cold start to interactive measured, presence service initializes quickly
- [ ] Presence update latency < 100ms
  - Test Gate: Firebase Realtime Database calls measured, meets target
- [ ] Smooth 60fps with 100+ presence indicators
  - Test Gate: Use LazyVStack, verify with instruments, no UI blocking
- [ ] Memory usage optimization
  - Test Gate: Presence listeners don't cause memory leaks, proper cleanup

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass (user comes online/offline, status updates <100ms)
- [ ] All edge case gates pass (network disconnection, app termination)
- [ ] All multi-user gates pass (real-time sync <100ms across 3+ devices)
- [ ] All performance gates pass (app load <2-3s, smooth 60fps, <100ms latency)

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex presence logic
- [ ] Document Firebase Realtime Database structure
- [ ] Update README with presence system overview
- [ ] Create PR description (use format from MessageAI/agents/coder-agent-template.md)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] PresenceService implemented + unit tests (Swift Testing)
- [ ] SwiftUI presence indicators implemented with state management
- [ ] Firebase Realtime Database integration tested (real-time sync, onDisconnect hooks)
- [ ] UI tests pass (XCTest)
- [ ] Multi-device sync verified (<100ms)
- [ ] App lifecycle handling tested (foreground/background/terminated)
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
- Focus on Firebase Realtime Database onDisconnect hooks for reliable offline detection
- Test app state transitions thoroughly (foreground/background/terminated)
- Ensure presence indicators are visually consistent across all UI components
