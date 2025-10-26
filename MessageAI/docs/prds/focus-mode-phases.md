# Focus Mode: Phased Implementation Plan

**Feature**: Focus Mode with AI Prioritization  
**Status**: Planning  
**Owner**: Claudia Alban  
**Created**: January 2025

---

## 📋 Overview

This document breaks down the Focus Mode PRD into manageable phases, each delivered as a separate PR with clear deliverables.

**Total Phases**: 5  
**Dependencies**: Foundation features (auth, messaging, chat)

---

## 🎯 Phase Breakdown

### Phase 1: Foundation + Classification Engine
**PR**: #20  
**Goal**: Build AI message classification backend without UI

#### Deliverables
- ✅ OpenAI integration (Cloud Function)
- ✅ Message classification service
- ✅ Firestore trigger for auto-classification
- ✅ Data model updates (priority field)
- ✅ Keyword-based urgency detection
- ✅ Classification logging/analytics

#### Success Criteria
- ✅ Messages auto-classified as urgent/normal within 3s
- ✅ Classification accuracy >85% on test set
- ✅ Firestore updated with priority field
- ✅ No impact on message send latency

#### Key Files
**Backend:**
- `functions/src/services/openaiClient.ts`
- `functions/src/services/aiPrioritization.ts`
- `functions/src/triggers/classifyMessage.ts`

**Testing:**
- `MessageAITests/Services/FocusModeClassificationTests.swift`

---

### Phase 2: Focus Mode UI Foundation
**PR**: #21  
**Goal**: Basic Focus Mode toggle and UI structure

#### Deliverables
- ✅ FocusModeService implementation
- ✅ Focus Mode toggle (toolbar button)
- ✅ FocusModeBanner component
- ✅ Two-section list view (Priority / Review Later)
- ✅ Local state management
- ✅ User preferences model

#### Success Criteria
- Toggle activates/deactivates Focus Mode
- Banner appears with correct count badges
- Chats filter into Priority vs Review Later
- State persists across app restarts
- Smooth animations (no jank)

#### Key Files
**iOS:**
- `MessageAI/Services/FocusModeService.swift`
- `MessageAI/Views/FocusModeBanner.swift`
- `MessageAI/Views/ConversationListView.swift` (updates)
- `MessageAI/ViewModels/ConversationListViewModel.swift` (updates)
- `MessageAI/Models/FocusMode.swift`

**Testing:**
- `MessageAITests/Services/FocusModeServiceTests.swift`
- `MessageAIUITests/FocusModeFlowUITests.swift`

---

### Phase 3: AI-Integrated Focus Mode ✅ COMPLETE
**PR**: #22  
**Goal**: Connect classification engine to UI

#### Deliverables
- ✅ Real-time classification listening
- ✅ Priority badge indicators on chats
- ✅ Auto-sorting based on priority
- ✅ Classification confidence display (optional)
- ✅ Feedback mechanism ("This should be urgent/normal")

#### Success Criteria
- ✅ New messages auto-classified on receive
- ✅ Chat list updates automatically
- ✅ Urgent messages move to Priority section
- ✅ Classification happens in <3s
- ✅ User can report incorrect classification

#### Key Files
**Integration:**
- `MessageAI/Services/AIClassificationService.swift` (new)
- `MessageAI/ViewModels/ConversationListViewModel.swift` (updates)
- Real-time Firestore listeners for priority updates

**Testing:**
- `MessageAITests/Integration/AIClassificationIntegrationTests.swift`
- `MessageAIUITests/FocusModeRealTimeTests.swift`

---

### Phase 4: Session Summarization
**PR**: #23  
**Goal**: AI-generated summaries when Focus Mode ends

#### Deliverables
- ✅ GPT-4 summarization service
- ✅ Summary generation on deactivation
- ✅ FocusSummaryView modal
- ✅ Summary caching in Firestore
- ✅ Focus sessions data model
- ✅ Action items extraction

#### Success Criteria
- Summary generates in <10s
- Includes overview + action items + decisions
- Summary cached for re-viewing
- Modal shows smoothly after deactivation
- Export/share functionality works

#### Key Files
**Backend:**
- `functions/src/services/threadSummarization.ts`
- `functions/src/api/getSummary.ts`
- `functions/src/triggers/generateSummary.ts`

**iOS:**
- `MessageAI/Services/SummaryService.swift`
- `MessageAI/Views/FocusSummaryView.swift`
- `MessageAI/Models/FocusSummary.swift`

**Testing:**
- `MessageAITests/Services/SummaryServiceTests.swift`
- `MessageAIUITests/FocusSummaryUITests.swift`

---

### Phase 5: Semantic Search (RAG Pipeline)
**PR**: #24  
**Goal**: Semantic search across message history

#### Deliverables
- ✅ OpenAI embeddings generation
- ✅ Pinecone vector database integration
- ✅ Embedding generation trigger
- ✅ Semantic search API endpoint
- ✅ SmartSearchView UI
- ✅ Search result navigation

#### Success Criteria
- Embeddings generated for all new messages
- Search returns relevant results (relevance >0.7)
- Search latency <2s
- Results link to correct messages
- Empty states and suggestions shown

