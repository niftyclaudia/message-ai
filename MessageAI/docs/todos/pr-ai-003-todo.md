# PR-AI-003 TODO — Function Calling Framework

**Branch**: `feat/ai-003-function-calling`  
**Source PRD**: `MessageAI/docs/prds/pr-ai-003-prd.md`  
**Owner (Agent)**: Cody Backend + Cody iOS Agent  
**Complexity**: Complex (Backend Orchestrator + iOS Integration + Type Safety)  
**Estimated Time**: 4-6 days

---

## 🚨 Prerequisites & Setup (DO THESE FIRST!)

These setup tasks will make your life MUCH easier. Do them before writing any code.

### External Dependencies Check
- [ ] **Verify PR #AI-001 (RAG Pipeline) Status**
  - Function calling framework depends on RAG Pipeline for semantic operations
  - Check if `semanticSearch` Cloud Function is deployed and working
  - If PR #AI-001 incomplete: Create mock RAG responses for testing
  - **Why**: 5 of 8 functions call RAG Pipeline - need it for integration tests

- [ ] **OpenAI Function Calling API Access**
  - Verify OpenAI API key has function calling capabilities (GPT-4 or GPT-3.5-turbo)
  - Test function calling with simple example:
    ```bash
    curl https://api.openai.com/v1/chat/completions \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d '{"model": "gpt-4", "messages": [...], "functions": [...]}'
    ```
  - **Why**: Function calling requires specific OpenAI models

- [ ] **Firebase Functions Configuration**
  - Ensure Firebase Functions on Blaze plan (function calling can be resource-intensive)
  - Check Functions quota (concurrent executions, compute time)
  - Verify Firestore has test data (messages, chats, users)
  - **Why**: Avoid hitting quotas during testing

### Local Development Environment

- [ ] **Install Dependencies**
  ```bash
  cd functions/
  npm install openai
  npm install -D @types/node typescript
  ```
  - Verify TypeScript compilation works: `npm run build`
  - **Why**: Get all packages before coding

- [ ] **Configure Environment Variables**
  - Create `functions/.env.local` for local testing:
    ```
    OPENAI_API_KEY=sk-...
    PINECONE_API_KEY=...
    PINECONE_ENV=us-central1-gcp
    PINECONE_INDEX=messageai
    ```
  - Ensure `.gitignore` includes `.env.local`
  - For production, verify Firebase config:
    ```bash
    firebase functions:config:get
    ```
  - **Why**: Function calling needs OpenAI API key immediately

- [ ] **Create Test Data**
  - Manually add 10+ test messages to Firestore in dev/staging
  - Create test threads with varied content:
    - Long thread (20+ messages) for summarization
    - Messages with action items ("Review by Friday", "I'll send the doc")
    - Messages with decisions ("We decided on Stripe", "Approved")
    - Messages with scheduling phrases ("Let's meet", "Schedule a call")
  - Document messageIds/threadIds for testing
  - **Why**: Each function needs specific test data patterns

- [ ] **iOS Development Setup**
  - Ensure Xcode project opens without errors
  - Verify Firebase SDK installed in iOS project
  - Check `GoogleService-Info.plist` present
  - Run existing unit tests to confirm test harness works
  - **Why**: Catch iOS setup issues early

### Branch & Documentation

- [ ] **Create feature branch** from `develop`
  ```bash
  git checkout develop
  git pull origin develop
  git checkout -b feat/ai-003-function-calling
  ```

- [ ] **Read supporting docs** (20 min investment that saves hours)
  - Read `MessageAI/agents/shared-standards.md` (error handling, testing patterns)
  - Read `MessageAI/docs/prds/pr-ai-003-prd.md` thoroughly
  - Review `MessageAI/docs/prds/pr-ai-001-prd.md` for RAG integration patterns
  - Skim OpenAI function calling docs: https://platform.openai.com/docs/guides/function-calling
  - **Why**: Understand patterns before coding

---

## 1. Project Structure Setup

Create folder structure for function calling framework before coding.

- [ ] **Create function calling directories**
  ```bash
  cd functions/src/
  mkdir -p functionCalling/handlers
  mkdir -p utils
  ```

