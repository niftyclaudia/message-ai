# PRD: Cloud Functions for Push Notifications

**Feature**: Serverless Backend for Push Notification Triggers

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 4

**Links**: [PR Brief: PR #14](../pr-brief/pr-briefs.md), [TODO: pr-14-todo.md](../todos/pr-14-todo.md), [Dependency: PR #13 PRD](pr-13-prd.md)

---

## 1. Summary

Implement Firebase Cloud Functions to automatically detect new messages in Firestore and trigger push notifications to all chat participants (excluding the sender). This completes the end-to-end notification system by bridging client-side infrastructure (PR #13) with server-side notification delivery.

---

## 2. Problem & Goals

**Problem:** Users don't receive notifications when messages are sent because there's no backend trigger. Client-side code cannot send notifications to other devices - this requires privileged server-side code with FCM admin access.

**Why Now:** Phase 4, immediately following PR #13. Client-side notification handling is complete; now we need the server-side trigger.

**Goals:**
- [x] G1 — Deploy Cloud Function that triggers on every new message with 100% reliability
- [x] G2 — Send push notifications to all participants (excluding sender) within 2 seconds
- [x] G3 — Handle errors gracefully without blocking message delivery

---

## 3. Non-Goals / Out of Scope

- [ ] Notification customization/preferences (sounds, DND, mute)
- [ ] Notification batching or rate limiting
- [ ] Rich notifications with media attachments
- [ ] Multi-device token management (use latest token only)

---

## 4. Success Metrics

**User-visible:**
- Delivery time: <2 seconds (p95)
- Success rate: >99%
- 0 self-notifications

**System:**
- Cold start: <3s | Warm execution: <500ms | FCM API success: >99%

**Quality:**
- 0 blocking bugs | Crash rate: <0.1% | Comprehensive error logging

---

## 5. Users & Stories

- As a user, I want to receive notifications when someone messages me so I stay updated without checking the app
- As a user, I don't want notifications for my own messages so my device isn't unnecessarily interrupted

---

## 6. Experience Specification

**Flow:** User A sends message → Firestore write → Cloud Function triggers → Fetches tokens → Sends to User B, C (not A) → Notifications arrive <2s

**Error Handling:** Invalid token → skip & log | FCM fails → log & continue | Missing chat → log & exit gracefully

**Performance:** Cold start <3s | Warm <500ms | Total delivery <2s

---

## 7. Functional Requirements

### MUST Requirements

**M1: Firestore Trigger**
- Trigger on `onCreate` for `chats/{chatID}/messages/{messageID}`
- Node.js 18, Firebase Admin SDK, us-central1 region
- **[Gate]** Function triggers within 1 second of message creation

**M2: Data Extraction & Validation**
- Extract chatID, messageID, senderID, message text
- Validate all required fields, log & exit if invalid
- **[Gate]** Invalid data → graceful exit with error log (no crash)

**M3: Recipient Filtering (CRITICAL)**
- Fetch chat document, get members array
- **Exclude sender from recipient list**
- Handle empty/missing members array
- **[Gate]** 1-on-1 chat → 1 recipient | Group (5 members) → 4 recipients (sender excluded)

**M4: Token Retrieval**
- Fetch user documents for all recipients (parallel reads)
- Extract FCM tokens, skip users without tokens
- **[Gate]** Missing tokens → skip user, log, continue to others

**M5: Notification Payload**
- Title: Sender display name
- Body: Message text (truncate to 100 chars if longer)
- Data: chatID, senderID, messageText, timestamp
- Priority: high, with APNs configuration
- **[Gate]** Payload includes all required fields for navigation

**M6: FCM Sending**
- Send to all recipient tokens using Admin SDK
- Handle FCM errors (invalid token, quota exceeded)
- Never throw unhandled exceptions
- **[Gate]** Invalid token → log, cleanup, continue (no crash)

**M7: Error Logging**
- Log function start (chatID, messageID)
- Log recipient count, token results, send results
- Use structured logging with context
- **[Gate]** Every error includes detailed context

**M8: Performance Optimization**
- Parallel Firestore reads
- Batch token lookups
- Function timeout: 60s, Memory: 256MB
- **[Gate]** Warm execution <500ms, cold start <3s

---

## 8. Data Model

### Firestore Schema (Read-Only)

**chats/{chatID}:**
```javascript
{
  members: ["userA", "userB", "userC"],  // All participants
  isGroupChat: true
}
```

**chats/{chatID}/messages/{messageID}** (TRIGGER):
```javascript
{
  text: "Hello!",
  senderID: "userA",
  timestamp: Timestamp
}
```

**users/{userID}:**
```javascript
{
  displayName: "Alice",
  fcmToken: "device_token_xyz"  // Used by function
}
```

### Data Flow
```
Message Created → Fetch Chat (members) → Filter Sender → Fetch Tokens → Build Payload → Send via FCM → Log Results
```

---

## 9. Service Contracts

### Cloud Function Definition

**Function Name:** `sendMessageNotification`  
**Trigger:** Firestore onCreate on `chats/{chatID}/messages/{messageID}`  
**Runtime:** Node.js 18, TypeScript  
**Memory:** 256MB, Timeout: 60s

### Key Methods (TypeScript)

```typescript
// Extract and validate message data
function extractMessageData(snapshot): MessageData | null

// Fetch chat document for members array
async function fetchChatData(chatID: string): Promise<ChatData | null>

// Get recipients (exclude sender)
function getRecipientIDs(members: string[], senderID: string): string[]

// Fetch FCM tokens for recipients
async function fetchRecipientTokens(recipientIDs: string[]): Promise<RecipientData[]>

// Build FCM notification payload
function buildNotificationPayload(
  senderName: string, 
  messageText: string, 
  chatID: string, 
  senderID: string
): admin.messaging.Message

// Send notifications to all tokens
async function sendNotifications(tokens: string[], payload): Promise<SendResults>

// Cleanup invalid tokens
async function cleanupInvalidToken(userID: string): Promise<void>
```

### Error Types
```typescript
enum NotificationError {
  INVALID_MESSAGE_DATA,
  CHAT_NOT_FOUND,
  NO_RECIPIENTS,
  FCM_SEND_FAILED,
  TOKEN_FETCH_FAILED
}
```

---

## 10. Files to Create

```
/functions/
├── package.json                    # Dependencies: firebase-functions, firebase-admin
├── tsconfig.json                   # TypeScript config
├── src/
│   ├── index.ts                    # Main export
│   ├── sendMessageNotification.ts  # Core function
│   ├── types.ts                    # Interfaces
│   └── utils/
│       ├── firestore.ts            # DB helpers
│       ├── fcm.ts                  # Notification helpers
│       └── logger.ts               # Structured logging
└── .firebaserc                     # Project config
```

**Modified:**
- `firebase.json` — Add functions configuration
- `.gitignore` — Add functions/node_modules, functions/lib
- `README.md` — Cloud Functions section

---

## 11. Integration Points

- **Firebase Cloud Functions** — Serverless execution, Firestore onCreate trigger
- **Firebase Admin SDK** — Firestore reads, FCM messaging API
- **FCM** — Push notification delivery, token validation
- **Firestore** — Read chat/message/user documents
- **APNs** — iOS notifications via FCM

---

## 12. Test Plan & Acceptance Gates

### Happy Path
- [ ] **HP1:** 1-on-1 chat → User B receives notification <2s
- [ ] **HP2:** Group chat (5 users) → 4 recipients get notifications (sender excluded)
- [ ] **HP3:** Long message → Truncates to 100 chars with "..."
- [ ] **HP4:** Multiple rapid messages → All trigger separate notifications

### Edge Cases
- [ ] **EC1:** User has no token → Skip user, log, no crash
- [ ] **EC2:** Invalid FCM token → Log error, cleanup, continue
- [ ] **EC3:** Chat document missing → Log error, exit gracefully
- [ ] **EC4:** Empty message text → Send with placeholder
- [ ] **EC5:** All recipients offline → FCM queues notifications

### Performance
- [ ] **P1:** Cold start <3s | **P2:** Warm execution <500ms | **P3:** Total delivery <2s
- [ ] **P4:** Firestore reads in parallel (not sequential)

### Multi-User
- [ ] **MU1:** 5 simultaneous messages → All execute independently
- [ ] **MU2:** Large group (10 members) → 9 notifications sent

---

## 13. Definition of Done

- [ ] Cloud Functions initialized with Node.js 18 + TypeScript
- [ ] All files created (index.ts, sendMessageNotification.ts, utils)
- [ ] TypeScript interfaces defined for all data structures
- [ ] All MUST requirements (M1-M8) implemented
- [ ] Sender exclusion logic working correctly
- [ ] FCM token retrieval & notification sending implemented
- [ ] Invalid token cleanup implemented
- [ ] Comprehensive error logging implemented
- [ ] Unit tests for all utility functions
- [ ] Integration tests for end-to-end flow
- [ ] All acceptance gates pass (HP, EC, P, MU)
- [ ] Performance targets met (<500ms warm, <3s cold, <2s total)
- [ ] Functions deployed to Firebase successfully
- [ ] Tested with real iOS devices (notifications received)
- [ ] Error scenarios tested (no token, invalid chat, etc.)
- [ ] Cloud Function logs verified (structured, contextual)
- [ ] Code follows Node.js/TypeScript best practices
- [ ] Documentation complete (comments, README)

---

## 14. Risks & Mitigations

**R1: Cold Start Latency** → Accept 3s for MVP; optimize with keep-alive in future  
**R2: FCM Token Invalid** → Implement token cleanup; graceful fallback  
**R3: Sender Self-Notification** → Critical! Always filter sender from recipients  
**R4: Function Timeout** → Keep simple; paginate if >100 recipients  
**R5: FCM Quota Limits** → Monitor usage; exponential backoff for quota errors

---

## 15. Rollout & Monitoring

**Deployment:**
```bash
firebase deploy --only functions
```

**Key Metrics:**
- Function execution count & time
- Error rate (<1% target)
- FCM send success rate
- Notification delivery latency

**Validation:**
1. Deploy function to Firebase
2. Send test message from iOS app
3. Verify notification on second device <2s
4. Check Cloud Function logs for successful execution
5. Test error scenarios

---

## 16. Critical Implementation Notes

**Sender Exclusion (CRITICAL):**
```typescript
// MUST filter sender from members array
const recipients = members.filter(id => id !== senderID);
```

**FCM Payload Structure:**
```javascript
{
  notification: {
    title: "Sender Name",
    body: "Message text (max 100 chars)"
  },
  data: {
    chatID: "chat123",
    senderID: "userA",
    messageText: "Full message text",
    timestamp: "2025-01-15T10:30:00Z"
  },
  apns: {
    payload: {
      aps: {
        sound: "default",
        badge: 1,
        contentAvailable: true
      }
    },
    headers: { "apns-priority": "10" }
  }
}
```

**Development Setup:**
```bash
# Initialize
npm install -g firebase-tools
firebase init functions  # Select TypeScript

# Local testing
firebase emulators:start

# Deploy
firebase deploy --only functions
```

**Resources:**
- [Firebase Cloud Functions Docs](https://firebase.google.com/docs/functions)
- [FCM Admin SDK](https://firebase.google.com/docs/cloud-messaging/admin)
- [Firestore Triggers](https://firebase.google.com/docs/functions/firestore-events)

