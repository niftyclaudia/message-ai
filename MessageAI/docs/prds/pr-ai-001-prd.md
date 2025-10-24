# PRD: RAG Pipeline Infrastructure

**Feature**: RAG Pipeline Infrastructure (AI Foundation)

**Version**: 1.0

**Status**: Draft

**Agent**: Pete Agent

**Target Release**: Phase 1 - AI Foundation

**PR Number**: #AI-001

**Links**: 
- [AI Implementation Brief](../ai-implementation-brief.md#pr-ai-001-rag-pipeline-infrastructure)
- [Architecture Doc](../architecture.md)
- [AI Product Vision](../AI-PRODUCT-VISION.md)

---

## 1. Summary

Establish the foundational RAG (Retrieval Augmented Generation) pipeline that powers all AI features in MessageAI. This PR creates the invisible infrastructure layer that enables semantic search, thread summarization, action item extraction, priority detection, and decision tracking—all while remaining completely transparent to users. This is pure backend/infrastructure work with zero user-facing UI at this stage.

**Smallest End-to-End Outcome:** Messages stored in Firestore automatically generate vector embeddings and become semantically searchable via Cloud Functions, enabling future AI features to query conversation history by meaning rather than keywords.

---

## 2. Problem & Goals

### Problem
MessageAI's planned AI features (Thread Summarization, Smart Search, Priority Detection, Decision Tracking, Proactive Assistant) all require the ability to:
1. Understand message meaning beyond keyword matching (semantic understanding)
2. Find relevant messages from conversation history quickly (vector similarity search)
3. Build context for AI operations by retrieving related messages (retrieval augmented generation)

Without this foundational RAG pipeline, none of the AI features can function. Traditional keyword search is insufficient for queries like "What did we decide about the payment processor?" which requires semantic understanding and context.

### Why Now?
This is Phase 1 foundation work that must be completed before any user-facing AI features. All 6 core AI features (PR #AI-006 through #AI-011) depend on this infrastructure. Building it first enables parallel development of AI features in subsequent PRs.

### Goals (ordered, measurable)
- [ ] G1 — Every message sent generates a 1536-dimensional vector embedding via OpenAI text-embedding-3-small within 500ms
- [ ] G2 — Semantic search returns relevant messages for natural language queries in under 1 second (p95 latency)
- [ ] G3 — Vector database (Pinecone or Weaviate) stores embeddings with cosine similarity metric and supports queries at scale (10K+ messages per user)
- [ ] G4 — Cloud Functions provide `generateEmbedding(messageId)` and `semanticSearch(query, userId, limit)` APIs for iOS client
- [ ] G5 — Infrastructure is production-ready with error handling, monitoring, and graceful degradation (core messaging works even if RAG pipeline fails)

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not implementing user-facing AI features yet (Thread Summarization, Smart Search UI, Priority Detection UI, etc.) — Those come in Phase 2 PRs
- [ ] Not building iOS UI components for RAG pipeline (this is backend-only infrastructure)
- [ ] Not implementing function calling framework (that's PR #AI-003)
- [ ] Not building user preference system (that's PR #AI-002)
- [ ] Not implementing memory/state management (that's PR #AI-004)
- [ ] Not optimizing for real-time streaming responses (batch processing is sufficient for MVP)
- [ ] Not implementing multi-modal embeddings (text only; images/files deferred to future PRs)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:

### System Performance Metrics
- **Message Indexing Speed**: <500ms from message creation to embedding generation complete (p95)
- **Semantic Search Latency**: <1s from query submission to results returned (p95)
- **Embedding Generation Success Rate**: >99% (handle failures gracefully)
- **Search Accuracy**: Top 10 results include at least 8 semantically relevant messages (80% relevance minimum)
- **Uptime**: RAG pipeline available 99.9% of the time

### Quality Metrics
- **0 blocking bugs**: Core messaging continues working even if RAG pipeline fails
- **Graceful degradation**: Fallback to keyword search if vector search unavailable
- **Error rate**: <1% of embedding generation requests fail
- **Crash-free rate**: >99.9% for Cloud Functions

### Cost Metrics (Monitoring)
- **OpenAI Embedding Cost**: ~$0.0001 per 1K tokens (track monthly spend)
- **Pinecone Query Cost**: Track queries/month and cost per query
- **Firebase Functions Invocations**: Monitor for quota usage

---

## 5. Users & Stories

**Primary User (Internal):** iOS App + Future AI Features
- As the **iOS MessageService**, I want to send messages to Firestore and trust that embeddings are generated automatically, so that I don't need to handle AI logic in the client.
- As the **Thread Summarization feature** (PR #AI-006), I want to query "What are the key decisions in this thread?" and receive relevant messages, so that I can build a concise summary.
- As the **Smart Search feature** (PR #AI-008), I want to accept natural language queries like "payment processor decision" and return semantically similar messages, so that users can find information by meaning not keywords.
- As the **Priority Detection feature** (PR #AI-009), I want to analyze message content semantically to detect urgency signals, so that I can categorize messages accurately.
- As the **Decision Tracking feature** (PR #AI-010), I want to query conversation history for decision patterns, so that I can log key decisions made by the team.

**Secondary User (Indirect):** End Users (Maya)
- As **Maya**, I don't see the RAG pipeline directly, but it enables the AI features I'll use in future PRs to understand my messages and help me stay organized.

---

## 6. Experience Specification (UX)

### User Experience
**IMPORTANT:** This PR has **zero user-facing UI**. The RAG pipeline is completely invisible infrastructure.

**From User Perspective:**
- Users send messages as normal via iOS app
- Messages appear instantly in conversations (existing functionality)
- No visible changes, loading indicators, or AI signals at this stage
- Users are completely unaware that embeddings are being generated in the background

**From Developer/Future AI Feature Perspective:**
- Cloud Functions can be called to generate embeddings for messages
- Cloud Functions can be called to perform semantic search across message history
- Results return in <1s with relevant messages ranked by similarity
- Error states handled gracefully with fallback options

### Performance Targets (Backend)
- **Embedding Generation**: <500ms from function trigger to completion (p95)
- **Semantic Search**: <1s from query to results (p95)
- **Concurrent Requests**: Handle 100+ concurrent searches without degradation
- **Firestore Reads**: Batch reads efficiently (max 10 documents per search result)
- **OpenAI API Calls**: Retry with exponential backoff on rate limits

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**M1. Automatic Embedding Generation**
- MUST trigger Cloud Function on every new message creation (Firestore onMessageCreated trigger)
- MUST generate 1536-dimensional vector embedding using OpenAI text-embedding-3-small
- MUST store embedding in Pinecone/Weaviate with messageId as identifier
- MUST update Firestore message document with `embeddingGenerated: true` flag
- MUST complete within 500ms (p95 latency)
- [Gate] When message created in Firestore → embedding generated and stored in vector DB within 500ms → Firestore document updated with embeddingGenerated flag

**M2. Semantic Search Service**
- MUST accept natural language query string (e.g., "payment processor decision")
- MUST generate query embedding using same OpenAI model
- MUST perform vector similarity search in Pinecone/Weaviate using cosine similarity
- MUST return top N (default 10) most relevant messageIds ranked by similarity score
- MUST fetch full message documents from Firestore and return to caller
- MUST complete within 1s (p95 latency)
- [Gate] When semantic search called with query "payment processor" → returns top 10 relevant messages within 1s → messages ranked by relevance

**M3. Searchable Metadata Storage**
- MUST enhance Firestore message schema with searchable metadata:
  - `embeddingGenerated: boolean` (indicates embedding is ready)
  - `searchableMetadata: { keywords: string[], participants: string[], decisionMade: boolean }`
- MUST extract basic metadata during embedding generation (keywords, participants)
- MUST preserve backward compatibility with existing messages
- [Gate] When message with metadata saved → metadata queryable via Firestore → iOS can filter by metadata

**M4. Cloud Function APIs**
- MUST implement `generateEmbedding(messageId)` Cloud Function (HTTP Callable):
  - Input: `{ messageId: string }`
  - Output: `{ success: boolean, embeddingId: string, metadata: object }`
  - Errors: `invalid_message_id`, `openai_api_error`, `vector_db_error`
- MUST implement `semanticSearch(query, userId, limit)` Cloud Function (HTTP Callable):
  - Input: `{ query: string, userId: string, limit?: number, chatId?: string }`
  - Output: `{ results: SearchResult[], totalResults: number, queryTime: number }`
  - Errors: `invalid_query`, `openai_api_error`, `vector_db_error`
- [Gate] When iOS calls `semanticSearch("payment processor", userId, 10)` → returns SearchResult[] → includes messageId, text, similarity score, timestamp

**M5. Environment Configuration**
- MUST configure Firebase Functions with environment variables:
  - `OPENAI_API_KEY`: OpenAI API key for embedding generation
  - `PINECONE_API_KEY` or `WEAVIATE_API_KEY`: Vector database credentials
  - `PINECONE_ENV` or `WEAVIATE_URL`: Vector database environment/endpoint
  - `PINECONE_INDEX`: Index name for message embeddings
- MUST use Firebase Functions config (not hardcoded values)
- MUST validate environment variables on function initialization
- [Gate] When function deployed without env vars → logs clear error → function fails gracefully

**M6. Vector Database Setup**
- MUST create Pinecone or Weaviate index with specifications:
  - Dimensions: 1536 (matches OpenAI text-embedding-3-small)
  - Metric: Cosine similarity
  - Metadata fields: `messageId`, `chatId`, `senderId`, `timestamp`
- MUST support upsert operations (update existing embeddings if message edited)
- MUST support filtering by metadata (e.g., search only within specific chatId)
- [Gate] When embedding upserted to vector DB → queryable by vector search → returns with metadata

**M7. Error Handling & Graceful Degradation**
- MUST handle OpenAI API errors (rate limits, timeouts, invalid requests)
- MUST handle Vector DB errors (connection failures, quota exceeded)
- MUST retry failed embedding generation with exponential backoff (3 attempts max)
- MUST log all errors for monitoring and debugging
- MUST NOT break core messaging if RAG pipeline fails
- [Gate] When OpenAI API times out → function retries 3 times → logs error → returns graceful error response to caller

### SHOULD Requirements

**S1. Batch Embedding Generation**
- SHOULD support batch embedding generation for existing messages (backfill script)
- SHOULD process batches of 100 messages at a time to avoid quota issues
- SHOULD provide progress tracking for batch operations

**S2. Embedding Cache**
- SHOULD cache embeddings for identical message text to reduce OpenAI API costs
- SHOULD use Firestore or Redis for cache storage with 30-day TTL

**S3. Search Result Ranking Enhancements**
- SHOULD boost recency (newer messages rank higher with same similarity score)
- SHOULD boost messages from urgent contacts (when user preferences available)
- SHOULD include context snippets in search results (50 characters before/after match)

---

## 8. Data Model

### Firestore Schema Changes

#### Enhanced Message Document
```typescript
// /chats/{chatId}/messages/{messageId}
interface Message {
  // Existing fields
  id: string;
  text: string;
  senderId: string;
  timestamp: Timestamp;
  readBy: string[];
  type: "text" | "image" | "file";
  
  // NEW: RAG Pipeline fields
  embeddingGenerated?: boolean;  // True when embedding exists in vector DB
  searchableMetadata?: {
    keywords: string[];            // Extracted keywords for filtering
    participants: string[];        // UserIds mentioned or involved
    decisionMade?: boolean;        // True if decision detected (future)
    hasActionItem?: boolean;       // True if action item detected (future)
  };
}
```

### Vector Database Schema (Pinecone/Weaviate)

```typescript
// Pinecone Vector Schema
interface MessageEmbedding {
  id: string;                     // Same as Firestore messageId
  values: number[];               // 1536-dimensional embedding vector
  metadata: {
    messageId: string;            // Firestore messageId (for lookup)
    chatId: string;               // Firestore chatId (for filtering)
    senderId: string;             // UserId who sent message
    timestamp: number;            // Unix timestamp (for sorting)
    text?: string;                // Optional: store full text for debugging
  };
}
```

### Validation & Indexing
- `messageId` must exist in Firestore, `query` must be 3-500 chars, `userId` authenticated
- `limit` must be 1-50, `similarityScore` 0.0-1.0
- Firestore indexes: `embeddingGenerated`, `chatId + timestamp`
- Pinecone metadata filters: `chatId`, `timestamp`

---

## 9. API / Service Contracts

### Cloud Function: generateEmbedding
```typescript
// Input: { messageId: string }
// Output: { success: boolean, embeddingId: string, metadata: object }
// Errors: invalid_message_id, openai_api_error, vector_db_error
export const generateEmbedding = functions.https.onCall(...)

// Auto-trigger on message creation
export const onMessageCreated = functions.firestore
  .document('chats/{chatId}/messages/{messageId}').onCreate(...)
```
- Generates 1536-dim embedding via OpenAI, stores in vector DB, updates Firestore
- Retries 3x with exponential backoff, logs errors, completes in <500ms

### Cloud Function: semanticSearch
```typescript
// Input: { query: string, userId: string, limit?: number, chatId?: string, minScore?: number }
// Output: { results: SearchResult[], totalResults: number, queryTime: number }
// Errors: invalid_query, openai_api_error, vector_db_error, permission_denied
export const semanticSearch = functions.https.onCall(...)
```
- Validates query (3-500 chars), checks permissions, performs vector search, returns in <1s
- Retries 3x, logs errors, ranks by similarity score (0-1)

---

## 10. Backend Components to Create

### Firebase Cloud Functions (`functions/src/`)

#### RAG Pipeline Core
- `rag/embeddings.ts` — OpenAI embedding generation logic
  - `generateEmbeddingVector(text: string): Promise<number[]>`
  - `extractKeywords(text: string): string[]`
  - `extractParticipants(text: string, chatId: string): Promise<string[]>`

- `rag/vectorSearch.ts` — Pinecone/Weaviate operations
  - `upsertEmbedding(messageId: string, vector: number[], metadata: object): Promise<string>`
  - `queryVectorDB(queryVector: number[], limit: number, filters: object): Promise<VectorMatch[]>`
  - `deleteEmbedding(messageId: string): Promise<void>` (future: message deletion)

- `rag/semanticQuery.ts` — High-level semantic search orchestration
  - `performSemanticSearch(query: string, userId: string, options: SearchOptions): Promise<SearchResult[]>`
  - `rankResults(matches: VectorMatch[], boost: RankingBoost): SearchResult[]`

#### Cloud Function Endpoints
- `functions/generateEmbedding.ts` — HTTP Callable function for manual embedding generation
- `functions/semanticSearch.ts` — HTTP Callable function for semantic search queries

#### Firestore Triggers
- `triggers/onMessageCreated.ts` — Auto-generate embedding on new message

#### Utilities
- `utils/openai.ts` — OpenAI API client wrapper
  - `initializeOpenAI(): OpenAI`
  - `generateEmbedding(text: string, model: string): Promise<number[]>`
  
- `utils/pinecone.ts` — Pinecone/Weaviate client wrapper
  - `initializePinecone(): Pinecone`
  - `getIndex(name: string): Index`
  - `upsert(index: Index, vectors: Vector[]): Promise<void>`
  - `query(index: Index, vector: number[], options: QueryOptions): Promise<QueryResponse>`

- `utils/firestore.ts` — Firestore helper functions
  - `fetchMessage(messageId: string): Promise<Message>`
  - `updateMessageMetadata(messageId: string, metadata: object): Promise<void>`
  - `checkUserPermission(userId: string, chatId: string): Promise<boolean>`

- `utils/logger.ts` — Structured logging
  - `logEmbeddingGeneration(messageId: string, duration: number, success: boolean)`
  - `logSemanticSearch(query: string, resultCount: number, duration: number)`
  - `logError(operation: string, error: Error, context: object)`

#### Configuration
- `config/env.ts` — Environment variable validation
  - `validateEnvVars(): { openaiKey: string, pineconeKey: string, pineconeEnv: string, pineconeIndex: string }`

### iOS Integration Layer (Future PR, documented here for context)
- `Services/AI/EmbeddingService.swift` — iOS client for embedding functions (created in future PRs)
- `Services/AI/SmartSearchService.swift` — iOS client for semantic search (PR #AI-008)

---

## 11. Integration Points

### External Services
- **OpenAI API**: text-embedding-3-small model for embedding generation
- **Pinecone OR Weaviate**: Vector database for similarity search
- **Firebase Firestore**: Message storage and metadata
- **Firebase Functions**: Serverless compute for RAG pipeline
- **Firebase Auth**: User authentication for Cloud Function security

### Internal Dependencies
- **MessageService** (existing): Creates messages in Firestore, triggers onMessageCreated
- Future AI Features (consumers):
  - Thread Summarization (PR #AI-006)
  - Action Item Extraction (PR #AI-007)
  - Smart Search (PR #AI-008)
  - Priority Detection (PR #AI-009)
  - Decision Tracking (PR #AI-010)

---

## 12. Test Plan & Acceptance Gates

### Unit Tests (Node.js/TypeScript)
- [ ] Embedding generation returns 1536-dim vector for valid text, errors for empty text
- [ ] Keyword/participant extraction from message text works correctly
- [ ] Vector DB upsert/query with metadata filtering and error handling (retry 3x)
- [ ] Semantic search end-to-end with ranking, empty results, query validation

### Integration Tests (Firebase Functions)
- [ ] `generateEmbedding`: Valid messageId succeeds, invalid returns error, unauthenticated rejected
- [ ] `semanticSearch`: Query returns results <1s, chatId filter works, invalid query/permissions rejected
- [ ] `onMessageCreated`: Trigger fires on new message, embedding generated <500ms, Firestore updated

### Performance Tests
- [ ] Embedding generation p95 <500ms (100 samples)
- [ ] Semantic search p95 <1s (100 samples)
- [ ] 100 concurrent queries complete within 2s
- [ ] Search remains <1s with 10K+ indexed messages

### Edge Cases & Security
- [ ] Short/long messages (1 word, 5000+ chars), special characters/emojis handled
- [ ] OpenAI timeout/rate limit/Vector DB quota exceeded: retries 3x, logs error, returns graceful failure
- [ ] Unauthenticated calls rejected, permission violations caught, no injection vulnerabilities

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:

- [ ] All Cloud Functions implemented and deployed to Firebase
- [ ] OpenAI API integration working (text-embedding-3-small)
- [ ] Pinecone OR Weaviate vector database configured and operational
- [ ] Environment variables configured via Firebase Functions config
- [ ] Firestore schema enhanced with embeddingGenerated and searchableMetadata fields
- [ ] Firestore trigger (onMessageCreated) automatically generates embeddings
- [ ] generateEmbedding Cloud Function callable from iOS (HTTP Callable)
- [ ] semanticSearch Cloud Function callable from iOS (HTTP Callable)
- [ ] All unit tests pass (embedding generation, vector ops, semantic search)
- [ ] All integration tests pass (Cloud Functions, Firestore triggers)
- [ ] Performance tests pass (p95 <500ms embedding, p95 <1s search)
- [ ] Security tests pass (authentication, permission checks)
- [ ] Error handling implemented with graceful degradation
- [ ] Monitoring and logging configured (Cloud Logging)
- [ ] Documentation updated (README, API docs, environment setup guide)
- [ ] Code reviewed and approved
- [ ] PR merged to develop branch

---

## 14. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **OpenAI Rate Limits** | Embedding generation fails during high traffic | Exponential backoff (3 retries), queue failed requests, monitor usage, cache identical text |
| **Vector DB Cost Scaling** | Costs exceed budget with message growth | Daily monitoring, query caching, user limits (50/hour), evaluate self-hosted alternatives |
| **Search Accuracy <80%** | Users lose trust in AI features | User feedback collection, A/B test models, hybrid search fallback, test suite with known queries |
| **Embedding Latency >500ms** | Messages slow to become searchable | Async processing, batch low-traffic periods, profile bottlenecks, upgrade Functions tier |
| **Cold Start Latency** | First query after idle takes 3-5s | Keep-alive pings, min-instances setting, friendly loading states, accept tradeoff for rare searches |
| **Privacy Concerns** | Users uncomfortable with OpenAI data sharing | Privacy policy transparency, verify OpenAI terms, future on-device embeddings, opt-out option |

---

## 15. Rollout & Telemetry

### Feature Flag
`rag_pipeline_enabled` (Firebase Remote Config, default: true) — Disable if critical issues found

### Key Metrics
- **Performance**: Embedding p50/p95/p99 latency, search p50/p95/p99 latency, success rates
- **Usage**: Embeddings/searches per day, zero-result query %, function invocations
- **Costs**: OpenAI API daily cost, Pinecone/Weaviate daily cost
- **Errors**: Error rate by type, failed embedding/search counts

### Alerts
- Embedding error rate >5%, search p95 >1.5s, daily cost >$100, Vector DB failures >10/hour

### Rollout Plan
Staging (24h manual validation) → Production 5% (48h monitoring) → 20% → 50% → 100%

---

## 16. Open Questions

| Question | Recommendation | Decision Owner |
|----------|---------------|----------------|
| Pinecone vs Weaviate? | Start with Pinecone (easier setup), evaluate Weaviate if costs issue | Cody Backend |
| 1536 or 3072 dimensions? | 1536 (text-embedding-3-small) for MVP, A/B test 3072 if accuracy issues | Cody Backend |
| Backfill existing messages? | Backfill last 1K for testing, then batch process all in background | Cody Backend |
| Real-time vs batch generation? | Real-time for new messages (Firestore trigger), batch for backfill | Cody Backend |

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:
- [ ] **Hybrid search** (vector + keyword fallback) — Deferred to PR #AI-008 (Smart Search UI)
- [ ] **Multi-modal embeddings** (images, files) — Deferred to Phase 2
- [ ] **On-device embeddings** (CoreML models) — Deferred to Phase 3
- [ ] **PII redaction** before OpenAI API calls — Deferred to Phase 2 privacy enhancements
- [ ] **Embedding cache** for identical messages — Optional optimization, evaluate after cost analysis
- [ ] **Search result feedback** (thumbs up/down) — Deferred to PR #AI-008 (Smart Search UI)
- [ ] **Advanced ranking** (boost by contact importance) — Deferred to PR #AI-009 (Priority Detection with User Preferences)
- [ ] **Cross-platform sync** (web/desktop) — Deferred to Phase 3

---

## 18. Authoring Notes

- Write integration tests before coding (test-driven development)
- Favor asynchronous processing (don't block message send on embedding generation)
- Keep Cloud Functions small and focused (single responsibility)
- Log all operations for debugging and monitoring
- Test with real OpenAI API in staging (not mocks)
- Document environment setup clearly for future developers
- Reference `MessageAI/agents/shared-standards.md` for error handling patterns
- This is backend-only work: No iOS code changes in this PR

---

**Document Status:** ✅ Ready for Review  
**Next Step:** Present to user for feedback, then create TODO document (YOLO: false)  
**Estimated Complexity:** Complex (backend infrastructure, external API integration, vector DB setup)  
**Estimated Timeline:** 3-5 days (including testing and monitoring setup)

