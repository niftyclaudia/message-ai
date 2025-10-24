# Testing Strategy

**Last Updated**: October 24, 2025

**Philosophy:** User-centric manual validation for speed and quality. Ship features fast with pragmatic testing.

---

## Current Approach: Manual Flow Testing

Each PR ends with testing **3 critical scenarios:**

### 1. Happy Path (Required)
**What:** Main user flow from start to finish  
**Why:** Validates the feature works as intended for the primary use case

**Example (Message Send):**
1. User opens chat
2. Types message "Hello World"
3. Taps send button
4. Message appears in chat bubble
5. Other device receives message (if real-time feature)

**Pass Criteria:** 
- Flow completes without errors
- User sees expected outcome
- No console errors or warnings

---

### 2. Edge Cases (1-2 Required)
**What:** Non-standard inputs or conditions  
**Why:** Ensures feature degrades gracefully under unusual circumstances

**Common Edge Cases to Test:**
- **Empty input:** Send blank message → Shows "Message cannot be empty"
- **Long input:** 500+ character message → Handles without crash
- **Special characters:** Emojis, symbols, Unicode → Displays correctly
- **Rapid actions:** Spam send button 10x → Queues properly, no duplicates
- **Concurrent users:** 2 users act simultaneously → Both actions succeed
- **Boundary conditions:** Max group size, character limits → Enforced gracefully

**Pass Criteria:** 
- App doesn't crash
- Shows appropriate feedback to user
- Data remains consistent

---

### 3. Error Handling (Required)
**What:** How the feature behaves when things fail  
**Why:** Users must understand what went wrong and how to recover

**Common Error Scenarios:**

**Offline Mode:**
- Enable airplane mode
- Attempt action (send message, update profile)
- **Expected:** "No internet connection" message, action queues for retry

**Network Timeout:**
- Simulate slow network (or wait for natural timeout)
- **Expected:** Loading state → "Taking longer than expected" → retry option

**Invalid Data:**
- Submit empty required field
- Enter malformed email/phone
- **Expected:** Validation error inline, clear instruction to fix

**Permission Denied:**
- Attempt action user doesn't have rights for
- **Expected:** "You don't have permission to do this" message

**Pass Criteria:** 
- Clear, actionable error message shown
- User can retry or take alternative action
- No data corruption or partial writes
- App remains functional after error

---

## Testing Checklist (Copy to Each TODO)

**Before marking PR complete:**

- [ ] **Happy Path:** Main user flow works end-to-end without errors
- [ ] **Edge Case 1:** [Document specific scenario] handled gracefully
- [ ] **Edge Case 2:** [Document specific scenario] handled gracefully (optional but recommended)
- [ ] **Error Handling:** 
  - Offline mode shows clear message (test: airplane mode)
  - Invalid input shows validation error
  - Timeout shows retry option (if long-running operation)
- [ ] **No Console Errors:** Clean console during all test scenarios
- [ ] **Performance Check:** Feature feels responsive (subjective, no noticeable lag)
- [ ] **Threading Safety:** UI updates on main thread, heavy operations on background threads

---

## Optional Testing (When Applicable)

### Multi-Device Testing
**When Required:** Real-time sync features (messaging, presence, typing indicators, read receipts)

**How to Test:**
1. Open app on Device 1 (iPhone or Simulator)
2. Open app on Device 2 (different device or simulator)
3. Perform action on Device 1 (send message, update status)
4. **Verify:** Change appears on Device 2 within ~500ms
5. Repeat in reverse (Device 2 → Device 1)

**Pass Criteria:** Sync happens quickly, no data loss

---

### Performance Testing
**When Required:** Lists with 50+ items, heavy animations, image loading

**How to Test:**
- **Scrolling:** Scroll through long list, verify smooth 60fps (no jank)
- **Loading:** Measure time from tap to screen display
- **Memory:** Check for leaks with large datasets

**Pass Criteria:** 
- Smooth scrolling (subjective)
- Fast load times (< 2-3 seconds)
- No memory warnings

---

## Testing Examples by Feature Type

