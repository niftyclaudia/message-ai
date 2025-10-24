# Agent A — UI/UX Polish & Essential Features PR Brief

---

## Overview

Agent A focuses on transforming the MVP into a production-ready messaging app by addressing critical reliability issues, adding essential media features, and implementing professional polish throughout. This initiative applies Calm Intelligence principles to every user interaction while ensuring 100% reliability and seamless offline functionality.

**Status:** 🔄 READY FOR IMPLEMENTATION  
**Target Outcome:** Production-ready app with professional polish and essential features

---

## PR Breakdown

Agent A is broken down into **6 individual feature PRs** for maximum flexibility and incremental delivery.

---

## Phase 1: Critical Fixes & Media (P0)

### PR #20: Presence Indicator Reliability

**Brief:** Fix presence indicator propagation to achieve 100% reliability and <500ms update time. Implement retry logic with exponential backoff (max 3 attempts), connection health monitoring with fallback to lastSeen, and smooth fade animations for online ↔ offline transitions. Ensure presence works correctly in conversation list, chat header, and group member list, and survives app state transitions from background to terminated to foreground. This PR addresses the critical reliability issue where presence indicators sometimes don't update or show incorrect status, transforming them into a reliable real-time feature.

**Dependencies:** None (builds on existing MVP)

**Complexity:** Medium

**Phase:** 1 (P0)

**Key Deliverables:**
- PresenceService reliability fixes with retry logic
- Exponential backoff implementation (max 3 attempts)
- Connection health monitoring system
- Fallback to lastSeen when real-time unavailable
- Smooth fade animations for status transitions
- Works across conversation list, chat header, group member list
- Survives all app state transitions
- Unit tests for PresenceService reliability

**Success Metrics:**
- 100% accuracy in presence status
- <500ms propagation time
- Zero stuck or incorrect states
- Survives background → terminated → foreground cycle

---

### PR #21: Failed/Queued Message UI

**Brief:** Implement clear visual feedback for failed and queued messages with automatic retry functionality. Add red exclamation icon with "Tap to retry" text for failed messages, orange clock icon with "Sending when online" text for queued messages, and queue count in chat header ("3 messages queued"). Include auto-retry when network is restored, batch retry for multiple messages, and smooth status transition animations. This PR solves the problem of unclear visual feedback when messages fail or queue offline, following Calm Intelligence principles with informative but not aggressive status indicators.

**Dependencies:** None

**Complexity:** Medium

**Phase:** 1 (P0)

**Key Deliverables:**
- Enhanced MessageStatusIndicatorView with three states: sent, failed, queued
- Failed state: Red exclamation + "Tap to retry" text
- Queued state: Orange clock + "Sending when online" text
- Queue count badge in chat header
- Auto-retry logic when network restored
- Batch retry for multiple queued messages
- Smooth status transition animations
- Clear visual distinction (red vs orange)
- Unit tests for retry logic and state management

**Success Metrics:**
- Clear status indication within 100ms
- Auto-retry success rate >95%
- Visual distinction clear at a glance
- Smooth animations (60 FPS)

---

### PR #22: Image Messaging

**Brief:** Implement complete image messaging functionality with Firebase Storage integration, compression, and offline queueing. Add camera and photo library selection using PHPickerViewController, image preview before sending with cancel option, automatic compression to <2MB before upload, gentle progress indicator during upload, and display in bubbles with proper aspect ratio. Include tap for fullscreen with pinch-to-zoom, lazy loading for 60 FPS scrolling performance, and failed upload retry with clear error messages. This PR adds table-stakes image messaging capabilities that transform the MVP into a complete messaging platform.

**Dependencies:** PR #21 (for failed/queued UI states)

**Complexity:** Complex

**Phase:** 1 (P0)

**Key Deliverables:**
- Firebase Storage integration with CDN delivery
- ImageUploadService with compression and retry logic
- Camera + photo library picker (PHPickerViewController)
- ImagePreviewView for pre-send confirmation
- Automatic compression to <2MB
- ImageMessageView with proper aspect ratio display
- Fullscreen view with pinch-to-zoom gesture
- Gentle progress indicator during upload
- Lazy loading for scroll performance
- Offline queueing with auto-upload on reconnect
- Failed upload retry button with clear errors
- Unit tests for ImageUploadService
- UI tests for complete image flow

**Success Metrics:**
- <3s send-to-display time on good connection
- <5s upload time for 2MB image
- 60 FPS scrolling with images loaded
- Compression always <2MB
- Offline queueing works 100% of the time

---

## Phase 2: User Control & Polish (P1)

### PR #23: Message Deletion

