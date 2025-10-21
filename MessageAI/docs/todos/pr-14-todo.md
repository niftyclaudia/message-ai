# PR-14 TODO — Cloud Functions for Push Notifications

**Branch**: `feat/pr-14-cloud-functions-notifications`  
**Source PRD**: `MessageAI/docs/prds/pr-14-prd.md`  
**Owner (Agent)**: Cody  
**Dependencies**: PR #13 (APNs & FCM Setup) must be complete

---

## 0. Pre-Flight Checks

- [ ] Read PRD: `MessageAI/docs/prds/pr-14-prd.md`
- [ ] Read shared standards: `MessageAI/agents/shared-standards.md`
- [ ] Review PR #13 PRD for client-side integration
- [ ] Verify Firebase CLI installed: `firebase --version`

### Assumptions
- Using TypeScript with Node.js 18 runtime
- Deploying to us-central1 region
- PR #13 complete (client can receive notifications)
- Single device per user (latest token only)

---

## 1. Firebase Functions Setup

### 1.1 Initialize Project
- [ ] Install Firebase CLI: `npm install -g firebase-tools`
- [ ] Login: `firebase login`
- [ ] Initialize Functions: `firebase init functions` from project root
  - Select: TypeScript, ESLint yes, install dependencies yes
  - Test Gate: `functions/` directory created with package.json

### 1.2 Install Dependencies
- [ ] `cd functions/`
- [ ] `npm install firebase-admin firebase-functions@latest`
- [ ] `npm install --save-dev @types/node`
  - Test Gate: All dependencies in package.json

### 1.3 Configuration
- [ ] Update `firebase.json` with functions config
- [ ] Update `.gitignore`: Add `functions/node_modules/`, `functions/lib/`
- [ ] Create/verify `.firebaserc` with project ID
  - Test Gate: All config files in place

---

## 2. TypeScript Types (types.ts)

- [ ] Create `functions/src/types.ts`
- [ ] Define interfaces:
  ```typescript
  export interface MessageData {
    text: string;
    senderID: string;
    chatID: string;
    messageID: string;
  }
  
  export interface ChatData {
    id: string;
    members: string[];
    isGroupChat: boolean;
  }
  
  export interface UserData {
    uid: string;
    displayName: string;
    fcmToken?: string;
  }
  
  export interface RecipientData {
    userID: string;
    displayName: string;
    fcmToken: string;
  }
  
  export interface SendResults {
    successCount: number;
    failureCount: number;
    invalidTokens: string[];
  }
  
  export enum NotificationError {
    INVALID_MESSAGE_DATA = 'Invalid message data',
    CHAT_NOT_FOUND = 'Chat not found',
    NO_RECIPIENTS = 'No valid recipients',
    FCM_SEND_FAILED = 'FCM send failed',
    TOKEN_FETCH_FAILED = 'Token fetch failed'
  }
  ```
  - Test Gate: TypeScript compiles without errors

---

## 3. Utility Functions

### 3.1 Logger (utils/logger.ts)
- [ ] Create `functions/src/utils/logger.ts`
- [ ] Implement structured logging:
  ```typescript
  export const logger = {
    info: (msg: string, data?: any) => console.log(JSON.stringify({level: 'info', msg, ...data})),
    warn: (msg: string, data?: any) => console.warn(JSON.stringify({level: 'warn', msg, ...data})),
    error: (msg: string, err?: any) => console.error(JSON.stringify({level: 'error', msg, err}))
  }
  ```
  - Test Gate: Logs include level, message, context

### 3.2 Firestore Helpers (utils/firestore.ts)
- [ ] Create `functions/src/utils/firestore.ts`
- [ ] Implement `fetchChatData(chatID: string): Promise<ChatData | null>`
  - Test Gate: Returns ChatData or null if not found
- [ ] Implement `fetchMultipleUsers(userIDs: string[]): Promise<RecipientData[]>`
  - Test Gate: Batch reads, filters users without tokens
- [ ] Implement `removeInvalidToken(userID: string): Promise<void>`
  - Test Gate: Sets fcmToken to null in Firestore

### 3.3 FCM Helpers (utils/fcm.ts)
- [ ] Create `functions/src/utils/fcm.ts`
- [ ] Implement `buildNotificationPayload()`:
  ```typescript
  export function buildNotificationPayload(
    senderName: string,
    messageText: string,
    chatID: string,
    senderID: string
  ): admin.messaging.Message {
    const truncatedText = messageText.length > 100 
      ? messageText.substring(0, 97) + '...' 
      : messageText;
    
    return {
      notification: {
        title: senderName,
        body: truncatedText
      },
      data: { chatID, senderID, messageText, timestamp: new Date().toISOString() },
      apns: {
        payload: {
          aps: { sound: 'default', badge: 1, contentAvailable: true }
        },
        headers: { 'apns-priority': '10' }
      }
    };
  }
  ```
  - Test Gate: Truncates at 100 chars, includes APNs config
  
