# Shared Standards & Requirements

This document contains common standards referenced by all agent templates to avoid duplication.

---

## Performance Requirements

All features MUST maintain these targets:

### Phase 1 (Post-MVP) Targets
- **App load time**: < 2 seconds (cold start to interactive UI)
- **Navigation**: Inbox → thread < 400ms
- **Message delivery latency**: p95 < 200ms (send → server ack → render)
- **Scrolling**: Smooth 60fps with 1000+ messages (list windowing required)
- **Burst messaging**: 20+ messages rapidly with no lag or out-of-order renders
- **Presence propagation**: < 500ms for all online users
- **Typing indicators**: < 200ms appearance, < 500ms hide after idle
- **Tap feedback**: < 50ms response time
- **No UI blocking**: Keep main thread responsive
- **Smooth animations**: Use SwiftUI best practices

### MVP Baseline Targets (for reference)
- **App load time**: < 2-3 seconds (cold start to interactive UI)
- **Message delivery latency**: < 100ms (send to receive)
- **Scrolling**: Smooth 60fps with 100+ messages

---

## Real-Time Messaging Requirements

Every feature involving messaging MUST address:

### Phase 1 (Post-MVP) Requirements
- **Sync speed**: Messages sync across devices in < 200ms (p95)
- **Burst handling**: 20+ messages rapidly with no visible lag or out-of-order renders
- **Offline behavior**: 3-message queue in Airplane Mode → visible 'Queued' → auto-send on reconnect
- **Network resilience**: 30s+ network drop → auto-reconnect; full sync completes in < 1s
- **Force-quit recovery**: Full chat history preserved after force-quit
- **Optimistic UI**: Immediate visual feedback before server confirmation
- **Concurrent messaging**: Handle multiple simultaneous messages gracefully
- **Works with 3+ devices**: Test multi-device scenarios
- **Presence system**: Online/offline status propagates within < 500ms
- **Typing indicators**: Multi-user support ("Alice & Bob are typing...")

### MVP Baseline Requirements (for reference)
- **Sync speed**: Messages sync across devices in < 100ms
- **Offline behavior**: Messages queue and send on reconnect
- **Optimistic UI**: Immediate visual feedback before server confirmation
- **Concurrent messaging**: Handle multiple simultaneous messages gracefully
- **Works with 3+ devices**: Test multi-device scenarios

---

## Code Quality Standards

### Swift/SwiftUI Best Practices
- ✅ Use proper Swift types (avoid `Any`)
- ✅ All function parameters and return types explicitly typed
- ✅ Structs/Classes properly defined for models
- ✅ Proper use of `@State`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`
- ✅ Views broken into small, reusable components
- ✅ Keep functions small and focused
- ✅ Meaningful variable names

### Architecture
- ✅ Service layer methods are deterministic
- ✅ SwiftUI views are thin wrappers around services
- ✅ No business logic in UI views
- ✅ State management follows SwiftUI patterns

### Documentation
- ✅ Complex logic has comments
- ✅ Public APIs have documentation comments
- ✅ No commented-out code
- ✅ No hardcoded values (use constants)
- ✅ No magic numbers
- ✅ No TODO comments without tickets

---

## Testing Standards

### Testing Framework Strategy

This project uses a **hybrid testing approach**:

**Unit/Service Tests → Swift Testing Framework ⭐ REQUIRED**
- Modern `@Test("Display Name")` syntax with custom names
- Tests appear with readable names in test navigator
- Use `#expect` for assertions
- Best for service layer, business logic, data models

**UI Tests → XCTest Framework**
- Traditional `XCTestCase` with `XCUIApplication`
- Descriptive function names (e.g., `testLoginView_DisplaysCorrectly()`)
- Use `XCTAssert` for assertions
- Required for UI automation and app lifecycle

### Test Types Required

**1. Unit Tests (Swift Testing)** — Mandatory for all features
- Path: `MessageAITests/{Feature}Tests.swift`
- Framework: Swift Testing
- Pattern: `@Test("Display Name")` with `#expect`
- Tests: Service method behavior, validation, Firebase operations
- Example: `MessageAITests/AuthenticationServiceTests.swift`

