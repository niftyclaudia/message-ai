# PRD: Conversation List Screen

**Feature**: Conversation List Home Screen

**Version**: 1.0

**Status**: Draft

**Agent**: Pete

**Target Release**: Phase 2 - 1-on-1 Chat

**Links**: [PR Brief #4](../pr-brief/pr-briefs.md#pr-4-conversation-list-screen)

---

## 1. Summary

Build the conversation list screen that displays all existing chats with the most recent message, timestamps, and online/offline status of other users. This is the home screen users see when opening the app, with real-time Firestore updates when new messages arrive.

---

## 2. Problem & Goals

**Problem**: Users need a centralized view of all conversations, sorted by recent activity, to quickly access chats.

**Why Now**: Foundation for PR #5 (Chat View) and PR #6 (Messaging). Depends on PR #1-3.

**Goals**:
- [ ] Display list of conversations sorted by most recent message
- [ ] Show last message preview, timestamp, and sender
- [ ] Real-time updates when new messages arrive
- [ ] Display user avatars and names for 1-on-1 chats
- [ ] Handle empty state gracefully

---

## 3. Non-Goals

- Creating conversations (PR #9)
- Sending/receiving messages (PR #6)
- Group chat UI (PR #10)
- Unread counts (PR #12)
- Search/filter, swipe actions (future)

---

## 4. Users & Stories

**Primary User**: Active messaging user who needs quick access to conversations

**User Stories**:
- As a user, I want to see all my conversations sorted by most recent activity so I can quickly find the chat I want
- As a user, I want to see the last message preview so I can remember what we were talking about
- As a user, I want to see when the last message was sent so I know how recent the conversation is
- As a user, I want to see the other person's avatar and name so I can easily identify who I'm chatting with
- As a user, I want the list to update in real-time so I see new messages immediately without refreshing

---

## 5. Success Metrics

**Performance**:
- List load: < 1s for 100 chats
- Real-time sync: < 100ms
- Smooth 60fps scrolling

**Quality**:
- All acceptance gates pass
- Test coverage > 80%

---

## 5. Experience Specification

**Conversation List**:
- Title: "Chats", logout button (top right)
- Each row: 40pt avatar, name, last message preview, timestamp
- "You: " prefix if current user sent last message
- Sorted by `lastMessageTimestamp` descending
- Tap row → Navigate to ChatView (placeholder for PR #5)

**Empty State**: "No conversations yet" with icon

**Loading State**: Full-screen spinner

**Timestamp Format**: "5m", "2h", "Yesterday", "Jan 15"

---

## 6. Data Model

### Chat Model

```swift
struct Chat: Codable, Identifiable, Equatable {
    let id: String
    var members: [String]               // User IDs
    var lastMessage: String
    var lastMessageTimestamp: Date
    var lastMessageSenderID: String
    var isGroupChat: Bool
    var createdAt: Date

    func getOtherUserID(currentUserID: String) -> String?
}
```

**Firestore Collection**: `chats`

**Example**:
```json
{
  "id": "chat123",
  "members": ["user1", "user2"],
  "lastMessage": "See you tomorrow!",
  "lastMessageTimestamp": Timestamp,
  "lastMessageSenderID": "user2",
  "isGroupChat": false,
  "createdAt": Timestamp
}
```

### Message Model (Minimal for this PR)

```swift
struct Message: Codable, Identifiable {
    let id: String
    let chatID: String
    let senderID: String
    var text: String
    var timestamp: Date
    var readBy: [String]
}
```

**Firestore Collection**: `messages` (fully used in PR #6)

### Query

```swift
db.collection("chats")
  .whereField("members", arrayContains: currentUserID)
  .order(by: "lastMessageTimestamp", descending: true)
```

---

## 7. Service & ViewModel

### ChatService

```swift
class ChatService {
    func fetchUserChats(userID: String) async throws -> [Chat]
    func observeUserChats(userID: String,
                         completion: @escaping ([Chat]) -> Void) -> ListenerRegistration
    func fetchChat(chatID: String) async throws -> Chat
}

enum ChatServiceError: LocalizedError {
    case chatNotFound, permissionDenied, networkError, unknown(Error)
}
```

### ConversationListViewModel

```swift
@MainActor
class ConversationListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var chatUsers: [String: User] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var listener: ListenerRegistration?

    func loadChats() async
    func observeChatsRealTime()
    func stopObserving()
    func getOtherUser(chat: Chat) -> User?
    func formatTimestamp(date: Date) -> String
}
```

---

## 8. UI Components

### ConversationRowView

- Reuses `AvatarView` (40pt)
- Displays: avatar | name + message preview (vertical) | timestamp
- Truncates long messages with "..."
- "You: " prefix for current user's messages

### ConversationListView

- NavigationStack with "Chats" title
- LazyVStack for performance
- Loading/Empty/Error states
- `.task { }` for initial load
- `.onDisappear { }` for listener cleanup
- Replaces `EmptyStateView` in `MainTabView`

---

## 9. Acceptance Gates

**Display**:
- [Gate] List loads in < 1s
- [Gate] Empty state shows when no chats
- [Gate] Shows other user's avatar and name
- [Gate] "You: " prefix for own messages
- [Gate] Long messages truncated
- [Gate] Timestamps formatted correctly

**Real-Time**:
- [Gate] New message → Row updates < 100ms, moves to top
- [Gate] Profile photo update → Avatar updates
- [Gate] Listener cleans up on disappear

**Performance**:
- [Gate] 100+ chats → Smooth 60fps scroll
- [Gate] No memory leaks

---

## 10. Implementation Plan

### Step 1: Data Models
- Create Chat and Message models with proper Codable conformance
- Define Firestore collection structure and security rules
- **Deliverable**: Complete data models ready for service layer

### Step 2: ChatService Implementation
- Implement ChatService with async/await methods and error handling
- Add fetchUserChats, observeUserChats, fetchChat methods
- **Deliverable**: Complete service layer with proper error handling

### Step 3: Service Layer Testing
- Write unit tests (Swift Testing) for ChatService methods
- Test error scenarios and edge cases
- **Deliverable**: Complete test coverage for service layer

### Step 4: ConversationListViewModel
- Build ConversationListViewModel with @Published properties
- Implement loadChats, observeChatsRealTime, stopObserving methods
- **Deliverable**: Working ViewModel with state management

### Step 5: Real-Time Listeners
- Implement real-time Firestore listeners with proper cleanup
- Add memory management and listener lifecycle handling
- **Deliverable**: Real-time updates with proper resource management

### Step 6: ViewModel Testing
- Write unit tests (Swift Testing) for ConversationListViewModel logic
- Test real-time updates and state changes
- **Deliverable**: Complete ViewModel test coverage

### Step 7: ConversationRowView
- Create ConversationRowView with avatar, name, message preview, timestamp
- Implement "You: " prefix logic and message truncation
- **Deliverable**: Reusable row component with proper layout

### Step 8: ConversationListView
- Build ConversationListView with LazyVStack and state handling
- Add loading, empty, and error states
- **Deliverable**: Complete list view with all states

### Step 9: MainTabView Integration
- Integrate ConversationListView into MainTabView
- Replace EmptyStateView with ConversationListView
- **Deliverable**: Integrated conversation list in main app

### Step 10: Navigation & States
- Implement navigation to ChatView placeholder
- Add proper empty/loading/error state handling
- **Deliverable**: Complete user flow with navigation

### Step 11: UI Testing
- Write UI tests (XCTest) for user interactions and navigation flows
- Test conversation list interactions and state changes
- **Deliverable**: Complete UI test coverage

### Step 12: Performance & Final Testing
- Performance testing with 100+ chats, real-time sync verification
- Memory leak testing and optimization
- **Deliverable**: Production-ready conversation list with performance targets met

**Total**: 12 sequential steps with specific deliverables

---

## 11. Risks & Mitigations

**Risk 1: Real-time listener performance with 100+ chats**
- **Impact**: Slow UI updates, poor user experience
- **Mitigation**: Implement pagination, lazy loading, and listener optimization
- **Monitoring**: Track listener response times and memory usage

**Risk 2: Memory leaks from uncleaned listeners**
- **Impact**: App crashes, poor performance over time
- **Mitigation**: Proper cleanup in `.onDisappear`, use weak references
- **Monitoring**: Memory profiling during development

**Risk 3: Firebase query performance degradation**
- **Impact**: Slow list loading, timeout errors
- **Mitigation**: Optimize Firestore indexes, implement query caching
- **Monitoring**: Track query execution times and error rates

**Risk 4: Concurrent message updates causing UI flicker**
- **Impact**: Poor user experience, confusing interface
- **Mitigation**: Implement proper state management, debounce updates
- **Monitoring**: Test with multiple simultaneous message updates

**Risk 5: Offline behavior breaking real-time expectations**
- **Impact**: Users expect updates but see stale data
- **Mitigation**: Clear offline indicators, queue updates for when online
- **Monitoring**: Test offline/online transitions thoroughly

---

## 12. Dependencies

**Depends On**: PR #1 (Firebase), PR #2 (Navigation), PR #3 (User Profiles)

**Required For**: PR #5 (Chat View), PR #6 (Messaging)

---

## 13. Security Rules

```javascript
match /chats/{chatID} {
  allow read: if isAuthenticated() && isMember(chatID);
  allow create, update: if false;  // PR #6 and PR #9
}
```

---

**End of PRD**
