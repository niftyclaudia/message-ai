# PRD: Optimistic UI & Server Timestamps

**Feature**: Optimistic UI & Server Timestamps

**Version**: 1.0

**Status**: COMPLETED

**Agent**: Pete

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief #7](../pr-brief/pr-briefs.md#pr-7-optimistic-ui--server-timestamps)

---

## 1. Summary

Implement optimistic UI updates and server-synced timestamps to ensure messages appear instantly in the UI while being sent to the server, and use Firestore server timestamps to prevent time-sync issues. This PR builds on PR #6's real-time messaging foundation to provide a smooth, responsive user experience with proper message status indicators.

---

## 2. Problem & Goals

**Problem**: Users experience delays when sending messages because the UI waits for server confirmation, and device time differences can cause message ordering issues. Users need instant visual feedback and consistent message ordering across devices.

**Why Now**: PR #6 established real-time messaging foundation. This PR optimizes the user experience with instant UI updates and reliable timestamps.

**Goals**:
- [ ] G1 — Messages appear instantly in UI (optimistic updates)
- [ ] G2 — Server timestamps prevent ordering issues across devices
- [ ] G3 — Message status indicators show delivery progress
- [ ] G4 — Smooth animations for message appearance and status changes
- [ ] G5 — Handle optimistic update failures gracefully

---

## 3. Non-Goals / Out of Scope

