# Agent A — UI/UX Polish & Essential Features

---

## 🎯 What It Is

Complete essential UI/UX features and reliability fixes to transform the MVP into a production-ready messaging app. Focus on presence reliability, clear message status feedback, image messaging, user control, and attention management with Calm Intelligence principles throughout.

---

## 📊 Feature Overview

| Category | Focus | Priority | Status |
|----------|-------|----------|--------|
| Phase 1 | Critical Fixes & Media | P0 | 🔄 IN PROGRESS |
| Phase 2 | User Control & Polish | P1 | ⏳ PLANNED |
| **TOTAL** | **6 Feature Groups** | | **Target: Production Ready** |

---

## 🚀 Phase 1: Critical Fixes & Media Features (P0)

**Goal:** Fix reliability issues and add essential image messaging  
**Status:** 🔄 IN PROGRESS  
**Why now:** MVP is complete but has known reliability gaps and lacks core media features

### 3 Core Categories

#### 1.1 Presence Indicator Reliability
**Problem:** Presence indicators sometimes don't update or show incorrect status

- Fix propagation to 100% reliability, < 500ms update time
- Add retry logic with exponential backoff (max 3 attempts)
- Connection health monitoring with fallback to lastSeen
- Smooth fade animations for online ↔ offline transitions
- Works in conversation list, chat header, and group member list
- Survives app state transitions (background → terminated → foreground)

**Key metric:** 100% accuracy, < 500ms propagation

#### 1.2 Failed/Queued Message UI
**Problem:** Unclear visual feedback when messages fail or queue offline

- **Failed messages:**
  - Red exclamation icon (clear but not alarming)
  - "Tap to retry" text prominently displayed
  - Auto-retry when network restored
  
- **Queued messages:**
  - Orange clock icon
  - "Sending when online" text
  - Queue count in chat header ("3 messages queued")
  - Batch retry for multiple messages
  
- **Visual distinction:**
  - Red vs orange clear at a glance
  - Smooth status transition animations
  - Calm Intelligence: Informative, not aggressive

**Key metric:** Clear status within 100ms, auto-retry success > 95%

#### 1.3 Image Messaging
**Problem:** Users cannot share images (table-stakes messaging feature)

- Firebase Storage integration with CDN delivery
- Camera + photo library selection (PHPickerViewController)
- Image preview before sending with cancel option
- Compression to < 2MB before upload
- Gentle progress indicator during upload
- Display in bubbles with proper aspect ratio
- Tap for fullscreen with pinch-to-zoom
- Offline queueing → auto-upload on reconnect
- Lazy loading for 60 FPS scrolling performance
- Failed upload → retry button with clear error

**Key metric:** < 3s send-to-display time, < 5s upload for 2MB image

### Key Deliverables
- PresenceService reliability fixes with unit tests
- Enhanced MessageStatusIndicatorView with clear states
- ImageUploadService with compression and retry
- ImageMessageView with fullscreen support
- Image picker integration complete
- All features work offline with proper queueing
- Performance targets met (60 FPS scrolling with images)

---

## 🎨 Phase 2: User Control & Polish (P1)

**Goal:** Give users control and attention management tools  
**Status:** ⏳ PLANNED  
**Why now:** Production readiness requires deletion, unread tracking, and polished group features

### 3 Polish Categories

#### 2.1 Message Deletion
**Problem:** Users have no control to delete sent messages

- Long-press on own message → "Delete" option
- Gentle confirmation dialog (not scary warning)
- Soft delete (mark `isDeleted = true` for audit trail)
- "Message deleted" placeholder in bubble
- Optimistic UI removes immediately
- Queues offline, syncs across devices
- Only sender can delete (serverside validation)
- Optional: Undo within 5 seconds

**Key metric:** Optimistic UI < 50ms, sync success > 99%

#### 2.2 Unread Badge Counts
**Problem:** Users can't prioritize conversations or know what needs attention

- Badge on conversation rows with count ("3" or "99+")
- Blue/green badges (Calm Intelligence: not red/urgent)
- Real-time updates < 100ms when message arrives
- Clears when user opens conversation
- Persists across app restarts
- Total unread count on app icon badge
- Firestore transactions for consistency
- Efficient queries < 50ms