**Brief:** Implement message deletion with soft-delete audit trail and optimistic UI. Add long-press on own messages to show "Delete" option, gentle confirmation dialog that's not scary, soft delete that marks isDeleted=true for audit trail, and "Message deleted" placeholder in bubble. Include optimistic UI that removes immediately, offline queueing that syncs on reconnect, serverside validation that only sender can delete, and optional 5-second undo window. This PR gives users essential control over their messages while maintaining audit trails and following Calm Intelligence principles with gentle confirmations.

**Dependencies:** None

**Complexity:** Medium

**Phase:** 2 (P1)

**Key Deliverables:**
- MessageService.deleteMessage() method with soft-delete logic
- Long-press gesture on MessageRowView for delete option
- Gentle confirmation dialog (not scary warning)
- Soft delete: isDeleted flag + audit trail (deletedAt, deletedBy)
- "Message deleted" placeholder in bubble UI
- Optimistic UI removes message immediately
- Offline queueing with sync on reconnect
- Serverside validation (only sender can delete)
- Optional: 5-second undo window
- Syncs across all devices
- Unit tests for MessageService deletion
- UI tests for long-press → confirm → delete flow

**Success Metrics:**
- <50ms optimistic UI response
- >99% sync success across devices
- Serverside validation 100% enforced
- Works offline with proper queueing

---

### PR #24: Unread Badge Counts

**Brief:** Implement real-time unread badge counts with blue/green badges and app icon integration. Add badge on conversation rows with count ("3" or "99+"), use blue/green colors per Calm Intelligence (not red/urgent), real-time updates <100ms when messages arrive, auto-clear when user opens conversation, and persistence across app restarts. Include total unread count on app icon badge, Firestore transactions for consistency, and efficient queries <50ms. This PR solves the problem of users not being able to prioritize conversations or know what needs attention, providing clear attention management with calming color choices.

**Dependencies:** None

**Complexity:** Medium

**Phase:** 2 (P1)

**Key Deliverables:**
- ChatService unread count methods with Firestore transactions
- UnreadBadgeView component with blue/green styling
- Badge integration on ConversationRowView
- Count display: "3" or "99+" for large numbers
- Real-time updates when new message arrives
- Auto-clear when conversation opened
- Persistence across app restarts
- Total unread count on app icon badge (UNUserNotificationCenter)
- Efficient Firestore queries (<50ms)
- Firestore transactions for consistency
- Unit tests for unread count logic
- UI tests for badge display and clearing

**Success Metrics:**
- <100ms update time when message arrives
- 100% accuracy in count
- Blue/green badges (calming, not urgent)
- Persists across app restarts
- Efficient queries <50ms

---

### PR #25: Timestamp & Group Presence Polish

**Brief:** Enhance timestamp displays and group presence indicators with professional polish. Add relative timestamps by default ("5m ago", "1h ago"), long-press to reveal exact timestamp, date separators for multi-day conversations ("Today", "Yesterday", "Monday"), and server time for accuracy. Polish group presence with header showing online count ("3 of 5 online"), real-time updates <500ms, member list sorted with online members at top, smooth animations for status changes, and optional last seen timestamps for offline members. This PR adds professional polish that matches top-tier messaging apps and improves group conversation awareness.

**Dependencies:** PR #20 (uses improved presence system)

**Complexity:** Simple

**Phase:** 2 (P1)

**Key Deliverables:**
- Relative timestamp formatting ("5m ago", "1h ago", "Yesterday")
- Long-press gesture reveals exact timestamp
- TimestampSeparatorView for date breaks
- Server time synchronization for accuracy
- Group header with "X of Y online" count
- Real-time presence updates in group context
- GroupMemberListView sorted: online at top
- Smooth animations for presence changes (60 FPS)
- Optional: Last seen timestamps for offline members
- Unit tests for timestamp formatting
- UI tests for long-press timestamp reveal

**Success Metrics:**
- <500ms presence updates in groups
- Smooth 60 FPS animations
- Accurate server-based timestamps
- Intuitive relative time display
- Clear online/offline member visibility

---

## Calm Intelligence Integration

All features in Agent A strictly follow the four core principles:

### 1. Silence by Design
- Failed message UI: Clear red exclamation, not aggressive alerts
- Queue status: Gentle "Sending when online", not alarming banners
- Progress indicators: Subtle, non-intrusive
- Deletion confirmation: Gentle dialog, not scary warning

### 2. Ambient Reassurance
- Presence: Smooth fade transitions, not jarring updates
- Unread badges: Blue/green (calming), not red (urgent)
- Image loading: Gentle progress indicator
- Queue count: Informative header, not distracting banner

