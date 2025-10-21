# PRD: Chat View Screen & Message Display

**Feature**: Chat View Screen & Message Display

**Version**: 1.0

**Status**: COMPLETED

**Agent**: Pete

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief #5](../pr-brief/pr-briefs.md#pr-5-chat-view-screen--message-display)

---

## 1. Summary

Build the chat view screen that displays messages in a conversation with proper message bubbles, scrolling, and layout. This PR implements the core chat interface where users view and interact with messages, including message timestamps and basic message status indicators.

---

## 2. Problem & Goals

**Problem**: Users need a dedicated screen to view and interact with messages in a conversation, with proper message layout and real-time updates.

**Why Now**: Foundation for PR #6 (Real-Time Messaging) and PR #7 (Optimistic UI). Depends on PR #4 (Conversation List).

**Goals**:
- [ ] Display messages in conversation with proper bubble layout
- [ ] Show message timestamps and sender information
- [ ] Implement smooth scrolling with proper message ordering
- [ ] Handle different message states (sent, delivered, read)
- [ ] Support both 1-on-1 and group chat layouts
- [ ] Provide visual feedback for message status

---

## 3. Non-Goals

- Sending messages (PR #6)
- Real-time message updates (PR #6)
- Message read receipts (PR #12)
- Message input field (PR #6)
- Message editing/deletion (future)
- Message reactions (future)
- Media message support (future)

---

## 4. Users & Stories

**Primary User**: Active messaging user who needs to view conversation history and message details

**User Stories**:
- As a user, I want to see all messages in a conversation so I can follow the conversation flow
- As a user, I want to see who sent each message so I can understand the conversation context
- As a user, I want to see when each message was sent so I can understand the timing
- As a user, I want messages to be clearly separated (bubbles) so I can easily read them
- As a user, I want to scroll through message history so I can see older messages
- As a user, I want to see the status of my sent messages so I know if they were delivered

---

## 5. Success Metrics

**Performance**:
- Message display: < 100ms for 50 messages
- Smooth 60fps scrolling with 200+ messages
- Memory usage: < 50MB for 500 messages

**Quality**:
- All acceptance gates pass
- Test coverage > 80%
- Zero UI glitches during scrolling

---

## 6. Experience Specification

**Chat View Screen**:
- Title: Other user's name (1-on-1) or group name
- Navigation: Back button to conversation list
- Message area: ScrollView with LazyVStack for performance
- Message bubbles: Rounded rectangles with proper spacing
- Timestamps: Subtle, non-intrusive display
- Status indicators: Small icons for message states

**Message Layout**:
- Sent messages: Right-aligned, blue bubbles
- Received messages: Left-aligned, gray bubbles
- Group chats: Show sender name above message
- Timestamps: Relative format ("2m ago", "Yesterday")
- Status: "Sent", "Delivered", "Read" indicators

**Empty State**: "No messages yet" with friendly icon

**Loading State**: Skeleton message bubbles

**Error State**: "Unable to load messages" with retry button

---

## 7. Data Model

### Message Model (Extended)

```swift
struct Message: Codable, Identifiable, Equatable {
    let id: String
    let chatID: String
    let senderID: String
    var text: String
    var timestamp: Date
    var readBy: [String]
    var status: MessageStatus
    var senderName: String?  // For group chats
}

enum MessageStatus: String, Codable, CaseIterable {
    case sending = "sending"
    case sent = "sent"
    case delivered = "delivered"
    case read = "read"
    case failed = "failed"
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
  "readBy": ["user789", "user101"],
  "status": "delivered",
  "senderName": "John Doe"
}
```

### Chat Model (Referenced)

```swift
struct Chat: Codable, Identifiable {
    let id: String
    var members: [String]
    var isGroupChat: Bool
    var groupName: String?  // For group chats
}
```

### Query

```swift
db.collection("chats/{chatID}/messages")
  .order(by: "timestamp", descending: false)
  .limit(to: 50)  // Pagination for performance
```

---

## 8. Service & ViewModel

### MessageService

```swift
class MessageService {
    func fetchMessages(chatID: String, limit: Int) async throws -> [Message]
    func observeMessages(chatID: String,
                        completion: @escaping ([Message]) -> Void) -> ListenerRegistration
    func fetchMessage(messageID: String) async throws -> Message
    func markMessageAsRead(messageID: String, userID: String) async throws
}

enum MessageServiceError: LocalizedError {
    case messageNotFound, permissionDenied, networkError, unknown(Error)
}
```

### ChatViewModel

```swift
@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var chat: Chat?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentUserID: String
    
    private var listener: ListenerRegistration?
    
    func loadMessages(chatID: String) async
    func observeMessagesRealTime(chatID: String)
    func stopObserving()
    func markMessageAsRead(messageID: String)
    func formatTimestamp(date: Date) -> String
    func getMessageStatus(message: Message) -> MessageStatus
}
```

---

## 9. UI Components

### MessageRowView

- Displays individual message with bubble layout
- Handles sent vs received message styling
- Shows timestamp and status indicators
- Supports group chat sender names
- Handles message truncation and line breaks

### ChatView

- Main chat screen with ScrollView and LazyVStack
- Navigation header with chat title
- Message list with proper spacing
- Loading/Empty/Error states
- Scroll-to-bottom functionality

### MessageBubbleView

- Reusable bubble component
- Sent (blue) vs received (gray) styling
- Rounded corners and proper padding
- Text wrapping and truncation
- Status indicator integration

### TimestampView

- Relative timestamp display
- Subtle styling that doesn't interfere with reading
- Smart grouping (same minute messages)
- Date separators for different days

---

## 10. Integration Points

- Firebase Authentication (current user)
- Firestore (message data)
- Real-time listeners (message updates)
- State management (SwiftUI patterns)
- Navigation (from conversation list)

---

## 11. Test Plan & Acceptance Gates

**Happy Path**:
- [ ] Messages display in correct order
- [ ] Sent messages show on right, received on left
- [ ] Timestamps display correctly
- [ ] Status indicators show appropriate states
- [ ] Smooth scrolling through message history

**Edge Cases**:
- [ ] Empty conversation shows empty state
- [ ] Long messages wrap properly
- [ ] Very long conversations scroll smoothly
- [ ] Network errors show retry option
- [ ] Invalid message data handled gracefully

**Multi-User**:
- [ ] Group chat shows sender names
- [ ] Message status updates correctly
- [ ] Real-time updates don't cause UI flicker
- [ ] Concurrent message updates handled

**Performance**:
- [ ] 200+ messages scroll at 60fps
- [ ] Memory usage stays under 50MB
- [ ] Message loading completes in < 100ms
- [ ] No memory leaks from listeners

---

## 12. Definition of Done

- [ ] MessageService implemented + unit tests (Swift Testing)
- [ ] ChatViewModel with state management
- [ ] SwiftUI views with all states (loading, empty, error, success)
- [ ] Message bubble layout working correctly
- [ ] Timestamp formatting implemented
- [ ] Status indicators functional
- [ ] UI tests pass (XCTest)
- [ ] Performance targets met
- [ ] All acceptance gates pass
- [ ] Code follows shared-standards.md patterns

---

## 13. Risks & Mitigations

**Risk 1: Performance degradation with large message history**
- **Impact**: Slow scrolling, poor user experience
- **Mitigation**: Implement pagination, lazy loading, and message virtualization
- **Monitoring**: Track scroll performance with 500+ messages

**Risk 2: Memory leaks from message listeners**
- **Impact**: App crashes, poor performance over time
- **Mitigation**: Proper cleanup in `.onDisappear`, use weak references
- **Monitoring**: Memory profiling during development

**Risk 3: Message ordering issues with concurrent updates**
- **Impact**: Messages appear out of order, confusing interface
- **Mitigation**: Use server timestamps, implement proper sorting logic
- **Monitoring**: Test with multiple simultaneous message updates

**Risk 4: UI flicker during real-time updates**
- **Impact**: Poor user experience, distracting interface
- **Mitigation**: Implement smooth animations, debounce updates
- **Monitoring**: Test real-time update scenarios

**Risk 5: Message bubble layout breaking with long text**
- **Impact**: Poor readability, broken UI layout
- **Mitigation**: Implement proper text wrapping, max width constraints
- **Monitoring**: Test with various message lengths and content

---

## 14. Dependencies

**Depends On**: PR #4 (Conversation List)

**Required For**: PR #6 (Real-Time Messaging), PR #7 (Optimistic UI)

---

## 15. Security Rules

```javascript
match /chats/{chatID}/messages/{messageID} {
  allow read: if isAuthenticated() && isMember(chatID);
  allow create, update: if false;  // PR #6
}
```

---

## 16. Implementation Plan

### Step 1: Data Models
- Extend Message model with status and sender information
- Define MessageStatus enum with all states
- Update Firestore schema documentation
- **Deliverable**: Complete data models ready for service layer

### Step 2: MessageService Implementation
- Implement MessageService with async/await methods
- Add fetchMessages, observeMessages, markMessageAsRead methods
- Implement proper error handling and edge cases
- **Deliverable**: Complete service layer with error handling

### Step 3: Service Layer Testing
- Write unit tests (Swift Testing) for MessageService methods
- Test error scenarios, edge cases, and performance
- **Deliverable**: Complete test coverage for service layer

### Step 4: ChatViewModel
- Build ChatViewModel with @Published properties
- Implement loadMessages, observeMessagesRealTime, stopObserving methods
- Add message status and timestamp formatting logic
- **Deliverable**: Working ViewModel with state management

### Step 5: Message Bubble Components
- Create MessageBubbleView with sent/received styling
- Implement proper text wrapping and layout
- Add status indicator integration
- **Deliverable**: Reusable message bubble component

### Step 6: Message Row Component
- Create MessageRowView with bubble layout
- Implement group chat sender name display
- Add timestamp and status integration
- **Deliverable**: Complete message row component

### Step 7: Chat View Screen
- Build ChatView with ScrollView and LazyVStack
- Implement navigation header and chat title
- Add loading, empty, and error states
- **Deliverable**: Complete chat screen with all states

### Step 8: Real-Time Integration
- Implement real-time Firestore listeners
- Add proper cleanup and memory management
- Handle concurrent message updates
- **Deliverable**: Real-time message updates with proper resource management

### Step 9: Performance Optimization
- Implement message pagination and lazy loading
- Add scroll performance optimizations
- Test with large message histories
- **Deliverable**: Optimized performance for 200+ messages

### Step 10: UI Testing
- Write UI tests (XCTest) for message display and interactions
- Test scrolling, message layout, and state changes
- **Deliverable**: Complete UI test coverage

### Step 11: Integration Testing
- Test navigation from conversation list
- Verify message display with real data
- Test group chat vs 1-on-1 chat layouts
- **Deliverable**: Complete integration with existing app

### Step 12: Performance & Final Testing
- Performance testing with 500+ messages
- Memory leak testing and optimization
- Final acceptance gate verification
- **Deliverable**: Production-ready chat view with performance targets met

**Total**: 12 sequential steps with specific deliverables

---

**End of PRD**