- [ ] Implement `sendNotificationsBatch(tokens: string[], payload): Promise<SendResults>`
  - Test Gate: Sends to all tokens, identifies invalid tokens

---

## 4. Main Function (sendMessageNotification.ts)

- [ ] Create `functions/src/sendMessageNotification.ts`
- [ ] Import dependencies and initialize Admin SDK
- [ ] Define Firestore trigger:
  ```typescript
  export const sendMessageNotification = functions.firestore
    .document('chats/{chatID}/messages/{messageID}')
    .onCreate(async (snapshot, context) => {
      // Implementation below
    });
  ```

### 4.1 Implement Function Logic (7 Steps)

**Step 1: Extract & Validate Data**
- [ ] Extract chatID, messageID from context.params
- [ ] Extract message data from snapshot
- [ ] Validate required fields (text, senderID)
- [ ] Return early with error log if invalid
  - Test Gate: Invalid data exits gracefully

**Step 2: Fetch Chat Data**
- [ ] Call `fetchChatData(chatID)`
- [ ] Handle chat not found (log error, return)
- [ ] Validate members array exists
  - Test Gate: Missing chat exits gracefully

**Step 3: Compute Recipients (CRITICAL)**
- [ ] **Filter sender from members: `recipients = members.filter(id => id !== senderID)`**
- [ ] Log recipient count
- [ ] Exit if no recipients
  - Test Gate: Sender excluded | 1-on-1 → 1 recipient | Group (5) → 4 recipients

**Step 4: Fetch Recipient Tokens**
- [ ] Call `fetchMultipleUsers(recipientIDs)`
- [ ] Filter users without tokens
- [ ] Log results (found vs missing)
- [ ] Exit if no valid tokens
  - Test Gate: Missing tokens handled gracefully

**Step 5: Build Notification**
- [ ] Get sender display name
- [ ] Truncate message if needed
- [ ] Call `buildNotificationPayload()`
- [ ] Log payload summary
  - Test Gate: Payload structure correct

**Step 6: Send Notifications**
- [ ] Extract tokens from RecipientData
- [ ] Call `sendNotificationsBatch()`
- [ ] Log results (success/failure counts)
- [ ] Handle invalid tokens (call `removeInvalidToken()`)
  - Test Gate: All sends attempted, errors logged

**Step 7: Error Handling**
- [ ] Wrap entire function in try-catch
- [ ] Log all errors with context
- [ ] Return gracefully (never throw)
  - Test Gate: No unhandled exceptions

---

## 5. Export Function (index.ts)

- [ ] Update `functions/src/index.ts`:
  ```typescript
  export { sendMessageNotification } from './sendMessageNotification';
  ```
  - Test Gate: Function exported correctly

---

## 6. Local Testing with Emulator

- [ ] Install emulators: `firebase init emulators` (Firestore + Functions)
- [ ] Start emulators: `firebase emulators:start`
  - Test Gate: UI at http://localhost:4000
  
- [ ] Test valid 1-on-1 chat:
  - Create chat with 2 members
  - Create message from userA
  - Verify function logs show 1 notification sent to userB
  - Test Gate: HP1 passes in emulator
  
- [ ] Test group chat (5 members):
  - Create message from userA
  - Verify 4 notifications sent
  - Test Gate: HP2 passes, sender excluded
  
- [ ] Test missing chat document:
  - Create message without parent chat
  - Verify graceful exit with error log
  - Test Gate: EC3 passes
  
- [ ] Test user without token:
  - Create user with no fcmToken
  - Verify user skipped, function continues
  - Test Gate: EC1 passes

---

## 7. Unit Tests

- [ ] Install: `npm install --save-dev jest @types/jest ts-jest`
- [ ] Create `jest.config.js`
- [ ] Create test files:

**utils/firestore.test.ts:**
- [ ] Test fetchChatData (valid & invalid)
- [ ] Test fetchMultipleUsers (filters no-token users)
- [ ] Test removeInvalidToken

**utils/fcm.test.ts:**
- [ ] Test buildNotificationPayload (normal & long messages)
- [ ] Test sendNotificationsBatch (handles invalid tokens)

**sendMessageNotification.test.ts:**
- [ ] Test sender exclusion
- [ ] Test invalid data handling
- [ ] Test missing chat handling

- [ ] Run tests: `npm test`
  - Test Gate: All tests pass

---

## 8. Deploy to Firebase

### 8.1 Pre-Deploy
- [ ] Build: `npm run build` (no errors)
- [ ] Lint: `npm run lint` (fix any issues)
- [ ] Tests: `npm test` (all pass)

### 8.2 Deploy
- [ ] Deploy: `firebase deploy --only functions`
  - Test Gate: Deployment succeeds
- [ ] Verify in Firebase Console → Functions
  - Status: Active
  - Runtime: Node.js 18
  - Trigger: Firestore onCreate
  - Test Gate: Function visible and active

---

## 9. Production Testing

### 9.1 Real Device Testing
- [ ] Two iOS devices with app installed, users logged in
- [ ] Verify FCM tokens in Firestore users collection
  
