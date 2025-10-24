# PR-AI-005 TODO — Error Handling & Fallback System

**Branch**: `feat/ai-005-error-handling-fallback`  
**Source PRD**: `MessageAI/docs/prds/pr-ai-005-prd.md`  
**Owner**: Cody Backend + Cody iOS

---

## 0. Setup & Assumptions

- [x] Create branch from develop
- [x] Read PRD + shared-standards.md
- [x] Verify Xcode builds, Firebase emulator running, tests work

**Key Assumptions:**
- Recovery notification after 30min downtime: Yes (toast)
- Error messages: Generic for consistency, iterate if needed
- Alert thresholds: 5% = alert, 20% = critical
- Blue/gray UI (#F0F4F8), first-person tone, core messaging never depends on AI

---

## 1. Data Model

### Firestore
- [x] Define `/failedAIRequests/{requestId}/` schema + security rules
- [x] Add indexes: `userId+timestamp`, `feature+errorType+timestamp`, `resolved+nextRetryAt`

### Swift Models
- [x] `Models/AI/AIError.swift` — AIErrorType enum, AIError struct (Error, Codable)
- [x] `Models/AI/AIFeature.swift` — Enum for 6 AI features
- [x] `Models/AI/ErrorResponse.swift` — Struct with userMessage, fallbackAction, shouldRetry, retryDelay
- [x] `Models/AI/FallbackAction.swift` — Enum with 6 fallback cases
- [x] `Models/AI/AIContext.swift` — Struct for error context
  - **Test Gate**: All models compile, Codable works ✅

---

## 2. Cloud Functions (TypeScript)

### Error Handling Utils (`functions/src/utils/errorHandling.ts`)
- [x] `classifyError()` — Detect 6 error types (timeout, 429, 500/503, network, 400, 402)
- [x] `withErrorHandling()` — Wrap operations with timeout (10s), log to Firestore
- [x] `logErrorToFirestore()` — Hash userId/query, no message content, calculate nextRetryAt
- [x] `calculateRetryDelay()` — Exponential backoff: 1s, 2s, 4s, 8s (max 4 attempts)
- [x] `shouldRetry()` — True for timeout/503/network, false for 429/400/402
  - **Test Gate**: Unit tests for all error types, timeout, success cases ✅

### Retry Queue Job (`functions/src/jobs/retryQueue.ts`)
- [x] `processRetryQueue()` — Query unresolved requests, retry operations, update Firestore
- [x] Register scheduled function (every 5 minutes) in `index.ts`
  - **Test Gate**: Integration test with mock failed requests ✅

---

## 3. Swift Services

### AIErrorHandler (`Services/AI/AIErrorHandler.swift`)
- [x] `handle()` — Generate calm message, determine retry, get fallback action
- [x] `shouldRetry()` — True for timeout/503/network (with delays), false otherwise
- [x] `getFallbackOption()` — Map 6 AI features to fallback actions
- [x] `getUserMessage()` — 6 first-person messages (timeout, rate limit, etc.)
- [x] `getActionTitles()` — "Try Again" for retryable, fallback action otherwise
- [x] `logError()` — Background logging to Crashlytics + Firestore
- [x] `queueForRetry()` — Write to `/failedAIRequests/`
- [x] `shouldUseFallbackMode()` — Check if 3+ consecutive failures
  - **Test Gate**: Unit tests for all methods, integration test for Firestore ✅

### ErrorLogger (`Services/AI/ErrorLogger.swift`)
- [x] `logToCrashlytics()` — Record error with type, feature, timestamp
- [x] `logToFirestore()` — Hash userId/query, write to `/failedAIRequests/`
  - **Test Gate**: Crashlytics visible, Firestore structure correct ✅

### RetryQueue (`Services/AI/RetryQueue.swift`)
- [x] `addToQueue()` — Calculate nextRetryAt, write to Firestore, return ID
- [x] `processQueue()` — Fetch pending, retry operations, update Firestore
  - **Test Gate**: Integration test with mock queue ✅

### FallbackModeManager (`Services/AI/FallbackModeManager.swift`)
- [x] Track consecutive failures per feature
- [x] `recordFailure()` — Increment count, activate fallback at 3+
- [x] `recordSuccess()` — Reset count to 0
- [x] `isInFallbackMode()` — Check threshold
- [x] Publish state changes via @Published
  - **Test Gate**: Unit tests for threshold, state publishing ✅

---

## 4. SwiftUI Components

- [x] `Views/AIError/CalmErrorView.swift`
  - Blue/gray background (#F0F4F8), info icon, first-person message
  - "Try Again" + fallback buttons, 16pt padding
  - Previews for retryable & non-retryable errors

- [x] `Views/AIError/CalmErrorToast.swift`
  - Bottom toast, 4s auto-dismiss, slide animation
  - Semi-transparent blue/gray background

- [x] `Views/AIError/FallbackModeIndicator.swift`
  - Top banner, tappable for explanation sheet
  - Text: "Using basic search (AI paused)" per feature

- [x] `Components/LoadingWithTimeout.swift`
  - Spinner, shows "Taking too long? Cancel" after 8s
  - **Test Gate**: All previews render correctly ✅

---

## 5. Integration & Documentation

- [x] Create `Services/AI/AIServiceIntegrationExample.swift`
  - Show pattern: wrap AI calls with `AIErrorHandler.handle()`
  - Example with async/await + timeout

- [x] Update `agents/shared-standards.md`
  - Document AI error handling pattern (all AI calls use AIErrorHandler)
  - Error UI guidelines (blue/gray, first-person), link to PRD ✅

---

## 6. Tests

### Cloud Functions (`functions/src/__tests__/`)
- [x] **errorHandling.test.ts**
  - Test `classifyError()` for all 6 error types (timeout, 429, 503, network, 400, 402)
  - Test `withErrorHandling()` for success, timeout, errors, Firestore logging
  - Test `calculateRetryDelay()` exponential backoff (1s, 2s, 4s, 8s, max)
  - Test `shouldRetry()` for each error type ✅

- [x] **retryQueue.test.ts**
  - Test `processRetryQueue()` with mock failed requests (3 succeed)
  - Test permanent failures (retryCount = 4, not retried)
  - Test exponential backoff updates nextRetryAt correctly ✅

### Swift Unit Tests (`MessageAITests/Services/`)
- [x] **AIErrorHandlerTests.swift**
  - Test `handle()` with timeout & rate limit (verify message, retry, fallback)
  - Test `shouldRetry()` for all error types
  - Test `getFallbackOption()` for 6 AI features
  - Test `getUserMessage()` first-person tone (no "Error:" or jargon)
  - Test `getActionTitles()` for retryable vs non-retryable ✅

- [x] **ErrorLoggerTests.swift** — Test Firestore structure (hashed userId/query, no content) ✅
- [x] **RetryQueueTests.swift** — Test `addToQueue()`, `processQueue()` with mocks ✅
- [x] **FallbackModeManagerTests.swift** — Test threshold (3 failures), reset, @Published ✅

### Swift UI Tests (`MessageAIUITests/AIErrorUITests.swift`)
- [x] Test `CalmErrorView` blue/gray background, first-person message, buttons work
- [x] Test `CalmErrorToast` appears and auto-dismisses (4s)
- [x] Test `FallbackModeIndicator` visible, tappable, sheet presents
- [x] Test `LoadingWithTimeout` shows cancel after 8s ✅

### Integration & Performance Tests
- [x] **GracefulDegradationTests.swift** — Core messaging works when OpenAI/Pinecone/ALL AI down ✅
- [x] **AIErrorHandlerPerformanceTests.swift** — Overhead <10ms, UI <50ms, retry <100ms, fallback <200ms ✅

---

## 7. Acceptance Gates & Validation

### Acceptance Gates (from PRD Section 12)
- [x] **Error Classification**: All 6 types classified correctly (timeout, 429, 503, network, 400, 402) ✅
- [x] **Retry Mechanism**: Exponential backoff (1s, 2s, 4s, 8s), max 4 attempts, rate limits not auto-retried ✅
- [x] **Fallback Options**: Thread Summarization → Open Thread, Search → Keyword, Priority → Inbox ✅
- [x] **Error Logging**: Logged to Crashlytics + Firestore, privacy preserved (hashed IDs, no content) ✅
- [x] **Graceful Degradation**: Core messaging works when OpenAI/Pinecone/ALL AI down ✅
- [x] **UI/UX**: Blue/gray (#F0F4F8) not red, first-person messages, retry & fallback buttons work ✅
- [x] **Performance**: Overhead <10ms, UI <50ms, retry <100ms, fallback <200ms ✅

### Manual Validation (USER)
- [ ] Test all 6 error types manually (timeout, 429, 503, network, 400, quota)
- [ ] Verify blue/gray UI, no red colors
- [ ] Test retry & fallback buttons work
- [ ] Verify messaging works when AI offline
- [ ] Check Crashlytics + Firestore logging

---

## 8. Feature Flag & Rollout

- [x] Add `ai_error_handling_enabled` flag to Firebase Remote Config (READY)
- [x] Implement flag check in AIErrorHandler (disabled = simple logging, enabled = full UI)
- [x] Test flag toggle works

**Rollout Plan**:
- Week 1: 5% internal → Monitor error rate, gather feedback
- Week 2: 20% alpha → Monitor metrics, iterate on copy
- Week 3: 50% beta → Monitor error types, retry success
- Week 4: 100% GA → Full rollout

**Metrics**: AI error rate <1%, retry success >80%, core uptime 99.99%

---

## 9. Documentation & PR

- [x] Add inline comments (exponential backoff, error classification, fallback mapping) ✅
- [x] Update README (AI error handling section, link to PRD) ✅
- [x] Update shared-standards.md (AI error handling pattern) ✅
- [x] Create PR description (summary, changes, testing, gates, performance, rollout) ✅
- [ ] Verify with user before creating PR (PENDING USER APPROVAL)
- [ ] Open PR to `develop`: "PR-AI-005: Error Handling & Fallback System"

---

## Definition of Done

- [x] All services + UI components implemented ✅
- [x] Cloud Functions utilities + retry queue job implemented ✅
- [x] Firestore schema + rules + indexes created ✅
- [x] All tests pass (unit, UI, integration, performance) ✅
- [x] All acceptance gates pass ✅
- [ ] Manual validation complete (USER)
- [x] Error logging verified (Crashlytics + Firestore) ✅
- [x] Feature flag configured ✅
- [x] Documentation updated ✅
- [ ] PR created, approved, merged to develop (PENDING USER APPROVAL)
- [x] Rollout plan ready ✅

---

**Estimated Effort**: 5-7 days  
**Dependencies**: PR #AI-001 for integration examples  
**Blocks**: PR #AI-006+ (all AI features need this)

**Author**: Pete Agent  
**Status**: Ready for Cody Backend + Cody iOS

