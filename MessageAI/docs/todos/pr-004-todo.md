# PR-004 TODO — Memory & State Management System

**Branch**: `feat/pr-004-memory-state`  
**Source PRD**: `MessageAI/docs/prds/pr-004-prd.md`  
**Owner (Agent)**: Cody iOS / Pete

---

## 0. Prerequisites & Setup

### Environment Setup
- [ ] **Verify Xcode version** — iOS 16+ support, Swift 5.9+
  - Command: `xcodebuild -version` (should be Xcode 14.0+)
  
- [ ] **Verify Firebase SDK** — Firebase iOS SDK 10.x installed
  - Check: `MessageAI.xcodeproj` → Package Dependencies → firebase-ios-sdk
  
- [ ] **Install/Update Firebase CLI** (for Cloud Functions deployment)
  ```bash
  npm install -g firebase-tools
  firebase --version  # Should be 12.0.0+
  ```

### Project Familiarization
- [ ] **Read PRD thoroughly** — `MessageAI/docs/prds/pr-004-prd.md`
- [ ] **Read shared standards** — `MessageAI/agents/shared-standards.md`
- [ ] **Review existing models** — `MessageAI/MessageAI/Models/User.swift`, `Chat.swift`, `Message.swift`
- [ ] **Review existing services** — `MessageAI/MessageAI/Services/AuthService.swift`, `ChatService.swift`, `MessageService.swift`
- [ ] **Understand Firestore patterns** — Check `MessageService.swift` for listener examples

---

## 1. Branch Setup

- [ ] **Create feature branch from develop**
  ```bash
  cd /Users/claudiaalban/Desktop/MessagingApp-secondagent
  git checkout develop
  git pull origin develop
  git checkout -b feat/pr-004-memory-state
  ```
  - **Acceptance**: Branch created, no uncommitted changes from develop

- [ ] **Verify project builds** — Confirm baseline works before changes
  ```bash
  xcodebuild -scheme MessageAI -configuration Debug build
  ```
  - **Acceptance**: Build succeeds with 0 errors, 0 warnings

- [ ] **Run existing tests** — Ensure tests pass before modifications
  ```bash
  xcodebuild test -scheme MessageAI -destination 'platform=iOS Simulator,name=iPhone 15'
  ```
  - **Acceptance**: All existing tests pass (baseline)

---

## 2. Data Models (16 Models)

### Task 2.1: Create Core State Models
- [ ] **Create**: `Models/AI/SessionContext.swift`
  - Fields: currentConversationId, lastActiveTimestamp, recentMessages[], recentQueries[], contextVersion, timestamps
  - Add: Codable conformance, Firestore Timestamp encoding/decoding
  - Add: Validation (max 20 messages, max 5 queries)
  - **Gate**: Compiles, validates limits correctly

- [ ] **Create**: `Models/AI/ContextMessage.swift`
  - Fields: messageId, chatId, senderId, text (truncate to 200 chars), timestamp
  - **Gate**: Codable, text truncation works

- [ ] **Create**: `Models/AI/AIQuery.swift`
  - Fields: queryId, queryText, responseText (truncate to 300 chars), featureSource, timestamp
  - **Gate**: Codable, truncation works

### Task 2.2: Create Task State Models
- [ ] **Create**: `Models/AI/TaskState.swift`
  - Fields: actionItems[], decisions[], lastSyncedAt, version
  - **Gate**: Compiles, Codable

- [ ] **Create**: `Models/AI/TaskItem.swift`
  - Fields: id, taskDescription, chatId, messageId, extractedBy, assignee, deadline, priority, completionStatus, timestamps
  - **Gate**: All fields typed correctly

- [ ] **Create**: `Models/AI/DecisionItem.swift`
  - Fields: id, decisionText, participants[], chatId, messageId, detectedBy, confidence, isImportant, tags[], createdAt
  - **Gate**: Codable, confidence validation (0.0-1.0)

- [ ] **Create**: `Models/AI/TaskPriority.swift` — Enum (urgent, normal, low)
- [ ] **Create**: `Models/AI/TaskStatus.swift` — Enum (pending, inProgress, completed, archived)