- [ ] Test HP1: Send message Device A → Device B
  - Test Gate: Device B notification <2s, correct content
  
- [ ] Test HP2: Group chat (3+ users)
  - Test Gate: All recipients except sender get notifications
  
- [ ] Test HP3: Long message (200 chars)
  - Test Gate: Notification truncates to 100 chars
  
- [ ] Test EC2: Invalid token (corrupt in Firestore)
  - Test Gate: Error logged, token cleaned up, no crash

### 9.2 Performance Testing
- [ ] Check Cloud Function logs for execution times:
  - First execution (cold start): <3s
  - Subsequent (warm): <500ms
  - Test Gate: P1 & P2 pass
  
- [ ] Measure end-to-end: message send → notification received
  - Test Gate: P3 passes (<2s)
  
- [ ] Test MU2: Send 10 messages rapidly
  - Test Gate: All function executions complete, scaling works

---

## 10. Monitoring & Verification

- [ ] Firebase Console → Functions → Logs
  - Verify structured logs with context (chatID, messageID)
  - Verify recipient counts, send results
  - No unexpected errors
  
- [ ] Firebase Console → Functions → Metrics
  - Execution count matches message volume
  - Execution time <500ms warm, <3s cold
  - Error rate <1%
  - Test Gate: All metrics healthy

---

## 11. Documentation

- [ ] Add JSDoc comments to all functions in utils/
- [ ] Add inline comments for complex logic (sender exclusion, error handling)
- [ ] Update project README.md:
  - Cloud Functions section
  - Development: `firebase emulators:start`
  - Testing: `npm test`
  - Deployment: `firebase deploy --only functions`
  - Viewing logs: Firebase Console
  - Test Gate: Documentation clear and complete

---

## 12. Acceptance Gates Checklist

### Happy Path
- [ ] HP1: 1-on-1 → notification <2s ✅
- [ ] HP2: Group (5) → 4 notifications (sender excluded) ✅
- [ ] HP3: Long message → truncates to 100 chars ✅
- [ ] HP4: Multiple messages → all trigger separately ✅

### Edge Cases
- [ ] EC1: No token → skip, no crash ✅
- [ ] EC2: Invalid token → log, cleanup, continue ✅
- [ ] EC3: Missing chat → log, exit gracefully ✅
- [ ] EC4: Empty text → placeholder sent ✅
- [ ] EC5: Offline recipients → FCM queues ✅

### Performance
- [ ] P1: Cold start <3s ✅
- [ ] P2: Warm exec <500ms ✅
- [ ] P3: Total delivery <2s ✅
- [ ] P4: Parallel reads ✅

### Multi-User
- [ ] MU1: 5 simultaneous → all execute ✅
- [ ] MU2: Large group (10) → 9 notifications ✅

---

## 13. Definition of Done

- [ ] All files created (index.ts, sendMessageNotification.ts, types.ts, utils)
- [ ] All MUST requirements (M1-M8) implemented
- [ ] Sender exclusion working correctly (CRITICAL)
- [ ] Token retrieval & FCM sending implemented
- [ ] Invalid token cleanup implemented
- [ ] Comprehensive error logging
- [ ] Unit tests pass
- [ ] Integration tests pass (emulator)
- [ ] All acceptance gates pass
- [ ] Performance targets met
- [ ] Deployed successfully
- [ ] Tested with real iOS devices
- [ ] Logs verified (structured, contextual)
- [ ] Documentation complete

---

## 14. PR Preparation

- [ ] Run final linter: `npm run lint` (0 errors)
- [ ] Review all changed files:
  - functions/ directory (package.json, src/*, utils/*)
  - firebase.json
  - .gitignore
  - README.md
  - Test Gate: No accidental files, node_modules not committed
  
- [ ] Create PR:
  - Title: "feat: Cloud Functions for Push Notifications (PR #14)"
  - Description: Links to PRD, TODO, deployment instructions
  - Screenshots/logs of successful notifications
  - Target: develop branch
  
- [ ] Get user approval before merging

---

## Quick Reference

### Critical Implementation Point
```typescript
// ALWAYS exclude sender from recipients
const recipients = members.filter(id => id !== senderID);
```

### Common Commands
```bash
# Local development
cd functions/
npm run build          # Compile TypeScript
npm run lint           # Run ESLint
npm test               # Run unit tests
firebase emulators:start  # Start emulator

# Deployment
firebase deploy --only functions
firebase functions:log  # View logs
```

### Key Testing Scenarios
1. **Sender exclusion** (no self-notification) — CRITICAL
2. **Invalid data handling** (no crashes)
3. **Performance** (<2s total delivery)
4. **Group chats** (multiple recipients)
5. **Error logging** (debugging)

### Resources
- PRD: `MessageAI/docs/prds/pr-14-prd.md`
- Shared Standards: `MessageAI/agents/shared-standards.md`
- Firebase Docs: https://firebase.google.com/docs/functions
- FCM Admin: https://firebase.google.com/docs/cloud-messaging/admin