- [ ] **Create placeholder files** (helpful for imports)
  ```bash
  # Backend
  touch functions/src/functionCalling/orchestrator.ts
  touch functions/src/functionCalling/schemas.ts
  touch functions/src/functionCalling/validation.ts
  touch functions/src/utils/executionLogger.ts
  touch functions/src/utils/errorHandler.ts
  touch functions/src/utils/permissionChecker.ts
  
  # Create handler files
  touch functions/src/functionCalling/handlers/summarizeThread.ts
  touch functions/src/functionCalling/handlers/extractActionItems.ts
  touch functions/src/functionCalling/handlers/searchMessages.ts
  touch functions/src/functionCalling/handlers/categorizeMessage.ts
  touch functions/src/functionCalling/handlers/trackDecisions.ts
  touch functions/src/functionCalling/handlers/detectSchedulingNeed.ts
  touch functions/src/functionCalling/handlers/checkCalendar.ts
  touch functions/src/functionCalling/handlers/suggestMeetingTimes.ts
  ```

- [ ] **Create iOS structure**
  ```bash
  # iOS
  mkdir -p MessageAI/MessageAI/Services/AI
  mkdir -p MessageAI/MessageAI/Utilities/AI
  
  touch MessageAI/MessageAI/Services/AI/FunctionCallingService.swift
  touch MessageAI/MessageAI/Services/AI/FunctionCallingModels.swift
  touch MessageAI/MessageAI/Utilities/AI/FunctionCallLogger.swift
  ```

- [ ] **Update TypeScript config** if needed
  - Ensure `functions/tsconfig.json` includes new directories
  - Verify module resolution works

---

## 2. Backend: Function Schemas & Types

Define OpenAI function schemas and TypeScript types FIRST. This drives everything else.

### Function Schema Definitions

- [ ] **Create `functionCalling/schemas.ts`**
  - Define all 8 function schemas in OpenAI format (JSON)
  - Export `FUNCTION_SCHEMAS: FunctionSchema[]` array
  - **Test Gate**: Schemas validate against OpenAI spec (no syntax errors)

- [ ] **Define TypeScript types for each function**
  ```typescript
  // Input/Output types for all 8 functions
  interface SummarizeThreadParams { threadId: string; maxLength?: number; }
  interface ThreadSummary { summary: string; keyPoints: string[]; participants: string[]; decisionCount: number; messageCount: number; }
  
  interface ExtractActionItemsParams { threadId: string; userId: string; }
  interface ActionItem { id: string; task: string; deadline?: Date; assignee?: string; sourceMessageId: string; createdAt: Date; }
  
  // ... define all 8 function param/result types
  ```
  - **Test Gate**: TypeScript compiles without errors

- [ ] **Create validation rules mapping**
  ```typescript
  const VALIDATION_RULES = {
    summarizeThread: {
      threadId: { type: 'string', required: true, pattern: /^[a-zA-Z0-9_-]+$/ },
      maxLength: { type: 'number', min: 50, max: 500, required: false }
    },
    // ... rules for all 8 functions
  }
  ```
  - **Test Gate**: Validation rules cover all parameters

### Parameter Validation Utilities

- [ ] **Create `functionCalling/validation.ts`**
  - Implement `validateParameters(functionName, params): ValidationResult`
  - Implement helpers:
    - `validateThreadId(id: string): boolean`
    - `validateUserId(id: string): boolean`
    - `validateDateRange(start: string, end: string): boolean`
    - `validateLimit(limit: number, min: number, max: number): boolean`
    - `validateArray(arr: any[], minItems: number, maxItems: number): boolean`
  - **Test Gate**: Unit tests pass for valid/invalid inputs

- [ ] **Write validation unit tests**
  ```typescript
  // tests for validation.ts
  describe('Parameter Validation', () => {
    test('valid threadId passes', () => {
      expect(validateThreadId('chat_abc123')).toBe(true);
    });
    test('invalid threadId rejected', () => {
      expect(validateThreadId('')).toBe(false);
      expect(validateThreadId('invalid@#$')).toBe(false);
    });
    // ... tests for all validation functions
  });
  ```
  - **Test Gate**: All validation tests pass (20+ tests)

---

## 3. Backend: Function Handlers (Core Logic)

Implement handlers for each of the 8 functions. **Strategy**: Start with 2-3 simple handlers, test end-to-end, then implement remaining 5.