### Messaging Features
**Happy Path:** Open chat → Type → Send → Message appears  
**Edge Case 1:** Send empty message → Blocked with error  
**Edge Case 2:** Send 1000-char message → Accepted or truncated with warning  
**Error:** Airplane mode → Queues message, sends on reconnect

---

### Profile Features
**Happy Path:** Tap Edit → Change name → Save → Name updates  
**Edge Case 1:** Save without changes → No API call, instant success  
**Edge Case 2:** Invalid email format → Validation error inline  
**Error:** Offline → "Can't update profile offline"

---

### List/Search Features
**Happy Path:** Open list → See items → Tap item → Detail loads  
**Edge Case 1:** Empty list → "No items yet" empty state  
**Edge Case 2:** Search no results → "No matches found"  
**Error:** Load fails → "Couldn't load items" with retry button

---

### Presence & Real-Time Features
**Happy Path:** User comes online → Presence indicator updates → Other users see status  
**Edge Case 1:** Rapid online/offline transitions → Debounced updates prevent flicker  
**Edge Case 2:** Network timeout → Graceful fallback to "last seen"  
**Error:** Firebase connection lost → Shows stale status with indicator

---

## Future: Automated Testing (Phase 6+)

**When to Add:** After MVP ships and revenue validates product direction

**Priorities:**
1. **Unit Tests:** Service layer business logic (high ROI)
2. **Integration Tests:** Critical user flows (signup, send message)
3. **UI Tests:** Smoke tests for major screens

**See below for AI feature integration test templates when Phase 6 begins.**

### 1. Unit Testing Framework

**Recommended Framework**: Swift Testing (Modern)
- **Path**: `MessageAITests/{Feature}Tests.swift`
- **Syntax**: `@Test("Display Name")` with `#expect`
- **Benefits**: Readable test names, modern async/await support

**What to Test:**
- Service layer business logic
- Data model validation
- Error handling and edge cases
- Firebase operations (with emulator)
- Authentication flows
- Message processing logic
- AI response generation
- Context management

**Example Structure:**
```swift
import Testing
@testable import MessageAI

@Suite("Message Service Tests")
struct MessageServiceTests {
    
    @Test("Send Message With Valid Data Creates Message")
    func sendMessageWithValidDataCreatesMessage() async throws {
        // Given
        let service = MessageService()
        let testMessage = "Hello World"
        let testChatID = "test-chat"
        
        // When
        let messageID = try await service.sendMessage(
            chatID: testChatID,
            text: testMessage
        )
        
        // Then
        #expect(messageID != nil)
    }
}
```

### 2. Integration Testing

**Recommended Framework**: XCTest + Firebase Emulator
- **Path**: `MessageAITests/Integration/{Feature}IntegrationTests.swift`
- **Purpose**: Test Firebase integrations, multi-service workflows
- **Setup**: Firebase emulator suite for isolated testing

**What to Test:**
- Auth + Firestore integration flows
- End-to-end user journeys
- Multi-device sync scenarios
- Offline/online state transitions
- Security rules validation
- Performance benchmarks
- AI feature integrations

**Example Structure:**
```swift
import XCTest
@testable import MessageAI

class AuthFirestoreIntegrationTests: XCTestCase {
    
    func testSignupCreatesBothAuthAndFirestoreUser() async throws {
        // Given: Clean state
        // When: User signs up
        // Then: Both Firebase Auth and Firestore user created
        // And: UIDs match between services
    }
}
```

### 3. UI Testing

**Recommended Framework**: XCTest (XCUITest)
- **Path**: `MessageAIUITests/{Feature}UITests.swift`
- **Purpose**: Automated user interaction testing
- **Benefits**: Full app lifecycle testing, accessibility validation

**What to Test:**
- Complete user flows (login → chat → logout)
- Navigation between screens
- Form interactions and validation
- Accessibility compliance
- Visual regression (screenshots)
- Performance under load

**Example Structure:**
```swift
import XCTest

class ChatFlowUITests: XCTestCase {
    var app: XCUIApplication!
    
    func testCompleteChatFlow() throws {
        // Login
        app.buttons["loginButton"].tap()
        app.textFields["emailField"].typeText("test@example.com")
        app.secureTextFields["passwordField"].typeText("password")
        app.buttons["submitButton"].tap()
        
        // Send message
        app.textFields["messageInput"].typeText("Hello World")
        app.buttons["sendButton"].tap()
        
        // Verify message appears
        XCTAssertTrue(app.staticTexts["Hello World"].exists)
    }
}
```

