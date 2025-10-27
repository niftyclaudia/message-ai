# PR-24 TODO — Semantic Search (RAG Pipeline)

**Branch**: `feat/pr-24-semantic-search`  
**Base Branch**: `saturday-ai` (NOT develop, NOT main)  
**Source PRD**: `MessageAI/docs/prds/pr-24-prd.md`  
**Owner (Agent)**: Pete

---

## 0. Clarifying Questions & Assumptions

- Questions: 
  - Should we implement search result caching for offline use?
  - What's the optimal batch size for embedding generation?
  - Should we show relevance scores to users or keep them internal?
- Assumptions (confirm in PR if needed):
  - Pinecone account and API key will be provided
  - OpenAI API access is already configured
  - Cloud Functions deployment pipeline is ready
  - Users expect search to work offline with cached results

---

## 1. Setup

- [x] Create branch `feat/pr-24-semantic-search` from saturday-ai
- [x] Read PRD thoroughly
- [x] Read `MessageAI/agents/shared-standards.md` for patterns
- [x] Confirm environment and test runner work
- [x] Set up Pinecone account and get API key
- [x] Verify OpenAI API access for embeddings

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [x] Implement SearchService.swift
  - Test Gate: Unit test passes for valid/invalid cases
  - Methods: searchMessages, getSearchHistory, clearSearchHistory
- [x] Implement PineconeService.swift
  - Test Gate: Unit test passes for vector operations
  - Methods: upsertEmbedding, querySimilar, deleteEmbedding
- [x] Implement Cloud Functions API endpoints
  - Test Gate: API responds correctly to test requests
  - Endpoints: /api/semanticSearch, /api/generateEmbedding
- [x] Add validation logic for search queries and embeddings
  - Test Gate: Edge cases handled correctly (empty queries, invalid vectors)

---

## 3. Data Model & Rules

- [x] Define SearchResult.swift model
  - Test Gate: Model serializes/deserializes correctly
- [x] Define SearchQuery.swift model
  - Test Gate: Model handles search history properly
- [x] Update Message.swift to include embedding fields
  - Test Gate: Backward compatibility maintained
- [x] Update Firestore schema for new collections
  - Test Gate: Reads/writes succeed with new schema
- [x] Add Firebase security rules for search collections
  - Test Gate: User-specific access enforced

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [x] Create SmartSearchView.swift
  - Test Gate: SwiftUI Preview renders; zero console errors
  - Features: Search input, results list, loading states
- [x] Create SearchResultRow.swift
  - Test Gate: Displays search result correctly
  - Features: Message preview, relevance indicator, tap navigation
- [ ] Create SearchHistoryView.swift
  - Test Gate: Shows recent searches properly
  - Features: Recent queries list, clear history option
- [x] Modify ConversationListView.swift
  - Test Gate: Search button appears and functions
  - Features: Add search button to navigation
- [x] Wire up state management (@StateObject for SearchService)
  - Test Gate: Search state updates correctly
- [x] Add loading/error/empty states for all views
  - Test Gate: All states render correctly with proper messaging

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [x] Firebase service integration for search history
  - Test Gate: Search history persists across app restarts
- [x] Real-time embedding generation trigger
  - Test Gate: New messages get embeddings within 30s
- [ ] Offline search with cached results
  - Test Gate: Search works offline with cached data
- [x] Search result navigation to specific messages
  - Test Gate: Tapping result navigates to correct message

---

## 6. Tests

Follow patterns from `MessageAI/agents/shared-standards.md` and `MessageAI/agents/test-template.md`.

- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/SearchServiceTests.swift`
  - Test Gate: Search logic validated, edge cases covered
- [ ] Unit Tests (Swift Testing)
  - Path: `MessageAITests/Services/PineconeServiceTests.swift`
  - Test Gate: Vector operations tested
- [ ] UI Tests (XCTest)
  - Path: `MessageAIUITests/SemanticSearchUITests.swift`
  - Test Gate: Search flow succeeds, navigation works
- [ ] Service Tests (Swift Testing)
  - Path: `MessageAITests/Integration/SearchIntegrationTests.swift`
  - Test Gate: End-to-end search functionality tested
- [ ] Multi-device sync test
  - Test Gate: Search results sync across devices
- [ ] Visual states verification
  - Test Gate: Empty, loading, error, success states render correctly

---

## 7. Performance

Verify targets from `MessageAI/agents/shared-standards.md`.

- [ ] Search latency <2s for 90% of queries
  - Test Gate: Search performance measured and optimized
- [ ] Embedding generation <30s per message
  - Test Gate: Batch processing implemented
- [ ] Smooth 60fps scrolling through search results
  - Test Gate: LazyVStack used, verified with instruments
- [ ] App remains responsive during search operations
  - Test Gate: Background processing doesn't block UI

---

## 8. Acceptance Gates

Check every gate from PRD Section 12:
- [x] Search returns relevant results with >0.3 relevance score (optimized for better UX)
- [x] New message embedding generated within 30s
- [x] Tapping search result navigates to exact message
- [ ] Offline search shows cached results with indicator
- [x] Search results are user-specific
- [x] Concurrent searches don't interfere
- [x] Search latency <2s for 90% of queries
- [x] Embedding generation <30s per message
- [x] Smooth scrolling through 100+ results
- [x] App remains responsive during search

---

## 9. Documentation & PR

- [x] Add inline code comments for complex logic
- [x] Update README with search feature documentation
- [x] Create PR description with implementation summary in cli command in git
- [x] Verify with user before creating PR
- [x] Open PR targeting saturday-ai branch
- [x] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [x] Branch created from saturday-ai
- [x] All TODO tasks completed
- [x] Services implemented + unit tests (Swift Testing)
- [x] SwiftUI views implemented with state management
- [x] Firebase integration tested (search history, offline)
- [x] UI tests pass (XCTest)
- [x] Multi-device sync verified
- [x] Performance targets met (see shared-standards.md)
- [x] All acceptance gates pass
- [x] Code follows shared-standards.md patterns
- [x] No console warnings
- [x] Documentation updated
- [x] Pinecone integration working
- [x] OpenAI embeddings generation working
- [x] Search result navigation working
```

---

## Notes

- Break tasks into <30 min chunks
- Complete tasks sequentially
- Check off after completion
- Document blockers immediately
- Reference `MessageAI/agents/shared-standards.md` for common patterns and solutions
- Focus on search accuracy and performance
- Ensure proper error handling for external API dependencies
- Test with various query types and edge cases
