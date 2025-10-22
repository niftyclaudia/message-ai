# PR-10 TODO — Group Chat Logic & Multi-User Support

**Branch**: `feat/pr-10-group-chat-logic`  
**Source PRD**: `MessageAI/docs/prds/pr-10-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - PRD is comprehensive and clear
- **Assumptions (confirm in PR if needed)**:
  - Group chat creation flow from PR #9 is complete and functional
  - Existing messaging infrastructure (real-time sync, optimistic UI, offline persistence) works for 1-on-1 chats
  - Focus on 3-10 member groups for optimal performance
  - No schema changes needed - existing Firestore structure supports group chats

---

## 1. Setup

- [ ] Create branch `feat/pr-10-group-chat-logic` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Verify PR #9 group chat creation is complete

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Verify `MessageService.sendMessage()` works with group chats
  - Test Gate: Unit test passes for 1-on-1 and group chats
- [ ] Verify `MessageService.observeMessages()` works with group chats
  - Test Gate: Real-time listeners work for group chat messages
- [ ] Verify `MessageService.markMessageAsRead()` works with group chats
  - Test Gate: Read receipts update correctly for all group members
- [ ] Add group member validation logic
  - Test Gate: Edge cases handled correctly (invalid members, empty groups)

---

## 3. Data Model & Rules

- [ ] Verify existing Chat model supports group chats
  - Test Gate: Members array handles 2+ users correctly
- [ ] Verify existing Message model supports group read receipts
  - Test Gate: ReadBy array tracks all group members
- [ ] Update Firebase security rules for group chats
  - Test Gate: All group members can read/write messages
- [ ] Add group chat validation rules
  - Test Gate: Invalid group configurations rejected

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Modify `ChatView.swift` to display sender names in group chats
  - Test Gate: SwiftUI Preview renders group messages with sender names
- [ ] Update `MessageBubbleView.swift` for group chat display
  - Test Gate: Group messages show sender info, 1-on-1 messages unchanged
- [ ] Create `ReadReceiptView.swift` for group read receipts
  - Test Gate: Shows "Read by X of Y" for group messages
- [ ] Update `ChatViewModel.swift` for group chat state management
  - Test Gate: State updates work for group chats
- [ ] Add group member presence indicators
  - Test Gate: Online/offline status shows for all group members

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Verify Firebase service integration works with group chats
  - Test Gate: All Firebase operations work for group chats
- [ ] Test real-time listeners with group chats
  - Test Gate: Messages sync across all group members <100ms
- [ ] Verify offline persistence works with group chats
  - Test Gate: Group messages persist and sync on reconnect
- [ ] Test presence indicators for all group members
  - Test Gate: Online/offline states reflect correctly for all members

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/MessageServiceGroupChatTests.swift`
  - Test Gate: Group chat service logic validated, edge cases covered
  
- [ ] UI Tests (XCUITest)
  - Path: `MessageAIUITests/GroupChatUITests.swift`
  - Test Gate: Group chat user flows succeed, navigation works
  
- [ ] Service Tests (Swift Testing)
  - Path: `MessageAITests/Services/ChatServiceGroupTests.swift`
  - Test Gate: Group chat Firebase operations tested
  
- [ ] Multi-device group chat sync test
  - Test Gate: Use pattern from shared-standards.md for 3+ devices
  
- [ ] Visual states verification
  - Test Gate: Group chat UI renders correctly (sender names, read receipts)

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] App load time < 2-3 seconds with group chats
  - Test Gate: Cold start to interactive measured
- [ ] Message latency < 100ms for group chats
  - Test Gate: Firebase calls measured for 5-member groups
- [ ] Smooth 60fps scrolling with 100+ group messages
  - Test Gate: Use LazyVStack, verify with instruments
- [ ] Group chat performance with 10 members
  - Test Gate: No performance degradation with larger groups

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass (group message delivery, read receipts)
- [ ] All edge case gates pass (offline members, network interruptions)
- [ ] All multi-user gates pass (3+ devices, real-time sync)
- [ ] All performance gates pass (latency, scrolling, load time)

---

## 9. Documentation & PR

- [ ] Add inline code comments for group chat logic
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
- [ ] SwiftUI views implemented with group chat support
- [ ] Firebase integration tested (real-time sync, offline)
- [ ] UI tests pass (XCUITest)
- [ ] Multi-device group chat sync verified (<100ms)
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
- Focus on ensuring existing features work seamlessly with group chats
- Test thoroughly with 3, 5, and 10-member groups
