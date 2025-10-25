# Focus Mode PR Briefs

**Feature**: Focus Mode with AI Prioritization  
**Total Phases**: 5  
**PR Range**: #20-24  
**Created**: January 2025

---

## PR #20: Classification Engine Foundation

**Phase**: 1  
**Priority**: P0  
**Dependencies**: None (foundation feature)

### Brief
Build the AI message classification engine as a Cloud Function that automatically tags messages as "urgent" or "normal". This is the backend foundation for Focus Mode - no UI work in this PR.

### What We're Building
- OpenAI integration service
- Message classification logic with keyword fallback
- Firestore trigger that auto-classifies on message create
- Data model updates (add priority field to messages)
- Classification logging and analytics

### Technical Approach
1. Create `aiPrioritization.ts` service with GPT-3.5 classification
2. Implement keyword-based fast path (urgent words like "ASAP", "emergency")
3. Add Firestore trigger `onCreate` on messages collection
4. Update message documents with `priority`, `classifiedAt`, `classificationReason`
5. Add error handling and timeout logic

### Success Criteria
- [ ] All new messages get priority field within 3s
- [ ] Classification accuracy >85% on test messages
- [ ] Zero impact on message send latency (async processing)
- [ ] OpenAI cost <$5/day for 1000 users
- [ ] All classifications logged for analytics

### Test Plan
- Send 20 test messages (urgent and normal)
- Verify priority field appears in Firestore
- Check classification reasons are reasonable
- Measure latency with timestamps
- Verify keyword detection works

### Files to Create/Modify
**Backend:**
- `functions/src/services/openaiClient.ts` (new)
- `functions/src/services/aiPrioritization.ts` (new)
- `functions/src/triggers/classifyMessage.ts` (new)
- `functions/src/index.ts` (update exports)

**Testing:**
- `MessageAITests/Services/FocusModeClassificationTests.swift` (new)

**Data Model:**
- Update Message model (add priority fields)

---

## PR #21: Focus Mode UI Foundation

**Phase**: 2  
**Priority**: P0  
**Dependencies**: PR #20 (classification must be working)

### Brief
Build the Focus Mode UI: toggle button, banner, and two-section list view (Priority / Review Later). This is pure UI work with local filtering - no AI integration yet.

### What We're Building
- FocusModeService for local state management
- Focus Mode toggle button in toolbar
- FocusModeBanner component
- Two-section conversation list (Priority / Review Later)
- Local chat filtering based on existing priority field
- User preferences model and persistence

### Technical Approach
1. Create FocusModeService (singleton) managing isActive state
2. Add Focus Mode button to ConversationListView toolbar
3. Create FocusModeBanner SwiftUI view with animation
4. Split ConversationListView into two sections when active
5. Filter chats based on latest message priority
6. Persist state to UserDefaults

### Success Criteria
- [ ] Toggle activates/deactivates Focus Mode
- [ ] Banner slides in/out smoothly (<300ms)
- [ ] Chats correctly filter into Priority vs Review Later
- [ ] State persists across app restarts
- [ ] No crashes during 100 toggle cycles
- [ ] Animations at 60fps

### Test Plan
- Toggle Focus Mode on/off 10 times
- Verify chats move between sections correctly
- Kill app and restart - verify state persists
- Test with 0, 1, 10, 100 chats
- Profile animations with Instruments

### Files to Create/Modify
**iOS:**
- `MessageAI/Services/FocusModeService.swift` (new)
- `MessageAI/Views/FocusModeBanner.swift` (new)
- `MessageAI/Models/FocusMode.swift` (new)
- `MessageAI/Views/ConversationListView.swift` (modify)
- `MessageAI/ViewModels/ConversationListViewModel.swift` (modify)

**Testing:**
- `MessageAITests/Services/FocusModeServiceTests.swift` (new)
- `MessageAIUITests/FocusModeFlowUITests.swift` (new)

---

## PR #22: AI-Integrated Focus Mode

**Phase**: 3  
**Priority**: P0  
**Dependencies**: PR #20 + #21

### Brief
Connect the classification engine to the UI. Real-time updates when new messages are classified. Add feedback mechanism for users to report incorrect classifications.

### What We're Building
- Real-time Firestore listener for priority updates
- AIClassificationService for iOS
- Auto-sorting when classifications complete
- Priority badge indicators on chats
- Feedback button ("This should be urgent/normal")

### Technical Approach
1. Create AIClassificationService wrapping Cloud Function calls
2. Set up Firestore listener for message priority changes
3. Update ConversationListView when priority field changes
4. Add feedback button that calls Cloud Function
5. Show loading states during classification
6. Display confidence scores (optional)

### Success Criteria
- [ ] New messages auto-classify within 3s
- [ ] Chat list updates automatically when classified
- [ ] Urgent messages move to Priority section
- [ ] User can submit feedback on classifications
- [ ] No duplicate classifications
- [ ] Graceful error handling if API fails

### Test Plan
- Send urgent message → verify Priority section updates
- Send normal message → verify Review Later section updates
- Submit feedback → verify sent to backend
- Test offline/online transitions
- Measure update latency