### Task 2.3: Create Learning Data Models
- [ ] **Create**: `Models/AI/LearningDataEntry.swift`
  - Fields: id, entryType, optional nested types (categorizationOverride, meetingPreference, toneFeedback), userId, featureSource, timestamps
  - **Gate**: Codable, handles optional nested types

- [ ] **Create**: `Models/AI/LearningType.swift` — Enum (categorizationOverride, meetingPreference, toneFeedback)

- [ ] **Create**: `Models/AI/CategorizationOverride.swift`
  - Fields: messageId, chatId, originalCategory, userCategory, context
  - Reuse MessageCategory and MessageContext from PR #AI-002
  - **Gate**: Compiles, references existing types

- [ ] **Create**: `Models/AI/MeetingPreference.swift`
  - Fields: suggestionId, wasAccepted, suggestedTime, suggestedDuration, participants[], reasonForRejection
  - **Gate**: Codable

- [ ] **Create**: `Models/AI/ToneFeedback.swift`
  - Fields: responseId, aiResponseText (200 chars), wasHelpful, userComment, featureSource
  - **Gate**: Text truncation works

### Task 2.4: Create Conversation History Models
- [ ] **Create**: `Models/AI/ConversationHistoryEntry.swift`
  - Fields: id, userQuery, aiResponse, featureSource, contextUsed[], confidence, wasHelpful, timestamp, createdAt
  - **Gate**: Codable, handles optional wasHelpful

### Task 2.5: Create Supporting Models
- [ ] **Create**: `Models/AI/AIFeature.swift` — Enum (threadSummary, actionItems, smartSearch, priorityDetection, decisionTracking, proactiveAssistant)

- [ ] **Create**: `Models/AI/MemoryStats.swift`
  - Fields: totalContextMessages, totalActionItems, totalDecisions, totalLearningEntries, totalConversations, oldestEntryDate, estimatedSizeKB
  - **Gate**: All fields Int/Date types, Codable

---

## 3. Service Layer (MemoryService)

### Task 3.1: Create Service Protocol & Error Types
- [ ] **Create**: `Services/AI/MemoryService.swift`
- [ ] **Define protocol**: MemoryServiceProtocol with method signatures (see PRD Section 9)
  - Session Context: fetchSessionContext, updateSessionContext, clearExpiredContext, setActiveConversation, getRecentContext
  - Task State: fetchTaskState, addActionItem, updateActionItemStatus, addDecision, flagDecisionAsImportant, archiveOldTasks
  - Learning: logCategorizationOverride, logMeetingPreference, logToneFeedback, fetchLearningData
  - History: saveConversation, fetchConversationHistory, updateConversationFeedback
  - Utility: clearMemory, getMemoryStats, observeTaskState
- [ ] **Define error enum**: MemoryError (contextLimitExceeded, invalidTaskState, sessionExpired, dataCorruption, missingUserId, networkError)
  - **Gate**: Protocol compiles, errors have localizedDescription

### Task 3.2: Implement Session Context Methods
- [ ] **Implement fetchSessionContext()** — Read `/users/{userId}/aiState/sessionContext`, handle missing (return default), <100ms target
- [ ] **Implement updateSessionContext()** — Add message/query, prune if >20 messages or >5 queries (oldest first), update timestamp
- [ ] **Implement clearExpiredContext()** — Remove entries >24 hours old
- [ ] **Implement setActiveConversation()** — Update currentConversationId + timestamp
- [ ] **Implement getRecentContext()** — Return last N messages for AI prompts
- **Gate**: Fetch/update work, limits enforced, expired cleanup works

### Task 3.3: Implement Task State Methods
- [ ] **Implement fetchTaskState()** — Read `/users/{userId}/aiState/taskState`, handle missing (return default)
- [ ] **Implement addActionItem()** — Append to actionItems[], sync <300ms
- [ ] **Implement updateActionItemStatus()** — Find by ID, update status + timestamp
- [ ] **Implement addDecision()** — Append to decisions[]
- [ ] **Implement flagDecisionAsImportant()** — Find by ID, set isImportant = true
- [ ] **Implement archiveOldTasks()** — Move completed tasks >30 days to archived status
- **Gate**: CRUD operations work, task sync <300ms

