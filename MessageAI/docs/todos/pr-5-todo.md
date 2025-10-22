# PR-5 TODO — Chat View Screen & Message Display

**Branch**: `feat/pr-5-chat-view-screen`  
**Source PRD**: `MessageAI/docs/prds/pr-5-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- Questions: None - PRD is comprehensive
- Assumptions (confirm in PR if needed):
  - MessageService will be implemented in PR #6 (Real-Time Messaging)
  - ChatViewModel will handle both 1-on-1 and group chat layouts
  - Message bubbles will use standard iOS messaging design patterns
  - Performance targets are achievable with LazyVStack and pagination

---

## 1. Setup

- [ ] Create branch `feat/pr-5-chat-view-screen` from develop
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Review existing Message and Chat models from PR #4

---

## 2. Data Model & Rules

- [ ] Extend Message model with status and sender information
  - Test Gate: Model compiles and conforms to Codable
- [ ] Define MessageStatus enum with all states (sending, sent, delivered, read, failed)
  - Test Gate: Enum cases match PRD requirements
- [ ] Add senderName field for group chat support
  - Test Gate: Optional field handles both 1-on-1 and group chats
- [ ] Update Firestore schema documentation
  - Test Gate: Schema matches PRD data model examples
- [ ] Add Firebase security rules for messages sub-collection
  - Test Gate: Rules allow read access for chat members

---

## 3. Service Layer

Implement MessageService methods from PRD Section 8.

- [ ] Implement fetchMessages(chatID:limit:) method
  - Test Gate: Unit test passes for valid/invalid cases
- [ ] Implement observeMessages(chatID:completion:) method
  - Test Gate: Real-time listener works correctly
- [ ] Implement fetchMessage(messageID:) method
  - Test Gate: Single message retrieval works
- [ ] Implement markMessageAsRead(messageID:userID:) method
  - Test Gate: Read status updates correctly
- [ ] Add proper error handling for all methods
  - Test Gate: Edge cases handled correctly
- [ ] Add MessageServiceError enum with localized descriptions
  - Test Gate: Error messages are user-friendly

---

## 4. ViewModel Layer

- [ ] Create ChatViewModel with @Published properties
  - Test Gate: ObservableObject conformance works
- [ ] Implement loadMessages(chatID:) method
  - Test Gate: Messages load and display correctly
- [ ] Implement observeMessagesRealTime(chatID:) method
  - Test Gate: Real-time updates work without memory leaks
- [ ] Implement stopObserving() method
  - Test Gate: Listener cleanup prevents memory leaks
- [ ] Add markMessageAsRead(messageID:) method
  - Test Gate: Read status updates in UI
- [ ] Implement formatTimestamp(date:) method
  - Test Gate: Timestamps display in user-friendly format
- [ ] Add getMessageStatus(message:) method
  - Test Gate: Status indicators show correctly
- [ ] Add proper state management for loading/error states
  - Test Gate: All states render correctly

---

## 5. UI Components - Message Bubbles

- [ ] Create MessageBubbleView component
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Implement sent message styling (blue, right-aligned)
  - Test Gate: Sent messages appear on right side
- [ ] Implement received message styling (gray, left-aligned)
  - Test Gate: Received messages appear on left side
- [ ] Add proper text wrapping and padding
  - Test Gate: Long messages wrap correctly
- [ ] Implement rounded corners and spacing
  - Test Gate: Bubbles look like standard iOS messages
- [ ] Add status indicator integration
  - Test Gate: Status icons display correctly

---

## 6. UI Components - Message Rows

- [ ] Create MessageRowView component
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Implement group chat sender name display
  - Test Gate: Group chats show sender names above messages
- [ ] Add timestamp display with relative formatting
  - Test Gate: Timestamps show "2m ago", "Yesterday" format
- [ ] Implement message status indicators
  - Test Gate: Status shows "Sent", "Delivered", "Read"
- [ ] Add proper spacing between messages
  - Test Gate: Messages have consistent spacing
- [ ] Handle message truncation for very long text
  - Test Gate: Long messages don't break layout

---

## 7. UI Components - Chat View

- [ ] Create ChatView main screen
  - Test Gate: SwiftUI Preview renders; zero console errors
- [ ] Implement ScrollView with LazyVStack for performance
  - Test Gate: Smooth scrolling with 100+ messages
- [ ] Add navigation header with chat title
  - Test Gate: Header shows correct chat name
- [ ] Implement loading state with skeleton messages
  - Test Gate: Loading state renders correctly
- [ ] Add empty state for no messages
  - Test Gate: Empty state shows friendly message
- [ ] Implement error state with retry button
  - Test Gate: Error state allows retry
- [ ] Add scroll-to-bottom functionality
  - Test Gate: New messages scroll into view

---

## 8. Integration & Real-Time

- [ ] Firebase service integration
  - Test Gate: Auth/Firestore configured correctly
- [ ] Real-time listeners working
  - Test Gate: Data syncs across devices <100ms
- [ ] Offline persistence
  - Test Gate: App restarts work offline with cached data
- [ ] Message status updates
  - Test Gate: Status changes reflect in real-time
- [ ] Proper listener cleanup
  - Test Gate: No memory leaks from listeners

---

## 9. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/MessageServiceTests.swift`
  - Test Gate: Service logic validated, edge cases covered
  