**2. UI Tests (XCTest)** — Mandatory for user-facing features
- Path: `MessageAIUITests/{Feature}UITests.swift`
- Framework: XCTest
- Pattern: `class XCTestCase` with `func test...()`
- Tests: User interactions, navigation, state changes
- Example: `MessageAIUITests/AuthenticationUITests.swift`

**3. Service Tests (Swift Testing)** — If you created/modified service methods
- Path: `MessageAITests/Services/{ServiceName}Tests.swift`
- Framework: Swift Testing
- Pattern: `@Test("Display Name")` with `#expect`
- Tests: Firebase interactions, async operations, error handling

### Test Coverage Requirements

#### Phase 1 (Post-MVP) Requirements
- ✅ Happy path scenarios
- ✅ Edge cases (empty input, offline, errors)
- ✅ Multi-user scenarios (3+ simultaneous users)
- ✅ Performance targets (p95 < 200ms, 60fps with 1000+ messages)
- ✅ Real-time sync (<200ms p95)
- ✅ Offline persistence (3-message queue, force-quit recovery)
- ✅ Burst messaging (20+ messages rapidly)
- ✅ Presence propagation (<500ms)
- ✅ Typing indicators (multi-user, <200ms appearance)
- ✅ Network resilience (30s+ drops, <1s sync)
- ✅ Group chat performance (3+ users simultaneously)

#### MVP Baseline Requirements (for reference)
- ✅ Happy path scenarios
- ✅ Edge cases (empty input, offline, errors)
- ✅ Multi-user scenarios
- ✅ Performance targets
- ✅ Real-time sync (<100ms)
- ✅ Offline persistence

### Multi-Device Testing Pattern (Swift Testing)

#### Phase 1 (Post-MVP) Testing Patterns
```swift
// Burst messaging test (20+ messages rapidly)
@Test("Burst Messaging Handles 20+ Messages Without Lag")
func burstMessagingHandles20PlusMessagesWithoutLag() async throws {
    let service = MessageService()
    let chatID = "test-chat"
    
    // Send 20 messages rapidly
    let startTime = Date()
    for i in 1...20 {
        try await service.sendMessage(chatID: chatID, text: "Message \(i)")
    }
    let endTime = Date()
    
    // Should complete without visible lag
    let duration = endTime.timeIntervalSince(startTime)
    #expect(duration < 5.0) // 20 messages in < 5 seconds
}

// Presence propagation test
@Test("Presence Status Propagates Within 500ms")
func presenceStatusPropagatesWithin500ms() async throws {
    let service1 = PresenceService()
    let service2 = PresenceService()
    
    // Device 1 goes online
    let startTime = Date()
    try await service1.setOnline()
    
    // Wait for propagation
    try await Task.sleep(nanoseconds: 500_000_000) // 500ms
    
    // Device 2 should see Device 1 as online
    let isOnline = try await service2.isUserOnline(userID: "device1")
    #expect(isOnline == true)
}

// Performance measurement test
@Test("Message Delivery p95 Latency Under 200ms")
func messageDeliveryP95LatencyUnder200ms() async throws {
    let service = MessageService()
    let latencies: [TimeInterval] = []
    
    // Send 100 messages and measure latency
    for _ in 1...100 {
        let startTime = Date()
        try await service.sendMessage(chatID: "test", text: "test")
        let latency = Date().timeIntervalSince(startTime)
        latencies.append(latency)
    }
    
    // Calculate p95
    let sortedLatencies = latencies.sorted()
    let p95Index = Int(Double(sortedLatencies.count) * 0.95)
    let p95Latency = sortedLatencies[p95Index]
    
    #expect(p95Latency < 0.2) // < 200ms
}
```

#### MVP Baseline Testing Pattern (for reference)
```swift
// Automated test simulating multiple devices
@Test("Message Sync Across Devices Completes Within 100ms")
func messageSyncAcrossDevicesCompletesWithin100ms() async throws {
    // Given: Two devices
    let device1Service = MessageService()
    let device2Service = MessageService()
    
    // When: Device 1 sends message
    let messageID = try await device1Service.sendMessage(
        chatID: "test-chat",
        text: "Hello from device 1"
    )
    
    // Wait for Firebase sync (should be <100ms)
    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    
    // Then: Device 2 receives the message
    let messages = try await device2Service.fetchMessages(chatID: "test-chat")
    #expect(messages.contains { $0.id == messageID })
}
```