### Task 3.4: Implement Learning Data Methods
- [ ] **Implement logCategorizationOverride()** — Create doc in `/aiState/learningData/` with auto-generated ID, <150ms
- [ ] **Implement logMeetingPreference()** — Create learning entry with meeting data
- [ ] **Implement logToneFeedback()** — Create learning entry with feedback data
- [ ] **Implement fetchLearningData()** — Query by timestamp DESC, filter by days + optional type, limit 100 entries
- **Gate**: Logs created, queries work with filters

### Task 3.5: Implement Conversation History Methods
- [ ] **Implement saveConversation()** — Create doc in `/aiState/conversationHistory/` with auto-generated ID, <200ms
- [ ] **Implement fetchConversationHistory()** — Query by timestamp DESC, filter by days + optional feature
- [ ] **Implement updateConversationFeedback()** — Find by ID, update wasHelpful field
- **Gate**: Save/fetch work, feedback updates correctly

### Task 3.6: Implement Utility Methods
- [ ] **Implement clearMemory()** — Delete all non-important data (preserve flagged decisions, active tasks)
- [ ] **Implement getMemoryStats()** — Count entries across all collections, calculate oldest date, estimate size
- [ ] **Implement observeTaskState()** — Real-time Firestore snapshot listener, return ListenerRegistration
- **Gate**: Clear preserves important items, stats accurate, listener triggers on changes

---

## 4. Firebase Integration

### Task 4.1: Update Firestore Security Rules
- [ ] **Modify file**: `firestore.rules`
- [ ] **Add rules for aiState collection**:
  ```javascript
  match /users/{userId}/aiState/{document=**} {
    allow read, write: if request.auth.uid == userId;
    
    // Validate context constraints
    allow write: if request.resource.data.recentMessages.size() <= 20
              && request.resource.data.recentQueries.size() <= 5;
  }
  
  match /users/{userId}/aiState/learningData/{document=**} {
    allow read, write: if request.auth.uid == userId;
    allow delete: if request.auth.uid == userId;
  }
  
  match /users/{userId}/aiState/conversationHistory/{document=**} {
    allow read: if request.auth.uid == userId;
    allow write: if request.auth.uid == userId;
    allow delete: if request.auth.uid == userId;
  }
  ```
- **Acceptance**: Rules validate constraints, users can only access own data

### Task 4.2: Deploy Firestore Rules
- [ ] **Deploy rules to Firebase**:
  ```bash
  firebase deploy --only firestore:rules
  ```
- [ ] **Test rules in Firebase Console** — Rules Playground
  - Test read/write as authenticated user
  - Test blocked access for other users
- **Acceptance**: Rules deployed, validation works, access control enforced

### Task 4.3: Create Firestore Composite Indexes
- [ ] **Add indexes to `firestore.indexes.json`**:
  ```json
  {
    "indexes": [
      {
        "collectionGroup": "learningData",
        "queryScope": "COLLECTION",
        "fields": [
          { "fieldPath": "timestamp", "order": "DESCENDING" },
          { "fieldPath": "entryType", "order": "ASCENDING" }
        ]
      },
      {
        "collectionGroup": "conversationHistory",
        "queryScope": "COLLECTION",
        "fields": [
          { "fieldPath": "timestamp", "order": "DESCENDING" },
          { "fieldPath": "featureSource", "order": "ASCENDING" }
        ]
      }
    ]
  }
  ```
- [ ] **Deploy indexes**: `firebase deploy --only firestore:indexes`
- **Acceptance**: Queries run without "needs index" error

---

## 5. Cloud Functions (90-Day Cleanup)

### Task 5.1: Create Cleanup Cloud Function
- [ ] **Create**: `functions/src/cleanup/memoryCleanup.ts`
- [ ] **Implement scheduled function** — Runs daily at midnight UTC
  - Query learningData entries with timestamp < 90 days ago
  - Query conversationHistory entries with timestamp < 90 days ago
  - Skip entries where decisions[].isImportant === true
  - Batch delete old entries (max 500 per batch)
  - Log cleanup results (entries deleted, errors)