- [ ] ViewModel Tests (Swift Testing)
  - Path: `MessageAITests/ViewModels/ChatViewModelTests.swift`
  - Test Gate: ViewModel logic tested, state changes verified
  
- [ ] UI Tests (XCTest)
  - Path: `MessageAIUITests/ChatViewUITests.swift`
  - Test Gate: User flows succeed, navigation works
  
- [ ] Message Display Tests (Swift Testing)
  - Path: `MessageAITests/Views/MessageRowViewTests.swift`
  - Test Gate: Message layout and styling verified
  
- [ ] Multi-device sync test
  - Test Gate: Use pattern from shared-standards.md
  
- [ ] Visual states verification
  - Test Gate: Empty, loading, error, success render correctly

---

## 10. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] App load time < 2-3 seconds
  - Test Gate: Cold start to interactive measured
- [ ] Message display latency < 100ms
  - Test Gate: Message rendering measured
- [ ] Smooth 60fps scrolling (200+ messages)
  - Test Gate: Use LazyVStack, verify with instruments
- [ ] Memory usage < 50MB for 500 messages
  - Test Gate: Memory profiling shows acceptable usage
- [ ] No memory leaks from listeners
  - Test Gate: Memory profiling shows no leaks

---

## 11. Acceptance Gates

Check every gate from PRD Section 11 (Test Plan & Acceptance Gates):
- [ ] Messages display in correct order
- [ ] Sent messages show on right, received on left
- [ ] Timestamps display correctly
- [ ] Status indicators show appropriate states
- [ ] Smooth scrolling through message history
- [ ] Empty conversation shows empty state
- [ ] Long messages wrap properly
- [ ] Very long conversations scroll smoothly
- [ ] Network errors show retry option
- [ ] Invalid message data handled gracefully
- [ ] Group chat shows sender names
- [ ] Message status updates correctly
- [ ] Real-time updates don't cause UI flicker
- [ ] Concurrent message updates handled
- [ ] Memory usage stays under 50MB
- [ ] Message loading completes in < 100ms
- [ ] No memory leaks from listeners

---

## 12. Documentation & PR

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
- [ ] MessageService implemented + unit tests (Swift Testing)
- [ ] ChatViewModel implemented with state management
- [ ] SwiftUI views implemented with all states
- [ ] Message bubble layout working correctly
- [ ] Timestamp formatting implemented
- [ ] Status indicators functional
- [ ] UI tests pass (XCTest)
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
- Focus on message display and layout - messaging functionality comes in PR #6