**Key metric:** < 100ms update time, 100% accuracy

#### 2.3 Timestamp & Group Presence Polish
**Problem:** Missing timestamp details and group online visibility

- **Timestamps:**
  - Relative by default ("5m ago", "1h ago")
  - Long-press reveals exact timestamp
  - Date separators for multi-day ("Today", "Yesterday", "Monday")
  - Server time for accuracy
  
- **Group presence:**
  - Header shows online count ("3 of 5 online")
  - Real-time updates < 500ms
  - Member list sorted: online at top
  - Smooth animations for status changes
  - Optional: Last seen timestamps for offline members

**Key metric:** < 500ms presence updates, smooth 60 FPS animations

### Key Deliverables
- MessageService.deleteMessage() with unit tests
- ChatService unread count methods with unit tests
- UnreadBadgeView component
- Chat model unread tracking with transactions
- Timestamp enhancements complete
- Group presence polish complete
- All UI tests passing (XCUITest)
- Documentation updated

---

## 🧘 Calm Intelligence Integration

**Four Core Principles Applied:**

### 1. Silence by Design
- Failed message UI: Red exclamation (clear) not aggressive alerts
- Queue status: Gentle "Sending when online" not alarming banners
- Progress indicators: Subtle, not attention-demanding

### 2. Ambient Reassurance
- Presence indicators: Smooth transitions, not jarring updates
- Unread badges: Blue/green (calming) not red (urgent)
- Deletion confirmation: Gentle dialog, not scary warning

### 3. Adaptive Prioritization
- Queue count in header: Informative, not distracting
- Image loading: Lazy, respects user's scroll behavior
- Retry options: Available but not pushy

### 4. Transparency-First
- Clear message states: Failed/Queued/Delivered with explanations
- Image upload progress: Visible without blocking
- Deletion feedback: Clear confirmation of action

**Reference:** See `MessageAI/docs/calm-intelligence-vision.md` for full philosophy

---

## 📊 Success Metrics

### User-Visible
- ✅ Presence shows correct status 100% of the time
- ✅ Failed/queued messages clearly distinguishable
- ✅ Image messages send and display within 3 seconds
- ✅ Message deletion instant with optimistic UI
- ✅ Unread badges update in real-time (< 100ms)
- ✅ All interactions maintain 60 FPS

### System Performance
- Presence propagation < 500ms
- Image upload < 5s for 2MB image
- Unread count queries < 50ms
- Optimistic UI response < 50ms
- 60 FPS scrolling with images (lazy loading)
- No memory leaks from image caching

### Quality
- 0 blocking bugs
- All features work offline with proper queueing
- Comprehensive test coverage (Swift Testing + XCUITest)
- Follows Calm Intelligence principles
- Crash-free rate > 99%

---

## 🔧 Technical Implementation

### Data Model Changes

**Message Model Extensions:**
```swift
struct Message {
    // NEW: Media support
    var mediaType: MessageMediaType? = nil
    var mediaURL: String? = nil
    var thumbnailURL: String? = nil
    var mediaMetadata: MediaMetadata? = nil
    
    // NEW: Deletion support
    var isDeleted: Bool = false
    var deletedAt: Date? = nil
    var deletedBy: String? = nil
}
```

**Chat Model Extensions:**
```swift
struct Chat {
    // NEW: Unread tracking
    var unreadCount: [String: Int] = [:]
    var lastReadTimestamp: [String: Date] = [:]
}
```

### New Services

- `ImageUploadService.swift` — Firebase Storage uploads with compression
- `Services/PresenceService.swift` — Enhanced reliability with retry logic
- `Services/MessageService.swift` — Extensions for deletion and images
- `Services/ChatService.swift` — Unread count tracking with transactions

### New UI Components

- `ImageMessageView.swift` — Display images in bubbles
- `ImagePickerView.swift` — Camera/gallery selection
- `ImagePreviewView.swift` — Preview before sending
- `UnreadBadgeView.swift` — Reusable badge component
- `TimestampSeparatorView.swift` — Date separators
- `FailedMessageRetryView.swift` — Retry UI for failures

### Modified Components