- [ ] **Add error handling** — Retry logic, alert if fails 3+ times
- **Gate**: Function deletes old entries, preserves important items, logs correctly

### Task 5.2: Deploy Cloud Function
- [ ] **Export function in `functions/src/index.ts`**
- [ ] **Deploy**: `firebase deploy --only functions:memoryCleanup`
- [ ] **Test**: Create 91-day-old test entry → Trigger function → Verify deletion
- **Acceptance**: Function runs on schedule, cleanup works correctly

---

## 6. App Initialization

### Task 6.1: Initialize MemoryService on Launch
- [ ] **Modify file**: `MessageAI/MessageAIApp.swift`
- [ ] **Add MemoryService initialization**:
  ```swift
  @StateObject private var memoryService = MemoryService()
  ```
- [ ] **Inject as EnvironmentObject** (if needed by future AI features):
  ```swift
  .environmentObject(memoryService)
  ```
- **Acceptance**: Service initialized on app launch, no crashes

---

## 7. Testing (Swift Testing + XCTest)

### Task 7.1: Unit Tests — Session Context (Swift Testing)
- [ ] **Create**: `MessageAITests/Services/MemoryServiceTests.swift`
- [ ] **Test**: Session context tracking (add 5 messages, fetch, verify order)
- [ ] **Test**: Context limit enforcement (add 25 messages, verify only 20 retained, oldest pruned)
- [ ] **Test**: Expired context cleanup (25-hour-old entry removed)
- [ ] **Test**: Recent context retrieval (get last N messages for AI prompts)
- **Gate**: All tests pass, limits enforced, cleanup works

### Task 7.2: Unit Tests — Task State (Swift Testing)
- [ ] **Test**: Task persistence (add action item, fetch, verify present)
- [ ] **Test**: Task status update (change status, verify updated)
- [ ] **Test**: Decision storage (add decision, fetch by ID)
- [ ] **Test**: Flag important decision (flag, verify isImportant = true)
- [ ] **Test**: Archive old tasks (completed >30 days archived)
- **Gate**: CRUD operations work, archiving correct

### Task 7.3: Unit Tests — Learning & History (Swift Testing)
- [ ] **Test**: Categorization override logging (log, fetch by date)
- [ ] **Test**: Meeting preference logging (log, query by type)
- [ ] **Test**: Tone feedback logging (log, verify stored)
- [ ] **Test**: Conversation history save/fetch (query by feature)
- [ ] **Test**: Conversation feedback update (mark helpful/not helpful)
- **Gate**: All logging works, queries filter correctly

### Task 7.4: Integration Tests — Persistence
- [ ] **Create**: `MessageAITests/Integration/MemoryPersistenceTests.swift`
- [ ] **Test**: Force-quit recovery (add 3 tasks → force-quit → relaunch → verify present)
- [ ] **Test**: Offline persistence (Airplane Mode → add task → reconnect → sync <1s)
- [ ] **Test**: Data corruption recovery (corrupt document → fetch returns default → no crash)
- **Gate**: Tasks survive force-quit, offline queue works, graceful degradation

### Task 7.5: Integration Tests — Multi-Device Sync
- [ ] **Test**: Real-time task sync (add on device 1 → device 2 updates <300ms)
- [ ] **Test**: Concurrent updates (modify on 2 devices → last write wins → no corruption)
- [ ] **Test**: Session context sync (update on device 1 → device 2 sees changes)
- **Gate**: Sync works, conflict resolution correct, no data loss

### Task 7.6: Performance Tests
- [ ] **Create**: `MessageAITests/Performance/MemoryPerformanceTests.swift`
- [ ] **Test**: Context fetch latency (<100ms p95) — 100 fetches, measure p95
- [ ] **Test**: Task save latency (<200ms p95) — 100 saves, measure p95
- [ ] **Test**: Real-time sync latency (<300ms) — Measure propagation time
- **Gate**: All performance targets met

