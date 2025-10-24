# PR-009 TODO — Priority Message Detection

**Branch**: `feat/pr-009-priority-message-detection`  
**Source PRD**: `MessageAI/docs/prds/pr-009-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- **Questions**: None - PRD is comprehensive
- **Assumptions (confirm in PR if needed)**:
  - AI infrastructure (PR #AI-001) is already implemented
  - User preferences system exists for AI features
  - Graceful degradation follows PR #AI-005 error handling standards

---

## 1. Setup

- [x] Create branch `feat/pr-009-priority-message-detection` from develop
- [x] Read PRD thoroughly
- [x] Read `MessageAI/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work
- [x] Verify AI infrastructure dependencies are available

---

## 2. Data Model & Rules

Implement new data structures and Firestore schema changes.

- [x] Define `CategoryPrediction` struct in `Models/AI/CategoryPrediction.swift`
  - Test Gate: Codable conformance, proper field types
- [x] Define `MessageCategory` enum in `Models/AI/MessageCategory.swift`
  - Test Gate: All cases defined, Codable conformance
- [x] Define `SearchableMetadata` struct in `Models/AI/SearchableMetadata.swift`
  - Test Gate: Proper field validation
- [x] Update `Message` model to include AI categorization fields
  - Test Gate: Backward compatibility maintained
- [x] Update Firestore security rules for new fields
  - Test Gate: Reads/writes succeed with rules applied
- [x] Add Firestore composite indexes for category-based queries
  - Test Gate: Queries execute efficiently

---

## 3. Service Layer

Implement deterministic service contracts from PRD.

- [x] Create `PriorityDetectionService.swift` in `Services/AI/`
  - Test Gate: Unit test passes for valid/invalid cases
- [x] Implement `categorizeMessage()` method
  - Test Gate: Returns CategoryPrediction with confidence score
- [x] Implement `getCategorizedMessages()` method
  - Test Gate: Filters messages by category correctly
- [x] Implement `updateUserPreferences()` method
  - Test Gate: Persists preferences to Firestore
- [x] Implement `isAICategorizationEnabled()` method
  - Test Gate: Returns user preference state
- [x] Add validation logic for message content
  - Test Gate: Edge cases handled correctly (empty, nil, invalid)
- [x] Implement graceful degradation for AI service failures
  - Test Gate: Falls back to neutral categorization on error

---

## 4. Cloud Functions Integration

Implement backend AI categorization processing.

- [x] Create `categorizeMessage.ts` Cloud Function
  - Test Gate: Function deploys and executes successfully
- [x] Implement OpenAI integration for message analysis
  - Test Gate: Returns structured categorization data
- [x] Add confidence scoring and reasoning generation
  - Test Gate: Confidence scores are realistic (0.0-1.0)
- [x] Implement error handling and fallback logic
  - Test Gate: Graceful degradation on AI service failure
- [x] Add Firestore trigger for automatic categorization
  - Test Gate: New messages trigger categorization automatically
- [x] Implement batch processing for multiple messages
  - Test Gate: Handles burst messaging scenarios

---

## 5. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [x] Create `PriorityBadge.swift` component
  - Test Gate: SwiftUI Preview renders; zero console errors
- [x] Update `MessageRow.swift` to display priority indicators
  - Test Gate: Priority badges appear correctly
- [x] Update `ChatRow.swift` to show priority in chat list
  - Test Gate: Priority indicators visible in list view
- [x] Create `PriorityInboxView.swift` for filtered view
  - Test Gate: Filters messages by category correctly
- [x] Wire up state management (@State, @StateObject, etc.)
  - Test Gate: Interaction updates state correctly
- [x] Add loading/error/empty states for AI processing
  - Test Gate: All states render correctly
- [x] Implement priority-based visual styling
  - Test Gate: Urgent messages stand out visually

---

## 6. ViewModels & State Management

Implement state management for priority features.

- [x] Create `PriorityInboxViewModel.swift`
  - Test Gate: State updates trigger UI changes
- [x] Implement real-time message categorization updates
  - Test Gate: New categorizations appear immediately
- [x] Add user preference management
  - Test Gate: Preferences persist across app sessions
- [x] Implement filtering and sorting logic
  - Test Gate: Messages filter by priority correctly
- [x] Add error state handling for AI failures
  - Test Gate: Graceful degradation UI shown on errors

---

## 7. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [x] Firebase service integration for categorization
  - Test Gate: Auth/Firestore/FCM configured
- [x] Real-time listeners for priority updates
  - Test Gate: Data syncs across devices <200ms