### Files to Create/Modify
**iOS:**
- `MessageAI/Services/AIClassificationService.swift` (new)
- `MessageAI/ViewModels/ConversationListViewModel.swift` (modify)
- `MessageAI/Views/ConversationListView.swift` (modify)

**Backend:**
- `functions/src/api/submitFeedback.ts` (new)

**Testing:**
- `MessageAITests/Integration/AIClassificationIntegrationTests.swift` (new)
- `MessageAIUITests/FocusModeRealTimeTests.swift` (new)

---

## PR #23: Session Summarization

**Phase**: 4  
**Priority**: P1  
**Dependencies**: PR #20-22

### Brief
When user turns off Focus Mode, generate an AI summary of what happened during the session. Show modal with overview, action items, decisions, and open questions.

### What We're Building
- GPT-4 summarization service
- Summary generation trigger on Focus Mode deactivation
- FocusSummaryView modal
- Summary caching in Firestore
- Focus sessions data model
- Action items extraction

### Technical Approach
1. Create threadSummarization.ts service with GPT-4
2. HTTP endpoint `getSummary` that fetches messages and generates summary
3. Call endpoint when Focus Mode deactivates
4. Create FocusSummaryView SwiftUI modal
5. Store summary in Firestore for re-viewing
6. Show loading indicator during generation

### Success Criteria
- [ ] Summary generates in <10s for typical session
- [ ] Includes overview + action items + decisions
- [ ] Summary cached in Firestore
- [ ] Modal shows smoothly after deactivation
- [ ] Export/share buttons work
- [ ] User can view past summaries

### Test Plan
- Complete 5-min Focus Mode session with messages
- Deactivate Focus Mode → verify summary appears
- Check summary quality (makes sense, accurate)
- Verify summary cached in Firestore
- Test export functionality
- Test with empty session (no messages)

### Files to Create/Modify
**Backend:**
- `functions/src/services/threadSummarization.ts` (new)
- `functions/src/api/getSummary.ts` (new)
- `functions/src/triggers/generateSummary.ts` (new)

**iOS:**
- `MessageAI/Services/SummaryService.swift` (new)
- `MessageAI/Views/FocusSummaryView.swift` (new)
- `MessageAI/Models/FocusSummary.swift` (new)
- `MessageAI/Services/FocusModeService.swift` (modify)

**Testing:**
- `MessageAITests/Services/SummaryServiceTests.swift` (new)
- `MessageAIUITests/FocusSummaryUITests.swift` (new)

---

## PR #24: Semantic Search (RAG)

**Phase**: 5  
**Priority**: P2  
**Dependencies**: PR #20-23

### Brief
Implement semantic search using RAG (Retrieval Augmented Generation). Users can search for messages by meaning, not just keywords. "When is the meeting?" finds scheduling messages.

### What We're Building
- OpenAI embeddings generation
- Pinecone vector database integration
- Embedding trigger on message create
- Semantic search API endpoint
- SmartSearchView UI
- Search result navigation

### Technical Approach
1. Create embeddingService.ts with OpenAI embeddings
2. Set up Pinecone index for message vectors
3. Trigger to generate embeddings for new messages
4. Semantic search endpoint that queries Pinecone
5. SmartSearchView with search bar and results
6. Navigate to messages from search results

### Success Criteria
- [ ] Embeddings generated for 100% of new messages
- [ ] Search returns relevant results (relevance >0.7)
- [ ] Search latency <2s
- [ ] Results link to correct messages
- [ ] Empty states and suggestions shown
- [ ] Works for 1000+ messages

### Test Plan
- Seed 100 test messages with known content
- Search for "meeting time" → verify finds scheduling
- Search for "deadline" → verify finds dates
- Verify relevance scores make sense
- Test with large dataset (1000+ messages)
- Measure search latency

### Files to Create/Modify
**Backend:**
- `functions/src/services/embeddingService.ts` (new)
- `functions/src/services/pineconeClient.ts` (new)
- `functions/src/triggers/generateEmbedding.ts` (new)
- `functions/src/api/semanticSearch.ts` (new)

**iOS:**
- `MessageAI/Services/SearchService.swift` (new)
- `MessageAI/Views/SmartSearchView.swift` (new)
- `MessageAI/Models/SearchResult.swift` (new)

**Testing:**
- `MessageAITests/Services/SearchServiceTests.swift` (new)
- `MessageAIUITests/SemanticSearchUITests.swift` (new)

---

## Summary

| PR | Phase | Focus | Dependencies |
|----|-------|-------|--------------|
| #20 | 1 | Classification engine | None |
| #21 | 2 | Focus UI | #20 |
| #22 | 3 | AI integration | #20, #21 |
| #23 | 4 | Summarization | #20-22 |
| #24 | 5 | Semantic search | #20-23 |

---

**Next Steps:**
1. Review PR briefs with team
2. Set up OpenAI and Pinecone accounts
3. Create feature flags
4. Start implementation with PR #20