### 3. Adaptive Prioritization
- Auto-retry: Available but not pushy
- Image loading: Lazy, respects scroll behavior
- Queue visibility: Informative when needed
- Deletion undo: Optional 5-second window

### 4. Transparency-First
- Message states: Failed/Queued/Delivered with clear explanations
- Upload progress: Visible without blocking
- Deletion feedback: Clear confirmation
- Queue count: Visible in header when applicable

**Reference:** `MessageAI/docs/calm-intelligence-vision.md`

---

## Technical Implementation Summary

### New Services
- `ImageUploadService.swift` — Firebase Storage with compression and retry
- Enhanced `PresenceService.swift` — Reliability fixes with exponential backoff
- Enhanced `MessageService.swift` — Deletion and image support
- Enhanced `ChatService.swift` — Unread count tracking with transactions

### New UI Components
- `ImageMessageView.swift` — Display images in bubbles
- `ImagePickerView.swift` — Camera/gallery selection
- `ImagePreviewView.swift` — Preview before sending
- `UnreadBadgeView.swift` — Reusable badge component
- `TimestampSeparatorView.swift` — Date separators
- `FailedMessageRetryView.swift` — Retry UI for failures

### Modified Components
- `PresenceIndicator.swift` — Smooth animations, improved visibility
- `MessageStatusIndicatorView.swift` — Clear failed/queued states
- `MessageRowView.swift` — Long-press menu, image display
- `ConversationRowView.swift` — Unread badge integration
- `ChatView.swift` — Queue count header, image picker
- `GroupMemberListView.swift` — Online count, sorted list

### Data Model Changes
```swift
// Message model extensions
var mediaType: MessageMediaType? = nil
var mediaURL: String? = nil
var thumbnailURL: String? = nil
var mediaMetadata: MediaMetadata? = nil
var isDeleted: Bool = false
var deletedAt: Date? = nil
var deletedBy: String? = nil

// Chat model extensions
var unreadCount: [String: Int] = [:]
var lastReadTimestamp: [String: Date] = [:]
```

---

## Testing Strategy

### Manual Testing
- Multi-device presence testing (3+ devices)
- Image upload with various network conditions (WiFi, LTE, offline)
- Message deletion in 1:1 and group chats
- Unread badge persistence across app restarts
- Failed message retry flow with network toggling
- Offline queueing for all features

### Automated Testing
- Unit tests (Swift Testing) for all service methods
- UI tests (XCUITest) for all user flows
- Performance tests for image loading and scrolling
- Integration tests for offline queueing

### Performance Validation
- PerformanceMonitor for all metrics
- 60 FPS verification with image scrolling
- Presence propagation latency measurement
- Image upload time tracking
- Unread count query performance

---

## Security & Validation

### Firebase Security Rules
```javascript
// Storage: Authenticated users only, upload to own chat paths
allow write: if request.auth != null 
  && request.resource.size < 2 * 1024 * 1024;

// Firestore: Message deletion only by sender
allow update: if request.auth.uid == resource.data.senderID;

// Firestore: Unread counts writable only by user or via transaction
allow update: if request.auth.uid in resource.data.participantIDs;
```

### Validation Rules
- Images compressed to <2MB before upload
- Unread counts must be non-negative integers
- Only message sender can delete (serverside validation)
- Presence updates require authentication

### Indexing Requirements
```javascript
// Firestore composite index
{
  collection: "messages",
  fields: [
    { field: "chatID", order: "ASCENDING" },
    { field: "isDeleted", order: "ASCENDING" },
    { field: "timestamp", order: "DESCENDING" }
  ]
}

// Storage path structure
messages/{chatID}/{messageID}/{filename}
```

---

## Acceptance Criteria

### PR #20: Presence Indicator Reliability

- ✅ Updates within 500ms for online/offline changes
- ✅ Shows correctly in conversation list, chat header, and group member list
- ✅ Survives app state transitions (background → terminated → foreground)
- ✅ No stuck or incorrect states (100% accuracy)
- ✅ Retry logic with exponential backoff implemented
- ✅ Fallback to lastSeen when real-time unavailable
- ✅ Smooth fade animations for transitions

### PR #21: Failed/Queued Message UI

- ✅ Red exclamation + "Tap to retry" for failed messages
- ✅ Orange clock + "Sending when online" for queued messages
- ✅ Clear visual distinction (red vs orange)
- ✅ Auto-retry when network restored (>95% success rate)
- ✅ Queue count visible in chat header when applicable
- ✅ Batch retry for multiple messages works
- ✅ Smooth status transition animations (60 FPS)

