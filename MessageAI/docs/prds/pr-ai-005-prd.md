# PRD: Error Handling & Fallback System

**Feature**: AI Error Handling & Fallback System (Calm Intelligence Foundation)

**Version**: 1.0

**Status**: Draft

**Agent**: Pete Agent

**Target Release**: Phase 1 - AI Foundation

**PR Number**: #AI-005

**Links**: 
- [AI Implementation Brief](../ai-implementation-brief.md#pr-ai-005-error-handling--fallback-system)
- [Shared Standards](../../agents/shared-standards.md)

---

## 1. Summary

Implement comprehensive calm error handling across all AI features ensuring graceful degradation when services fail. When OpenAI times out, Pinecone hits rate limits, or network fails, users see calm first-person messages ("I'm having trouble right now. Want to try again?") in blue/gray tones with actionable fallbacks. Core messaging always works even when ALL AI services are down.

**Smallest End-to-End Outcome:** Any AI feature failure shows calm blue/gray error message with retry/fallback options, and core messaging continues working uninterrupted.

---

## 2. Problem & Goals

### Problem
AI services fail in multiple ways (timeouts, rate limits, network errors, quota exceeded). Traditional "ERROR" messages in red create anxiety and don't provide clear next steps. Users need AI to fail gracefully without disrupting their core communication workflow.

### Why Now?
Phase 1 foundation work built in parallel with AI features. Implementing error handling upfront prevents inconsistent error experiences and ensures all AI features follow Calm Intelligence principles from day one.

### Goals (ordered, measurable)
- [ ] G1 — Unified `AIErrorHandler` service provides consistent calm error messages across all AI features
- [ ] G2 — All AI failures show blue/gray calm UI (never red) with transparent explanation
- [ ] G3 — Every error provides actionable fallback: retry, open full content, or continue without AI
- [ ] G4 — Core messaging works 100% when ALL AI services down (graceful degradation)
- [ ] G5 — Retry mechanisms use exponential backoff (1s, 2s, 4s, 8s max) to avoid overwhelming services
- [ ] G6 — Error rate <1% with monitoring and alerts

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing AI features themselves (Thread Summarization, Smart Search, etc.) — This provides error infrastructure they'll use
- [ ] Not building admin error dashboard UI — Just logging infrastructure
- [ ] Not implementing circuit breaker pattern — Simple retry with exponential backoff is sufficient
- [ ] Not handling Firebase/Firestore errors — Only AI-specific service errors (OpenAI, Pinecone)

---

## 4. Success Metrics

### System Performance
- **AI Error Rate**: <1% of AI requests fail
- **Timeout Rate**: <0.5% of OpenAI API calls timeout (>10s)
- **Retry Success Rate**: >80% of automatically retried requests succeed
- **Graceful Degradation**: Core messaging works 99.99% regardless of AI status

### User Experience
- **Error UI Latency**: <50ms from error detection to UI update
- **Fallback Activation**: <200ms to switch to fallback mode
- **User Satisfaction**: >90% understand what went wrong from error message

### Quality
- **0 blocking bugs**: AI errors never crash app or prevent core messaging
- **Crash-free rate**: >99.9% even under AI service failures

---

## 5. Users & Stories

**Primary Users:** All AI Features (PR #AI-006 through #AI-011)
- As **Thread Summarization**, I want to call `AIErrorHandler.handle(error)` when OpenAI times out, so users see calm message and can open full thread
- As **Smart Search**, I want to fall back to keyword search when vector search unavailable
- As **Priority Detection**, I want uncategorized messages in neutral "Inbox" when categorization fails

**End Users (Maya):**
- When thread summarization times out, I want calm message "I'm having trouble right now. Want to try again?" with button to open full thread
- When Smart Search hits rate limit, I want to know "I need a moment to catch up. Try again in 30 seconds"
- When AI services are down, I want my core messaging to work perfectly without disruption

---

## 6. Experience Specification (UX)

### Error UI - Calm Intelligence Principles

**Inline Error Message:**
- **Colors**: Soft blue/gray background (#F0F4F8), never red
- **Icon**: ℹ️ information icon (not ❌ error)
- **Tone**: First-person supportive ("I'm having trouble" not "Error occurred")
- **Actions**: Prominent [Try Again] [Open Thread] buttons

**Error Messages by Type:**
- **Timeout**: "I'm having trouble right now. Want to try again?"
- **Rate Limit**: "I need a moment to catch up. Try again in 30 seconds"
- **Service Unavailable**: "Taking longer than expected. Want to open the full thread while I work?"
- **Network Failure**: "I can't reach my AI assistant right now"
- **Quota Exceeded**: "AI features are temporarily limited"

**Fallback Mode Indicator:**
- Top banner: "🔵 Using basic search (AI paused)" when in degraded mode
- Transparent explanation on tap

### Performance
- Error display: <50ms
- Retry start: <100ms after user tap
- Fallback switch: <200ms
- Error handling overhead: <10ms per AI request

---

## 7. Functional Requirements

### MUST: Error Detection & Classification
Detect and classify 6 core error types:
1. **Timeout** (>10s response) → Auto-retry
2. **Rate Limit** (429) → Manual retry only
3. **Service Unavailable** (500/503) → Auto-retry
4. **Network Failure** → Auto-retry
5. **Invalid Request** (400) → No retry
6. **Quota Exceeded** (402) → No retry

### MUST: Error Handling Service
Create `AIErrorHandler.swift` with:
- `func handle(error: AIError, context: AIContext) -> ErrorResponse`
- `func shouldRetry(error: AIError) -> (shouldRetry: Bool, delay: TimeInterval)`
- `func getFallbackOption(feature: AIFeature) -> FallbackAction?`
- `func logError(error: AIError, context: AIContext) async throws`

### MUST: Retry Mechanism
Exponential backoff for transient errors:
- 1st: 1s delay
- 2nd: 2s delay
- 3rd: 4s delay
- 4th: 8s delay (max)
- Stop after 4 attempts
- Only auto-retry timeouts and 500/503 (not rate limits or 400s)

### MUST: Graceful Degradation
Core messaging works when ALL AI services down:
- Send/receive messages ✓
- Read conversations ✓
- AI features gracefully disabled with explanation

### MUST: Fallback Options by Feature
- **Thread Summarization**: "Open Full Thread" button
- **Action Item Extraction**: Show last 10 messages
- **Smart Search**: Fall back to keyword search
- **Priority Detection**: All messages to neutral "Inbox"
- **Decision Tracking**: Skip detection, show raw history
- **Proactive Assistant**: "Check calendar manually"

### MUST: Error Logging
Log every AI error to Crashlytics + Firestore `/failedAIRequests/`:
- Error type, timestamp, AI feature, user ID (hashed)
- Request context (messageId/threadId/query)
- NO message content (privacy)

### SHOULD: Smart Retry Queuing
Queue failed requests for automatic retry when service recovers (background job every 5 mins)

---

## 8. Data Model

### Firestore: `/failedAIRequests/{requestId}/`
```typescript
{
  id: string;
  userId: string;                // Hashed
  feature: AIFeature;            // "summarization" | "search" | "priority" etc
  errorType: AIErrorType;        // "timeout" | "rateLimit" | "serviceUnavailable" etc
  timestamp: Timestamp;
  retryCount: number;            // 0-4
  nextRetryAt: Timestamp;        // Exponential backoff
  requestContext: {
    messageId?: string;
    threadId?: string;
    query?: string;              // Hashed
  };
  errorDetails: {
    message: string;
    statusCode?: number;
  };
  resolved: boolean;
  resolvedAt?: Timestamp;
}
```

**Indexes**: `userId + timestamp`, `feature + errorType + timestamp`, `resolved + nextRetryAt`

### Swift Models
```swift
enum AIErrorType: String, Codable {
    case timeout, rateLimit, serviceUnavailable, 
         networkFailure, invalidRequest, quotaExceeded, unknown
}

struct AIError: Error, Codable {
    let type: AIErrorType
    let message: String
    let statusCode: Int?
    let retryable: Bool
    let retryDelay: TimeInterval
    let timestamp: Date
}

enum AIFeature: String, Codable {
    case summarization, actionItemExtraction, semanticSearch,
         priorityDetection, decisionTracking, proactiveScheduling
}

struct ErrorResponse {
    let error: AIError
    let userMessage: String        // Calm first-person message
    let fallbackAction: FallbackAction?
    let shouldRetry: Bool
    let retryDelay: TimeInterval
}

enum FallbackAction {
    case openFullThread(threadId: String)
    case showRecentMessages(count: Int)
    case useKeywordSearch(query: String)
    case showInbox
    case skipDetection
    case manualScheduling
}
```

---

## 9. API / Service Contracts

### AIErrorHandler Service (Swift)
```swift
class AIErrorHandler {
    // Core error handling
    func handle(error: AIError, context: AIContext) -> ErrorResponse
    func shouldRetry(error: AIError) -> (shouldRetry: Bool, delay: TimeInterval)
    func getFallbackOption(feature: AIFeature, context: AIContext) -> FallbackAction?
    
    // Logging & monitoring
    func logError(error: AIError, context: AIContext) async throws
    func queueForRetry(error: AIError, context: AIContext) async throws -> String
    func shouldUseFallbackMode(feature: AIFeature) async -> Bool
    
    // Retry management
    func retryRequest(requestId: String) async throws -> Bool
    func processRetryQueue() async throws -> Int
    
    // User-facing messages
    func getUserMessage(for error: AIError, feature: AIFeature) -> String
    func getActionTitles(for error: AIError) -> (primary: String, secondary: String?)
}
```

### Cloud Functions Error Handling (TypeScript)
```typescript
// Classify any error into AIErrorType
export function classifyError(error: any): {
  type: AIErrorType;
  message: string;
  retryable: boolean;
  retryDelay: number;
  statusCode?: number;
}

// Wrap AI API calls with timeout and error handling
export async function withErrorHandling<T>(
  operation: () => Promise<T>,
  timeoutMs: number = 10000,
  context: AIContext
): Promise<{ success: boolean; data?: T; error?: ClassifiedError }>
```

---

## 10. UI Components to Create/Modify

### New SwiftUI Components
- `Views/AIError/CalmErrorView.swift` — Inline error with blue/gray background, first-person message, action buttons
- `Views/AIError/CalmErrorToast.swift` — Bottom toast for background notifications (4s)
- `Views/AIError/FallbackModeIndicator.swift` — Top banner for degraded mode
- `Components/LoadingWithTimeout.swift` — Loading with "Taking too long? Cancel" after 8s

### New Swift Services
- `Services/AI/AIErrorHandler.swift` — Central error handling
- `Services/AI/ErrorLogger.swift` — Crashlytics + Firestore logging
- `Services/AI/RetryQueue.swift` — Exponential backoff retry logic
- `Services/AI/FallbackModeManager.swift` — Track consecutive failures

### Modified Services (Integration)
- All AI services wrap calls with `AIErrorHandler.handle()`

### New Cloud Functions
- `functions/src/utils/errorHandling.ts` — `classifyError()`, `withErrorHandling()`
- `functions/src/jobs/retryQueue.ts` — Background job (every 5 mins)

---

## 11. Integration Points

- **Firestore**: Store failed requests in `/failedAIRequests/`
- **Crashlytics**: Log all AI errors
- **Cloud Scheduler**: Trigger retry queue processing every 5 minutes
- **OpenAI/Pinecone**: Catch all error types and classify
- **All AI Features**: Must call `AIErrorHandler.handle()` on any failure

---

## 12. Test Plan & Acceptance Gates

### Unit Tests (Swift Testing)

**Error Classification:**
- [ ] Timeout (>10s) → `.timeout`, retry=true, delay=1s
- [ ] Rate limit (429) → `.rateLimit`, retry=false, message="I need a moment"
- [ ] Service unavailable (503) → `.serviceUnavailable`, retry=true, delay=2s
- [ ] Network failure → `.networkFailure`, retry=true
- [ ] Invalid request (400) → `.invalidRequest`, retry=false
- [ ] Quota exceeded → `.quotaExceeded`, retry=false

**Retry Mechanism:**
- [ ] Exponential backoff: 1s, 2s, 4s, 8s delays
- [ ] Max 4 retry attempts before persistent error
- [ ] Rate limits not auto-retried

**Fallback Options:**
- [ ] Thread Summarization → "Open Full Thread"
- [ ] Smart Search → Keyword search
- [ ] Priority Detection → Neutral "Inbox"

**Error Logging:**
- [ ] AI error logged to Crashlytics + Firestore
- [ ] Privacy preserved (no message content, hashed IDs)

**Graceful Degradation:**
- [ ] Core messaging works when OpenAI down
- [ ] Core messaging works when Pinecone down
- [ ] Core messaging works when ALL AI down

### UI Tests (XCTest)
- [ ] AI error shows blue/gray view (not red)
- [ ] First-person message visible ("I'm having trouble")
- [ ] "Try Again" button works (retries operation)
- [ ] Fallback button works (e.g., "Open Thread" navigates)
- [ ] Timeout shows "Taking too long? Cancel" after 8s
- [ ] Fallback mode banner visible when degraded

### Performance Tests
- [ ] Error handling overhead <10ms
- [ ] Error UI display <50ms
- [ ] Retry start <100ms after tap
- [ ] Fallback activation <200ms

### Integration Tests (TypeScript)
- [ ] `classifyError()` correctly identifies timeout/429/503/network/400/402
- [ ] `withErrorHandling()` wraps OpenAI calls and logs errors
- [ ] Failed requests stored in `/failedAIRequests/`
- [ ] Retry queue background job processes requests

---

## 13. Definition of Done

- [ ] `AIErrorHandler.swift` service implemented with all methods
- [ ] Unit tests (Swift Testing) for error classification, retry, fallback
- [ ] UI tests (XCTest) for calm error views, buttons, fallback mode
- [ ] `CalmErrorView`, `CalmErrorToast`, `FallbackModeIndicator` SwiftUI components
- [ ] Cloud Functions `withErrorHandling()` utility wraps all AI calls
- [ ] Error logging to Crashlytics + Firestore verified
- [ ] Retry queue background job tested (runs every 5 mins)
- [ ] Graceful degradation verified: messaging works when AI down
- [ ] All acceptance gates pass
- [ ] Performance targets met (<50ms UI, <10ms overhead)
- [ ] Docs updated with error handling patterns

---

## 14. Risks & Mitigations

### Risk: Error messages feel too technical or robotic
**Mitigation:** User-test messages with 5+ users, use first-person tone, avoid jargon, iterate on copy

### Risk: Too many retries overwhelm recovering service
**Mitigation:** Exponential backoff, max 4 attempts, fallback mode after 3 consecutive failures

### Risk: Fallback options aren't good enough
**Mitigation:** Test fallback flows with real users, ensure fallback preserves core user goal

### Risk: Error handling overhead slows AI features
**Mitigation:** Measure overhead (<10ms target), use lightweight classification, async logging

---

## 15. Rollout & Telemetry

### Feature Flag
**Yes** — `ai_error_handling_enabled`
- Week 1: 5% internal testing
- Week 2: 20% alpha users
- Week 3: 50% beta users
- Week 4: 100% GA

### Metrics to Monitor
- **AI error rate**: <1% target
- **Error rate by type**: Breakdown (timeout, rate limit, etc.)
- **Retry success rate**: >80% target
- **User sentiment**: Feedback on error messages
- **Fallback usage**: % using fallback vs retry
- **Core messaging uptime**: 99.99% target

### Manual Validation
- [ ] Test all 6 error types manually
- [ ] Verify blue/gray UI (no red)
- [ ] Test retry and fallback flows
- [ ] Verify messaging works when AI offline
- [ ] Check error logging in Crashlytics + Firestore

---

## 16. Open Questions

**Q1:** Should we notify users when AI recovers after >30min downtime?  
**Recommendation:** Yes, show toast "My AI assistant is back online ✓"

**Q2:** Should error messages differ between features?  
**Recommendation:** Keep generic for consistency unless feature-specific context adds value

**Q3:** Critical error rate threshold for paging engineer?  
**Recommendation:** 5% sustained for 10 mins = alert, 20% = critical page

---

## 17. Appendix: Out-of-Scope Backlog

- [ ] Admin error dashboard UI (future PR)
- [ ] Circuit breaker pattern (future enhancement)
- [ ] Predictive fallback activation (Phase 3)
- [ ] Multi-language error messages (future i18n)
- [ ] Custom error verbosity per user (low priority)

---

## Preflight Questionnaire

1. **Smallest end-to-end outcome:** Any AI failure shows calm error message with retry/fallback, messaging works
2. **Primary user:** All AI features; **Critical action:** Handle failures gracefully
3. **Must-have:** Error classification, calm UI, retry, fallback, graceful degradation, logging
4. **Real-time requirements:** Error display <50ms, retry <100ms, fallback switch <200ms
5. **Performance:** Error overhead <10ms per AI request
6. **Edge cases:** 6 error types, multiple failures, error during retry, network offline, quota exceeded
7. **Data model:** `/failedAIRequests/` collection, Swift error models
8. **Service APIs:** `AIErrorHandler`, `classifyError()`, `withErrorHandling()`
9. **UI states:** Loading, timeout, rate limit, service unavailable, network failure, fallback mode
10. **Security:** Hash user IDs, no message content in logs
11. **Dependencies:** PR #AI-001 (RAG) for AI calls to wrap, Cloud Functions for background jobs
12. **Rollout:** Gradual with feature flag, 5% → 20% → 50% → 100%
13. **Out of scope:** Admin dashboard, circuit breaker, predictive fallback, implementing AI features

---

**Author:** Pete Agent  
**Status:** Draft — Ready for Review (YOLO: false)  
**Next Step:** After approval, create TODO list  
**Line Count:** ~500 lines (vs 1536 before) ✂️