#### Key Files
**Backend:**
- `functions/src/services/embeddingService.ts`
- `functions/src/services/pineconeClient.ts`
- `functions/src/triggers/generateEmbedding.ts`
- `functions/src/api/semanticSearch.ts`

**iOS:**
- `MessageAI/Services/SearchService.swift`
- `MessageAI/Views/SmartSearchView.swift`
- `MessageAI/Models/SearchResult.swift`

**Testing:**
- `MessageAITests/Services/SearchServiceTests.swift`
- `MessageAIUITests/SemanticSearchUITests.swift`

---

---

## 🔗 Dependencies

### Phase 1 Dependencies
- Firebase project configured
- OpenAI API key set
- Cloud Functions deployed
- Message model exists

### Phase 2 Dependencies
- Phase 1 complete (classification working)
- Conversation list UI exists
- MVVM architecture in place

### Phase 3 Dependencies
- Phase 1 + 2 complete
- Real-time Firestore listeners implemented
- Notification system working

### Phase 4 Dependencies
- Phase 1-3 complete
- Focus sessions tracking implemented
- Modal presentation patterns established

### Phase 5 Dependencies
- Phase 1-4 complete
- Pinecone account created
- Embedding API access confirmed

---

## 📊 Success Metrics by Phase

### Phase 1 Metrics
- ✅ 95% of messages classified within 3s
- ✅ Classification accuracy >85% (test set)
- ✅ Zero impact on message send latency
- ✅ OpenAI API cost <$5/day

### Phase 2 Metrics
- [ ] Focus Mode toggle responds in <300ms
- [ ] UI animations at 60fps
- [ ] No crashes during 100 toggle cycles
- [ ] State persists across app kills

### Phase 3 Metrics
- ✅ Auto-classification works for 95% of messages
- ✅ List updates within 5s of classification
- ✅ User feedback submission rate >5%
- ✅ Classification accuracy improves to >90%

### Phase 4 Metrics
- [ ] Summary generates in <10s for 80% of sessions
- [ ] Summary viewed by 60% of users
- [ ] Export functionality used by 10% of users
- [ ] User satisfaction >4.5/5

### Phase 5 Metrics
- [ ] Embeddings generated for 100% of new messages
- [ ] Search results relevance score >0.7
- [ ] Search latency <2s for 90% of queries
- [ ] Daily search usage >20% of active users

---

## 🚨 Risks by Phase

### Phase 1 Risks
- **High API costs** → Mitigation: Rate limiting, keyword pre-filtering
- **Slow classification** → Mitigation: Async processing, timeout fallbacks
- **Low accuracy** → Mitigation: Keyword fallback, continuous tuning

### Phase 2 Risks
- **UI performance issues** → Mitigation: Efficient list rendering, lazy loading
- **State management bugs** → Mitigation: Comprehensive unit tests
- **Animation jank** → Mitigation: Use SwiftUI animations, profile with Instruments

### Phase 3 Risks
- **Real-time sync issues** → Mitigation: Robust Firestore listeners, error handling
- **User confusion** → Mitigation: Clear visual indicators, onboarding flow
- **Battery drain** → Mitigation: Throttle listener updates, optimize queries

### Phase 4 Risks
- **Summary generation failures** → Mitigation: Retry logic, graceful degradation
- **High OpenAI costs** → Mitigation: Token limits, caching, batch processing
- **Poor summary quality** → Mitigation: Prompt engineering, user feedback loop

### Phase 5 Risks
- **Pinecone dependency** → Mitigation: Fallback to keyword search, error handling
- **Embedding generation lag** → Mitigation: Batch processing, async processing
- **Search accuracy issues** → Mitigation: Hybrid search (vector + keyword), feedback loop

---

## ✅ Acceptance Criteria (Overall)

### Must-Have (MVP)
- ✅ Messages classified as urgent/normal
- [ ] Focus Mode toggle works
- [ ] Two-section list view (Priority/Review Later)
- ✅ Real-time classification updates
- ✅ Classification in <3s
- [ ] Summary generation on deactivation
- [ ] Semantic search functionality

### Should-Have (Phase 1-3)
- ✅ Classification accuracy >90%
- ✅ User feedback mechanism
- [ ] Focus session tracking
- [ ] Summary caching

### Nice-to-Have (Future)
- [ ] Auto-activate schedules
- [ ] Custom urgency keywords
- [ ] Multi-device sync
- [ ] Export to Notes
- [ ] Voice search

---

## 📝 Next Steps

1. **Review this phased plan** with engineering team
2. **Create individual PR briefs** for each phase (PR #20-24)
3. **Set up OpenAI and Pinecone accounts**
4. **Create feature flags** for gradual rollout
5. **Define analytics events** for each phase
6. **Begin Phase 1 implementation** (PR #20)

---

## 🤝 Team Handoff

**For Cody Agent (Implementation):**
- Start with PR #20 (Phase 1: Foundation)
- Follow Pete's TODO for each phase
- Test after each phase before moving to next

**For Pete Agent (Planning):**
- Create detailed PRDs for each phase (optional)
- Create TODO files for each phase (pr-20-todo.md, pr-21-todo.md, etc.)
- Monitor success metrics for each phase

---

**Last Updated**: January 2025  
**Status**: Ready for Implementation Planning