---

## Phase 1 (Post-MVP) Specific Requirements

### Performance Measurement & Evidence Collection

All Phase 1 features MUST include:

#### Performance Measurement Tools
- **Latency tracking**: Measure p50, p95, p99 latencies for all operations
- **Performance monitoring**: Use `PerformanceMonitor.swift` for real-time metrics
- **Evidence collection**: Screenshots, videos, and timing data for each category

#### Required Evidence Types
- **Latency histograms**: Visual representation of performance distributions
- **Demo videos**: Real-time performance demonstrations
- **Screenshots**: UI states, timing measurements, performance metrics
- **Timing data**: Measured latencies, sync times, propagation speeds

#### Testing Scenarios
- **Burst testing**: 20+ messages in < 5 seconds
- **Multi-device sync**: 3+ devices simultaneously
- **Offline scenarios**: Airplane Mode, force-quit, network drops
- **Group chat**: 3+ users messaging simultaneously
- **Lifecycle transitions**: Background/foreground, push notifications

#### Performance Targets by Category
- **Real-Time Delivery**: p95 < 200ms, burst handling, presence < 500ms
- **Offline Persistence**: 3-message queue, force-quit recovery, 30s+ network drops
- **Group Chat**: 3+ simultaneous users, attribution, read receipts
- **Mobile Lifecycle**: Instant sync, push notifications, no message loss
- **Performance & UX**: < 2s launch, 60fps with 1000+ messages, optimistic UI

---

## Data Model Examples

### Message Document
```swift
{
  id: String,
  text: String,
  senderID: String,
  timestamp: Timestamp,  // FieldValue.serverTimestamp()
  readBy: [String]  // Array of user IDs
}
```

### Chat Document
```swift
{
  id: String,
  members: [String],  // Array of user IDs
  lastMessage: String,
  lastMessageTimestamp: Timestamp,
  isGroupChat: Bool
}
```

---

## Service Contract Examples

```swift
// Message operations
func sendMessage(chatID: String, text: String) async throws -> String
func observeMessages(chatID: String, completion: @escaping ([Message]) -> Void) -> ListenerRegistration
func markMessageAsRead(messageID: String, userID: String) async throws

// Chat operations
func createChat(members: [String], isGroup: Bool) async throws -> String
```

---

## Git Branch Strategy

**Base Branch**: Always branch from `develop`  
**Branch Naming**: `feat/pr-{number}-{feature-name}`  
**PR Target**: Always target `develop`, NEVER `main`

Example:
```bash
git checkout develop
git pull origin develop
git checkout -b feat/pr-1-message-send
```

---

## Success Metrics Template

### Phase 1 (Post-MVP) Metrics
- **User-visible**: Time to complete task, number of taps, flow completion
- **System**: p95 message latency < 200ms, app load < 2s, 60fps with 1000+ messages
- **Performance**: Burst messaging (20+ messages), presence propagation < 500ms
- **Offline**: 3-message queue, force-quit recovery, 30s+ network resilience
- **Group chat**: 3+ simultaneous users, attribution, read receipts
- **Quality**: 0 blocking bugs, all acceptance gates pass, crash-free rate >99%
- **Evidence**: Latency histograms, demo videos, timing data, screenshots

### MVP Baseline Metrics (for reference)
- **User-visible**: Time to complete task, number of taps, flow completion
- **System**: Message delivery latency, app load time, scrolling fps
- **Quality**: 0 blocking bugs, all acceptance gates pass, crash-free rate >99%

---

## Common Issues & Solutions

### Issue: Changes don't sync to Firebase
**Solution:** Call service methods, not just local state updates
```swift
// ❌ Wrong - only updates local state
messages.append(newMessage)

// ✅ Correct - saves to Firebase AND updates local state
Task {
    try await messageService.sendMessage(chatID: chatID, text: text)
}
```

