# PRD: AI-Integrated Focus Mode

**Feature**: Real-time AI Classification Integration

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: January 2025

**Links**: [PR Brief: focus-mode-pr-briefs.md], [TODO: pr-22-todo.md], [Designs: User Mockups], [Tracking Issue: PR #22]

---

## 1. Summary

Connect the AI classification engine (PR #20) to the Focus Mode UI (PR #21) with real-time updates. When new messages arrive, they automatically get classified and move to the appropriate section (Priority/Review Later) based on AI-determined urgency. Users can provide feedback on classifications to improve accuracy.

---

## 2. Problem & Goals

- **Problem**: Users need messages to automatically sort into Priority/Review Later sections as they arrive, not just when Focus Mode is activated
- **Why now**: PR #20 classification engine and PR #21 UI foundation are complete, enabling real-time AI integration
- **Goals**:
  - [ ] G1 — New messages auto-classify and move to correct sections within 3s
  - [ ] G2 — Users can provide feedback on incorrect classifications to improve accuracy
  - [ ] G3 — Real-time updates work seamlessly without blocking the UI
  - [ ] G4 — Classification accuracy improves to >90% with user feedback

---

## 3. Non-Goals / Out of Scope

- [ ] Session summarization (handled in PR #23)
- [ ] Semantic search functionality (handled in PR #24)
- [ ] Custom urgency keywords or user training
- [ ] Multi-device sync of classification feedback
- [ ] Offline classification (requires internet connection)
- [ ] Classification of messages older than 24 hours

---

## 4. Success Metrics

- **User-visible**: Auto-classification within 3s, 95% of messages classified correctly
- **System**: Real-time updates within 5s, classification accuracy >90%, feedback submission rate >5%
- **Quality**: 0 blocking bugs, graceful error handling, no duplicate classifications

---

## 5. Users & Stories

- As a busy professional, I want new messages to automatically sort into Priority/Review Later sections so that I don't have to manually organize them
- As a user, I want to provide feedback when AI misclassifies a message so that the system learns and improves
- As a team lead, I want to see priority badges on urgent messages so that I can quickly identify what needs immediate attention

---

## 6. Experience Specification (UX)

### Entry Points and Flows
- **Primary**: Automatic classification when new messages arrive
- **Secondary**: Feedback button on each message for classification correction
- **Layout**: Priority badges on urgent messages, feedback buttons in message context menu

### Visual Behavior
- **New Message Flow**: Message appears → AI classification (3s) → moves to correct section
- **Priority Badges**: Small red dot or "URGENT" label on priority messages
- **Feedback UI**: "This should be urgent/normal" button in message options
- **Loading States**: Subtle spinner during classification, no blocking UI

### Loading/Disabled/Error States
- **Loading**: Small spinner next to unclassified messages
- **Error**: Graceful fallback to "normal" classification, retry option
- **Offline**: Messages remain unclassified until connection restored
- **Empty States**: No changes to existing empty states from PR #21

### Performance
- Classification updates: <3s for 95% of messages
- UI updates: <5s after classification complete
- Real-time sync: No blocking of message sending/receiving

---

## 7. Functional Requirements (Must/Should)

### MUST
- Real-time Firestore listener for message priority updates
- AIClassificationService for iOS integration with Cloud Functions
- Auto-sorting when classifications complete
- Feedback mechanism for classification correction
- Graceful error handling if classification fails

### SHOULD
- Priority badge indicators on urgent messages
- Classification confidence display (optional)
- Retry mechanism for failed classifications
- Offline queue for feedback submissions

### Acceptance Gates
- [Gate] New message arrives → classified within 3s → moves to correct section
- [Gate] User submits feedback → sent to backend → classification updated
- [Gate] Classification fails → message defaults to "normal" → retry available
- [Gate] Real-time updates don't block message sending/receiving
- [Gate] No duplicate classifications for same message

---

## 8. Data Model

Uses existing message priority field from PR #20, adds feedback tracking:

```swift
// Existing Message model (from PR #20)
struct Message {
    let id: String
    let text: String
    let priority: String? // "urgent" | "normal" | nil
    let classifiedAt: Date?
    let classificationReason: String?
    let confidence: Float? // 0.0-1.0
    // ... other existing fields
}

// New Classification Feedback model
struct ClassificationFeedback {
    let messageId: String
    let userId: String
    let originalPriority: String
    let suggestedPriority: String
    let feedbackReason: String?
    let submittedAt: Date
}
```

- **Validation**: Feedback requires valid message ID and user authentication
- **Indexing**: Index on messageId for feedback lookups

---

## 9. API / Service Contracts

```swift
// AIClassificationService
class AIClassificationService: ObservableObject {
    func listenForClassificationUpdates() async throws
    func submitClassificationFeedback(messageId: String, suggestedPriority: String, reason: String?) async throws
    func retryClassification(messageId: String) async throws
    func getClassificationStatus(messageId: String) async throws -> ClassificationStatus
}

// Classification Status
enum ClassificationStatus {
    case pending
    case classified(priority: String, confidence: Float)
    case failed(error: Error)
    case feedbackSubmitted
}

// Cloud Function API
struct ClassificationFeedbackRequest {
    let messageId: String
    let suggestedPriority: String
    let reason: String?
}
```

- **Pre-conditions**: User authenticated, message exists, valid priority values
- **Post-conditions**: UI updates, feedback logged, classification retried if needed
- **Error handling**: Network failures, invalid requests, rate limiting
- **Parameters**: Message IDs, priority strings, optional feedback reasons
- **Return values**: Classification status, success/failure responses

---

## 10. UI Components to Create/Modify

- `Services/AIClassificationService.swift` — Real-time classification integration
- `ViewModels/ConversationListViewModel.swift` — Add classification listeners
- `Views/ConversationListView.swift` — Add priority badges and feedback buttons
- `Views/Components/PriorityBadge.swift` — Urgent message indicator
- `Views/Components/ClassificationFeedbackView.swift` — Feedback submission UI
- `Models/ClassificationFeedback.swift` — Feedback data model

---

## 11. Integration Points

- **Firebase Authentication** — User session validation for feedback
- **Firestore** — Real-time listeners for priority updates
- **Cloud Functions** — Classification engine and feedback processing
- **FocusModeService** — Integration with existing Focus Mode state
- **MessageService** — Real-time message updates and classification

---

## 12. Test Plan & Acceptance Gates

### Happy Path
- [ ] New urgent message → classified as urgent → moves to Priority section
- [ ] New normal message → classified as normal → moves to Review Later section
- [ ] Gate: Classification completes within 3s for 95% of messages

### Edge Cases
- [ ] Classification fails → message defaults to normal → retry button available
- [ ] Network offline → messages queue for classification when online
- [ ] Duplicate message → no duplicate classification
- [ ] Invalid message → graceful error handling

### Multi-User
- [ ] Multiple users can provide feedback on same message
- [ ] Real-time updates work for all users simultaneously
- [ ] Feedback doesn't interfere with other users' experience

### Performance
- [ ] Real-time updates don't block message sending
- [ ] UI remains responsive during classification
- [ ] No memory leaks with continuous listeners

---

## 13. Definition of Done

- [ ] AIClassificationService implemented with real-time listeners
- [ ] Priority badges and feedback UI integrated
- [ ] Real-time classification updates working
- [ ] Feedback submission and processing verified
- [ ] Error handling and retry mechanisms tested
- [ ] All acceptance gates pass
- [ ] Documentation updated

---

## 14. Risks & Mitigations

- **Risk**: Real-time sync issues → Mitigation: Robust Firestore listeners, error handling
- **Risk**: User confusion about classifications → Mitigation: Clear visual indicators, onboarding
- **Risk**: Battery drain from continuous listeners → Mitigation: Throttle updates, optimize queries
- **Risk**: Classification accuracy issues → Mitigation: User feedback loop, continuous improvement

---

## 15. Rollout & Telemetry

- **Feature flag**: Yes - gradual rollout for real-time classification
- **Metrics**: Classification accuracy, feedback submission rate, update latency, user satisfaction
- **Manual validation**: Test with various message types, verify real-time updates

---

## 16. Open Questions

- Q1: Should we show classification confidence scores to users?
- Q2: How many feedback submissions should trigger a classification retry?
- Q3: Should we limit feedback to recent messages only?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:
- [ ] Session summarization (PR #23)
- [ ] Semantic search (PR #24)
- [ ] Custom urgency keywords
- [ ] Multi-device sync
- [ ] Offline classification
- [ ] Classification of old messages

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome**: New message arrives and automatically sorts into correct Priority/Review Later section
2. **Primary user and critical action**: Busy professional receiving urgent message that auto-classifies and moves to Priority section
3. **Must-have vs nice-to-have**: Real-time classification (must), feedback mechanism (should)
4. **Real-time requirements**: Classification within 3s, UI updates within 5s
5. **Performance constraints**: No blocking of message flow, responsive UI during classification
6. **Error/edge cases**: Classification failures, network issues, duplicate messages, invalid feedback
7. **Data model changes**: Add feedback tracking, use existing priority field
8. **Service APIs required**: AIClassificationService, Cloud Function feedback endpoint
9. **UI entry points**: Automatic classification, feedback buttons on messages
10. **Security/permissions**: User authentication for feedback, message ownership validation
11. **Dependencies**: PR #20 (classification engine), PR #21 (Focus Mode UI)
12. **Rollout strategy**: Feature flag for gradual rollout, monitor classification accuracy
13. **Out of scope**: Summarization, search, custom keywords, multi-device sync

---

## Authoring Notes

- Build on existing PR #20 classification engine and PR #21 UI foundation
- Focus on seamless real-time integration without blocking user experience
- Implement robust error handling and retry mechanisms
- Test thoroughly with various message types and network conditions
- Prioritize user feedback loop for continuous improvement