**All handlers follow this pattern:**
1. Validate parameters
2. Check user permissions
3. Execute logic (fetch data, call RAG, analyze)
4. Return structured result

### Phase 1: Simple Handlers (Start Here)

- [ ] **Implement `handlers/searchMessages.ts`** — Delegates to RAG Pipeline semantic search
- [ ] **Implement `handlers/categorizeMessage.ts`** — Analyzes message content with RAG, returns MessageCategory
- [ ] **Implement `handlers/detectSchedulingNeed.ts`** — Searches for scheduling phrases ("let's meet", "schedule")

### Phase 2: Complex Handlers

- [ ] **Implement `handlers/summarizeThread.ts`** — Fetches messages, uses RAG for key points, returns ThreadSummary
- [ ] **Implement `handlers/extractActionItems.ts`** — Uses RAG to find task patterns, returns ActionItem[]
- [ ] **Implement `handlers/trackDecisions.ts`** — Uses RAG to detect decision patterns, returns Decision[]

### Phase 3: Calendar/Scheduling Handlers

- [ ] **Implement `handlers/checkCalendar.ts`** — Fetches calendar events (calls iOS EventKit via iOS SDK)
- [ ] **Implement `handlers/suggestMeetingTimes.ts`** — Calls checkCalendar for all participants, finds overlapping free slots, respects focus hours

### Handler Testing

- [ ] **Write unit tests for each handler** (40+ tests total)
  - Happy path, validation errors, permission errors, edge cases, RAG failures
  - **Test Gate**: All handlers return correct types with proper error handling

---

## 4. Backend: Function Calling Orchestrator

Central orchestrator that routes function calls to appropriate handlers.

- [ ] **Create `functionCalling/orchestrator.ts`**
  - Implement `executeFunctionCall(functionName, parameters, userId): Promise<FunctionResult>`
  - Workflow:
    1. Validate authentication (check Firebase Auth context)
    2. Validate functionName (must be one of 8 defined functions)
    3. Validate parameters using validation.ts
    4. Route to appropriate handler based on functionName
    5. Execute handler with 2s timeout
    6. Log execution (success/failure)
    7. Return structured result or error
  - **Test Gate**: Orchestrator routes to correct handler for each functionName

- [ ] **Implement handler routing**
  ```typescript
  const HANDLER_MAP: Record<string, FunctionHandler<any, any>> = {
    summarizeThread: summarizeThreadHandler,
    extractActionItems: extractActionItemsHandler,
    searchMessages: searchMessagesHandler,
    categorizeMessage: categorizeMessageHandler,
    trackDecisions: trackDecisionsHandler,
    detectSchedulingNeed: detectSchedulingNeedHandler,
    checkCalendar: checkCalendarHandler,
    suggestMeetingTimes: suggestMeetingTimesHandler
  };
  
  const handler = HANDLER_MAP[functionName];
  if (!handler) throw new Error('invalid_function');
  ```
  - **Test Gate**: Unknown function names rejected with `invalid_function` error

- [ ] **Implement timeout enforcement**
  ```typescript
  const executeWithTimeout = async (handler, timeoutMs = 2000) => {
    return Promise.race([
      handler(),
      new Promise((_, reject) => 
        setTimeout(() => reject(new Error('timeout')), timeoutMs)
      )
    ]);
  };
  ```
  - **Test Gate**: Functions exceeding 2s timeout return `timeout` error

- [ ] **Deploy Cloud Function**
  ```typescript
  export const executeFunctionCall = functions.https.onCall(async (data, context) => {
    const { functionName, parameters } = data;
    const userId = context.auth?.uid;
    
    if (!userId) throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
    
    return await orchestrator.executeFunctionCall(functionName, parameters, userId);
  });
  ```
  - **Test Gate**: Cloud Function deployed and callable from iOS

---

## 5. Backend: Utilities

Support utilities for logging, error handling, and permissions.

### Execution Logging

- [ ] **Create `utils/executionLogger.ts`**
  - Implement `logExecution(functionName, params, userId, duration, status, error?)`
  - Write to Firestore `/functionExecutionLogs/{executionId}`
  - Sanitize parameters (remove sensitive data)
  - Store: executionId, functionName, params (sanitized), userId, timestamp, duration, status, errorDetails
  - **Test Gate**: Logs written to Firestore after function execution