### Issue: Performance slow with many messages
**Solution:** Use LazyVStack
```swift
ScrollView {
    LazyVStack {
        ForEach(messages) { message in
            MessageRow(message: message)
        }
    }
}
```

### Issue: Tests failing
**Check:**
1. Async operations properly awaited
2. Firebase emulator running
3. State updated before assertion
4. No race conditions in concurrent tests

### Issue: Real-time sync slow
**Solution:**
1. Optimize Firebase queries with indexes
2. Use Firebase batch writes
3. Ensure Firestore persistence enabled

### Issue: Phase 1 performance targets not met
**Solution:**
1. Use `PerformanceMonitor.swift` to measure actual latencies
2. Profile with Xcode Instruments to identify bottlenecks
3. Implement list windowing for 1000+ messages
4. Optimize Firebase listener setup and caching
5. Test burst scenarios (20+ messages) under load

### Issue: Presence propagation slow (>500ms)
**Solution:**
1. Use Firebase Realtime Database for presence (faster than Firestore)
2. Implement onDisconnect hooks properly
3. Test multi-device scenarios with timing measurements
4. Consider WebSocket connections for critical presence updates

### Issue: Offline queue not working properly
**Solution:**
1. Verify Firestore offline persistence is enabled
2. Test 3-message queue in Airplane Mode
3. Implement proper UI indicators ("Queued", "Sending X...")
4. Test force-quit and recovery scenarios
5. Measure sync completion time (< 1s target)

---

## AI Error Handling Standards (PR-AI-005)

All AI features MUST use the centralized error handling system for consistent UX and graceful degradation.

### Core Principles

