# PR-12 TODO — Message Read Receipts

**Branch**: `feat/pr-12-message-read-receipts`  
**Source PRD**: `MessageAI/docs/prds/pr-12-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should read receipts be batched for performance optimization?
  - Should we implement read receipt privacy controls in this PR?
- **Assumptions (confirm in PR if needed)**:
  - Read receipts are automatically triggered when user views messages (no manual action required)
  - Read receipts work with existing optimistic UI system
  - Read receipts are only for 1-on-1 chats (group chat read receipts are future feature)

---

## 1. Setup

- [ ] Create branch `feat/pr-12-message-read-receipts` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Create `ReadReceiptService.swift`
  - Test Gate: Unit test passes for valid/invalid cases
- [ ] Implement `markMessageAsRead(messageID:userID:)` method
  - Test Gate: Unit test passes for successful read receipt update
- [ ] Implement `markChatAsRead(chatID:userID:)` method
  - Test Gate: Unit test passes for batch read receipt updates
- [ ] Implement `observeReadReceipts(chatID:completion:)` method
  - Test Gate: Unit test passes for real-time read receipt updates
- [ ] Add validation logic for user permissions
  - Test Gate: Edge cases handled correctly (unauthorized users, invalid message IDs)

---

## 3. Data Model & Rules

- [ ] Create `Models/ReadReceipt.swift` with read receipt data structure
- [ ] Update `Models/Message.swift` to include `readBy` and `readAt` fields
- [ ] Update Firestore schema to support read receipt fields
- [ ] Add Firebase security rules for read receipt updates
  - Test Gate: Reads/writes succeed with rules applied
- [ ] Add Firestore indexes for read receipt queries
  - Test Gate: Read receipt queries perform efficiently

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create `Views/Components/ReadReceiptIndicatorView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Update `Views/Components/MessageRowView.swift` to include read receipt indicator
  - Test Gate: Read receipt indicators display correctly for sent messages
- [ ] Wire up read receipt state management in `ViewModels/ChatViewModel.swift`
  - Test Gate: Read receipt state updates trigger UI changes
- [ ] Add loading/error/empty states for read receipts
  - Test Gate: All states render correctly (read/unread/loading/error)

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Firebase service integration for read receipts
  - Test Gate: Read receipt updates sync to Firestore
- [ ] Real-time listeners for read receipt updates
  - Test Gate: Read receipts sync across devices <100ms
- [ ] Offline persistence for read receipts
  - Test Gate: Read receipts queue and sync on reconnect
- [ ] Integration with existing MessageService
  - Test Gate: Read receipts work seamlessly with message sending/receiving

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/ReadReceiptServiceTests.swift`
  - Test Gate: Service logic validated, edge cases covered
  
- [ ] UI Tests (XCUITest)
  - Path: `MessageAIUITests/ReadReceiptUITests.swift`
  - Test Gate: User flows succeed, read receipts display correctly
  
- [ ] Service Tests (Swift Testing)
  - Path: `MessageAITests/Services/ReadReceiptServiceTests.swift`
  - Test Gate: Firebase operations tested
  
- [ ] Multi-device sync test
  - Test Gate: Use pattern from shared-standards.md for read receipt sync
  
- [ ] Visual states verification
  - Test Gate: Read receipt states (read/unread/loading/error) render correctly

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Read receipt updates don't impact message scrolling performance
  - Test Gate: Smooth 60fps scrolling maintained with read receipts
- [ ] Read receipt sync latency < 100ms
  - Test Gate: Firebase read receipt updates measured
- [ ] Batch read receipt updates for performance
  - Test Gate: Multiple read receipts batched efficiently

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass (read receipts appear when messages viewed)
- [ ] All edge case gates pass (network failures, offline scenarios)
- [ ] All multi-user gates pass (real-time sync across devices)
- [ ] All performance gates pass (no impact on message performance)

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex read receipt logic
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
- [ ] ReadReceiptService implemented + unit tests (Swift Testing)
- [ ] ReadReceiptIndicatorView implemented with state management
- [ ] Firebase integration tested (real-time sync, offline)
- [ ] UI tests pass (XCUITest)
- [ ] Multi-device read receipt sync verified (<100ms)
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