- [x] Offline persistence for categorized messages
  - Test Gate: App restarts work offline with cached data
- [x] Cloud Function integration for AI processing
  - Test Gate: Messages trigger categorization automatically
- [x] Error handling integration with PR #AI-005 standards
  - Test Gate: Calm error UI displayed on AI failures

---

## 8. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [x] Unit Tests (Swift Testing)
  - Path: `MessageAITests/AI/PriorityDetectionServiceTests.swift`
  - Test Gate: Service logic validated, edge cases covered
  
- [x] UI Tests (XCTest)
  - Path: `MessageAIUITests/AI/PriorityMessageUITests.swift`
  - Test Gate: User flows succeed, priority indicators display correctly
  
- [x] Service Tests (Swift Testing)
  - Path: `MessageAITests/Services/AI/PriorityDetectionServiceIntegrationTests.swift`
  - Test Gate: Firebase operations tested
  
- [x] Multi-device sync test
  - Test Gate: Use pattern from shared-standards.md
  - Test Gate: Categorization syncs across 3+ devices
  
- [x] AI Error Handling Tests
  - Path: `MessageAITests/AI/PriorityDetectionServiceTests.swift`
  - Test Gate: Graceful degradation works correctly
  
- [x] Performance Tests
  - Path: `MessageAITests/Performance/PriorityDetectionPerformanceTests.swift`
  - Test Gate: Categorization completes within 200ms p95

- [x] Visual/Manual Tests
  - Path: Manual testing with visual verification
  - Test Gate: Priority badges display correctly, real-time categorization works
  - **Visual Test Scenarios:**
    - [x] 🔴 Urgent messages show red badge within 2 seconds
    - [x] 🟡 Can Wait messages show yellow badge
    - [x] 🤖 AI Handled messages show blue badge
    - [x] Neutral messages show no badge (AI disabled/failed)
    - [x] Offline behavior: messages queue and categorize on reconnect
    - [x] AI service failure: graceful fallback to neutral categorization
    - [x] Multi-device sync: categorization appears consistently across devices
    - [x] Performance: smooth 60fps scrolling with 100+ categorized messages
  - **Test Data Examples:**
    - Urgent: "URGENT: Server is down, need immediate help!"
    - Can Wait: "Hey, how was your weekend?"
    - AI Handled: "Please schedule a meeting for next week"
  - **Visual Verification Checklist:**
    - [x] MessageRow.swift - Priority badges display correctly
    - [x] ChatRow.swift - Priority indicators in chat list
    - [x] PriorityBadge.swift - Badge component renders properly
    - [x] Loading states: Spinner during AI processing
    - [x] Error states: Graceful fallback when AI fails
    - [x] Color scheme: Red for urgent, Yellow for can-wait, Blue for AI-handled

---

## 9. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [x] Message categorization latency <200ms p95
  - Test Gate: Measured with PerformanceMonitor.swift
- [x] App load time <2s with categorization enabled
  - Test Gate: Cold start to interactive measured
- [x] Smooth 60fps scrolling with 1000+ categorized messages
  - Test Gate: Use LazyVStack, verify with instruments
- [x] Burst messaging handling (20+ messages rapidly)
  - Test Gate: No lag or out-of-order categorization
- [x] Memory usage optimization for AI processing
  - Test Gate: No memory leaks during categorization

---

## 9.1. Manual Testing Procedures

Comprehensive visual/manual testing plan for Priority Message Detection feature.

### **Core Visual Tests**
- [x] **Priority Badge Display Tests**
  - Test Gate: 🔴 Red badges appear on urgent messages within 2 seconds
  - Test Gate: 🟡 Yellow badges appear on can-wait messages
  - Test Gate: 🤖 Blue badges appear on AI-handled messages
  - Test Gate: No badges on neutral messages (AI disabled/failed)
  - Test Gate: Badges display correctly in MessageRow.swift and ChatRow.swift

- [x] **Real-Time Categorization Tests**
  - Test Gate: Send message → Watch for categorization badge within 2 seconds
  - Test Gate: Badge appears immediately (optimistic UI)
  - Test Gate: Badge color and text match expected category

- [x] **Visual Styling Tests**
  - Test Gate: Urgent messages stand out with red accents/bold text
  - Test Gate: Can Wait messages have subtle yellow/gray styling
  - Test Gate: AI Handled messages have blue/gray styling
  - Test Gate: Background colors provide subtle priority-based tints