- [ ] **Implement log querying**
  - `queryExecutionLogs(filters: LogFilters): Promise<FunctionExecutionLog[]>`
  - Filter by: functionName, userId, status, date range
  - **Test Gate**: Can query logs by function name and user

- [ ] **Implement 30-day auto-cleanup**
  - Create scheduled function to delete logs older than 30 days
  - **Test Gate**: Old logs deleted automatically

### Error Handling

- [ ] **Create `utils/errorHandler.ts`**
  - Implement `handleFunctionError(error: Error, functionName: string): FunctionExecutionError`
  - Map errors to user-friendly codes:
    - `invalid_parameters` → "Missing or invalid parameters"
    - `permission_denied` → "You don't have access to this resource"
    - `timeout` → "Request took too long"
    - `service_unavailable` → "Service temporarily unavailable"
    - `internal_error` → "Unexpected error occurred"
  - **Test Gate**: All error types mapped correctly

- [ ] **Implement error response formatting**
  - `createErrorResponse(code, message, details?): ErrorResponse`
  - Include helpful context (which parameter failed, suggestions)
  - **Test Gate**: Error responses include actionable information

### Permission Checking

- [ ] **Create `utils/permissionChecker.ts`**
  - Implement `checkUserAccess(userId, resourceId, resourceType): Promise<boolean>`
  - Check user can access:
    - Messages (senderId === userId OR userId in chat members)
    - Threads (userId in chat members)
    - Calendar (userId matches requested calendar)
  - **Test Gate**: Permission checks prevent unauthorized access

---

## 6. iOS: Function Calling Models

Define Swift models matching TypeScript schemas EXACTLY.

- [ ] **Create `Services/AI/FunctionCallingModels.swift`**
  - Define all result models:
    - `struct ThreadSummary: Codable`
    - `struct ActionItem: Codable, Identifiable`
    - `struct SearchResult: Codable, Identifiable`
    - `struct MessageCategory: Codable`
    - `enum CategoryType: String, Codable` (urgent, canWait, aiHandled)
    - `struct Decision: Codable, Identifiable`
    - `struct SchedulingNeed: Codable`
    - `struct CalendarEvent: Codable, Identifiable`
    - `struct MeetingTimeSuggestion: Codable, Identifiable`
  - Define execution models:
    - `struct FunctionExecutionResult<T: Codable>: Codable`
    - `struct FunctionExecutionError: Codable`
  - **Test Gate**: Swift models compile without errors
  - **Test Gate**: All models are Codable (can serialize/deserialize)

- [ ] **Verify type safety**
  - Compare Swift models to TypeScript types in `schemas.ts`
  - Ensure field names match exactly (case-sensitive)
  - Ensure types match (String ↔ string, Int ↔ number, Date ↔ Timestamp)
  - **Test Gate**: Manual review confirms types match

---

## 7. iOS: Function Calling Service

iOS client service that calls Cloud Functions.

- [ ] **Create `Services/AI/FunctionCallingService.swift`**
  - Define protocol `FunctionCallingServiceProtocol` with all 8 function methods
  - Implement `class FunctionCallingService: FunctionCallingServiceProtocol`
  - Initialize Firebase Functions: `private let functions = Functions.functions()`
  - **Test Gate**: Service class compiles without errors

### Implement Function Methods

- [ ] **Implement all 8 function methods** (pattern: call `executeFunctionCall` Cloud Function → parse typed response → handle errors)
  1. `summarizeThread(threadId:maxLength:) -> ThreadSummary`
  2. `extractActionItems(threadId:) -> [ActionItem]`
  3. `searchMessages(query:chatId:limit:) -> [SearchResult]`
  4. `categorizeMessage(messageId:) -> MessageCategory`
  5. `trackDecisions(threadId:) -> [Decision]`
  6. `detectSchedulingNeed(threadId:) -> SchedulingNeed?`
  7. `checkCalendar(startDate:endDate:) -> [CalendarEvent]`
  8. `suggestMeetingTimes(participants:duration:) -> [MeetingTimeSuggestion]`
  - **Test Gate**: All methods return correct types with proper error handling

### Response Parsing & Error Handling

