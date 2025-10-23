# PR-2 TODO — Offline Persistence & Sync System

**Branch**: `feat/pr-2-offline-persistence-sync`  
**Source PRD**: `MessageAI/docs/prds/pr-2-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should we use Core Data or SQLite for offline storage?
  - What's the maximum offline queue size beyond 3 messages?
  - How should we handle message ordering during sync conflicts?
- **Assumptions (confirm in PR if needed)**:
  - Using Firestore offline persistence as base layer
  - 3-message queue is sufficient for most use cases
  - Network state detection will use Reachability framework
  - Force-quit recovery relies on Firestore's built-in persistence

---

## 1. Setup

- [ ] Create branch `feat/pr-2-offline-persistence-sync` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Set up Firebase offline persistence configuration

---

## 2. Data Model & Local Storage

Implement offline message data structures and local storage.

- [ ] Create `Models/OfflineMessage.swift`
  - Test Gate: Model compiles and initializes correctly
- [ ] Create `Models/ConnectionState.swift` enum
  - Test Gate: All states properly defined
- [ ] Create `Models/MessageStatus.swift` enum
  - Test Gate: Status transitions are valid
- [ ] Implement local storage schema (Core Data/SQLite)
  - Test Gate: Offline messages persist across app restarts
- [ ] Add data validation for offline messages
  - Test Gate: Invalid messages are rejected with proper error handling

---

## 3. Network Monitoring Service

Implement network connectivity detection and state management.

- [ ] Create `Services/NetworkMonitorService.swift`
  - Test Gate: Network state changes are detected accurately
- [ ] Implement `observeNetworkState()` method
  - Test Gate: State changes propagate to UI in real-time
- [ ] Implement `isOnline()` method
  - Test Gate: Returns correct online/offline status
- [ ] Implement `waitForConnection()` method
  - Test Gate: Waits for network connection with timeout
- [ ] Add network reachability detection
  - Test Gate: Detects WiFi, cellular, and no connection states

---

## 4. Offline Message Service

Implement offline message queue management.

- [ ] Create `Services/OfflineMessageService.swift`
  - Test Gate: Service initializes and manages offline queue
- [ ] Implement `queueMessageOffline()` method
  - Test Gate: Messages are queued locally when offline
- [ ] Implement `getOfflineMessages()` method
  - Test Gate: Returns all queued messages with correct status
- [ ] Implement `clearOfflineMessages()` method
  - Test Gate: Successfully sent messages are removed from queue
- [ ] Implement `updateMessageStatus()` method
  - Test Gate: Message status updates are persisted locally
- [ ] Add offline queue size limit (3 messages)
  - Test Gate: Queue size is enforced and oldest messages are removed

---

## 5. Sync Service

Implement message synchronization between offline queue and Firebase.

- [ ] Create `Services/SyncService.swift`
  - Test Gate: Service handles sync operations correctly
- [ ] Implement `syncOfflineMessages()` method
  - Test Gate: Queued messages are sent to Firebase on reconnect
- [ ] Implement `retryFailedMessages()` method
  - Test Gate: Failed messages are retried with exponential backoff
- [ ] Add sync conflict resolution
  - Test Gate: Message ordering is preserved during sync
- [ ] Implement sync progress tracking
  - Test Gate: Sync progress is reported accurately
- [ ] Add sync completion validation
  - Test Gate: All messages are confirmed as sent

---

## 6. UI Components

Create SwiftUI views for offline states and connection status.

- [ ] Create `Views/OfflineIndicator.swift`
  - Test Gate: SwiftUI Preview renders; shows offline banner correctly
- [ ] Create `Views/MessageQueueStatus.swift`
  - Test Gate: Shows queued message count and status
- [ ] Create `Views/ConnectionStatusView.swift`
  - Test Gate: Displays connecting/syncing states with animations
- [ ] Create `ViewModels/OfflineViewModel.swift`
  - Test Gate: Manages offline state and UI updates correctly
- [ ] Wire up state management (@StateObject, @ObservedObject)
  - Test Gate: UI updates reflect connection state changes
- [ ] Add loading/error/empty states for offline scenarios
  - Test Gate: All states render correctly with proper feedback

---

## 7. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Firebase offline persistence configuration
  - Test Gate: Firestore offline persistence is enabled
- [ ] Real-time connection state updates
  - Test Gate: Connection state syncs across devices < 200ms
- [ ] Offline message persistence
  - Test Gate: Messages persist through app restarts
- [ ] Network state propagation
  - Test Gate: Network state changes are reflected in UI immediately
- [ ] Auto-sync on reconnection
  - Test Gate: Queued messages auto-send within 1s of reconnection

---

## 8. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/OfflineMessageServiceTests.swift`
  - Test Gate: Offline message operations validated, edge cases covered
  
- [ ] Network Tests (Swift Testing)
  - Path: `MessageAITests/NetworkMonitorServiceTests.swift`
  - Test Gate: Network state detection and monitoring tested
  
- [ ] Sync Tests (Swift Testing)
  - Path: `MessageAITests/SyncServiceTests.swift`
  - Test Gate: Message synchronization and conflict resolution tested
  
- [ ] UI Tests (XCTest)
  - Path: `MessageAIUITests/OfflineMessagingUITests.swift`
  - Test Gate: Offline UI flows succeed, connection states display correctly
  
- [ ] Multi-device sync test
  - Test Gate: Use pattern from shared-standards.md for offline sync across devices
  
- [ ] Force-quit recovery test
  - Test Gate: Messages persist through force-quit and app restart
  
- [ ] Network resilience test
  - Test Gate: 30s+ network drops handled with auto-reconnect

---

## 9. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Offline queue performance
  - Test Gate: 3-message queue operations complete < 100ms
- [ ] Sync completion time
  - Test Gate: Offline messages sync < 1s after reconnection
- [ ] Network state detection latency
  - Test Gate: Network state changes detected < 500ms
- [ ] UI responsiveness during sync
  - Test Gate: UI remains responsive during bulk message sync
- [ ] Memory usage optimization
  - Test Gate: Offline queue doesn't cause memory leaks

---

## 10. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass
  - [ ] User goes offline → messages queue locally
  - [ ] User reconnects → queued messages auto-send
  - [ ] All queued messages sent within 1s of reconnection
- [ ] All edge case gates pass
  - [ ] App force-quit while offline → messages preserved on restart
  - [ ] Network drops for 30s+ → auto-reconnect works
  - [ ] Zero message loss during force-quit scenarios
- [ ] All multi-user gates pass
  - [ ] Offline messages sync across devices
  - [ ] Real-time status updates propagate
  - [ ] Offline queue syncs < 200ms across devices
- [ ] All performance gates pass
  - [ ] 3-message queue capacity maintained
  - [ ] Sync completion < 1s after reconnection
  - [ ] UI remains responsive during sync operations

---

## 11. Documentation & PR

- [ ] Add inline code comments for complex offline logic
- [ ] Document offline queue behavior and limitations
- [ ] Update README with offline capabilities
- [ ] Create PR description (use format from MessageAI/agents/cody-agent-template.md)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] Offline message service implemented + unit tests (Swift Testing)
- [ ] Network monitoring service with connection state management
- [ ] SwiftUI views for offline states (offline, connecting, syncing)
- [ ] Firebase offline persistence configured
- [ ] Real-time sync verified across 2+ devices
- [ ] Force-quit recovery tested
- [ ] Network resilience tested (30s+ drops)
- [ ] Performance targets met (3-message queue, < 1s sync)
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
- Test thoroughly with network simulation
- Ensure graceful degradation when offline
