# PR-23 TODO — Focus Mode Summarization

**Branch**: `feat/pr-23-focus-summarization`  
**Source PRD**: `MessageAI/docs/prds/pr-23-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should summaries include message sender names or just content?
  - What's the maximum token limit for OpenAI API calls?
  - Should we implement summary history view in this PR?
  - How many unread priority messages should be included before truncation?
  - Should summaries prioritize recent unread messages over older ones?
- **Assumptions** (confirm in PR if needed):
  - OpenAI API key is configured in Cloud Functions
  - Focus Mode sessions are already being tracked (from Phase 2-3) ✅ PR #20-22 complete
  - Users expect summaries in English only for v1
  - Summaries should include ALL unread priority messages, not just session-based ones

---

## 1. Setup

- [x] Create branch `feat/pr-23-focus-summarization` from develop
- [x] Read PRD thoroughly
- [x] Read `MessageAI/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work
- [x] Verify OpenAI API access in Cloud Functions

---

## 2. Backend Services (Cloud Functions)

Implement summary generation for ALL unread priority messages in Cloud Functions.

- [x] Create `functions/src/services/threadSummarization.ts`
  - Test Gate: Unit test passes for valid/invalid message arrays
- [x] Create `functions/src/api/getSummary.ts`
  - Test Gate: API endpoint returns summary for all unread priority messages
- [x] Create `functions/src/triggers/generateSummary.ts`
  - Test Gate: Trigger fires on Focus Mode deactivation and generates summary
- [x] Add OpenAI integration for GPT-4 summarization
  - Test Gate: Summary generation completes in <10s
- [x] Implement summary caching in Firestore
  - Test Gate: Summaries persist and can be retrieved
- [x] Update summarization to fetch ALL unread priority messages (not just session-based)
  - Test Gate: Summary includes messages from all time periods

---

## 3. Data Model & Rules

- [x] Define simplified `FocusSession` struct in Swift (session tracking only)
  - Test Gate: Struct compiles and matches Firestore schema
- [x] Define updated `FocusSummary` struct in Swift (sessionID optional)
  - Test Gate: Struct compiles and matches Firestore schema
- [x] Update Firestore security rules for summaries
  - Test Gate: Users can only read/write their own summaries
- [x] Add Firestore indexes for summary queries
  - Test Gate: Queries execute efficiently

---

## 4. Service Layer (iOS)

Implement summary and session services in iOS app.

- [x] Create `Services/SummaryService.swift`
  - Test Gate: Unit test passes for summary generation and retrieval
- [x] Update `Services/SummaryService.swift` to use new API contracts
  - Test Gate: `generateFocusSummary()` method works without session ID
- [x] Create `Services/FocusSessionService.swift` (simplified)
  - Test Gate: Unit test passes for session lifecycle management
- [x] Integrate with `MessageService` for fetching unread priority messages
  - Test Gate: All unread priority messages are retrieved
- [x] Integrate with `AIClassificationService` for message priority
  - Test Gate: Message priority classification works correctly
- [x] Implement export functionality
  - Test Gate: Export generates valid text/PDF data
- [x] Add error handling and retry logic
  - Test Gate: API failures handled gracefully

---

## 5. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [x] Create `Views/FocusSummaryView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [x] Create `Views/FocusSummaryRow.swift`
  - Test Gate: Preview renders with sample summary data
- [x] Create `ViewModels/FocusSummaryViewModel.swift`
  - Test Gate: State management works correctly
- [x] Wire up modal presentation from Focus Mode deactivation
  - Test Gate: Modal appears when Focus Mode ends
- [x] Add loading/error/empty states
  - Test Gate: All states render correctly (including "no unread priority messages")
- [x] Implement export/share functionality
  - Test Gate: Export button generates shareable content

---

## 6. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [x] Integrate with FocusModeService for Focus Mode triggers
  - Test Gate: Focus Mode deactivation triggers summary generation
- [x] Integrate with MessageService for fetching unread priority messages
  - Test Gate: All unread priority messages are retrieved for summarization
- [x] Integrate with AIClassificationService for message priority
  - Test Gate: Message priority classification works correctly
- [x] Connect to Firestore for summary storage
  - Test Gate: Summaries save and retrieve correctly
- [x] Implement real-time summary generation
  - Test Gate: Summary appears within 10s of Focus Mode deactivation
- [x] Add error handling and retry logic for summary generation
  - Test Gate: Failed generations can be retried

---

## 7. Tests

Follow patterns from `MessageAI/agents/shared-standards.md`.

- [x] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/SummaryServiceTests.swift`
  - Test Gate: Service logic validated, edge cases covered, tests ALL unread priority messages
  
- [x] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/FocusSessionServiceTests.swift`
  - Test Gate: Session lifecycle tested, error cases handled
  
- [x] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/MessageServiceTests.swift`
  - Test Gate: Unread priority message fetching tested
  
- [x] UI Tests (XCTest)
  - Path: `MessageAIUITests/FocusSummaryUITests.swift`
  - Test Gate: Modal presentation, export functionality works
  
- [x] Integration Tests (Swift Testing)
  - Path: `MessageAITests/Integration/SummaryIntegrationTests.swift`
  - Test Gate: End-to-end summary generation tested with all unread priority messages
  
- [x] Visual states verification
  - Test Gate: Loading, error, success, empty states render correctly

---

## 8. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [x] Modal presentation <500ms
  - Test Gate: Modal appears quickly after Focus Mode deactivation
- [x] Summary generation <10s
  - Test Gate: OpenAI API calls complete within time limit
- [x] Smooth 60fps animations
  - Test Gate: Modal slide-up animation is smooth
- [x] Memory usage optimization
  - Test Gate: Large summaries don't cause memory issues
- [x] Large unread priority message handling
  - Test Gate: Performance remains good with many unread priority messages

---

## 9. Acceptance Gates

Check every gate from PRD Section 12:
- [x] All happy path gates pass
  - [x] User deactivates Focus Mode → Summary generates and displays
  - [x] Summary includes overview, actions, decisions
  - [x] Summary includes ALL unread priority messages from all time periods
- [x] All edge case gates pass
  - [x] No unread priority messages handled gracefully
  - [x] API failure shows retry option
  - [x] Network timeout handled
- [x] All multi-user gates pass
  - [x] Summary generation doesn't block other users
  - [x] Concurrent Focus Mode deactivations handled
- [x] All performance gates pass
  - [x] Modal presentation <500ms
  - [x] Summary generation <10s
  - [x] Smooth 60fps animations

---

## 10. Documentation & PR

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
- [ ] Backend services implemented + unit tests (Swift Testing)
- [ ] iOS services implemented + unit tests (Swift Testing)
- [ ] SwiftUI views implemented with state management
- [ ] Firebase integration tested (summary storage, retrieval)
- [ ] UI tests pass (XCTest)
- [ ] Integration tests pass (Swift Testing)
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
- Test OpenAI API integration early to avoid blockers
- Ensure Cloud Functions are deployed before iOS integration