- `PresenceIndicator.swift` — Smooth animations, improved visibility
- `MessageStatusIndicatorView.swift` — Clear failed/queued distinction
- `MessageRowView.swift` — Long-press menu, image display
- `ConversationRowView.swift` — Unread badge integration
- `ChatView.swift` — Queue count header, image picker
- `GroupMemberListView.swift` — Online count, sorted list

---

## ✅ Acceptance Gates

### Phase 1: Must Pass Before Phase 2

**Presence:**
- [ ] Updates within 500ms for online/offline changes
- [ ] Shows correctly in conversation list and chat header
- [ ] Survives app state transitions
- [ ] No stuck or incorrect states

**Failed/Queued:**
- [ ] Red exclamation + "Tap to retry" for failures
- [ ] Orange clock + "Sending when online" for queued
- [ ] Auto-retry when back online
- [ ] Queue count in header

**Images:**
- [ ] < 3s send-to-display time
- [ ] Compression < 2MB before upload
- [ ] Fullscreen with pinch-to-zoom
- [ ] 60 FPS scrolling with images
- [ ] Offline queueing works

### Phase 2: Production Ready Gates

**Deletion:**
- [ ] Long-press shows "Delete" for own messages only
- [ ] Optimistic UI < 50ms
- [ ] Syncs across devices
- [ ] Works offline

**Unread Badges:**
- [ ] Updates < 100ms when message arrives
- [ ] Blue/green (not red)
- [ ] Persists across restarts
- [ ] Clears when chat opened

**Timestamps & Group:**
- [ ] Long-press reveals exact time
- [ ] Date separators for multi-day
- [ ] "X of Y online" in group header
- [ ] Member list sorted by status

---

## 🎯 Quick Summary

### What This Solves
- **Reliability:** 100% accurate presence, clear message status
- **Core Features:** Image messaging (table-stakes)
- **User Control:** Delete messages, see unread counts
- **Polish:** Timestamps, group visibility, smooth animations
- **Philosophy:** Calm Intelligence throughout (gentle, transparent, helpful)

### What's Out of Scope
- ❌ Video messaging (future)
- ❌ Audio messages (future)
- ❌ Message editing (future)
- ❌ Message reactions (future)
- ❌ GIFs/stickers (future)
- ❌ @mentions styling (future)

### Target Outcome
**Production-ready messaging app** with professional polish, essential features, and Calm Intelligence principles integrated throughout.

---

## 📋 Evidence & Validation

**Manual Testing:**
- Multi-device presence testing (3+ devices)
- Image upload with various network conditions
- Message deletion in group chats
- Unread badge persistence across app restarts
- Failed message retry flow

**Automated Testing:**
- Unit tests (Swift Testing) for all services
- UI tests (XCUITest) for all flows
- Performance tests (PerformanceMonitor)

**Metrics Collection:**
- Presence propagation latency
- Image upload success rate and time
- Message deletion rate
- Unread badge accuracy
- Queue retry success rate

**Documentation:**
- Screenshots of all UI states
- Before/after comparisons
- Performance metrics
- Test results

---

## 📌 Reference Documents

- **PR Brief:** `MessageAI/docs/pr-brief/agent-a-ui-features-brief.md`
- **Shared Standards:** `MessageAI/agents/shared-standards.md`
- **Calm Intelligence:** `MessageAI/docs/calm-intelligence-vision.md`
- **Phase 2 Context:** `MessageAI/docs/prd-full-features.md` (Flow A)
- **Sprint Plan:** `MessageAI/docs/sprints/tomorrow-night-sprint-plan.md`

---

## 🔐 Security & Validation

**Firebase Security Rules:**
- Storage: Authenticated users only, upload to own chat paths
- Firestore: Message deletion only by sender (validate `request.auth.uid == resource.data.senderID`)
- Firestore: Unread counts writable only via transaction or by user

**Validation Rules:**
- Images < 2MB after compression
- Unread counts non-negative integers
- Only sender can delete messages (serverside check)

**Indexing:**
- Composite index: `(chatID, isDeleted, timestamp)`
- Storage path: `messages/{chatID}/{messageID}/{filename}`
- Unread counts via Firestore transactions