### Task 7.7: Privacy & Security Tests
- [ ] **Test**: 90-day cleanup (create 91-day-old entry → cleanup runs → entry deleted)
- [ ] **Test**: Important item preservation (flag decision → 91 days → still present)
- [ ] **Test**: Manual memory clear (clear → non-important deleted → flagged preserved)
- [ ] **Test**: Data isolation (User A memory → User B cannot read via security rules)
- **Gate**: Cleanup works, important items safe, isolation enforced

---

## 8. Performance Verification

### Task 8.1: Measure Latencies
- [ ] **Session context fetch** — <100ms (p95)
  - Test: 100 fetches, calculate p95
- [ ] **Task save** — <200ms (p95)
  - Test: 100 saves, calculate p95
- [ ] **Real-time sync** — <300ms across devices
  - Test: Add task on device 1, measure time to appear on device 2
- **Gate**: All targets met, evidence collected (timing logs)

### Task 8.2: Test Force-Quit Scenarios
- [ ] **Scenario 1**: Add 3 tasks → force-quit app → relaunch → verify all 3 present
- [ ] **Scenario 2**: Update task status → force-quit during save → relaunch → verify state correct
- [ ] **Scenario 3**: Add context messages → force-quit → relaunch → verify context preserved
- **Gate**: 100% persistence across force-quit events

### Task 8.3: Test Offline Scenarios
- [ ] **Scenario 1**: Enable Airplane Mode → add task → disable → verify sync <1s
- [ ] **Scenario 2**: Offline → update 3 tasks → online → verify all 3 sync correctly
- [ ] **Scenario 3**: Offline for 30 seconds → reconnect → verify full sync completes
- **Gate**: Offline queue works, sync completes quickly

---

## 9. Manual Validation

### Task 9.1: Multi-Device Testing
- [ ] **Setup**: 2 physical devices or 1 device + 1 simulator
- [ ] **Test 1**: Add action item on device 1 → Verify appears on device 2 <300ms
- [ ] **Test 2**: Update task status on device 2 → Verify reflects on device 1
- [ ] **Test 3**: Update session context on device 1 → Verify syncs to device 2
- **Acceptance**: Real-time sync works, latency <300ms, no conflicts

### Task 9.2: Context Limits Validation
- [ ] **Add 25 messages** to session context → Verify only last 20 retained
- [ ] **Add 10 queries** to session context → Verify only last 5 retained
- [ ] **Verify oldest entries pruned first** (FIFO queue behavior)
- **Acceptance**: Limits enforced, no unbounded growth

### Task 9.3: Cleanup Validation
- [ ] **Create test entry with 91-day-old timestamp**
- [ ] **Trigger cleanup Cloud Function** (manually or wait for schedule)
- [ ] **Verify old entry deleted**, recent entries preserved
- [ ] **Verify important decision preserved** beyond 90 days
- **Acceptance**: Cleanup works, important items safe

---

## 10. Documentation

### Task 10.1: Code Documentation
- [ ] **Add inline comments** for complex logic:
  - Context pruning algorithm (oldest first)
  - Learning data aggregation patterns
  - Cleanup Cloud Function logic
- [ ] **Add method documentation** for all public MemoryService methods
- **Gate**: Complex code has explanatory comments

### Task 10.2: Update Project Documentation
- [ ] **Update README** — Add "AI Memory System" section describing feature
- [ ] **Document schema** — Add Firestore schema diagram/explanation for aiState collection
- [ ] **Document Cloud Function** — Add cleanup function schedule and behavior
- **Gate**: Documentation complete, clear for future developers

---

## 11. Acceptance Gates Checklist

**All 20 test scenarios from PRD Section 12:**

**Happy Path** (6 tests)
- [ ] Session context tracking (5 messages)
- [ ] Task persistence across restart
- [ ] Learning data logging
- [ ] Decision storage
- [ ] Real-time sync <300ms
- [ ] Conversation history retrieval

**Edge Cases** (6 tests)
- [ ] Context limit (20 max, prune oldest)
- [ ] Expired context cleanup (24h)
- [ ] Concurrent updates (last write wins)
- [ ] Network failure (queue + retry)
- [ ] Missing auth
- [ ] Data corruption recovery