### 4. Multi-Device Testing

**Recommended Approach**: Firebase Test Lab + Custom Framework
- **Purpose**: Test real-time sync across multiple devices
- **Setup**: Automated device orchestration
- **Coverage**: 2-5 devices, different OS versions

**What to Test:**
- Real-time message sync (< 500ms)
- Concurrent user actions
- Offline queue synchronization
- Presence indicators
- Conflict resolution
- Typing indicators

### 5. Performance Testing

**Recommended Tools**: XCTest + Instruments
- **Purpose**: Validate performance targets
- **Metrics**: Load times, memory usage, CPU usage, network efficiency

**What to Test:**
- App launch time (< 2-3 seconds)
- Message delivery latency (< 500ms)
- Scrolling performance (60fps with 100+ messages)
- Memory usage under load
- Battery efficiency
- Network optimization

---

## Testing Implementation Roadmap

### Phase 1: Foundation (Current - PR #1-20)
- ✅ Manual testing validation
- ✅ Performance monitoring
- ✅ Multi-device manual testing
- ✅ Thread safety validation

### Phase 2: Unit Testing (PR #21-30)
- [ ] Service layer unit tests
- [ ] Data model validation tests
- [ ] Error handling tests
- [ ] Firebase emulator setup
- [ ] AI service unit tests

### Phase 3: Integration Testing (PR #31-35)
- [ ] Auth + Firestore integration tests
- [ ] End-to-end user flow tests
- [ ] Multi-device sync tests
- [ ] Security rules validation
- [ ] AI conversation flow tests

### Phase 4: Comprehensive Testing (PR #36-40)
- [ ] Full UI test suite
- [ ] Performance benchmarking
- [ ] Accessibility testing
- [ ] Visual regression testing
- [ ] Load testing

---

## Testing Best Practices

### Test Organization
```
MessageAITests/
├── Unit/
│   ├── Services/
│   ├── Models/
│   ├── ViewModels/
│   └── Utilities/
├── Integration/
│   ├── Auth/
│   ├── Firestore/
│   ├── AIFeatures/
│   └── MultiDevice/
└── Performance/

MessageAIUITests/
├── Flows/
├── Components/
└── Accessibility/
```

### Test Data Management
- Use Firebase emulator for isolated testing
- Implement test data factories
- Clean up test data after each test
- Use unique identifiers to avoid conflicts

### Continuous Integration
- Run unit tests on every commit
- Run integration tests on pull requests
- Run full test suite before deployment
- Performance regression detection

---

## Testing Tools & Setup

### Required Tools
- **Xcode**: Native testing frameworks
- **Firebase Emulator**: Local Firebase testing
- **Firebase Test Lab**: Multi-device testing
- **Instruments**: Performance profiling
- **Accessibility Inspector**: Accessibility testing

### Test Environment Setup
```bash
# Install Firebase emulator
npm install -g firebase-tools
firebase init emulators

# Configure emulators
firebase emulators:start --only firestore,auth
```

### CI/CD Integration
- GitHub Actions for automated testing
- Firebase Test Lab integration
- Performance regression detection
- Automated deployment gates

---

## Testing Metrics & Success Criteria

### Quality Gates
- [ ] All unit tests pass
- [ ] All integration tests pass
- [ ] All UI tests pass
- [ ] Performance targets met
- [ ] No critical bugs in production
- [ ] 99%+ uptime

### Performance Targets
- App launch: < 2-3 seconds
- Message delivery: < 500ms
- UI responsiveness: < 50ms
- Memory usage: < 100MB baseline
- Battery efficiency: < 5% per hour
- Presence updates: < 500ms

### Coverage Requirements
- Unit test coverage: 80%+
- Integration test coverage: 100% critical paths
- UI test coverage: 100% main flows
- Performance test coverage: All targets validated

---

## Migration Strategy

### From Manual to Automated Testing