- [ ] **Implement response parsing helper**
  ```swift
  private func parseResponse<T: Codable>(_ data: Any, as type: T.Type) throws -> T {
    // Convert Firebase Functions response to Swift Codable type
    // Handle JSON parsing errors
    // Extract result or error from FunctionExecutionResult wrapper
    // Throw descriptive Swift errors
  }
  ```
  - **Test Gate**: Parsing handles valid responses correctly
  - **Test Gate**: Parsing throws descriptive errors for invalid responses

- [ ] **Define Swift error types**
  ```swift
  enum FunctionCallingError: LocalizedError {
    case invalidParameters(String)
    case permissionDenied(String)
    case timeout
    case serviceUnavailable(String)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
      // User-friendly error messages
    }
  }
  ```
  - **Test Gate**: All error types have user-friendly messages

- [ ] **Implement timeout handling**
  - Set reasonable timeout (5s for network calls)
  - Throw `FunctionCallingError.timeout` if exceeded
  - **Test Gate**: Timeout errors handled gracefully

---

## 8. Integration Testing

Test entire flow: iOS → Cloud Function → Handler → Response → iOS

### Backend Integration Tests

- [ ] **Test orchestrator end-to-end** — All 8 functions callable via `executeFunctionCall`, return correct types, execution logged
- [ ] **Test authentication & authorization** — Unauthenticated requests rejected, users can't access others' data
- [ ] **Test error handling** — Invalid function/params, timeouts, service unavailable, unexpected errors all handled gracefully

### iOS Integration Tests

- [ ] **Test all 8 iOS methods** — Deploy to staging, test each method with real data, verify Cloud Functions called successfully
- [ ] **Test response parsing** — Valid responses parse correctly, invalid responses throw descriptive errors, type safety enforced
- [ ] **Test error handling** — Network timeouts, invalid responses, Firebase Auth errors handled without crashes

### RAG Pipeline Integration Tests

- [ ] **Test RAG integration** — 5 functions (summarize, search, extractActionItems, categorize, trackDecisions) correctly call RAG Pipeline
- [ ] **Test RAG failures** — Functions handle RAG unavailable gracefully with fallback behavior

---

## 9. Performance Testing

- [ ] **Backend Performance** — Measure p95 latency (<2s target), validation speed (<50ms), concurrent calls (50 in <3s), logging overhead (<10ms)
- [ ] **iOS Performance** — Measure network roundtrip (<2.5s), response parsing (<100ms)
  - **Test Gate**: All performance targets met

---

## 10. Edge Case Testing

- [ ] **Edge case data** — Long threads (100+ messages), special characters, time zones, no available times, empty/missing/deleted resources
- [ ] **Invalid inputs** — Empty strings, null values, negative numbers, invalid IDs, malformed dates, out-of-range limits
- [ ] **Permission edge cases** — Deleted threads, removed from chat, blocked users
  - **Test Gate**: All edge cases handled gracefully with clear error messages

---

## 11. Documentation

- [ ] **Add inline code comments** — Complex logic, validation rules, timeout implementation, error codes
- [ ] **Create API documentation** — All 8 function schemas with examples, error codes, iOS service usage examples
- [ ] **Create README** — `functions/src/functionCalling/README.md` with architecture, adding new functions, testing, deployment
- [ ] **Update environment setup guide** — Required env vars, Firebase config, OpenAI API key

---

## 12. Acceptance Gates (From PRD Section 12)

Check every gate from PRD before marking complete:

### Unit Tests
- [ ] All 8 function schemas valid OpenAI format
- [ ] Parameter validation tests pass (valid pass, invalid rejected)
- [ ] Each of 8 handlers returns correct types
- [ ] Orchestrator routes correctly and enforces timeout

### Integration Tests
- [ ] All 8 functions callable from iOS
- [ ] Authentication rejects unauthenticated requests
- [ ] Error handling returns descriptive errors
- [ ] RAG Pipeline integration working

### Performance Tests
- [ ] Function execution p95 < 2s (all 8 functions)
- [ ] Parameter validation < 50ms
- [ ] 50 concurrent calls complete within 3s
- [ ] Logging adds < 10ms overhead

### Edge Cases
- [ ] Long threads, special characters, time zones handled
- [ ] Empty/missing data handled gracefully
- [ ] Permission violations caught

