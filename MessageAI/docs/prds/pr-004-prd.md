# PRD: Memory & State Management System

**Feature**: AI Memory & State  

**Version**: 1.0  

**Status**: Ready for Development  

**Agent**: Pete  

**Target Release**: Phase 1 - Foundation (AI Features)  

**Links**: 
- [PR Brief](../ai-implementation-brief.md#pr-ai-004-memory--state-management-system)
- [TODO](../todos/pr-004-todo.md) - *To be created after PRD approval*
- [Architecture](../architecture.md)

---

## 1. Summary

AI features without memory provide inconsistent, context-less experiences. This PR implements a stateful memory system that enables AI to remember conversation context across sessions, track task state (action items, decisions), learn from user behavior (categorization overrides, tone feedback), and persist data across app restarts. Memory enables follow-up questions ("Who made that decision?"), improves AI accuracy over time through learning, and provides seamless multi-session experiences.

---

## 2. Problem & Goals

### Problem
Current AI features would operate in isolation without shared context or learning capability:
- **No conversation memory**: AI can't answer "What was the decision we discussed yesterday?"
- **Lost task context**: Action items extracted but forgotten after app restart
- **No learning**: AI makes same mistakes repeatedly without improving from user corrections
- **Poor continuity**: Each AI interaction starts fresh with no context from previous sessions
- **Data sprawl**: No unified system for managing AI state leads to inconsistent patterns

**Why now?**
- Foundation for all AI features (PR #AI-006 through PR #AI-011)
- Must be built BEFORE Thread Summarization, Action Items, Priority Detection, and Decision Tracking
- Without memory, AI features can't provide contextual, personalized, learning experiences
- Dependency for PR #AI-002 (User Preferences uses learningData for feedback)

### Goals (Ordered, Measurable)
- [x] **G1** — Store and retrieve session context (last 20 messages, recent queries, active conversation) with <100ms read latency enabling follow-up questions
- [x] **G2** — Persist task state (action items, decisions, completion status) across app restarts with real-time sync <300ms ensuring no lost tasks
- [x] **G3** — Collect and store learning data (categorization overrides, meeting preferences, tone feedback) to improve AI accuracy from 75% → 95%+ over 30 days
- [x] **G4** — Implement 90-day auto-cleanup for privacy compliance while preserving important decisions and completed tasks with user-visible transparency

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep:

- [ ] **Not building AI learning algorithms** — This PR only stores learning data; future ML training pipeline uses it
- [ ] **Not implementing semantic memory search** — PR #AI-008 (Smart Search) handles searching conversation history
- [ ] **Not creating memory visualization UI** — Users interact with memory indirectly through AI features; explicit memory browser deferred to post-MVP
- [ ] **Not building multi-user shared memory** — Memory is user-specific; team-level sharing deferred to post-MVP
- [ ] **Not implementing memory export/import** — Data portability deferred to post-MVP
- [ ] **Not handling complex memory merging** — Last write wins for conflicts; advanced conflict resolution out of scope

---

## 4. Success Metrics

### Performance (See shared-standards.md)
- Fetch context: <100ms (p95) | Save state: <200ms (p95) | Sync: <300ms across devices

### User Experience
- Memory retrieval: <100ms for follow-up questions
- Task persistence: 100% survival rate across force-quit and app restart
- Learning speed: AI accuracy improves 75% → 85%+ after 10 overrides

### Quality
- Data integrity: 100% (no lost tasks or decisions) | Privacy: 90-day cleanup verified | Crash-free: >99.9% | 0 blocking bugs

---

## 5. Users & Stories

### Primary User: Maya (Remote Professional)

**As Maya**, I want AI to remember our last conversation so that I can ask follow-up questions like "Who made that decision?" without repeating context.

**As Maya**, I want my action items to survive app restarts so that I don't lose track of tasks when my phone dies or I force-quit the app.

**As Maya**, I want AI to learn from my corrections (when I manually recategorize messages) so that accuracy improves over time without manual retraining.

**As Maya**, I want decisions logged in conversation history to persist long-term so that I can reference them weeks later when needed.

**As Maya**, I want transparent control over what AI remembers so that I understand data retention and can trust the system respects my privacy.

**As Maya**, I want automatic cleanup of old conversation data so that my AI memory doesn't accumulate forever while preserving important information.

---

## 6. Key Behaviors

**Backend Infrastructure** — Users interact with memory indirectly through other AI features.

### Memory Types & Lifecycle
- **Session Context**: Last 20 messages, expires after 24 hours
- **Task State**: Action items persist until complete, decisions for 90 days
- **Learning Data**: Overrides, preferences, feedback for AI accuracy improvement
- **Cleanup**: 90-day auto-cleanup, important items preserved

### Performance Targets
- Read: <100ms | Write: <200ms | Sync: <300ms | Cleanup: Daily batch job

---

## 7. Functional Requirements

### MUST Requirements

**Session Context**: Last 20 messages, last 5 queries, expires after 24h, sync <300ms

**Task State**: Action items + decisions with metadata, persist across restarts, archive completed tasks after 30 days

**Learning Data**: Log categorization overrides, meeting preferences, tone feedback, tagged by feature source

**Conversation History**: Store AI queries/responses, thread preservation, retrieval by date/feature

**Privacy**: 90-day auto-cleanup (daily Cloud Function), preserve flagged items, user-specific isolation

**Persistence**: Survive force-quit/restart, offline queue syncs <1s on reconnect, last-write-wins conflict resolution

### Deferred to Post-MVP
- Smart memory summarization, importance scoring, semantic search, export/import

---

## 8. Data Model

### Firestore Schema: `/users/{userId}/aiState/`

**sessionContext** (document)
- currentConversationId, lastActiveTimestamp
- recentMessages[]: messageId, chatId, senderId, text (200 chars), timestamp (max 20)
- recentQueries[]: queryId, queryText, responseText (300 chars), featureSource, timestamp (max 5)

**taskState** (document)
- actionItems[]: id, taskDescription, chatId, messageId, extractedBy, assignee, deadline, priority, completionStatus, timestamps
- decisions[]: id, decisionText, participants[], chatId, messageId, detectedBy, confidence, isImportant, tags[], createdAt

**learningData/** (subcollection, auto-generated IDs)
- entryType: categorizationOverride | meetingPreference | toneFeedback
- Feature-specific data fields (messageId, categories, context, suggestions, feedback)
- Common: userId, featureSource, timestamp, createdAt

**conversationHistory/** (subcollection, auto-generated IDs)
- userQuery, aiResponse, featureSource, contextUsed[], confidence, wasHelpful, timestamp

### Validation Rules

**Firestore Security Rules**
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

### Indexing/Queries

**Firestore Composite Indexes**
```
Collection: /users/{userId}/aiState/learningData/
Fields: timestamp (DESC), entryType (ASC)
Purpose: Query recent learning data by type for pattern analysis

Collection: /users/{userId}/aiState/conversationHistory/
Fields: timestamp (DESC), featureSource (ASC)
Purpose: Query recent conversations by feature for context retrieval
```

---

## 9. Service API (MemoryService.swift)

### Key Methods

**Session Context**
- `fetchSessionContext()` → SessionContext (<100ms)
- `updateSessionContext(message?, query?)` → Prunes oldest if >20 messages
- `clearExpiredContext()` → Removes >24h old entries
- `getRecentContext(limit: 20)` → Array for AI prompts

**Task State**
- `fetchTaskState()` → TaskState with items + decisions
- `addActionItem(item)`, `updateActionItemStatus(id, status)`
- `addDecision(decision)`, `flagDecisionAsImportant(id)`
- `archiveOldTasks()` → Cleanup >30 days completed

**Learning & History**
- `logCategorizationOverride(messageId, categories, context)`
- `logMeetingPreference(preference)`, `logToneFeedback(feedback)`
- `saveConversation(query, response, featureSource, contextUsed, confidence)`
- `fetchLearningData(days, type?)`, `fetchConversationHistory(days, feature?)`

**Utility**
- `clearMemory()` → Preserves important items
- `getMemoryStats()` → Transparency metrics
- `observeTaskState(completion)` → Real-time listener

### Error Types
- contextLimitExceeded, invalidTaskState, sessionExpired, dataCorruption, missingUserId, networkError

---

## 10. Implementation Files

**Models** (16 files in `Models/AI/`)
- SessionContext, ContextMessage, AIQuery, TaskState, TaskItem, DecisionItem
- TaskPriority, TaskStatus, LearningDataEntry, LearningType
- CategorizationOverride, MeetingPreference, ToneFeedback
- ConversationHistoryEntry, AIFeature, MemoryStats

**Services**
- `Services/AI/MemoryService.swift` — Core implementation

**Initialization**
- `MessageAIApp.swift` — Initialize MemoryService on launch

**Note**: Backend only, no UI components

---

## 11. Integration Points

**Firebase**: Firestore for storage/sync, Auth for security, Cloud Functions for cleanup (daily 90-day, weekly aggregation, daily task archiving)

**Consumed By**:
- PR #AI-006 (Thread Summary) — sessionContext
- PR #AI-007 (Action Items) — taskState
- PR #AI-009 (Priority Detection) — learningData
- PR #AI-010 (Decision Tracking) — taskState + conversationHistory
- PR #AI-011 (Proactive Assistant) — meetingPreference

---

## 12. Test Plan

**Happy Path** (6 tests)
- Session context tracking (5 messages), task persistence across restart, learning data logging, decision storage, real-time sync <300ms, conversation history retrieval

**Edge Cases** (6 tests)
- Context limit (20 max, prune oldest), expired context cleanup (24h), concurrent updates (last write wins), network failure (queue + retry), missing auth, data corruption recovery

**Privacy & Cleanup** (4 tests)
- 90-day auto-cleanup, important item preservation, manual clear, data isolation

**Performance** (4 tests)
- Fetch <100ms, save <200ms, force-quit recovery, offline persistence + sync <1s

**Total**: 20 test scenarios (Swift Testing + XCTest)

---

## 13. Definition of Done

- [ ] MemoryService.swift with all methods + error handling
- [ ] 16 data models (Codable, Firestore Timestamps)
- [ ] Firestore schema + security rules deployed
- [ ] Real-time listeners, offline persistence enabled
- [ ] Context limits enforced (20 messages, 5 queries)
- [ ] 90-day cleanup Cloud Function
- [ ] All 20 test scenarios pass
- [ ] Performance targets met (<100ms fetch, <200ms save, <300ms sync)
- [ ] Force-quit + multi-device sync verified
- [ ] Documentation + PR description complete
- [ ] No warnings, follows shared-standards.md

---

## 14. Risks & Mitigations

**Memory Growth** → Strict limits (20 messages, 5 queries), auto-pruning, 90-day cleanup, 30-day task archiving

**Data Loss (force-quit/crash)** → Firestore offline persistence, local cache first, background sync, extensive QA testing

**Privacy Concerns** → Transparent disclosure, user-specific isolation, 90-day cleanup, no cross-user sharing

**Cleanup Failure** → Daily Cloud Function with retry, monitoring + alerts, client-side fallback

---

## 15. Rollout & Validation

**Feature Flag**: `ai_memory_enabled` (5% → 20% → 50% → 100%)

**Key Metrics**: Fetch/save success rate, sync latency, task persistence rate, AI accuracy improvement, override frequency (should decrease)

**Validation**: 2-device sync test, schema verification, context limits (25→20), 91-day cleanup, force-quit recovery

---

## 16. Deferred Features

- Memory visualization UI, semantic memory search (PR #AI-008), smart summarization (PR #AI-012)
- Importance auto-scoring, export/import, team-level sharing, conflict resolution UI

---

## Summary

**Smallest End-to-End Outcome:** User interacts with AI feature → Session context saved <200ms → Task/decision persists across force-quit → Learning data logged → AI accuracy improves over time.

**Key Design Decisions:**
1. Single collection (`/users/{userId}/aiState/`) with subcollections for organization
2. Real-time task state sync via Firestore listeners (no manual refresh)
3. Strict limits: 20 messages, 5 queries in session context (prevents unbounded growth)
4. 90-day cleanup for transient data, indefinite retention for important items
5. Backend-only service (no UI for MVP); consumed by other AI features

**Dependencies:**
- **PR #AI-002 (User Preferences):** Uses learningData structure defined here
- **Enables PR #AI-006 through PR #AI-011:** All AI features depend on memory for context, persistence, and learning

**Testing:** Unit tests (Swift Testing), force-quit/restart scenarios, multi-device sync

---

**Author:** Pete Agent (Product Manager)  
**Status:** Ready for Review  
**Next Step:** Await user approval → Create TODO  
**Estimated Implementation:** 2-3 days (14-16 tasks)