### PR #22: Image Messaging

- ✅ <3s send-to-display time on good connection
- ✅ <5s upload time for 2MB image
- ✅ Compression to <2MB before upload (100% of the time)
- ✅ Camera and photo library selection works
- ✅ Preview before sending with cancel option
- ✅ Fullscreen view with pinch-to-zoom
- ✅ 60 FPS scrolling with images (lazy loading)
- ✅ Offline queueing works, auto-uploads on reconnect
- ✅ Failed upload retry with clear error messages

### PR #23: Message Deletion

- ✅ Long-press shows "Delete" for own messages only
- ✅ Gentle confirmation dialog (not scary warning)
- ✅ Optimistic UI removes immediately (<50ms)
- ✅ Soft delete with audit trail (isDeleted, deletedAt, deletedBy)
- ✅ "Message deleted" placeholder displays correctly
- ✅ Syncs across devices (>99% success)
- ✅ Works offline, queues for sync
- ✅ Serverside validation enforced (only sender can delete)
- ✅ Optional: 5-second undo window

### PR #24: Unread Badge Counts

- ✅ Updates <100ms when new message arrives
- ✅ Blue/green badges (not red) per Calm Intelligence
- ✅ Count display: "3" or "99+" for large numbers
- ✅ Persists across app restarts (100% accuracy)
- ✅ Clears when user opens conversation
- ✅ Total count on app icon badge
- ✅ Efficient Firestore queries (<50ms)
- ✅ Firestore transactions ensure consistency

### PR #25: Timestamp & Group Presence Polish

- ✅ Relative timestamps by default ("5m ago", "1h ago", "Yesterday")
- ✅ Long-press reveals exact timestamp
- ✅ Date separators for multi-day conversations
- ✅ Server time for accuracy
- ✅ Group header shows "X of Y online"
- ✅ Member list sorted: online at top
- ✅ <500ms presence updates in groups
- ✅ 60 FPS animations for status changes
- ✅ Optional: Last seen timestamps for offline members

---

## Out of Scope

The following features are explicitly **not** included in Agent A:

- ❌ Video messaging (future)
- ❌ Audio messages (future)
- ❌ Message editing (future)
- ❌ Message reactions/emoji (future)
- ❌ GIFs/stickers (future)
- ❌ @mentions styling (future)
- ❌ Link previews (future)
- ❌ File attachments (future)

---

## Reference Documents

- **Full PRD:** `MessageAI/docs/prds/agent-a-ui-features-prd.md`
- **Shared Standards:** `MessageAI/agents/shared-standards.md`
- **Calm Intelligence Philosophy:** `MessageAI/docs/calm-intelligence-vision.md`
- **Sprint Plan:** `MessageAI/docs/sprints/tomorrow-night-sprint-plan.md`
- **Architecture Guide:** `MessageAI/docs/ai-architecture-guide.md`

---

## Implementation Strategy

**Approach:** Implement as **6 individual feature PRs** for maximum flexibility and incremental delivery.

**Sequential Order:**

**Phase 1 (P0 - Critical):**
1. PR #20: Presence Indicator Reliability (2 days)
2. PR #21: Failed/Queued Message UI (2 days)
3. PR #22: Image Messaging (3 days) — *depends on PR #21*

**Phase 2 (P1 - Polish):**
4. PR #23: Message Deletion (2 days) — *can start immediately*
5. PR #24: Unread Badge Counts (2 days) — *can start immediately*
6. PR #25: Timestamp & Group Presence Polish (1-2 days) — *depends on PR #20*

**Total Timeline:** ~12 days sequential, ~8 days with parallel work

**Parallel Opportunities:**
- PR #20 and PR #21 can be done in parallel (no dependencies)
- PR #23 and PR #24 can be done in parallel with each other and with Phase 1 PRs
- PR #22 and PR #25 have dependencies, must be sequential

**Rationale:**
- Each PR is a complete, testable feature
- Clear success metrics for each PR
- Can deploy incrementally as features complete
- Easier code review (smaller PRs)
- Reduces risk with focused changes
- Allows multiple developers to work in parallel
- Can reprioritize mid-stream if needed

**Recommended Workflow:**
- **Week 1:** PR #20 + PR #21 (parallel), then PR #22
- **Week 2:** PR #23 + PR #24 (parallel), then PR #25
- Each PR includes full test coverage before merge
- All PRs merge to `develop` branch

---

**Created by:** Brad Agent (PR Brief Builder)  
**Date:** October 24, 2025  
**Status:** ✅ READY FOR IMPLEMENTATION

