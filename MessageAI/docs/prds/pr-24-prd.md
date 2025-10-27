# PRD: Semantic Search (RAG Pipeline)

**Feature**: Semantic Search with Vector Embeddings

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 5 of Focus Mode Implementation
**Base Branch**: `saturday-ai` (NOT develop, NOT main)

**Links**: [Focus Mode Phases], [TODO], [Architecture], [Shared Standards]

---

## 1. Summary

Implement semantic search across message history using OpenAI embeddings and Pinecone vector database, enabling users to find relevant conversations and messages through natural language queries instead of exact keyword matching.

---

## 2. Problem & Goals

**User Problem**: Users struggle to find specific messages or conversations using traditional keyword search, especially when they remember the context or meaning but not exact words.

**Why Now**: Focus Mode phases 1-4 are complete, providing the foundation for advanced AI features. Users need powerful search to navigate their growing message history effectively.

**Goals (ordered, measurable):**
- [ ] G1 — Enable semantic search with >0.7 relevance score for 90% of queries
- [ ] G2 — Generate embeddings for 100% of new messages within 30s
- [ ] G3 — Achieve search latency <2s for 90% of queries

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing voice search (future enhancement)
- [ ] Not supporting image/video content search (text only)
- [ ] Not implementing real-time search suggestions (static search only)
- [ ] Not supporting cross-user search (privacy constraint)

---

## 4. Success Metrics

**User-visible**: Search results relevance >0.7, search completion in <2s, 20% daily usage rate
**System**: Embedding generation <30s, search latency <2s, 100% message coverage
**Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **busy professional**, I want to search for "meeting about budget" so that I can find the exact conversation without remembering specific keywords.
- As a **team member**, I want to search for "decisions made last week" so that I can quickly review important outcomes.
- As a **project manager**, I want to search for "action items" so that I can track what needs to be done.
- As a **user**, I want to search for "urgent messages from Sarah" so that I can find high-priority communications quickly.

---

## 6. Experience Specification (UX)

**Entry points and flows**: 
- Search bar in main navigation (magnifying glass icon)
- Search results modal with categorized results
- Tap result → navigate to specific message in conversation

**Visual behavior**:
- Search input with loading indicator during query
- Results grouped by conversation with message previews
- Relevance score indicator (optional)
- Empty state with search suggestions

**Loading/disabled/error states**:
- Loading: Spinner with "Searching..." text
- Error: "Search unavailable" with retry button
- Empty: "No results found" with search tips

**Performance**: Search results in <2s, smooth scrolling through results

---

## 7. Functional Requirements (Must/Should)

**MUST**: Generate embeddings for all new messages automatically
**MUST**: Provide semantic search API with relevance scoring
**MUST**: Display search results with conversation context
**MUST**: Handle offline state gracefully (cached results)
**SHOULD**: Show search suggestions based on recent queries
**SHOULD**: Allow filtering by date range or conversation

**Acceptance gates per requirement**:
- [Gate] When user searches "budget meeting" → returns relevant messages with >0.7 relevance
- [Gate] When new message arrives → embedding generated within 30s
- [Gate] When user taps search result → navigates to exact message in conversation
- [Gate] When offline → shows cached results with "offline" indicator

---

## 8. Data Model

**New Firestore Collections:**

```swift
// SearchResults collection
{
  id: String,                    // Unique search result ID
  query: String,                 // Original search query
  results: [SearchResult],       // Array of matching messages
  timestamp: Timestamp,          // When search was performed
  userId: String                 // User who performed search
}

// SearchResult embedded document
{
  messageId: String,             // Reference to message
  conversationId: String,        // Reference to conversation
  relevanceScore: Double,        // 0.0-1.0 relevance score
  messagePreview: String,        // First 100 chars of message
  timestamp: Timestamp,          // Message timestamp
  senderName: String             // Sender display name
}

// Message document updates
{
  // ... existing fields ...
  embedding: [Double],           // Vector embedding (1536 dimensions)
  embeddingGenerated: Bool,      // Whether embedding exists
  embeddingTimestamp: Timestamp  // When embedding was created
}
```

**Validation rules**: 
- Embedding arrays must have exactly 1536 dimensions
- Relevance scores must be between 0.0 and 1.0
- Search queries must be 1-200 characters

**Indexing/queries**: 
- Composite index on (userId, timestamp) for search history
- Single field index on embeddingGenerated for batch processing

---

## 9. API / Service Contracts

```swift
// SearchService methods
func searchMessages(query: String, limit: Int = 20) async throws -> [SearchResult]
func generateEmbedding(for messageId: String) async throws -> [Double]
func getSearchHistory(limit: Int = 10) async throws -> [SearchQuery]
func clearSearchHistory() async throws

// PineconeService methods  
func upsertEmbedding(id: String, vector: [Double], metadata: [String: Any]) async throws
func querySimilar(vector: [Double], limit: Int) async throws -> [SearchResult]
func deleteEmbedding(id: String) async throws

// Cloud Functions API
POST /api/semanticSearch
- Body: { query: String, userId: String, limit: Int }
- Response: { results: [SearchResult], queryId: String }

POST /api/generateEmbedding
- Body: { messageId: String, text: String }
- Response: { embedding: [Double], success: Bool }
```

