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

- [ ] Create branch `feat/pr-24-semantic-search` from saturday-ai
- [ ] Read PRD thoroughly
- [ ] Read `MessageAI/agents/shared-standards.md` for patterns
- [ ] Confirm environment and test runner work
- [ ] Set up Pinecone account and get API key
- [ ] Verify OpenAI API access for embeddings

---

## 2. Service Layer

Implement deterministic service contracts from PRD.

- [ ] Implement SearchService.swift
  - Test Gate: Unit test passes for valid/invalid cases
  - Methods: searchMessages, getSearchHistory, clearSearchHistory
- [ ] Implement PineconeService.swift
  - Test Gate: Unit test passes for vector operations
  - Methods: upsertEmbedding, querySimilar, deleteEmbedding
- [ ] Implement Cloud Functions API endpoints
  - Test Gate: API responds correctly to test requests
  - Endpoints: /api/semanticSearch, /api/generateEmbedding
- [ ] Add validation logic for search queries and embeddings
  - Test Gate: Edge cases handled correctly (empty queries, invalid vectors)

---

## 3. Data Model & Rules

- [ ] Define SearchResult.swift model
  - Test Gate: Model serializes/deserializes correctly
- [ ] Define SearchQuery.swift model
  - Test Gate: Model handles search history properly
- [ ] Update Message.swift to include embedding fields
  - Test Gate: Backward compatibility maintained
- [ ] Update Firestore schema for new collections
  - Test Gate: Reads/writes succeed with new schema
- [ ] Add Firebase security rules for search collections
  - Test Gate: User-specific access enforced

---

## 4. UI Components

Create/modify SwiftUI views per PRD Section 10.

- [ ] Create SmartSearchView.swift
  - Test Gate: SwiftUI Preview renders; zero console errors
  - Features: Search input, results list, loading states
- [ ] Create SearchResultRow.swift
  - Test Gate: Displays search result correctly
  - Features: Message preview, relevance indicator, tap navigation
- [ ] Create SearchHistoryView.swift
  - Test Gate: Shows recent searches properly
  - Features: Recent queries list, clear history option
- [ ] Modify ConversationListView.swift
  - Test Gate: Search button appears and functions
  - Features: Add search button to navigation
- [ ] Wire up state management (@StateObject for SearchService)
  - Test Gate: Search state updates correctly
- [ ] Add loading/error/empty states for all views
  - Test Gate: All states render correctly with proper messaging

---

## 5. Integration & Real-Time

Reference requirements from `MessageAI/agents/shared-standards.md`.

- [ ] Firebase service integration for search history
  - Test Gate: Search history persists across app restarts
- [ ] Real-time embedding generation trigger
  - Test Gate: New messages get embeddings within 30s
- [ ] Offline search with cached results
  - Test Gate: Search works offline with cached data
- [ ] Search result navigation to specific messages
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
- [ ] Search returns relevant results with >0.7 relevance score
- [ ] New message embedding generated within 30s
- [ ] Tapping search result navigates to exact message
- [ ] Offline search shows cached results with indicator
- [ ] Search results are user-specific
- [ ] Concurrent searches don't interfere
- [ ] Search latency <2s for 90% of queries
- [ ] Embedding generation <30s per message
- [ ] Smooth scrolling through 100+ results
- [ ] App remains responsive during search

---

## 9. Documentation & PR

- [ ] Add inline code comments for complex logic
- [ ] Update README with search feature documentation
- [ ] Create PR description with implementation summary in cli command in git
- [ ] Verify with user before creating PR
- [ ] Open PR targeting saturday-ai branch
- [ ] Link PRD and TODO in PR description

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from saturday-ai
- [ ] All TODO tasks completed
- [ ] Services implemented + unit tests (Swift Testing)
- [ ] SwiftUI views implemented with state management
- [ ] Firebase integration tested (search history, offline)
- [ ] UI tests pass (XCTest)
- [ ] Multi-device sync verified
- [ ] Performance targets met (see shared-standards.md)
- [ ] All acceptance gates pass
- [ ] Code follows shared-standards.md patterns
- [ ] No console warnings
- [ ] Documentation updated
- [ ] Pinecone integration working
- [ ] OpenAI embeddings generation working
- [ ] Search result navigation working
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