**Calm Intelligence Error UX:**
- ✅ Blue/gray background (#F0F4F8), never red
- ✅ Info icon (ℹ️), never error icon (❌)
- ✅ First-person messaging ("I'm having trouble..." not "Error occurred")
- ✅ Actionable fallbacks (retry, view full content, use basic mode)

**Graceful Degradation:**
- ✅ Core messaging ALWAYS works (send, receive, read)
- ✅ AI features fail gracefully with fallback options
- ✅ No crashes or blocking errors from AI failures

**Performance:**
- ✅ Error handling overhead: <10ms per AI request
- ✅ Error UI display: <50ms
- ✅ Retry start: <100ms
- ✅ Fallback activation: <200ms

### Error Handling Pattern

**Step 1: Wrap AI operations with error handling**
```swift
import MessageAI

let handler = AIErrorHandler.shared
let context = AIContext(
    feature: .summarization,
    userId: currentUserId,
    threadId: threadId
)

do {
    // Attempt AI operation
    let result = try await aiService.summarizeThread(threadId)
    
    // Record success (resets fallback mode)
    handler.recordSuccess(for: .summarization)
    
    // Use result
    displaySummary(result)
    
} catch let error as AIError {
    // Handle AI error with calm UX
    let response = handler.handle(error: error, context: context)
    
    // Show calm error view
    showCalmError(response)
    
} catch {
    // Convert generic errors to AIError
    let aiError = AIError.from(error, context: "Thread summarization")
    let response = handler.handle(error: aiError, context: context)
    showCalmError(response)
}
```

**Step 2: Display calm error UI**
```swift
// In your SwiftUI view
@State private var errorResponse: ErrorResponse?
@State private var showingError = false

// Show error
CalmErrorView(
    errorResponse: errorResponse!,
    onRetry: {
        // Retry the operation
        Task {
            await retryOperation()
        }
    },
    onFallback: {
        // Execute fallback action
        if let fallback = errorResponse?.fallbackAction {
            executeFallback(fallback)
        }
    }
)

// Or use toast for background errors
CalmErrorToast(
    message: errorResponse?.userMessage ?? "",
    isShowing: $showingError
)
```

**Step 3: Check fallback mode before operations**
```swift
let handler = AIErrorHandler.shared

if handler.shouldUseFallbackMode(feature: .semanticSearch) {
    // Use fallback: keyword search instead of semantic search
    performKeywordSearch(query)
} else {
    // Try semantic search
    performSemanticSearch(query)
}
```

### Error Types & Handling

| Error Type | Retryable? | Delay | User Message |
|------------|-----------|-------|--------------|
| `.timeout` | ✓ | 1s | "I'm having trouble right now. Want to try again?" |
| `.rateLimit` | ✗ | 30s | "I need a moment to catch up. Try again in 30 seconds?" |
| `.serviceUnavailable` | ✓ | 2s | "Taking longer than expected. Want to try the full version?" |
| `.networkFailure` | ✓ | 1s | "I can't reach my AI assistant right now. Check your connection?" |
| `.invalidRequest` | ✗ | 0s | "Something doesn't look quite right. Let me know if this keeps happening." |
| `.quotaExceeded` | ✗ | 0s | "AI features are temporarily limited. I'll be back soon!" |

### Fallback Actions by Feature

| Feature | Fallback Action |
|---------|----------------|
| Thread Summarization | Open full thread |
| Action Item Extraction | Show last 10 messages |
| Smart Search | Fall back to keyword search |
| Priority Detection | Show all in neutral inbox |
| Decision Tracking | Show raw message history |
| Proactive Scheduling | Prompt manual calendar check |

### Retry Logic

**Exponential Backoff:**
- Attempt 1: 1s delay
- Attempt 2: 2s delay
- Attempt 3: 4s delay
- Attempt 4: 8s delay (max)
- After 4 attempts: Permanent failure

**Fallback Mode:**
- Triggered after 3 consecutive failures
- Shows banner: "🔵 [Feature fallback mode description]"
- Exits automatically on successful operation

### Cloud Functions Error Handling

```typescript
import { withErrorHandling, AIContext } from './utils/errorHandling';

const context: AIContext = {
  requestId: uuid(),
  feature: 'summarization',
  userId: request.auth.uid,
  timestamp: admin.firestore.Timestamp.now(),
  retryCount: 0
};

const result = await withErrorHandling(
  async () => {
    // Your AI operation here
    return await openai.createCompletion(/* ... */);
  },
  context,
  10000 // 10s timeout
);

if (result.success) {
  return result.data;
} else {
  // Error logged to Firestore automatically
  return { error: result.error };
}
```

### Testing Requirements

**All AI features must test:**
- ✅ Error classification (all 6 types)
- ✅ Retry mechanism (exponential backoff)
- ✅ Fallback options work correctly
- ✅ Error logging (Crashlytics + Firestore)
- ✅ Graceful degradation (messaging works when AI down)
- ✅ UI displays calm error view (blue/gray, first-person)
- ✅ Performance targets (<10ms overhead, <50ms UI)

**Test files:**
- Unit tests: `AIErrorHandlerTests.swift`, `FallbackModeManagerTests.swift`
- UI tests: `AIErrorUITests.swift`
- Integration: `GracefulDegradationTests.swift`
- Performance: `AIErrorHandlerPerformanceTests.swift`

### Privacy & Logging

**What gets logged:**
- ✅ Error type, feature, timestamp
- ✅ Hashed user ID (SHA256 first 16 chars)
- ✅ Hashed query (if applicable)
- ✅ Request context (messageId, threadId)

**What does NOT get logged:**
- ❌ Message content
- ❌ Unhashed user IDs
- ❌ Unhashed search queries
- ❌ Any PII (personally identifiable information)

### Related Files

- **Models:** `Models/AIError.swift`, `AIFeature.swift`, `FallbackAction.swift`, `ErrorResponse.swift`, `AIContext.swift`
- **Services:** `Services/AI/AIErrorHandler.swift`, `ErrorLogger.swift`, `RetryQueue.swift`, `FallbackModeManager.swift`
- **Views:** `Views/AIError/CalmErrorView.swift`, `CalmErrorToast.swift`, `FallbackModeIndicator.swift`
- **Components:** `Components/LoadingWithTimeout.swift`
- **Cloud Functions:** `functions/src/utils/errorHandling.ts`, `functions/src/jobs/retryQueue.ts`
- **Schema:** `MessageAI/docs/schemas/failedAIRequests-schema.md`