**Phase 1**: Continue manual testing, document patterns  
**Phase 2**: Implement unit tests for new features  
**Phase 3**: Add integration tests for critical flows  
**Phase 4**: Full automated test suite

**Key Principles:**
- Don't break existing manual testing
- Add automated tests incrementally
- Maintain test quality over quantity
- Focus on high-value test cases first

---

## AI Feature Integration Tests (Phase 6+)

When AI features are implemented, use these happy path demos as integration test templates.

### Happy Path 1: AI-Suggested Reply Generation
**Tests:** AI Service Integration, Context Management, User Preferences, Threading

**Setup:**
- User has AI suggestions enabled in preferences
- Recent conversation context available
- OpenAI API credentials configured

**Flow:**
1. User receives message: "Are you free for coffee tomorrow at 2pm?"
2. **VERIFY:** AI service called on background thread
3. **VERIFY:** Context includes recent messages for personalization
4. **VERIFY:** 3 suggested replies generated within 2 seconds:
   - "Yes! 2pm works for me 😊"
   - "I'm free! Where should we meet?"
   - "Can we do 3pm instead? I have a conflict at 2"
5. User taps suggestion
6. **VERIFY:** Message sent with selected reply
7. **VERIFY:** UI updates on main thread without lag

**Expected Result:** AI generates contextually relevant suggestions quickly

**Success Criteria:**
- AI response time < 2 seconds
- Suggestions are contextually appropriate
- All network calls on background threads
- UI updates on main thread only
- No threading violations or crashes
- Graceful fallback if AI service unavailable

---

### Happy Path 2: Smart Context Awareness
**Tests:** Conversation History, Context Window Management, Memory/State

**Setup:**
- Active conversation with 50+ messages
- User preferences include tone and style settings
- Context window limit: last 20 messages

**Flow:**
1. User asks AI: "Summarize our conversation"
2. **VERIFY:** AI retrieves last 20 messages (context window)
3. **VERIFY:** Older messages properly truncated
4. **VERIFY:** Summary generated respects user tone preferences
5. **VERIFY:** Summary appears in chat within 3 seconds
6. User follows up: "What did we decide about the meeting?"
7. **VERIFY:** AI maintains conversation state across turns
8. **VERIFY:** AI references specific decision from context

**Expected Result:** AI maintains context and provides relevant summaries

**Success Criteria:**
- Context window properly managed (memory efficient)
- Multi-turn conversation state maintained
- Summary accuracy reflects actual conversation
- Response time < 3 seconds
- User preferences respected (tone, style)
- No data leakage across different conversations

---

### Happy Path 3: Intelligent Message Enhancement
**Tests:** AI Text Processing, User Control, Undo/Redo

**Setup:**
- User has AI enhancement features enabled
- User preferences for enhancement level (casual/professional)

**Flow:**
1. User types: "hey can u send me that doc we talked about"
2. User taps "Enhance with AI" button
3. **VERIFY:** AI processes on background thread
4. **VERIFY:** Enhanced version shown within 1 second:
   - "Hi! Could you please send me the document we discussed?"
5. User reviews enhanced text
6. **VERIFY:** "Undo" and "Accept" buttons visible
7. User taps "Accept"
8. **VERIFY:** Enhanced message sent
9. **VERIFY:** Original text preserved in local history

**Expected Result:** AI enhances text while preserving user control

**Success Criteria:**
- Enhancement respects user preferences
- Processing time < 1 second
- User can undo/redo changes
- Original text never lost
- Clear visual feedback during processing
- Graceful failure if AI unavailable

---

### Happy Path 4: Presence & Activity Awareness
**Tests:** Real-Time Presence, AI Context Integration, Multi-Device Sync

**Setup:**
- Multiple users online
- Presence indicators enabled
- AI features aware of user availability

**Flow:**
1. User A comes online
2. **VERIFY:** Presence indicator updates across all devices < 500ms
3. User B drafts message to User A: "Are you available?"
4. **VERIFY:** AI detects User A is actively online
5. **VERIFY:** AI suggests: "They're online now - they'll likely respond quickly"
6. User A goes offline mid-conversation
7. **VERIFY:** Presence changes to "last seen X minutes ago"
8. **VERIFY:** AI adjusts expectations: "They're offline - expect delayed response"