**Privacy & Cleanup** (4 tests)
- [ ] 90-day auto-cleanup
- [ ] Important item preservation
- [ ] Manual clear
- [ ] Data isolation

**Performance** (4 tests)
- [ ] Fetch <100ms
- [ ] Save <200ms
- [ ] Force-quit recovery
- [ ] Offline persistence + sync <1s

---

## 12. PR Preparation

### Task 12.1: Pre-PR Checklist
- [ ] **All 20 acceptance gates pass**
- [ ] **All tests pass** (0 failures)
- [ ] **No compiler warnings**
- [ ] **No linter errors**
- [ ] **Performance targets met** (evidence collected)
- [ ] **Force-quit + multi-device sync verified manually**
- [ ] **Code follows shared-standards.md patterns**

### Task 12.2: Create PR Description
- [ ] **Title**: `feat: PR-004 Memory & State Management System`
- [ ] **Description template**:
  ```markdown
  ## PR-004: Memory & State Management System
  
  **PRD**: MessageAI/docs/prds/pr-004-prd.md
  **TODO**: MessageAI/docs/todos/pr-004-todo.md
  
  ### Summary
  Implements stateful memory system enabling AI to remember conversation context, persist tasks/decisions, and learn from user behavior.
  
  ### Key Changes
  - 16 data models for session context, task state, learning data, conversation history
  - MemoryService with 20+ methods for CRUD operations
  - Firestore schema + security rules for `/users/{userId}/aiState/`
  - Cloud Function for 90-day auto-cleanup
  - Real-time sync with <300ms latency
  
  ### Performance
  - Fetch: <100ms (p95) ✅
  - Save: <200ms (p95) ✅
  - Sync: <300ms ✅
  - Force-quit recovery: 100% ✅
  
  ### Testing
  - 20 test scenarios pass (Happy Path, Edge Cases, Privacy, Performance)
  - Multi-device sync verified
  - Force-quit scenarios tested
  
  ### Checklist
  - [x] All TODO tasks completed
  - [x] 16 models implemented (Codable, Firestore Timestamps)
  - [x] MemoryService with all methods + error handling
  - [x] Firestore schema + security rules deployed
  - [x] Cloud Function for cleanup deployed
  - [x] Context limits enforced (20 messages, 5 queries)
  - [x] All 20 test scenarios pass
  - [x] Performance targets met
  - [x] Force-quit + multi-device sync verified
  - [x] Documentation complete
  - [x] No warnings, follows shared-standards.md
  ```
- **Acceptance**: PR description complete, references PRD/TODO

### Task 12.3: Open PR
- [ ] **Push branch**: `git push origin feat/pr-004-memory-state`
- [ ] **Open PR targeting `develop`** (NOT main)
- [ ] **Link PRD and TODO** in PR description
- [ ] **Request review** (if applicable)
- **Acceptance**: PR created, ready for review

---

## Definition of Done

- [ ] MemoryService.swift with all methods + error handling ✅
- [ ] 16 data models (Codable, Firestore Timestamps) ✅
- [ ] Firestore schema + security rules deployed ✅
- [ ] Cloud Function for 90-day cleanup deployed ✅
- [ ] Real-time listeners, offline persistence enabled ✅
- [ ] Context limits enforced (20 messages, 5 queries) ✅
- [ ] All 20 test scenarios pass ✅
- [ ] Performance targets met (<100ms fetch, <200ms save, <300ms sync) ✅
- [ ] Force-quit + multi-device sync verified ✅
- [ ] Documentation + PR description complete ✅
- [ ] No warnings, follows shared-standards.md ✅

---

**Estimated Time**: 2-3 days (16-20 hours)  
**Task Count**: 70+ granular tasks  
**Complexity**: Medium-High (Backend infrastructure, no UI)

---

## Notes

- Backend-only feature (no UI components)
- Focus on data integrity and persistence
- Test force-quit scenarios extensively
- Cleanup Cloud Function critical for cost control
- Memory service consumed by future AI features (PR #AI-006+)
- Document schema clearly for future developers