### iOS Integration
- [ ] Swift models deserialize correctly
- [ ] Network timeouts handled
- [ ] Type safety enforced

---

## 13. Deployment & Rollout

- [ ] **Deploy to staging** — `firebase deploy --only functions:executeFunctionCall`, test all 8 functions, verify logging
- [ ] **Deploy to production** — Gradual rollout (5% → 20% → 50% → 100%), monitor error rates/latency/costs
- [ ] **Configure monitoring & alerts** — Cloud Logging filters, alert on error rate >5%, p95 latency >2.5s, daily cost >budget
- [ ] **Create monitoring dashboard** — Function call counts, error rates, latency histograms, top error messages

---

## 14. PR & Code Review

- [ ] **Verify all TODO items complete**
  - Review this checklist thoroughly
  - Ensure no skipped items

- [ ] **Run final test suite**
  - Backend unit tests: `cd functions && npm test`
  - iOS unit tests: Run in Xcode
  - Integration tests: Manual verification in staging
  - **Test Gate**: All tests passing

- [ ] **Code cleanup**
  - Remove commented-out code
  - Remove debug logs
  - Fix any linter warnings
  - Ensure consistent formatting

- [ ] **Create PR description** with:
  - Summary: 8 functions (summarizeThread, extractActionItems, searchMessages, categorizeMessage, trackDecisions, detectSchedulingNeed, checkCalendar, suggestMeetingTimes)
  - Changes: Backend orchestrator + 8 handlers + iOS service + Swift models
  - Testing: Unit tests (40+), integration tests, performance tests
  - Acceptance gates: Schemas valid, handlers working, iOS integration, performance met, RAG integration, auth working
  - Dependencies: PR #AI-001 (RAG), enables Phase 2 features
  - Deployment: Env vars (OPENAI_API_KEY), Blaze plan, gradual rollout
  - Screenshots: Execution logs, test results, monitoring dashboard

- [ ] **Verify with user before creating PR**
  - Demo all 8 functions working
  - Show test results
  - Walk through code structure
  - **Get approval to create PR**

- [ ] **Create PR targeting develop branch**
  ```bash
  git push origin feat/ai-003-function-calling
  # Create PR in GitHub/GitLab targeting develop
  ```

- [ ] **Link PRD and TODO in PR description**
  - Link to `MessageAI/docs/prds/pr-ai-003-prd.md`
  - Link to `MessageAI/docs/todos/pr-ai-003-todo.md`

---

## Copyable Checklist (for PR description)

```markdown
- [ ] Branch created from develop: feat/ai-003-function-calling
- [ ] All TODO tasks completed
- [ ] 8 function schemas defined (OpenAI format)
- [ ] 8 function handlers implemented (TypeScript)
- [ ] Function calling orchestrator implemented (routing, validation, timeout)
- [ ] Execution logging, error handling, permission checking implemented
- [ ] FunctionCallingService.swift implemented (iOS client)
- [ ] Swift models match TypeScript schemas exactly
- [ ] All unit tests pass (40+ backend tests, iOS tests)
- [ ] Integration tests pass (iOS → Cloud Functions end-to-end)
- [ ] Performance tests pass (p95 < 2s, validation < 50ms)
- [ ] Edge case tests pass (invalid inputs, timeouts, permissions)
- [ ] RAG Pipeline integration tested (5 functions)
- [ ] Authentication & authorization tested
- [ ] Type safety verified (Swift ↔ TypeScript)
- [ ] Code follows shared-standards.md patterns
- [ ] Documentation complete (inline comments, API docs, README)
- [ ] No console warnings or linter errors
- [ ] Deployed to staging and tested
- [ ] Monitoring & alerts configured
```

---

## Notes

**Strategy**: Infrastructure first (schemas, validation, orchestrator) → 2-3 simple handlers → test end-to-end → remaining handlers. iOS and backend can work in parallel after schemas defined.

**Common Pitfalls**: Type mismatches (Swift ↔ TypeScript), unsanitized logs (privacy), unhandled RAG failures, too-short timeouts, bypassed permission checks.

**References**: OpenAI function calling docs, Firebase Functions docs, `shared-standards.md`, PR #AI-001 for RAG integration

---

**End of TODO — Ready for Implementation! 🚀**