**Expected Result:** AI integrates real-time presence into suggestions

**Success Criteria:**
- Presence updates < 500ms across devices
- AI suggestions reflect current availability
- Multi-device sync maintains consistency
- No flickering or race conditions
- Graceful handling of network issues
- Battery-efficient presence tracking

---

### Happy Path 5: Auto-Reply Mode (Smart Away)
**Tests:** User Preferences, Function Calling, Memory/State, Error Handling, Scheduled Automation

**Setup:**
- User has Auto-Reply Mode enabled for specific hours (11pm-7am on weekdays)
- User preferences stored in Firestore:
  - Response style: "casual and friendly"
  - Common away messages: "I'm sleeping, will reply in the morning!"
  - Important contacts: Mom, Best Friend (always notify immediately)
  - Auto-reply rules: Enable during set hours or manual activation

**Flow:**
1. Friend Sarah DMs at 11:30pm: "Hey! Are you up? Quick question about tomorrow"
2. **VERIFY:** AI detects Auto-Reply Mode is active for current time
3. **VERIFY:** AI analyzes message urgency (low urgency - casual "hey")
4. **VERIFY:** AI responds within 5 seconds: "Hey! I'm sleeping right now but I'll get back to you in the morning 😊"
5. **VERIFY:** Original message queued for user review
6. **VERIFY:** User sees notification next morning with AI's response shown
7. Sarah replies: "No worries! Talk tomorrow"
8. **VERIFY:** Follow-up also auto-replied appropriately
9. User wakes up at 7:05am (Auto-Reply Mode ends)
10. **VERIFY:** User sees conversation summary: "Sarah messaged while you were away. AI responded 2 times."
11. User reviews and sends manual follow-up

**Edge Case - Important Contact:**
1. Mom DMs at 11:45pm: "Call me when you can"
2. **VERIFY:** AI detects "Mom" is in important contacts list
3. **VERIFY:** Push notification sent immediately despite Auto-Reply Mode
4. **VERIFY:** No auto-reply sent (user should respond personally)

**Expected Result:** AI handles routine messages during away hours, preserves important contacts for personal response

**Success Criteria:**
- AI response time < 5 seconds
- Response tone matches user preferences exactly
- Important contacts bypass auto-reply system
- Multi-turn conversation state maintained across messages
- User notification triggered when Auto-Reply Mode ends
- All AI responses persisted in Firestore with metadata flag
- User maintains full control (can disable mid-session)
- Graceful handling if AI service unavailable (fails silently, no auto-reply sent)

---

### Happy Path 6: Conversation Memory & Context Recall
**Tests:** RAG Pipeline, Message History, Memory/State, Function Calling, User Preferences

**Setup:**
- Active conversation with friend Alex spanning 3 months
- Alex previously mentioned: "I'm moving to Austin next month" (2 weeks ago)
- Vector embeddings generated for all past messages
- Context window: Last 50 messages per conversation
- Semantic search enabled for conversation history

**Flow:**
1. Alex messages today: "Finally done packing! So exhausted 📦"
2. User opens chat, wants to reply
3. User taps "AI Suggest Replies" button
4. **VERIFY:** AI retrieves conversation history (background thread)
5. **VERIFY:** RAG searches past messages for context about "moving" and "Austin"
6. **VERIFY:** Semantic search returns messages with similarity score > 0.7:
   - "I'm moving to Austin next month" (14 days ago)
   - "So nervous about the move" (10 days ago)
   - "Found an apartment finally!" (5 days ago)
7. **VERIFY:** AI generates 3 contextually aware suggestions within 2 seconds:
   - "Almost there! When's the big move to Austin? 🚚"
   - "You've got this! Austin's gonna be amazing"
   - "Need any help with the move?"
8. User taps first suggestion
9. **VERIFY:** Message sent with full context awareness
10. Alex replies: "Tomorrow! Can't believe you remembered all this 😊"

**Follow-Up Test - User Asks AI for Context:**
1. Later, user receives message from Alex: "Made it to Austin!"
2. User thinks: "What did Alex say about their new place?"
3. User types in AI chat interface: "What did Alex say about their apartment?"
4. **VERIFY:** RAG searches Alex conversation history
5. **VERIFY:** AI surfaces: "Alex mentioned finding an apartment 5 days ago. They seemed excited about it."
6. **VERIFY:** AI provides relevant message snippets with timestamps
7. User now has context to craft meaningful reply

