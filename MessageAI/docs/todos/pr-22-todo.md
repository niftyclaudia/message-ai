# PR 22 TODO: AI-Integrated Focus Mode

**Feature**: Real-time AI Classification Integration  
**Status**: Ready for Development  
**Agent**: Cody  
**Target Release**: January 2025  

---

## 🎯 Overview

Connect the AI classification engine (PR #20) to the Focus Mode UI (PR #21) with real-time updates. When new messages arrive, they automatically get classified and move to the appropriate section (Priority/Review Later) based on AI-determined urgency. Users can provide feedback on classifications to improve accuracy.

---

## 📋 Development Tasks

### Phase 1: Core Service Layer
- [ ] **1.1** Create `AIClassificationService.swift`
  - [ ] Implement `@Published var classificationStatus: [String: ClassificationStatus]` property
  - [ ] Add `listenForClassificationUpdates()` async method
  - [ ] Add `submitClassificationFeedback(messageId: String, suggestedPriority: String, reason: String?)` method
  - [ ] Add `retryClassification(messageId: String)` method
  - [ ] Add `getClassificationStatus(messageId: String) -> ClassificationStatus` method
  - [ ] Integrate Firestore real-time listeners for priority updates
  - [ ] Add error handling with graceful fallbacks

- [ ] **1.2** Create `ClassificationFeedback.swift` model
  - [ ] Define `ClassificationFeedback` struct with messageId, userId, originalPriority, suggestedPriority, feedbackReason, submittedAt
  - [ ] Define `ClassificationStatus` enum with pending, classified, failed, feedbackSubmitted cases
  - [ ] Add proper initializers and validation
  - [ ] Add JSON encoding/decoding for Cloud Function communication

- [ ] **1.3** Unit Tests for Service Layer
  - [ ] Test AIClassificationService real-time listeners
  - [ ] Test feedback submission logic
  - [ ] Test retry mechanisms
  - [ ] Test error handling scenarios
  - [ ] Test offline queue functionality

### Phase 2: UI Components
- [ ] **2.1** Create `PriorityBadge.swift`
  - [ ] Design priority indicator for urgent messages
  - [ ] Add red dot or "URGENT" label styling
  - [ ] Make it reusable and configurable
  - [ ] Add accessibility labels

- [ ] **2.2** Create `ClassificationFeedbackView.swift`
  - [ ] Design feedback submission UI
  - [ ] Add "This should be urgent/normal" buttons
  - [ ] Add optional reason text field
  - [ ] Add submission confirmation
  - [ ] Handle loading and error states

- [ ] **2.3** Update `ConversationListView.swift`
  - [ ] Add priority badges to urgent messages
  - [ ] Integrate AIClassificationService via @StateObject
  - [ ] Add real-time updates when classifications complete
  - [ ] Add feedback buttons in message context menu
  - [ ] Show classification loading states
  - [ ] Handle classification failures gracefully

- [ ] **2.4** Update `ConversationListViewModel.swift`
  - [ ] Integrate AIClassificationService
  - [ ] Add real-time classification listeners
  - [ ] Handle automatic message sorting when classifications complete
  - [ ] Add feedback submission handling
  - [ ] Add retry logic for failed classifications

### Phase 3: Real-time Integration
- [ ] **3.1** Firestore Listeners Implementation
  - [ ] Set up real-time listener for message priority updates
  - [ ] Handle listener connection/disconnection
  - [ ] Add listener cleanup on view dismissal
  - [ ] Optimize listener queries for performance
  - [ ] Add error handling for listener failures

- [ ] **3.2** Cloud Function Integration
  - [ ] Create feedback submission endpoint
  - [ ] Add retry classification endpoint
  - [ ] Implement proper error responses
  - [ ] Add rate limiting for feedback submissions
  - [ ] Add logging for classification analytics

### Phase 4: Feedback System
- [ ] **4.1** Feedback Submission Flow
  - [ ] Implement feedback UI in message context menu
  - [ ] Add feedback validation (required fields, valid priorities)
  - [ ] Add offline queue for feedback submissions
  - [ ] Add feedback confirmation UI
  - [ ] Handle feedback submission errors

- [ ] **4.2** Classification Retry Logic
  - [ ] Add retry button for failed classifications
  - [ ] Implement exponential backoff for retries
  - [ ] Add retry status tracking
  - [ ] Handle retry failures gracefully
  - [ ] Add retry analytics

### Phase 5: Performance & Polish
- [ ] **5.1** Real-time Update Optimization
  - [ ] Ensure real-time updates don't block message sending/receiving
  - [ ] Optimize Firestore listener queries
  - [ ] Add throttling for rapid classification updates
  - [ ] Test with high message volume (100+ messages)
  - [ ] Profile with Instruments for performance

- [ ] **5.2** Error Handling & Edge Cases
  - [ ] Handle network connectivity issues
  - [ ] Handle classification API failures
  - [ ] Handle duplicate message classifications
  - [ ] Handle invalid message IDs
  - [ ] Handle user authentication failures

### Phase 6: Testing & Validation
- [ ] **6.1** Unit Tests
  - [ ] AIClassificationService comprehensive test coverage
  - [ ] ClassificationFeedback model tests
  - [ ] Real-time listener tests
  - [ ] Feedback submission tests

- [ ] **6.2** Integration Tests
  - [ ] End-to-end classification flow
  - [ ] Real-time update integration
  - [ ] Feedback submission integration
  - [ ] Error handling scenarios

- [ ] **6.3** UI Tests
  - [ ] Priority badge display
  - [ ] Feedback submission flow
  - [ ] Real-time classification updates
  - [ ] Error state handling
  - [ ] Accessibility testing

---

## ✅ Acceptance Gates

### Performance Gates
- [ ] **Gate 1**: New message arrives → classified within 3s → moves to correct section
- [ ] **Gate 2**: Real-time updates complete within 5s after classification
- [ ] **Gate 3**: Classification accuracy >90% with user feedback
- [ ] **Gate 4**: No blocking of message sending/receiving during classification
- [ ] **Gate 5**: No duplicate classifications for same message

### Functional Gates
- [ ] **Gate 6**: User submits feedback → sent to backend → classification updated
- [ ] **Gate 7**: Classification fails → message defaults to "normal" → retry available
- [ ] **Gate 8**: Priority badges display correctly on urgent messages
- [ ] **Gate 9**: Feedback buttons accessible in message context menu
- [ ] **Gate 10**: Offline feedback queue works when connection restored

### Quality Gates
- [ ] **Gate 11**: Real-time updates work seamlessly without UI blocking
- [ ] **Gate 12**: No blocking bugs
- [ ] **Gate 13**: All unit tests pass
- [ ] **Gate 14**: All integration tests pass
- [ ] **Gate 15**: All UI tests pass

---

## 🎨 Design Specifications

### Priority Badge States
- **Urgent Message**: Red dot or "URGENT" label
- **Normal Message**: No badge (default state)
- **Pending Classification**: Small spinner or loading indicator
- **Classification Failed**: Retry button or error indicator

### Feedback UI States
- **Available**: "This should be urgent/normal" buttons in context menu
- **Submitting**: Loading spinner with "Submitting feedback..." text
- **Submitted**: Checkmark with "Feedback submitted" confirmation
- **Error**: Retry button with error message

### Real-time Update Behavior
- **New Message**: Appears immediately, shows loading state during classification
- **Classification Complete**: Message moves to correct section, badge updates
- **Classification Failed**: Shows retry option, defaults to normal priority

---

## 🔧 Technical Requirements

### Dependencies
- PR #20 classification engine (completed)
- PR #21 Focus Mode UI (completed)
- Firestore real-time listeners
- Cloud Functions for feedback processing
- Existing Message model with priority field

### Performance Targets
- Classification updates: <3s for 95% of messages
- UI updates: <5s after classification complete
- Real-time sync: No blocking of message flow
- Feedback submission: <2s response time
- Memory: No leaks with continuous listeners

### Error Handling
- Graceful fallback to "normal" classification if API fails
- Retry mechanism for failed classifications
- Offline queue for feedback submissions
- No crashes under network pressure
- Log errors for debugging and analytics

---

## 📝 Definition of Done

- [ ] AIClassificationService implemented + unit tests
- [ ] Priority badges and feedback UI integrated
- [ ] Real-time classification updates working
- [ ] Feedback submission and processing verified
- [ ] Error handling and retry mechanisms tested
- [ ] All acceptance gates pass
- [ ] Documentation updated
- [ ] Code review completed
- [ ] Performance testing completed
- [ ] Accessibility testing completed

---

## 🚀 Rollout Strategy

- **Feature flag**: Yes - gradual rollout for real-time classification
- **Metrics**: Classification accuracy, feedback submission rate, update latency, user satisfaction
- **Manual validation**: Test with various message types, verify real-time updates
- **Deployment**: Gradual rollout after all gates pass

---

## 📊 Success Metrics

### User-Visible
- Auto-classification within 3s for 95% of messages
- Classification accuracy >90% with user feedback
- Feedback submission rate >5%
- User satisfaction with classification accuracy

### System
- Real-time updates within 5s after classification
- No blocking of message sending/receiving
- Feedback submission success rate >99%
- Classification API cost <$10/day

### Quality
- 0 blocking bugs
- All acceptance gates pass
- Comprehensive test coverage
- No memory leaks with continuous listeners

---

## 🔍 Open Questions

- Q1: Should we show classification confidence scores to users?
- Q2: How many feedback submissions should trigger a classification retry?
- Q3: Should we limit feedback to recent messages only?
- Q4: Should we add haptic feedback for classification updates?

---

## 📚 References

- [PRD: pr-22-prd.md](../prds/pr-22-prd.md)
- [PR Brief: focus-mode-pr-briefs.md](../pr-brief/focus-mode-pr-briefs.md)
- [Architecture: architecture.md](../architecture.md)
- [PR #20: Classification Engine (completed)]
- [PR #21: Focus Mode UI (completed)]

---

*Created by Pete Agent - Planning & PRD Creation*  
*Last Updated: January 2025*

