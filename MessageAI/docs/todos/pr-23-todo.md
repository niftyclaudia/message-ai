# PR-23 TODO — Session Summarization

**Branch**: `feat/pr-23-session-summarization`  
**Source PRD**: `MessageAI/docs/prds/pr-23-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should summaries include message sender names or just content?
  - What's the maximum token limit for OpenAI API calls?
  - Should we implement summary history view in this PR?
- **Assumptions** (confirm in PR if needed):
  - OpenAI API key is configured in Cloud Functions
  - Focus Mode sessions are already being tracked (from Phase 2-3) ✅ PR #20-22 complete
  - Users expect summaries in English only for v1

---

## 1. Setup

- [x] Create branch `feat/pr-23-session-summarization` from develop
- [x] Read PRD thoroughly
- [x] Read `MessageAI/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work
- [x] Verify OpenAI API access in Cloud Functions

---

## 2. Backend Services (Cloud Functions)

Implement summary generation and session management in Cloud Functions.

- [x] Create `functions/src/services/threadSummarization.ts`
  - Test Gate: Unit test passes for valid/invalid message arrays
- [x] Create `functions/src/api/getSummary.ts`
  - Test Gate: API endpoint returns summary for valid session ID
- [x] Create `functions/src/triggers/generateSummary.ts`
  - Test Gate: Trigger fires on session end and generates summary
- [x] Add OpenAI integration for GPT-4 summarization
  - Test Gate: Summary generation completes in <10s
- [x] Implement summary caching in Firestore
  - Test Gate: Summaries persist and can be retrieved

---

## 3. Data Model & Rules

- [ ] Define `FocusSession` struct in Swift
  - Test Gate: Struct compiles and matches Firestore schema
- [ ] Define `FocusSummary` struct in Swift
  - Test Gate: Struct compiles and matches Firestore schema
- [ ] Update Firestore security rules for summaries
  - Test Gate: Users can only read/write their own summaries
- [ ] Add Firestore indexes for summary queries
  - Test Gate: Queries execute efficiently

---

## 4. Service Layer (iOS)

Implement summary and session services in iOS app.

- [ ] Create `Services/SummaryService.swift`
  - Test Gate: Unit test passes for summary generation and retrieval
- [ ] Create `Services/FocusSessionService.swift`
  - Test Gate: Unit test passes for session lifecycle management
- [ ] Implement export functionality
  - Test Gate: Export generates valid text/PDF data
- [ ] Add error handling and retry logic
  - Test Gate: API failures handled gracefully

---

## 5. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create `Views/FocusSummaryView.swift`
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Create `Views/FocusSummaryRow.swift`
  - Test Gate: Preview renders with sample summary data
- [ ] Create `ViewModels/FocusSummaryViewModel.swift`
  - Test Gate: State management works correctly
- [ ] Wire up modal presentation from Focus Mode deactivation
  - Test Gate: Modal appears when Focus Mode ends
- [ ] Add loading/error/empty states
  - Test Gate: All states render correctly
- [ ] Implement export/share functionality
  - Test Gate: Export button generates shareable content

---

## 6. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Integrate with FocusModeService for session triggers
  - Test Gate: Session end triggers summary generation
- [ ] Connect to Firestore for summary storage
  - Test Gate: Summaries save and retrieve correctly
- [ ] Implement real-time summary generation
  - Test Gate: Summary appears within 10s of session end
- [ ] Add offline handling for summary generation
  - Test Gate: Failed generations can be retried

---

## 7. Tests

Follow patterns from `MessageAI/agents/shared-standards.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/SummaryServiceTests.swift`
  - Test Gate: Service logic validated, edge cases covered
  
- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/FocusSessionServiceTests.swift`
  - Test Gate: Session lifecycle tested, error cases handled
  
- [ ] UI Tests (XCTest)
  - Path: `MessageAIUITests/FocusSummaryUITests.swift`
  - Test Gate: Modal presentation, export functionality works
  
- [ ] Integration Tests (Swift Testing)
  - Path: `MessageAITests/Integration/SummaryIntegrationTests.swift`
  - Test Gate: End-to-end summary generation tested
  
- [ ] Visual states verification
  - Test Gate: Loading, error, success, empty states render correctly

---

## 8. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Modal presentation <500ms
  - Test Gate: Modal appears quickly after Focus Mode deactivation
- [ ] Summary generation <10s
  - Test Gate: OpenAI API calls complete within time limit
- [ ] Smooth 60fps animations
  - Test Gate: Modal slide-up animation is smooth
- [ ] Memory usage optimization
  - Test Gate: Large summaries don't cause memory issues

---

## 9. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass
  - [ ] User deactivates Focus Mode → Summary generates and displays
  - [ ] Summary includes overview, actions, decisions
- [ ] All edge case gates pass
  - [ ] Empty session handled gracefully
  - [ ] API failure shows retry option
  - [ ] Network timeout handled
- [ ] All multi-user gates pass
  - [ ] Summary generation doesn't block other users
  - [ ] Concurrent session endings handled
- [ ] All performance gates pass
  - [ ] Modal presentation <500ms
  - [ ] Summary generation <10s
  - [ ] Smooth 60fps animations

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
