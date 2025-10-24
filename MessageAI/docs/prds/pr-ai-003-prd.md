# PRD: Function Calling Framework

**Feature**: Function Calling Framework (AI Foundation)

**Version**: 1.0

**Status**: Draft

**Agent**: Pete Agent

**Target Release**: Phase 1 - AI Foundation

**PR Number**: #AI-003

**Links**: 
- [AI Implementation Brief](../ai-implementation-brief.md#pr-ai-003-function-calling-framework)
- [Architecture Doc](../architecture.md)
- [AI Product Vision](../AI-PRODUCT-VISION.md)

---

## 1. Summary

Build comprehensive function calling framework that enables AI to execute actions instead of just providing information. This PR creates the foundational infrastructure for OpenAI function calling, allowing the AI to intelligently select and execute specific functions (summarizeThread, extractActionItems, searchMessages, categorizeMessage, trackDecisions, detectSchedulingNeed, checkCalendar, suggestMeetingTimes) based on user intent. This transforms MessageAI's AI from passive information provider to active assistant capable of taking actions.

**Smallest End-to-End Outcome:** AI can interpret user requests, select appropriate functions from available schema, execute them with validated parameters, and return structured results—enabling all action-based AI features (Thread Summarization, Action Items, Smart Search, Priority Detection, Decision Tracking, Proactive Assistant).

---

## 2. Problem & Goals

### Problem
MessageAI's planned AI features require more than text generation—they need the ability to:
1. **Execute specific actions** (summarize threads, extract tasks, search messages, categorize priority, detect decisions, schedule meetings)
2. **Choose appropriate actions dynamically** based on user intent (user says "what did I miss?" → AI chooses summarizeThread + extractActionItems)
3. **Pass structured parameters** to functions with proper validation (threadId, userId, date ranges, filters)
4. **Return structured results** that can be displayed in iOS UI (not just plain text)

Without function calling, the AI can only generate text responses that require manual parsing and interpretation. OpenAI's function calling API enables the AI to trigger specific backend operations, making it an active assistant rather than passive chatbot.

### Why Now?
This is Phase 1 foundation work that must be completed before any action-based AI features. All 6 core AI features (PR #AI-006 through #AI-011) depend on function calling to execute their operations. Building this framework first enables parallel development of AI features that can immediately leverage function calling.

### Goals (ordered, measurable)
- [ ] G1 — Define 8 core functions with OpenAI function calling schema: summarizeThread, extractActionItems, searchMessages, categorizeMessage, trackDecisions, detectSchedulingNeed, checkCalendar, suggestMeetingTimes
- [ ] G2 — Implement function execution handlers in Cloud Functions that validate parameters, execute actions safely, and return structured results within <2s (p95 latency)
- [ ] G3 — Create unified function calling orchestrator that receives OpenAI function call requests, routes to appropriate handlers, and aggregates results
- [ ] G4 — Build `FunctionCallingService.swift` iOS service to handle function call requests and responses with type-safe Swift models
- [ ] G5 — Implement execution logging, parameter validation, error handling for function failures, and fallback options when functions timeout

---

## 3. Non-Goals / Out of Scope

Call out what's intentionally excluded to avoid scope creep.

- [ ] Not implementing the actual AI features that use function calling (Thread Summarization, Smart Search, etc.) — Those come in Phase 2 PRs
- [ ] Not building iOS UI components for displaying function results — That's part of individual feature PRs
- [ ] Not implementing RAG pipeline (that's PR #AI-001) — But function calling will invoke RAG functions
- [ ] Not building user preference system (that's PR #AI-002) — But functions will accept preference parameters when ready
- [ ] Not implementing memory/state management (that's PR #AI-004) — But functions will store execution history when ready
- [ ] Not creating custom functions for every possible use case (keeping to 8 core functions for MVP)
- [ ] Not implementing voice-based function calling (text-based requests only)
- [ ] Not building function chaining (sequential function calls) — Simple single-function execution for MVP

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:

### System Performance Metrics
- **Function Execution Latency**: <2s from function call initiation to result returned (p95)
- **Parameter Validation Speed**: <50ms to validate parameters and route to handler
- **Function Success Rate**: >98% (handle failures gracefully with meaningful errors)
- **OpenAI Function Selection Accuracy**: AI selects correct function >95% of the time for common user requests
- **Uptime**: Function calling framework available 99.9% of the time

### Quality Metrics
- **0 blocking bugs**: Core messaging and AI text generation work even if function execution fails
- **Graceful degradation**: Fallback to text-only response if function fails (e.g., "I tried to search but encountered an error. Let me explain what I would have done...")
- **Error rate**: <2% of function execution requests fail
- **Crash-free rate**: >99.9% for Cloud Functions

### Developer Experience Metrics
- **Schema clarity**: All 8 functions have clear documentation with examples
- **Type safety**: iOS Swift models match TypeScript function schemas exactly
- **Debugging ease**: Execution logs include function name, parameters, duration, success/failure

---

## 5. Users & Stories

**Primary User (Internal):** iOS App + Future AI Features
- As the **AI Chat feature**, I want to interpret user queries like "what did I miss?" and automatically call `summarizeThread` + `extractActionItems`, so that users get actionable results instead of text summaries.
- As the **Smart Search feature** (PR #AI-008), I want to call `searchMessages(query, filters)` when users type natural language queries, so that I can return semantically relevant messages.
- As the **Priority Detection feature** (PR #AI-009), I want to call `categorizeMessage(messageId)` for new messages, so that I can automatically sort messages into Urgent/Can Wait/AI Handled buckets.
- As the **Decision Tracking feature** (PR #AI-010), I want to call `trackDecisions(threadId)` when users ask "what decisions were made?", so that I can surface logged decisions.
- As the **Proactive Assistant feature** (PR #AI-011), I want to call `detectSchedulingNeed(threadId)` + `checkCalendar` + `suggestMeetingTimes`, so that I can proactively suggest optimal meeting times.

**Secondary User (Developer):** Building Agent (Cody)
- As **Cody (Building Agent)**, I want clear function schemas and examples, so that I can implement AI features quickly without ambiguity.
- As **Cody**, I want type-safe Swift models for all function inputs/outputs, so that I can build iOS UIs with confidence.

**Tertiary User (Indirect):** End Users (Maya)
- As **Maya**, I don't see the function calling framework directly, but it enables AI to take actions on my behalf (summarizing threads, finding information, scheduling meetings) instead of just talking about them.

---

## 6. Experience Specification (UX)

### User Experience
**IMPORTANT:** This PR has **minimal user-facing UI**. The function calling framework is primarily invisible infrastructure, but users will see the *results* of function execution.

**From User Perspective:**
- Users interact with AI via chat interface (existing or future PRs)
- Users type natural language requests: "Summarize this thread", "Find the budget decision", "What did I miss?"
- AI responds with structured results (summaries, search results, action items) powered by function calls
- No visible "function calling" indicators—it feels like natural AI conversation
- If function fails, users see helpful error message: "I'm having trouble accessing that right now. Want to try again?"

**From Developer/Future AI Feature Perspective:**
- Cloud Functions receive function call requests from OpenAI API
- Functions execute with validated parameters
- Results return in <2s as structured JSON
- Error states handled gracefully with fallback options

### Performance Targets (Backend)
- **Parameter Validation**: <50ms from request to handler routing
- **Function Execution**: <2s from initiation to result (p95)
- **OpenAI Integration**: <500ms to parse function call from OpenAI response
- **Concurrent Requests**: Handle 50+ concurrent function calls without degradation
- **Error Handling**: <100ms to detect and log errors with fallback response

---

## 7. Functional Requirements (Must/Should)

### MUST Requirements

**M1. Function Schema Definitions (OpenAI Format)**
- MUST define 8 core functions with OpenAI function calling schema in JSON format:
  1. `summarizeThread(threadId: string, maxLength?: number)` — Condense thread to 2-3 sentences
  2. `extractActionItems(threadId: string, userId: string)` — Find tasks requiring action
  3. `searchMessages(query: string, userId: string, chatId?: string, limit?: number)` — Semantic search
  4. `categorizeMessage(messageId: string, userId: string)` — Detect priority (Urgent/Can Wait/AI Handled)
  5. `trackDecisions(threadId: string)` — Find and log decision patterns
  6. `detectSchedulingNeed(threadId: string)` — Identify meeting requests
  7. `checkCalendar(userId: string, startDate: string, endDate: string)` — Fetch availability
  8. `suggestMeetingTimes(participants: string[], duration: number, preferredTimeRanges?: TimeRange[])` — Suggest optimal times
- MUST include parameter types, descriptions, required/optional flags, and examples for each function
- MUST follow OpenAI function calling specification exactly
- [Gate] When AI receives user query → OpenAI API returns function call with correct name and parameters → matches schema definition

**M2. Function Execution Handlers**
- MUST implement TypeScript handler for each of 8 functions in Cloud Functions
- MUST validate all parameters before execution (type checking, range validation, permission checks)
- MUST execute function logic and return structured result matching schema
- MUST complete execution within 2s (p95 latency) or timeout with error
- MUST log every execution (function name, parameters, duration, success/failure, userId)
- [Gate] When function handler called with valid parameters → executes successfully → returns structured result within 2s → logs execution details

**M3. Function Calling Orchestrator**
- MUST implement central orchestrator Cloud Function: `executeFunctionCall(functionName, parameters, userId)`
- MUST route incoming function call to appropriate handler based on functionName
- MUST aggregate results from multiple handlers if needed (future: function chaining)
- MUST enforce authentication and authorization (userId must match request context)
- MUST implement timeout mechanism (2s max execution, then return timeout error)
- [Gate] When executeFunctionCall invoked → validates user → routes to handler → returns result or error → completes within 2s

**M4. iOS Function Calling Service**
- MUST create `FunctionCallingService.swift` iOS service with methods for each function:
  - `summarizeThread(threadId: String, maxLength: Int?) async throws -> ThreadSummary`
  - `extractActionItems(threadId: String) async throws -> [ActionItem]`
  - `searchMessages(query: String, chatId: String?, limit: Int?) async throws -> [SearchResult]`
  - `categorizeMessage(messageId: String) async throws -> MessageCategory`
  - `trackDecisions(threadId: String) async throws -> [Decision]`
  - `detectSchedulingNeed(threadId: String) async throws -> SchedulingNeed?`
  - `checkCalendar(startDate: Date, endDate: Date) async throws -> [CalendarEvent]`
  - `suggestMeetingTimes(participants: [String], duration: Int) async throws -> [MeetingTimeSuggestion]`
- MUST define type-safe Swift models for all input/output types matching TypeScript schemas
- MUST handle network errors, timeouts, and invalid responses gracefully
- [Gate] When iOS calls `searchMessages("budget decision")` → invokes Cloud Function → receives structured SearchResult[] → displays in UI

**M5. Parameter Validation & Security**
- MUST validate all parameters before execution:
  - String lengths (threadId/messageId/userId must be valid Firebase IDs)
  - Numeric ranges (limit 1-50, duration 15-180 minutes, maxLength 50-500 chars)
  - Date formats (ISO 8601 for dates)
  - Array lengths (participants 2-10, preferredTimeRanges 0-5)
- MUST check user permissions (userId can only access their own messages/calendars)
- MUST sanitize inputs to prevent injection attacks
- MUST reject requests missing required parameters with clear error messages
- [Gate] When function called with invalid parameters → validation fails → returns descriptive error → does not execute

**M6. Error Handling & Fallback**
- MUST handle errors gracefully for each failure mode:
  - **Invalid parameters**: Return `invalid_parameters` error with details
  - **Permission denied**: Return `permission_denied` error
  - **Function timeout**: Return `timeout` error after 2s
  - **External service failure**: Return `service_unavailable` error (e.g., RAG pipeline down)
  - **Unexpected errors**: Return `internal_error` with logged details
- MUST provide fallback text response when function fails: "I tried to [action] but encountered an issue. Here's what I was trying to do..."
- MUST log all errors with context for debugging
- MUST NOT break core AI chat functionality if function execution fails
- [Gate] When function times out → returns timeout error → AI provides fallback text response → user sees helpful message

**M7. Execution Logging & Audit Trail**
- MUST log every function execution to Firestore `/functionExecutionLogs/{executionId}`:
  - `executionId`: Unique ID
  - `functionName`: Function called
  - `parameters`: Input parameters (sanitized, no sensitive data)
  - `userId`: User who initiated call
  - `timestamp`: Execution time
  - `duration`: Execution time in ms
  - `status`: success | error | timeout
  - `errorDetails`: Error message if failed
  - `resultSummary`: High-level result summary (not full data)
- MUST enable querying logs for debugging and monitoring
- MUST implement log retention (30 days for debugging, then auto-delete for privacy)
- [Gate] When function executed → log written to Firestore → queryable for debugging → auto-deleted after 30 days

### SHOULD Requirements

**S1. Function Call Response Formatting**
- SHOULD format function results in user-friendly way for AI to present:
  - `ThreadSummary`: Include key points, participants, decision count
  - `ActionItem[]`: Include task, deadline, assignee, source message
  - `SearchResult[]`: Include message text, sender, timestamp, relevance score
- SHOULD include metadata for transparency (e.g., "Analyzed 47 messages", "Found 3 action items")

**S2. Function Execution Caching**
- SHOULD cache identical function calls for 5 minutes to reduce redundant execution
  - Cache key: `${functionName}_${JSON.stringify(parameters)}`
  - Use Firebase Realtime Database or Redis for cache storage
  - Return cached result if available and <5 minutes old

**S3. Function Call Analytics**
- SHOULD track function usage metrics:
  - Most frequently called functions
  - Average execution time by function
  - Error rate by function type
  - User adoption (which users use which functions)

---

## 8. Data Model

### Firestore Schema

#### Function Execution Log Document
```typescript
// /functionExecutionLogs/{executionId}
interface FunctionExecutionLog {
  executionId: string;
  functionName: string;             // e.g., "summarizeThread"
  parameters: Record<string, any>;  // Sanitized input
  userId: string;
  timestamp: Timestamp;
  duration: number;                 // milliseconds
  status: "success" | "error" | "timeout";
  errorDetails?: string;
  resultSummary?: string;
}
```

### Function Schemas (OpenAI Format)

**All 8 functions follow this pattern:**
- Name, description, parameters (with types, required/optional, validation rules)
- See full schemas in implementation: `functions/src/functionCalling/schemas.ts`

**Core Functions:**
1. `summarizeThread(threadId, maxLength?)` — Condense thread to 2-3 sentences
2. `extractActionItems(threadId, userId)` — Find tasks requiring action
3. `searchMessages(query, userId, chatId?, limit?)` — Semantic search
4. `categorizeMessage(messageId, userId)` — Detect priority level
5. `trackDecisions(threadId)` — Log decision patterns
6. `detectSchedulingNeed(threadId)` — Identify meeting requests
7. `checkCalendar(userId, startDate, endDate)` — Fetch availability
8. `suggestMeetingTimes(participants, duration, preferredTimeRanges?)` — Suggest optimal times

**Parameter Validation Rules:**
- String lengths: threadId/messageId/userId must be valid Firebase IDs
- Numeric ranges: limit 1-50, duration 15-180 minutes, maxLength 50-500 chars
- Date formats: ISO 8601
- Array lengths: participants 2-10, preferredTimeRanges 0-5

### iOS Swift Models

**Type-safe models matching TypeScript schemas:**
- `ThreadSummary` — summary, keyPoints, participants, decisionCount, messageCount
- `ActionItem` — task, deadline, assignee, sourceMessageId
- `SearchResult` — messageId, text, senderId, timestamp, relevanceScore
- `MessageCategory` — category (urgent/canWait/aiHandled), confidence, reasoning, signals
- `Decision` — decisionText, participants, timestamp, confidence
- `SchedulingNeed` — detected, participants, suggestedDuration, urgency
- `CalendarEvent` — title, startTime, endTime
- `MeetingTimeSuggestion` — startTime, endTime, availableParticipants, score, reasoning
- `FunctionExecutionResult<T>` — success, result, error, executionTime
- `FunctionExecutionError` — code, message, details

See full definitions in: `MessageAI/Services/AI/FunctionCallingModels.swift`

---

## 9. API / Service Contracts

### Cloud Function: executeFunctionCall
**HTTP Callable Function** (main entry point)
- **Input**: `{ functionName: string, parameters: object, userId: string }`
- **Output**: `{ success: boolean, result: any, error?: ErrorResponse, executionTime: number }`
- **Errors**: `invalid_function`, `invalid_parameters`, `permission_denied`, `timeout`, `service_unavailable`, `internal_error`
- **Flow**: Validate auth → Validate params → Route to handler → Execute with 2s timeout → Log → Return result

### Function Handlers (Backend)
All 8 handlers follow this TypeScript pattern:
```typescript
type FunctionHandler<TParams, TResult> = (
  params: TParams,
  userId: string,
  context: CallableContext
) => Promise<TResult>;
```

Each handler: Validates params → Checks permissions → Executes logic → Returns structured result

### iOS Service: FunctionCallingService.swift
Service with 8 type-safe methods matching the Cloud Functions:
```swift
protocol FunctionCallingServiceProtocol {
    func summarizeThread(threadId: String, maxLength: Int?) async throws -> ThreadSummary
    func extractActionItems(threadId: String) async throws -> [ActionItem]
    func searchMessages(query: String, chatId: String?, limit: Int?) async throws -> [SearchResult]
    func categorizeMessage(messageId: String) async throws -> MessageCategory
    func trackDecisions(threadId: String) async throws -> [Decision]
    func detectSchedulingNeed(threadId: String) async throws -> SchedulingNeed?
    func checkCalendar(startDate: Date, endDate: Date) async throws -> [CalendarEvent]
    func suggestMeetingTimes(participants: [String], duration: Int) async throws -> [MeetingTimeSuggestion]
}
```

Each method calls `executeFunctionCall` Cloud Function, parses typed response, handles errors

---

## 10. Backend Components to Create

### Firebase Cloud Functions (`functions/src/`)

#### Core Infrastructure
- `functionCalling/orchestrator.ts` — Central orchestrator: routing, validation, timeout enforcement, logging
- `functionCalling/schemas.ts` — All 8 function schemas (OpenAI format), TypeScript types, validation rules
- `functionCalling/validation.ts` — Parameter validation utilities (IDs, dates, numeric ranges, arrays)

#### Function Handlers (8 handlers, one per function)
All handlers in `functionCalling/handlers/`:
1. `summarizeThread.ts` → `summarizeThreadHandler(): Promise<ThreadSummary>`
2. `extractActionItems.ts` → `extractActionItemsHandler(): Promise<ActionItem[]>`
3. `searchMessages.ts` → `searchMessagesHandler(): Promise<SearchResult[]>`
4. `categorizeMessage.ts` → `categorizeMessageHandler(): Promise<MessageCategory>`
5. `trackDecisions.ts` → `trackDecisionsHandler(): Promise<Decision[]>`
6. `detectSchedulingNeed.ts` → `detectSchedulingNeedHandler(): Promise<SchedulingNeed>`
7. `checkCalendar.ts` → `checkCalendarHandler(): Promise<CalendarEvent[]>`
8. `suggestMeetingTimes.ts` → `suggestMeetingTimesHandler(): Promise<MeetingTimeSuggestion[]>`

Each handler: validates params, checks permissions, executes logic, returns structured result

#### Utilities
- `utils/executionLogger.ts` — Log executions to Firestore, query logs for debugging
- `utils/errorHandler.ts` — Unified error handling, error response formatting
- `utils/permissionChecker.ts` — User access validation, permission checks

### iOS Components (`MessageAI/MessageAI/`)

- `Services/AI/FunctionCallingService.swift` — iOS client with 8 type-safe methods, response parsing, error handling
- `Services/AI/FunctionCallingModels.swift` — Swift models matching all TypeScript schemas
- `Utilities/AI/FunctionCallLogger.swift` — Optional: client-side logging for debugging

---

## 11. Integration Points

### External Services
- **OpenAI API**: Function calling API for interpreting user intent and selecting functions
- **Firebase Functions**: Serverless compute for function execution
- **Firebase Auth**: User authentication for security
- **Firebase Firestore**: Function execution logging

### Internal Dependencies
- **RAG Pipeline** (PR #AI-001): Functions invoke semantic search and embedding generation
- Future dependencies:
  - **User Preferences** (PR #AI-002): Functions will use preferences for personalized categorization
  - **Memory/State** (PR #AI-004): Functions will store execution history
  - **iOS Calendar**: checkCalendar and suggestMeetingTimes will integrate with iOS EventKit

### Function Dependencies (What Each Function Calls)
1. **summarizeThread** → RAG Pipeline (semantic search for key messages)
2. **extractActionItems** → RAG Pipeline (search for task patterns)
3. **searchMessages** → RAG Pipeline (semantic search directly)
4. **categorizeMessage** → RAG Pipeline (analyze message content) + User Preferences (future)
5. **trackDecisions** → RAG Pipeline (search for decision patterns)
6. **detectSchedulingNeed** → RAG Pipeline (search for scheduling phrases)
7. **checkCalendar** → iOS EventKit (calendar API)
8. **suggestMeetingTimes** → checkCalendar + User Preferences (focus hours)

---

## 12. Test Plan & Acceptance Gates

### Unit Tests (Node.js/TypeScript)
- [ ] **Schemas**: All 8 function schemas valid OpenAI format, parameter validation works
- [ ] **Parameter Validation**: Valid IDs pass, invalid rejected; numeric ranges enforced (limit 1-50, duration 15-180); date format validation; array length validation
- [ ] **Function Handlers**: Each of 8 handlers returns correct types, handles errors gracefully, validates permissions
- [ ] **Orchestrator**: Routes correctly, validates auth, enforces 2s timeout, logs all executions

### Integration Tests (Firebase Functions)
- [ ] **End-to-End**: All 8 functions callable from iOS, return structured results within 2s
- [ ] **Authentication**: Unauthenticated requests rejected, users cannot access other users' data
- [ ] **Error Handling**: Invalid functionName/parameters return descriptive errors, timeouts handled, RAG Pipeline failures return fallback
- [ ] **RAG Integration**: Functions that use RAG Pipeline (summarize, search, categorize, trackDecisions) integrate correctly

### Performance Tests
- [ ] Function execution p95 <2s (100 samples per function)
- [ ] Parameter validation <50ms
- [ ] 50 concurrent calls complete within 3s
- [ ] Logging adds <10ms overhead

### Edge Cases
- [ ] Long threads (100+ messages), special characters, time zones, no available times, empty/missing data handled gracefully

### iOS Integration Tests
- [ ] Swift models deserialize correctly, network timeouts handled, invalid responses caught, type safety enforced

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:

- [ ] All 8 function schemas defined in OpenAI format
- [ ] All 8 function handlers implemented in TypeScript
- [ ] Function calling orchestrator (executeFunctionCall) deployed as Cloud Function
- [ ] Parameter validation logic implemented and tested
- [ ] Error handling and timeout enforcement working
- [ ] Execution logging to Firestore operational
- [ ] FunctionCallingService.swift implemented with all 8 methods
- [ ] Swift models match TypeScript schemas exactly
- [ ] All unit tests pass (schema validation, parameter validation, handlers)
- [ ] All integration tests pass (end-to-end function execution, auth, errors)
- [ ] Performance tests pass (p95 <2s execution, <50ms validation)
- [ ] Security tests pass (authentication, authorization, permission checks)
- [ ] iOS integration tests pass (network calls, response parsing, error handling)
- [ ] Documentation complete (function schemas, usage examples, error codes)
- [ ] Code reviewed and approved
- [ ] PR merged to develop branch

---

## 14. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **Function execution >2s** | Poor user experience, timeouts | Profile handlers, optimize RAG calls, implement caching, use batch processing for slow operations |
| **OpenAI function selection errors** | AI calls wrong function or wrong parameters | Improve function descriptions, add examples, test with real queries, implement validation and retry |
| **Parameter validation too strict** | Valid requests rejected | Comprehensive test suite with edge cases, clear error messages, user feedback collection |
| **Handler failures cascade** | One broken handler breaks all functions | Isolate handler errors, graceful degradation per function, fallback to text responses |
| **Type mismatches (Swift ↔ TypeScript)** | Runtime errors, crashes | Generate Swift models from TypeScript schemas, integration tests for all types, CI validation |
| **Security vulnerabilities** | Unauthorized access, injection attacks | Input sanitization, permission checks, authentication enforcement, security audit |
| **Execution logs accumulate** | Firestore storage costs increase | 30-day auto-delete, query only recent logs, consider external logging service |
| **Cost scaling (OpenAI API calls)** | Budget exceeded with heavy usage | Rate limiting, caching identical calls, monitor daily costs, user quotas |

---

## 15. Rollout & Telemetry

### Feature Flag
`function_calling_enabled` (Firebase Remote Config, default: true) — Disable if critical issues found

### Key Metrics
- **Performance**: Function execution p50/p95/p99 by function type, parameter validation time, timeout rate
- **Usage**: Function calls per day by function type, unique users, error rate by function
- **Success Rate**: % successful executions by function, retry rate, fallback rate
- **Errors**: Error rate by type (invalid_parameters, timeout, permission_denied, service_unavailable, internal_error)

### Alerts
- Function execution p95 >2.5s, error rate >5%, timeout rate >2%, service_unavailable >10/hour

### Monitoring Dashboard
- Real-time function execution counts by type
- Error rate trends by function
- Performance histograms (latency distribution)
- Top error messages with frequencies

### Rollout Plan
1. **Staging** (48h): Deploy to staging, run integration tests, validate all 8 functions
2. **Production 5%** (72h): Enable for 5% users, monitor error rates, performance, costs
3. **Production 20%** (72h): Expand to 20%, validate at scale
4. **Production 50%** (72h): Expand to 50%, monitor cost scaling
5. **Production 100%**: Full rollout after validation

---

## 16. Open Questions

| Question | Recommendation | Decision Owner |
|----------|---------------|----------------|
| Cache function results? | Yes for 5 minutes (identical params) — reduces redundant execution | Cody Backend |
| Implement function chaining? | Not for MVP — single function execution sufficient, add in Phase 2 if needed | Pete / Product |
| Timeout value (2s vs 3s)? | Start with 2s, monitor timeout rate, increase if >2% | Cody Backend |
| Log full parameters or sanitized? | Sanitize (no sensitive data like message content) — privacy first | Cody Backend |
| Retry failed functions automatically? | Not automatic retry — return error, let user decide to retry | Cody iOS |
| Support multiple function calls per request? | Not for MVP — one function at a time, add chaining later if needed | Pete / Product |

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:
- [ ] **Function chaining** (execute multiple functions sequentially) — Deferred to Phase 2 if demand exists
- [ ] **Voice-based function calling** — Deferred to Phase 3 (voice interface)
- [ ] **Custom user-defined functions** — Deferred to Phase 4 (advanced personalization)
- [ ] **Real-time streaming function results** — Deferred to Phase 2 (currently batch results)
- [ ] **Function call retries with exponential backoff** — Let user manually retry for MVP
- [ ] **Advanced caching strategies** (per-user caching, cache invalidation) — Simple 5-min cache sufficient for MVP
- [ ] **Function call analytics dashboard** — Basic metrics sufficient, advanced dashboard in Phase 4
- [ ] **Function execution replay** (re-run past function calls) — Deferred to debugging tools
- [ ] **OpenAI function calling v2 features** (parallel function calling) — Use v1 for MVP stability

---

## 18. Authoring Notes

- Write integration tests before coding (test-driven development)
- Start with 2-3 core functions, then expand to all 8 (incremental implementation)
- Keep function handlers small and focused (single responsibility)
- Log liberally for debugging (but sanitize sensitive data)
- Test with real OpenAI function calling API in staging
- Coordinate with PR #AI-001 (RAG Pipeline) for integration
- Document error codes clearly for iOS developers
- iOS Swift models must match TypeScript schemas exactly (consider code generation)
- Reference `MessageAI/agents/shared-standards.md` for error handling patterns
- This PR includes both backend (Cloud Functions) and iOS (FunctionCallingService.swift)

---

**Document Status:** ✅ Ready for Review  
**Next Step:** Present to user for feedback, then create TODO document (YOLO: false)  
**Estimated Complexity:** Complex (8 functions, orchestrator, iOS integration, type safety across languages)  
**Estimated Timeline:** 4-6 days (including all handlers, iOS service, testing, and integration)

---

**End of PRD**