**Expected Result:** Semantic search finds relevant context, AI personalizes responses, user feels more connected

**Success Criteria:**
- Semantic search returns messages about "moving" and "Austin" accurately
- Similarity score > 0.7 for relevant messages
- AI suggestions include personalized details from past conversations
- Context retrieval happens on background thread
- UI updates on main thread without lag
- User maintains control (can edit suggestions before sending)
- Conversation feels natural and connected
- No performance degradation with large message history (1000+ messages)
- Privacy maintained (only searches within specific conversation)
- Graceful degradation if RAG service unavailable (generic suggestions shown)

---

### Happy Path 7: Error Handling & Graceful Degradation
**Tests:** Offline Mode, API Failures, User Feedback

**Setup:**
- AI features enabled
- Simulate various failure scenarios

**Flow:**
1. **Scenario A: Offline Mode**
   - User enables airplane mode
   - User taps "AI Suggest Replies"
   - **VERIFY:** Clear message: "AI features require internet connection"
   - **VERIFY:** User can still send messages manually
   
2. **Scenario B: API Timeout**
   - Simulate slow/hanging API request
   - **VERIFY:** Loading indicator shows
   - **VERIFY:** After 5 seconds: "AI taking longer than expected"
   - **VERIFY:** "Cancel" button available
   
3. **Scenario C: API Error**
   - Simulate 500 error from AI service
   - **VERIFY:** User-friendly error: "AI temporarily unavailable"
   - **VERIFY:** "Try Again" button visible
   - **VERIFY:** App remains functional
   
4. **Scenario D: Rate Limiting**
   - Simulate rate limit exceeded
   - **VERIFY:** Message: "You've used your AI quota. Resets in X hours"
   - **VERIFY:** Manual messaging still works

**Expected Result:** All AI failures degrade gracefully with clear feedback

**Success Criteria:**
- No crashes on any failure scenario
- Clear, actionable error messages
- User can always send messages manually
- Retry mechanisms work correctly
- State remains consistent after errors
- Errors logged for debugging

---

## Thread Safety Testing for AI Features

### Critical Threading Rules
Per project standards, all AI features must follow:

**Background Threads (Required):**
- All OpenAI API calls
- Context processing and embedding generation
- Message history retrieval and processing
- Heavy computation (summarization, enhancement)

**Main Thread (Required):**
- All UI updates (suggestions, loading states)
- Presenting/dismissing AI UI components
- Updating message bubbles with AI content
- Any SwiftUI state changes

### Threading Test Checklist
- [ ] Network calls execute on `.userInitiated` queue
- [ ] Heavy processing uses `.utility` queue
- [ ] UI updates wrapped in `DispatchQueue.main.async`
- [ ] No `@MainActor` violations
- [ ] No synchronous waits on main thread
- [ ] Proper weak self capture in closures
- [ ] No race conditions in state updates

---

## Resources & References

### Documentation
- [Swift Testing Framework](https://developer.apple.com/documentation/testing)
- [XCTest Framework](https://developer.apple.com/documentation/xctest)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab)

### Project-Specific Testing Standards
- See `MessageAI/agents/shared-standards.md` for current manual testing standards
- See `MessageAI/agents/test-template.md` for testing guidelines
- See `MessageAI/docs/architecture.md` for system architecture
- See `MessageAI/docs/ai-build-plan.md` for AI feature specifications

### Community Resources
- iOS Testing Best Practices
- Firebase Testing Patterns
- SwiftUI Testing Strategies
- Performance Testing Guidelines
- Swift Concurrency Testing

---

## Notes

- **Current Priority**: Manual testing validation for feature delivery
- **Future Priority**: Comprehensive automated testing for production readiness
- **Testing Philosophy**: Quality over speed, but speed enables quality
- **Human Validation**: Always required for UX/UI, even with automated tests
- **Thread Safety**: Critical for all AI features - test thoroughly
- **AI Integration**: Test with both real API and mocked responses

