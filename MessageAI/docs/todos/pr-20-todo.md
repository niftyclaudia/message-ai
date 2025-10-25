# PR-20 TODO — Foundation + Classification Engine

**Branch**: `feat/pr-20-classification-engine`  
**Source PRD**: `MessageAI/docs/prds/pr-20-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: 
  - Should we implement custom urgency keywords per user, or use global keywords? (Decision: Start with global keywords, add per-user customization in PR #22)
  - What confidence threshold should trigger manual review of classifications? (Decision: <0.7 confidence logged for review)
- **Assumptions (confirm in PR if needed)**:
  - OpenAI API key will be provided via environment variables
  - Firebase project is already configured with Firestore
  - Message model already exists and can be extended
  - Cloud Functions environment is set up and deployable

---

## 1. Setup

- [ ] Create branch `feat/pr-20-classification-engine` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm Firebase project and Cloud Functions environment work
- [ ] Set up OpenAI API key in Firebase Functions environment

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Implement `openaiClient.ts` service
  - Test Gate: Unit test passes for valid/invalid API calls
  - Test Gate: Error handling works for API failures
- [ ] Implement `aiPrioritization.ts` classification logic
  - Test Gate: Unit test passes for message classification
  - Test Gate: Confidence scoring works correctly
- [ ] Implement keyword-based fallback system
  - Test Gate: Edge cases handled correctly
  - Test Gate: Fallback activates when OpenAI fails
- [ ] Add rate limiting and cost control
  - Test Gate: API calls respect rate limits
  - Test Gate: Cost monitoring works

---

## 3. Data Model & Rules

- [ ] Update Message model in Swift to include priority fields
  - Test Gate: Model compiles and serializes correctly
- [ ] Create ClassificationResult model
  - Test Gate: Model handles all classification scenarios
- [ ] Update Firestore schema for new fields
  - Test Gate: Reads/writes succeed with new schema
- [ ] Add Firebase security rules for classification logs
  - Test Gate: Classification logs can be written/read correctly
- [ ] Create Firestore indexes for priority and classificationTimestamp
  - Test Gate: Queries on priority field perform efficiently

---

## 4. Cloud Functions Implementation

Create/modify Cloud Functions per PRD Section 10.

- [ ] Create `classifyMessage.ts` Firestore trigger
  - Test Gate: Trigger fires on new message creation
  - Test Gate: Classification completes within 3s
- [ ] Implement `classificationLogger.ts` utility
  - Test Gate: All classification attempts logged
  - Test Gate: Error cases logged with details
- [ ] Add error handling and retry logic
  - Test Gate: Failed classifications retry appropriately
  - Test Gate: Permanent failures don't block message delivery

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Firebase Functions deployment
  - Test Gate: Functions deploy successfully
  - Test Gate: Environment variables configured
- [ ] Firestore trigger integration
  - Test Gate: New messages trigger classification automatically
  - Test Gate: Classification results update message documents
- [ ] OpenAI API integration
  - Test Gate: API calls succeed with proper authentication
  - Test Gate: Rate limiting and error handling work
- [ ] Classification logging system
  - Test Gate: All classifications logged to Firestore
  - Test Gate: Analytics queries work efficiently

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/FocusModeClassificationTests.swift`
  - Test Gate: Classification logic validated, edge cases covered
  - Test Gate: Message model updates work correctly
  
- [ ] Cloud Functions Tests (Jest)
  - Path: `functions/src/__tests__/classification.test.js`
  - Test Gate: OpenAI integration tested
  - Test Gate: Firestore trigger logic validated
  
- [ ] Integration Tests (Swift Testing)
  - Path: `MessageAITests/Integration/ClassificationIntegrationTests.swift`
  - Test Gate: End-to-end classification flow works
  - Test Gate: Message priority updates in real-time
  
- [ ] Performance Tests
  - Test Gate: Classification completes within 3s for 95% of messages
  - Test Gate: No impact on message send latency

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Classification latency <3s for 95% of messages
  - Test Gate: Performance measured with sample dataset
- [ ] OpenAI API rate limiting implemented
  - Test Gate: API calls don't exceed rate limits
- [ ] Firestore write performance optimized
  - Test Gate: Message updates complete within 100ms
- [ ] No impact on message send latency
  - Test Gate: Message sending performance unchanged

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [ ] All happy path gates pass
  - Gate: New message triggers classification automatically
  - Gate: Classification completes within 3s
  - Gate: Message priority field updated correctly
- [ ] All edge case gates pass
  - Gate: OpenAI API timeout handled gracefully
  - Gate: Keyword fallback activates within 1s
  - Gate: Message delivery not blocked by classification failure
- [ ] All multi-user gates pass
  - Gate: Multiple simultaneous messages classified correctly
  - Gate: No race conditions in classification processing
- [ ] All performance gates pass
  - Gate: Classification latency <3s for 95% of messages
  - Gate: OpenAI API calls don't exceed rate limits
  - Gate: No impact on message send latency

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex classification logic
- [ ] Document OpenAI API integration patterns
- [ ] Update README with classification system overview
- [ ] Create PR description (use format from MessageAI/agents/coder-agent-template.md)
- [ ] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop
- [ ] All TODO tasks completed
- [ ] OpenAI service implemented + unit tests (Swift Testing)
- [ ] Firestore trigger deployed and tested
- [ ] Message model updated with priority fields
- [ ] Classification logging system implemented
- [ ] Keyword fallback system implemented
- [ ] Cloud Functions tests pass (Jest)
- [ ] Integration tests pass (Swift Testing)
- [ ] Performance targets met (classification <3s, no impact on send latency)
- [ ] All acceptance gates pass
- [ ] Code follows shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated
- [ ] Classification accuracy >85% on test dataset
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for common patterns and solutions
- Focus on backend implementation - no UI changes in this phase
- Test classification accuracy with diverse message samples
- Monitor OpenAI API costs during development