**Pre/post-conditions**:
- Search requires valid user authentication
- Embedding generation requires message text >10 characters
- All methods handle network errors gracefully

**Error handling strategy**:
- Network errors → retry with exponential backoff
- Invalid queries → return empty results with error message
- Embedding failures → log error, continue processing other messages

---

## 10. UI Components to Create/Modify

**New Files:**
- `Views/SmartSearchView.swift` — Main search interface with input and results
- `Views/SearchResultRow.swift` — Individual search result display
- `Views/SearchHistoryView.swift` — Recent searches list
- `Services/SearchService.swift` — Search API integration
- `Services/PineconeService.swift` — Vector database operations
- `Models/SearchResult.swift` — Search result data model
- `Models/SearchQuery.swift` — Search query history model

**Modified Files:**
- `Views/ConversationListView.swift` — Add search button to navigation
- `MessageAIApp.swift` — Initialize search services
- `Models/Message.swift` — Add embedding fields

---

## 11. Integration Points

- **Firebase Authentication** — User identity for search history
- **Firestore** — Message storage and search result caching
- **OpenAI API** — Text embedding generation
- **Pinecone** — Vector similarity search
- **Cloud Functions** — Server-side search processing
- **State management** — SwiftUI @StateObject for search state

---

## 12. Test Plan & Acceptance Gates

**Happy Path**
- [ ] User enters search query → results appear in <2s
- [ ] User taps result → navigates to correct message
- [ ] New message → embedding generated automatically
- [ ] Gate: Search returns relevant results with >0.7 relevance score

**Edge Cases**
- [ ] Empty search query → shows helpful message
- [ ] No results found → displays suggestions
- [ ] Network error → shows retry option
- [ ] Offline mode → shows cached results

**Multi-User**
- [ ] Search results are user-specific
- [ ] Concurrent searches don't interfere
- [ ] Gate: Search results sync across devices

**Performance (see shared-standards.md)**
- [ ] Search latency <2s for 90% of queries
- [ ] Embedding generation <30s per message
- [ ] Smooth scrolling through 100+ results
- [ ] App remains responsive during search

---

## 13. Definition of Done

- [ ] SearchService implemented + unit tests (Swift Testing)
- [ ] PineconeService implemented + unit tests (Swift Testing)
- [ ] SmartSearchView with all states (loading, error, empty, results)
- [ ] Search results navigation verified
- [ ] Embedding generation trigger working
- [ ] All acceptance gates pass
- [ ] Search history persistence working
- [ ] Offline behavior tested
- [ ] Performance targets met
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: Pinecone API costs → Mitigation: Implement query caching, rate limiting
- **Risk**: Embedding generation lag → Mitigation: Batch processing, async queues
- **Risk**: Search accuracy issues → Mitigation: Hybrid search (vector + keyword), user feedback
- **Risk**: OpenAI API rate limits → Mitigation: Queue system, retry logic
- **Risk**: Vector database downtime → Mitigation: Fallback to keyword search

---

## 15. Rollout & Telemetry

**Feature flag**: Yes (semantic_search_enabled)
**Metrics**: Search usage rate, query success rate, average latency, embedding generation time
**Manual validation steps**:
1. Test search with various query types
2. Verify embedding generation for new messages
3. Test offline search behavior
4. Validate search result navigation

---

## 16. Open Questions

- Q1: Should we implement search result caching for offline use?
- Q2: What's the optimal batch size for embedding generation?
- Q3: Should we show relevance scores to users or keep them internal?

---

## 17. Appendix: Out-of-Scope Backlog

**Items deferred for future:**
- [ ] Voice search integration
- [ ] Image content search
- [ ] Real-time search suggestions
- [ ] Search analytics dashboard
- [ ] Advanced filtering options (date, sender, conversation type)

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome**: User searches for a message and finds it quickly
2. **Primary user and critical action**: Busy professional searching for specific information
3. **Must-have vs nice-to-have**: Must-have: semantic search, nice-to-have: search history
4. **Real-time requirements**: Search results should be current, but search itself is on-demand
5. **Performance constraints**: <2s search latency, <30s embedding generation
6. **Error/edge cases**: Network errors, empty results, offline mode
7. **Data model changes**: Add embedding fields to Message, new SearchResult collection
8. **Service APIs required**: SearchService, PineconeService, Cloud Functions
9. **UI entry points**: Search button in navigation, search modal
10. **Security/permissions**: User-specific search results, no cross-user access
11. **Dependencies**: Pinecone account, OpenAI API access, Cloud Functions deployment
12. **Rollout strategy**: Feature flag with gradual rollout, usage metrics tracking
13. **Explicitly out of scope**: Voice search, image search, real-time suggestions

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice: basic search → advanced features
- Keep service layer deterministic
- SwiftUI views are thin wrappers around SearchService
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
- Focus on search accuracy and performance
- Ensure proper error handling for external API dependencies