- Message read receipts (PR #12)
- Push notifications (PR #13)
- Message editing/deletion (future)
- Media message support (future)
- Message reactions (future)
- Message search (future)
- Offline persistence improvements (PR #8)

---

## 4. Success Metrics

**User-visible**: 
- Message appears in UI: < 50ms from send tap
- Status updates smoothly: < 100ms transition time
- Message ordering consistent across devices

**System**: 
- Optimistic UI response: < 50ms
- Server timestamp accuracy: 100% consistent ordering
- Status update latency: < 100ms

**Quality**: 
- 0 blocking bugs, all acceptance gates pass, crash-free rate >99%
- Optimistic updates work reliably
- Server timestamp consistency verified

---

## 5. Users & Stories

**Primary User**: Active messaging user who needs instant feedback and reliable message ordering

**User Stories**:
- As a user, I want my messages to appear instantly when I send them so I can see immediate feedback
- As a user, I want to see the status of my messages (sending, sent, delivered) so I know they're being processed
- As a user, I want messages to appear in the correct order across all devices so conversations make sense
- As a user, I want smooth animations when messages appear so the interface feels polished
- As a user, I want to know if my message failed to send so I can retry
- As a user, I want the interface to feel responsive even when the network is slow

---

## 6. Experience Specification (UX)

**Optimistic Message Display**:
- Message appears instantly in chat when user taps send
- Message shows "Sending..." status immediately
- Input field clears instantly after send tap
- Send button shows loading state during send

**Status Indicators**:
- Sending: Message shows "Sending..." with subtle animation
- Sent: Message shows "Sent" with checkmark
- Delivered: Message shows "Delivered" with double checkmark
- Failed: Message shows "Failed" with retry button

**Animations**:
- New messages slide in smoothly from bottom
- Status changes animate smoothly
- Send button shows loading spinner
- Failed messages show error state with retry option

**Server Timestamp Behavior**:
- Messages ordered by server timestamp, not client time
- Consistent ordering across all devices
- No timezone issues or device clock differences

**Error Handling**:
- Failed optimistic updates show error state
- Retry mechanism for failed messages
- Graceful fallback to server timestamps

---

## 7. Functional Requirements (Must/Should)

**MUST**:
- Messages appear instantly in UI (optimistic updates)
- Server timestamps used for message ordering
- Status indicators show message delivery progress
- Smooth animations for message appearance and status changes
- Handle optimistic update failures gracefully
- Maintain message ordering consistency across devices

**SHOULD**:
- Optimistic updates work offline
- Status updates animate smoothly
- Failed messages show clear error states
- Retry mechanism for failed messages

**Acceptance Gates**:
- [Gate] When user sends message → appears instantly in UI
- [Gate] Message ordering consistent across devices using server timestamps
- [Gate] Status updates animate smoothly and show correct states
- [Gate] Failed optimistic updates show error state with retry option
- [Gate] Optimistic updates work offline and sync on reconnect

---

## 8. Data Model

### Message Document (Extended with Server Timestamps)

```swift
struct Message: Codable, Identifiable, Equatable {
    let id: String
    let chatID: String
    let senderID: String
    var text: String
    var timestamp: Date                    // Client timestamp for optimistic UI
    var serverTimestamp: Date?             // Server timestamp for ordering
    var readBy: [String]
    var status: MessageStatus
    var senderName: String?
    var isOptimistic: Bool = false         // For optimistic updates
    var isOffline: Bool = false
    var retryCount: Int = 0
}

enum MessageStatus: String, Codable, CaseIterable {
    case sending = "sending"               // Optimistic state
    case sent = "sent"                     // Server confirmed
    case delivered = "delivered"           // Delivered to recipient
    case read = "read"                     // Read by recipient
    case failed = "failed"                 // Send failed
    case queued = "queued"                 // Offline queued
}
```

**Firestore Collection**: `messages` (sub-collection under `chats/{chatID}`)

**Example with Server Timestamp**:
```json
{
  "id": "msg123",
  "chatID": "chat456",
  "senderID": "user789",
  "text": "Hello there!",
  "timestamp": Timestamp,                 // Client timestamp
  "serverTimestamp": Timestamp,            // Server timestamp
  "readBy": ["user789"],
  "status": "delivered",
  "senderName": "John Doe",
  "isOptimistic": false,
  "isOffline": false,
  "retryCount": 0
}
```

### Optimistic Message Queue

```swift
struct OptimisticMessage: Codable, Identifiable {
    let id: String
    let chatID: String
    let text: String
    let timestamp: Date
    var status: MessageStatus = .sending
    var retryCount: Int = 0
    var lastAttempt: Date?
}
```

**Local Storage**: UserDefaults for optimistic message tracking

---

## 9. API / Service Contracts

### MessageService (Extended for Optimistic UI)

```swift
class MessageService {
    // Core messaging with optimistic updates
    func sendMessageOptimistic(chatID: String, text: String) async throws -> String
    func sendMessage(chatID: String, text: String) async throws -> String
    func observeMessages(chatID: String, 
                        completion: @escaping ([Message]) -> Void) -> ListenerRegistration
    
    // Optimistic update management
    func addOptimisticMessage(chatID: String, text: String) async throws -> String
    func updateOptimisticMessageStatus(messageID: String, status: MessageStatus) async throws
    func removeOptimisticMessage(messageID: String) async throws
    func getOptimisticMessages(chatID: String) async -> [OptimisticMessage]
    
    // Server timestamp handling
    func updateMessageWithServerTimestamp(messageID: String, serverTimestamp: Date) async throws
    func sortMessagesByServerTimestamp(_ messages: [Message]) -> [Message]
    
    // Status management
    func updateMessageStatus(messageID: String, status: MessageStatus) async throws
    func markMessageAsDelivered(messageID: String) async throws
    
    // Error handling
    func retryFailedMessage(messageID: String) async throws
    func deleteFailedMessage(messageID: String) async throws
}

enum MessageServiceError: LocalizedError {
    case messageNotFound, permissionDenied, networkError, 
         optimisticUpdateFailed, serverTimestampError, unknown(Error)
}
```

### OptimisticUpdateService

```swift
class OptimisticUpdateService: ObservableObject {
    @Published var optimisticMessages: [String: OptimisticMessage] = [:]
    
    func addOptimisticMessage(_ message: OptimisticMessage)
    func updateOptimisticMessageStatus(_ messageID: String, status: MessageStatus)
    func removeOptimisticMessage(_ messageID: String)
    func clearOptimisticMessages(for chatID: String)
}
```

---

## 10. UI Components to Create/Modify

**New Components**:
- `Views/Components/OptimisticMessageRowView.swift` — Optimistic message display
- `Views/Components/MessageStatusIndicatorView.swift` — Status indicators with animations
- `Views/Components/MessageTimestampView.swift` — Server timestamp display
- `Views/Components/OptimisticUpdateView.swift` — Optimistic update management

**Modified Components**:
- `Views/Main/ChatView.swift` — Add optimistic message handling
- `Views/Components/MessageRowView.swift` — Add status indicators and animations
- `ViewModels/ChatViewModel.swift` — Add optimistic update logic
- `Services/MessageService.swift` — Add optimistic update methods

**Services**:
- `Services/OptimisticUpdateService.swift` — Optimistic update management
- `Services/MessageService.swift` — Extended with optimistic methods

---

## 11. Integration Points

- Firebase Authentication (current user)
- Firestore (message storage with server timestamps)
- Real-time listeners (optimistic update handling)
- Local storage (optimistic message tracking)
- State management (SwiftUI patterns)
- Animation system (SwiftUI animations)

---

## 12. Test Plan & Acceptance Gates

**Happy Path**:
- [ ] User sends message → appears instantly in UI
- [ ] Message status updates smoothly (sending → sent → delivered)
- [ ] Server timestamps ensure consistent ordering
- [ ] Optimistic updates work offline
- [ ] Animations are smooth and responsive

**Edge Cases**:
- [ ] Optimistic update fails → shows error state with retry
- [ ] Network failure during send → message shows failed status
- [ ] Server timestamp missing → falls back to client timestamp
- [ ] Multiple optimistic messages → handled correctly
- [ ] App restart with optimistic messages → handled gracefully

**Multi-User**:
- [ ] Message ordering consistent across devices
- [ ] Optimistic updates don't interfere with real-time sync
- [ ] Status updates sync in real-time
- [ ] Server timestamps prevent ordering issues

**Performance**:
- [ ] Optimistic UI response < 50ms
- [ ] Status updates animate smoothly
- [ ] No UI blocking during optimistic updates
- [ ] Memory usage stable with optimistic messages

---

## 13. Definition of Done

- [ ] MessageService implemented + unit tests (Swift Testing)
- [ ] Optimistic update service working
- [ ] Server timestamp handling implemented
- [ ] SwiftUI views with optimistic updates and animations
- [ ] UI tests pass (XCTest)
- [ ] Multi-device sync verified with server timestamps
- [ ] Optimistic updates work offline
- [ ] All acceptance gates pass
- [ ] Code follows shared-standards.md patterns

---

## 14. Risks & Mitigations

**Risk 1: Optimistic updates causing UI inconsistencies**
- **Impact**: Messages appear/disappear, confusing interface
- **Mitigation**: Proper state management, clear optimistic indicators
- **Monitoring**: Test optimistic update scenarios thoroughly

**Risk 2: Server timestamp synchronization issues**
- **Impact**: Message ordering problems across devices
- **Mitigation**: Use Firestore server timestamps, fallback to client timestamps
- **Monitoring**: Test message ordering across multiple devices

**Risk 3: Animation performance with many messages**
- **Impact**: UI lag, poor user experience
- **Mitigation**: Optimize animations, use LazyVStack, limit optimistic messages
- **Monitoring**: Performance testing with large message lists

**Risk 4: Optimistic update failures**
- **Impact**: Messages lost, poor user experience
- **Mitigation**: Robust error handling, retry mechanisms, user feedback
- **Monitoring**: Test network failure scenarios

**Risk 5: Memory leaks with optimistic messages**
- **Impact**: App crashes, poor performance
- **Mitigation**: Proper cleanup, limit optimistic message count
- **Monitoring**: Memory profiling during development

---

## 15. Dependencies

**Depends On**: PR #6 (Real-Time Message Sending/Receiving)

**Required For**: PR #8 (Offline Persistence), PR #12 (Read Receipts)

---

## 16. Security Rules

```javascript
match /chats/{chatID}/messages/{messageID} {
  allow read: if isAuthenticated() && isMember(chatID);
  allow create: if isAuthenticated() && isMember(chatID) && 
                request.auth.uid == resource.data.senderID;
  allow update: if isAuthenticated() && isMember(chatID) && 
                request.auth.uid == resource.data.senderID;
  allow delete: if false;  // No deletion for now
}
```

---

## 17. Implementation Plan

### Step 1: Optimistic Update Service
- Implement OptimisticUpdateService
- Add optimistic message tracking
- Integrate with SwiftUI state management
- **Deliverable**: Optimistic update service working

### Step 2: MessageService Optimistic Methods
- Implement sendMessageOptimistic method
- Add optimistic message management
- Implement server timestamp handling
- **Deliverable**: Optimistic messaging service

### Step 3: Server Timestamp Integration
- Implement server timestamp handling
- Add message ordering by server timestamp
- Handle timestamp fallbacks
- **Deliverable**: Server timestamp consistency

### Step 4: Optimistic UI Components
- Create OptimisticMessageRowView
- Add status indicators with animations
- Implement smooth message appearance
- **Deliverable**: Optimistic UI components

### Step 5: Status Indicator System
- Create MessageStatusIndicatorView
- Add status update animations
- Implement retry functionality
- **Deliverable**: Status indicator system

### Step 6: ChatView Integration
- Integrate optimistic updates with ChatView
- Add optimistic message handling
- Implement proper state management
- **Deliverable**: Complete optimistic chat interface

### Step 7: Animation System
- Implement smooth message animations
- Add status change animations
- Optimize animation performance
- **Deliverable**: Smooth animation system

### Step 8: Error Handling & Fallbacks
- Implement optimistic update failure handling
- Add retry mechanisms
- Create user-friendly error states
- **Deliverable**: Robust error handling

### Step 9: Service Layer Testing
- Write unit tests (Swift Testing) for optimistic methods
- Test server timestamp handling
- Test error scenarios
- **Deliverable**: Complete test coverage

### Step 10: UI Testing
- Write UI tests (XCTest) for optimistic updates
- Test animations and status changes
- Test error states
- **Deliverable**: Complete UI test coverage

### Step 11: Multi-Device Testing
- Test server timestamp consistency
- Verify message ordering across devices
- Test optimistic update synchronization
- **Deliverable**: Multi-device sync verification

### Step 12: Performance & Final Testing
- Performance testing with optimistic updates
- Animation performance testing
- Final acceptance gate verification
- **Deliverable**: Production-ready optimistic UI

**Total**: 12 sequential steps with specific deliverables

---

**End of PRD**
