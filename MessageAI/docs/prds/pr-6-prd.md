# PRD: Real-Time Message Sending/Receiving

**Feature**: Real-Time Message Sending/Receiving

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief #6](../pr-brief/pr-briefs.md#pr-6-real-time-message-sendingreceiving)

---

## 1. Summary

Implement real-time message sending and receiving using Firestore snapshot listeners. This PR adds the core messaging functionality with Firestore listeners, message creation, and real-time synchronization. Includes proper error handling and network failure management.

---

## 2. Problem & Goals

**Problem**: Users need to send and receive messages in real-time with instant synchronization across devices and proper error handling for network failures.

**Why Now**: Core messaging functionality required for Phase 2. Depends on PR #5 (Chat View Screen) for message display.

**Goals**:
- [ ] G1 — Send messages with real-time delivery < 100ms
- [ ] G2 — Receive messages instantly via Firestore listeners
- [ ] G3 — Handle network failures gracefully with retry logic
- [ ] G4 — Support offline message queuing and sync on reconnect
- [ ] G5 — Implement proper error states and user feedback

---

## 3. Non-Goals / Out of Scope

- Optimistic UI updates (PR #7)
- Message read receipts (PR #12)
- Push notifications (PR #13)
- Message editing/deletion (future)
- Media message support (future)
- Message reactions (future)
- Message search (future)

---

## 4. Success Metrics

**User-visible**: 
- Message send time: < 2 seconds from tap to delivery
- Message receive time: < 100ms from send to display
- Offline message sync: < 5 seconds after reconnect

**System**: 
- Message delivery latency: < 100ms (send to receive)
- Network failure recovery: < 3 seconds
- Offline message persistence: 100% reliability

**Quality**: 
- 0 blocking bugs, all acceptance gates pass, crash-free rate >99%
- Real-time sync verified across 2+ devices
- Offline persistence tested

---

## 5. Users & Stories

**Primary User**: Active messaging user who needs reliable real-time communication

**User Stories**:
- As a user, I want to send messages instantly so I can communicate in real-time
- As a user, I want to receive messages immediately so I can respond quickly
- As a user, I want my messages to sync across all my devices so I can continue conversations anywhere
- As a user, I want to send messages offline so I can communicate even without internet
- As a user, I want to see when my message failed to send so I can retry
- As a user, I want my offline messages to send automatically when I reconnect so I don't lose anything

---

## 6. Experience Specification (UX)

**Message Input**:
- Text input field with send button
- Send button disabled when input is empty
- Send button shows loading state during send
- Input clears after successful send

**Message Sending States**:
- Sending: Button shows spinner, message shows "Sending..."
- Sent: Message shows "Sent" status
- Failed: Message shows "Failed" with retry button
- Delivered: Message shows "Delivered" status

**Real-Time Updates**:
- New messages appear instantly without refresh
- Message status updates in real-time
- No UI flicker during updates
- Smooth animations for new messages

**Offline Behavior**:
- Messages queue locally when offline
- "Offline" indicator in message input
- Queued messages show "Waiting..." status
- Auto-send when connection restored

**Error States**:
- Network error: "Check your connection" message
- Send failure: "Failed to send" with retry option
- Permission error: "Unable to send message" alert

---

## 7. Functional Requirements (Must/Should)

**MUST**:
- Send messages to Firestore with proper error handling
- Receive messages via Firestore snapshot listeners
- Real-time sync across devices < 100ms
- Offline message queuing and persistence
- Network failure detection and retry logic
- Message status tracking (sending, sent, delivered, failed)
- Proper cleanup of Firestore listeners

**SHOULD**:
- Optimistic UI updates for better perceived performance
- Message delivery confirmation
- Offline indicator in UI
- Automatic retry for failed messages

**Acceptance Gates**:
- [Gate] When User A sends message → User B sees it in <100ms
- [Gate] Offline: messages queue and deliver on reconnect
- [Gate] Error case: network failure shows retry option
- [Gate] Real-time: new messages appear instantly without refresh
- [Gate] Status: message status updates in real-time

---

## 8. Data Model

### Message Document (Extended)

```swift
struct Message: Codable, Identifiable, Equatable {
    let id: String
    let chatID: String
    let senderID: String
    var text: String
    var timestamp: Date
    var readBy: [String]
    var status: MessageStatus
    var senderName: String?
    var isOffline: Bool = false  // For queued messages
    var retryCount: Int = 0      // For failed messages
}

enum MessageStatus: String, Codable, CaseIterable {
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case read = "read"
    case failed = "failed"
    case queued = "queued"       // For offline messages
}
```

**Firestore Collection**: `messages` (sub-collection under `chats/{chatID}`)

**Example**:
```json
{
  "id": "msg123",
  "chatID": "chat456",
  "senderID": "user789",
  "text": "Hello there!",
  "timestamp": Timestamp,
  "readBy": ["user789"],
  "status": "delivered",
  "senderName": "John Doe",
  "isOffline": false,
  "retryCount": 0
}
```

### Offline Message Queue

```swift
struct QueuedMessage: Codable, Identifiable {
    let id: String
    let chatID: String
    let text: String
    let timestamp: Date
    var retryCount: Int = 0
    var lastAttempt: Date?
}
```

**Local Storage**: UserDefaults or Core Data for offline persistence

---

## 9. API / Service Contracts

### MessageService (Extended)

```swift
class MessageService {
    // Core messaging
    func sendMessage(chatID: String, text: String) async throws -> String
    func observeMessages(chatID: String, 
                        completion: @escaping ([Message]) -> Void) -> ListenerRegistration
    
    // Offline support
    func queueMessage(chatID: String, text: String) async throws -> String
    func syncQueuedMessages() async throws
    func getQueuedMessages() async -> [QueuedMessage]
    
    // Status management
    func updateMessageStatus(messageID: String, status: MessageStatus) async throws
    func markMessageAsDelivered(messageID: String) async throws
    
    // Error handling
    func retryFailedMessage(messageID: String) async throws
    func deleteFailedMessage(messageID: String) async throws
}

enum MessageServiceError: LocalizedError {
    case messageNotFound, permissionDenied, networkError, 
         offlineQueueFull, retryLimitExceeded, unknown(Error)
}
```

### NetworkMonitor

```swift
class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    @Published var connectionType: ConnectionType = .wifi
    
    func startMonitoring()
    func stopMonitoring()
}

enum ConnectionType {
    case wifi, cellular, none
}
```

---

## 10. UI Components to Create/Modify

**New Components**:
- `Views/Components/MessageInputView.swift` — Text input with send button
- `Views/Components/MessageStatusView.swift` — Status indicators
- `Views/Components/OfflineIndicatorView.swift` — Offline status display
- `Views/Components/RetryButtonView.swift` — Retry failed messages

**Modified Components**:
- `Views/Main/ChatView.swift` — Add message input and real-time updates
- `Views/Components/MessageRowView.swift` — Add status indicators
- `ViewModels/ChatViewModel.swift` — Add send message and real-time logic

**Services**:
- `Services/MessageService.swift` — Core messaging functionality
- `Services/NetworkMonitor.swift` — Network status monitoring
- `Services/OfflineQueueService.swift` — Offline message management

---

## 11. Integration Points

- Firebase Authentication (current user)
- Firestore (message storage and real-time listeners)
- Network monitoring (connection status)
- Local storage (offline message queue)
- State management (SwiftUI patterns)
- Error handling (user feedback)

---

## 12. Test Plan & Acceptance Gates

**Happy Path**:
- [ ] User sends message → appears instantly in chat
- [ ] Message syncs to other devices < 100ms
- [ ] Message status updates correctly (sending → sent → delivered)
- [ ] Offline messages queue and send on reconnect
- [ ] Real-time listeners work without memory leaks

**Edge Cases**:
- [ ] Network failure during send → message shows failed status
- [ ] Offline send → message queues locally
- [ ] Reconnect → queued messages send automatically
- [ ] Invalid input → send button disabled
- [ ] Empty message → cannot send

**Multi-User**:
- [ ] Real-time sync verified across 2+ devices
- [ ] Concurrent messages handled correctly
- [ ] Message ordering preserved with timestamps
- [ ] Status updates sync in real-time

**Performance**:
- [ ] Message delivery < 100ms
- [ ] No UI blocking during send
- [ ] Smooth scrolling with real-time updates
- [ ] Memory usage stable with listeners

---

## 13. Definition of Done

- [ ] MessageService implemented + unit tests (Swift Testing)
- [ ] Real-time Firestore listeners working
- [ ] Offline message queuing implemented
- [ ] Network monitoring and error handling
- [ ] SwiftUI views with all states (sending, sent, failed, offline)
- [ ] UI tests pass (XCTest)
- [ ] Multi-device sync verified (<100ms)
- [ ] Offline persistence tested
- [ ] All acceptance gates pass
- [ ] Code follows shared-standards.md patterns

---

## 14. Risks & Mitigations

**Risk 1: Firestore listener memory leaks**
- **Impact**: App crashes, poor performance over time
- **Mitigation**: Proper cleanup in `.onDisappear`, use weak references
- **Monitoring**: Memory profiling during development

**Risk 2: Network failure handling**
- **Impact**: Messages lost, poor user experience
- **Mitigation**: Robust offline queuing, retry logic, user feedback
- **Monitoring**: Test offline scenarios thoroughly

**Risk 3: Real-time sync performance**
- **Impact**: Slow message delivery, poor user experience
- **Mitigation**: Optimize Firestore queries, use proper indexing
- **Monitoring**: Measure sync latency across devices

**Risk 4: Message ordering issues**
- **Impact**: Messages appear out of order, confusing interface
- **Mitigation**: Use server timestamps, implement proper sorting
- **Monitoring**: Test concurrent message scenarios

**Risk 5: Offline queue storage limits**
- **Impact**: Messages lost when offline too long
- **Mitigation**: Implement queue size limits, oldest-first cleanup
- **Monitoring**: Test offline scenarios with large message queues

---

## 15. Dependencies

**Depends On**: PR #5 (Chat View Screen)

**Required For**: PR #7 (Optimistic UI), PR #8 (Offline Persistence)

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

### Step 1: Network Monitoring
- Implement NetworkMonitor service
- Add connection status tracking
- Integrate with SwiftUI state management
- **Deliverable**: Network status monitoring working

### Step 2: MessageService Core Methods
- Implement sendMessage with async/await
- Add proper error handling and validation
- Implement message status tracking
- **Deliverable**: Core messaging service with error handling

### Step 3: Real-Time Listeners
- Implement Firestore snapshot listeners
- Add proper cleanup and memory management
- Handle concurrent message updates
- **Deliverable**: Real-time message synchronization

### Step 4: Offline Message Queuing
- Implement offline message storage
- Add queue management and persistence
- Implement sync on reconnect
- **Deliverable**: Offline message queuing system

### Step 5: Message Input Component
- Create MessageInputView with send functionality
- Add loading states and error handling
- Implement input validation
- **Deliverable**: Complete message input interface

### Step 6: Status Indicators
- Create MessageStatusView component
- Add status update logic
- Implement retry functionality
- **Deliverable**: Message status tracking and display

### Step 7: ChatView Integration
- Integrate message input with ChatView
- Add real-time message updates
- Implement proper state management
- **Deliverable**: Complete chat interface with messaging

### Step 8: Error Handling & User Feedback
- Implement network error states
- Add retry mechanisms
- Create user-friendly error messages
- **Deliverable**: Robust error handling and user feedback

### Step 9: Service Layer Testing
- Write unit tests (Swift Testing) for MessageService
- Test error scenarios and edge cases
- Test offline functionality
- **Deliverable**: Complete test coverage for service layer

### Step 10: UI Testing
- Write UI tests (XCTest) for message sending
- Test real-time updates and error states
- Test offline scenarios
- **Deliverable**: Complete UI test coverage

### Step 11: Multi-Device Testing
- Test real-time sync across devices
- Verify message delivery latency
- Test concurrent messaging scenarios
- **Deliverable**: Multi-device sync verification

### Step 12: Performance & Final Testing
- Performance testing with real-time updates
- Memory leak testing and optimization
- Final acceptance gate verification
- **Deliverable**: Production-ready real-time messaging

**Total**: 12 sequential steps with specific deliverables

---

**End of PRD**