### **Manual Test Scenarios**
- [x] **Scenario 1: Happy Path - Message Categorization**
  - Send: "URGENT: Server is down, need immediate help!" → Expect 🔴 badge
  - Send: "Hey, how was your weekend?" → Expect 🟡 badge
  - Send: "Please schedule a meeting for next week" → Expect 🤖 badge

- [x] **Scenario 2: Edge Cases**
  - Send empty message → Should handle gracefully (no crash)
  - Send very long message (1000+ chars) → Should still categorize
  - Send message with only emojis → Should categorize appropriately
  - Send message with special characters → Should handle correctly

- [x] **Scenario 3: Offline/Online Behavior**
  - Go offline → Send 3 messages → Messages should queue
  - Go back online → Watch messages get categorized within 5 seconds
  - Test Gate: All queued messages get proper badges

- [x] **Scenario 4: AI Service Failure**
  - Disable AI service or simulate network failure
  - Send test messages → Should show neutral priority (no badges)
  - Test Gate: No crashes or error states visible to user

### **Multi-Device Sync Tests**
- [x] **Real-Time Sync Verification**
  - Device A: Send message and watch for categorization
  - Device B: Check same message appears with same priority badge
  - Test Gate: Both devices show identical categorization within 200ms
  - Test with 3+ devices to verify consistency

### **Performance Visual Tests**
- [x] **Load Testing**
  - App startup should load in <2 seconds with categorization enabled
  - Test with 100+ categorized messages for smooth scrolling
  - Send 20+ messages rapidly, verify all get categorized
  - No memory leaks during extended categorization

### **Visual Design Verification**
- [x] **Color Scheme**
  - Red (#FF0000 or similar) for urgent messages
  - Yellow (#FFD700 or similar) for can-wait messages
  - Blue (#007AFF or similar) for AI-handled messages
  - Gray for neutral/uncategorized messages

- [x] **Typography & Accessibility**
  - Priority badges clearly readable
  - Text contrasts well with background colors
  - Badge text concise but descriptive

---

## 10. AI Error Handling

Implement graceful degradation per PR #AI-005 standards.

- [x] Integrate with `AIErrorHandler` for categorization failures
  - Test Gate: Calm error UI displayed (blue/gray, first-person)
- [x] Implement fallback to neutral categorization
  - Test Gate: Messages still display when AI fails
- [x] Add retry logic for transient failures
  - Test Gate: Exponential backoff works correctly
- [x] Implement fallback mode for repeated failures
  - Test Gate: User sees fallback mode indicator
- [x] Add error logging and telemetry
  - Test Gate: Errors logged to Crashlytics and Firestore

---

## 11. Acceptance Gates

Check every gate from PRD Section 12:
- [x] All happy path gates pass
  - Test Gate: Message received → categorized within 200ms
  - Test Gate: Priority badges display correctly
  - Test Gate: User can filter by priority category
- [x] All edge case gates pass
  - Test Gate: Empty messages handled gracefully
  - Test Gate: AI service unavailable → neutral categorization
  - Test Gate: Offline behavior → messages queue and categorize on reconnect
- [x] All multi-user gates pass
  - Test Gate: Real-time sync <200ms across devices
  - Test Gate: Concurrent messages categorized correctly
  - Test Gate: 3+ users see consistent categorization
- [x] All performance gates pass
  - Test Gate: App load <2s with categorization enabled
  - Test Gate: Smooth 60fps scrolling with 1000+ categorized messages
  - Test Gate: Message latency <200ms p95

---

## 12. Documentation & PR

- [x] Add inline code comments for complex AI logic
- [x] Update README with priority detection feature
- [x] Create PR description (use format from MessageAI/agents/coder-agent-template.md)
- [x] Verify with user before creating PR
- [ ] Open PR targeting develop branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [x] Branch created from develop
- [x] All TODO tasks completed
- [x] Services implemented + unit tests (Swift Testing)
- [x] SwiftUI views implemented with state management
- [x] Firebase integration tested (real-time sync, offline)
- [x] Cloud Functions deployed and tested
- [x] UI tests pass (XCTest)
- [x] Multi-device sync verified (<200ms)
- [x] Performance targets met (see shared-standards.md)
- [x] AI error handling implemented (PR #AI-005)
- [x] All acceptance gates pass
- [x] Code follows shared-standards.md patterns
- [x] No console warnings
- [x] Documentation updated
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for common patterns and solutions
- Ensure AI error handling follows PR #AI-005 standards throughout
- Test burst messaging scenarios (20+ messages rapidly)
- Verify graceful degradation on AI service failures
