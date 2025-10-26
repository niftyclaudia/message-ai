# PRD: Foundation + Classification Engine

**Feature**: AI Message Classification Backend

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 1 of Focus Mode Implementation

**Links**: [Focus Mode Phases], [TODO], [Architecture]

---

## 1. Summary

Build the AI-powered message classification backend that automatically categorizes incoming messages as "urgent" or "normal" priority using OpenAI's GPT-4 API, with keyword-based fallback detection and comprehensive logging for accuracy tracking.

---

## 2. Problem & Goals

- **What user problem are we solving?** Users receive many messages throughout the day but struggle to identify which ones require immediate attention versus those that can be reviewed later.
- **Why now?** This is the foundation for the Focus Mode feature that will help users manage message overload and improve productivity.
- **Goals (ordered, measurable):**
  - [ ] G1 — Messages auto-classified as urgent/normal within 3 seconds of receipt
  - [ ] G2 — Classification accuracy >85% on test dataset
  - [ ] G3 — Zero impact on message send latency (classification happens asynchronously)

---

## 3. Non-Goals / Out of Scope

- [ ] UI components for Focus Mode (handled in PR #21)
- [ ] Real-time UI updates based on classification (handled in PR #22)
- [ ] User feedback mechanism for classification accuracy (handled in PR #22)
- [ ] Message summarization (handled in PR #23)
- [ ] Semantic search capabilities (handled in PR #24)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Messages classified within 3s, no user-facing delays
- **System**: Classification accuracy >85%, OpenAI API cost <$5/day, zero impact on message send latency
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%

---

## 5. Users & Stories

- As a **busy professional**, I want my messages automatically prioritized so that I can focus on urgent communications first.
- As a **team member**, I want my messages classified consistently so that important updates don't get lost in the noise.
- As a **product manager**, I want classification data logged so that I can measure and improve the system's accuracy over time.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: Classification triggered automatically when new messages are written to Firestore
- **Visual behavior**: No UI changes in this phase - classification happens transparently in background
- **Loading/disabled/error states**: Classification failures logged but don't block message delivery
- **Performance**: See targets in `MessageAI/agents/shared-standards.md` - classification must complete within 3s

---

## 7. Functional Requirements (Must/Should)

- **MUST**: OpenAI integration service for message classification
- **MUST**: Firestore trigger that automatically classifies new messages
- **MUST**: Keyword-based urgency detection as fallback when OpenAI fails
- **MUST**: Message model updated with priority field (urgent/normal)
- **MUST**: Classification logging and analytics for accuracy tracking
- **SHOULD**: Rate limiting to control OpenAI API costs
- **SHOULD**: Retry logic for failed classification attempts

**Acceptance gates per requirement:**
- [Gate] When message written to Firestore → classification completes within 3s
- [Gate] OpenAI API failure → keyword fallback activates within 1s
- [Gate] Classification accuracy >85% on test dataset of 100 messages
- [Gate] Message send latency unchanged (classification is async)

---

## 8. Data Model

Describe new/changed Firestore collections, schemas, invariants.

Reference examples in `MessageAI/agents/shared-standards.md` for common patterns.

```swift
// Updated Message Document
{
  id: String,
  text: String,
  senderID: String,
  timestamp: Timestamp,
  readBy: [String],
  priority: String,  // NEW: "urgent" | "normal"
  classificationConfidence: Double?,  // NEW: 0.0-1.0 confidence score
  classificationMethod: String?,  // NEW: "openai" | "keyword" | "fallback"
  classificationTimestamp: Timestamp?  // NEW: when classification completed
}

// NEW: Classification Logs Collection
{
  messageID: String,
  originalText: String,
  classificationResult: String,
  confidence: Double,
  method: String,
  processingTimeMs: Int,
  timestamp: Timestamp,
  errorMessage: String?  // if classification failed
}
```

- **Validation rules**: Priority must be "urgent" or "normal", confidence must be 0.0-1.0
- **Indexing/queries**: Index on priority field for efficient filtering, index on classificationTimestamp for analytics

---

## 9. API / Service Contracts

Specify concrete service layer methods. Reference examples in `MessageAI/agents/shared-standards.md`.

```swift
// OpenAI Classification Service
func classifyMessage(text: String) async throws -> ClassificationResult
func classifyMessageWithKeywords(text: String) async -> ClassificationResult

// Classification Result Model
struct ClassificationResult {
    let priority: String  // "urgent" | "normal"
    let confidence: Double  // 0.0-1.0
    let method: String  // "openai" | "keyword" | "fallback"
    let processingTimeMs: Int
}

// Firestore Trigger Service
func onMessageCreated(messageID: String, messageData: [String: Any]) async throws
func updateMessagePriority(messageID: String, priority: String, confidence: Double, method: String) async throws
func logClassification(messageID: String, result: ClassificationResult, error: Error?) async throws
```

- **Pre/post-conditions**: Classification must complete within 3s, message priority field must be updated
- **Error handling strategy**: OpenAI failures fall back to keyword detection, all errors logged
- **Parameters and types**: String message text input, ClassificationResult output
- **Return values**: ClassificationResult with priority, confidence, method, and timing

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

**Backend (Cloud Functions):**
- `functions/src/services/openaiClient.ts` — OpenAI API integration and message classification
- `functions/src/services/aiPrioritization.ts` — Classification logic and keyword fallback
- `functions/src/triggers/classifyMessage.ts` — Firestore trigger for auto-classification
- `functions/src/utils/classificationLogger.ts` — Analytics and logging utilities

**iOS (Data Models):**
- `MessageAI/Models/Message.swift` — Add priority, confidence, method, classificationTimestamp fields
- `MessageAI/Models/ClassificationResult.swift` — New model for classification results

**Testing:**
- `MessageAITests/Services/FocusModeClassificationTests.swift` — Unit tests for classification logic

---

## 11. Integration Points

- **Firebase Authentication**: Not directly used in this phase
- **Firestore**: Message documents updated with priority field, classification logs stored
- **Firebase Realtime Database**: Not used in this phase
- **FCM (push notifications)**: Not used in this phase
- **State management**: No UI state changes in this phase
- **OpenAI API**: Primary classification service integration

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

**Happy Path**
- [ ] New message triggers classification automatically
- [ ] Gate: Classification completes within 3s
- [ ] Gate: Message priority field updated correctly
- [ ] Gate: Classification logged for analytics

**Edge Cases**
- [ ] OpenAI API timeout handled gracefully
- [ ] Gate: Keyword fallback activates within 1s
- [ ] Gate: Message delivery not blocked by classification failure
- [ ] Empty message text handled correctly
- [ ] Gate: Empty messages default to "normal" priority

**Multi-User**
- [ ] Multiple simultaneous messages classified correctly
- [ ] Gate: No race conditions in classification processing
- [ ] Gate: Each message gets unique classification result

**Performance (see shared-standards.md)**
- [ ] Classification latency <3s for 95% of messages
- [ ] Gate: OpenAI API calls don't exceed rate limits
- [ ] Gate: Firestore writes complete within 100ms
- [ ] Gate: No impact on message send latency

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] OpenAI service implemented + unit tests (Swift Testing)
- [ ] Firestore trigger deployed and tested
- [ ] Message model updated with priority fields
- [ ] Classification logging system implemented
- [ ] Keyword fallback system implemented
- [ ] All acceptance gates pass
- [ ] Classification accuracy >85% on test dataset
- [ ] Documentation updated

---

## 14. Risks & Mitigations

- **Risk**: OpenAI API costs exceed budget → Mitigation: Rate limiting, keyword pre-filtering, cost monitoring
- **Risk**: Classification accuracy below 85% → Mitigation: Prompt engineering, keyword fallback, continuous tuning
- **Risk**: Classification latency >3s → Mitigation: Async processing, timeout fallbacks, performance monitoring
- **Risk**: OpenAI API downtime → Mitigation: Robust keyword fallback system, error handling
- **Risk**: Firestore trigger failures → Mitigation: Retry logic, error logging, manual classification option

---

## 15. Rollout & Telemetry

- **Feature flag?** No - backend-only feature with no user-facing changes
- **Metrics**: Classification accuracy, processing time, API costs, error rates
- **Manual validation steps**: Test with sample message dataset, verify classification accuracy

---

## 16. Open Questions

- Q1: Should we implement custom urgency keywords per user, or use global keywords?
- Q2: What confidence threshold should trigger manual review of classifications?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] User-customizable urgency keywords (PR #22)
- [ ] Classification feedback mechanism (PR #22)
- [ ] Multi-language classification support
- [ ] Advanced ML models beyond GPT-4

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** Messages automatically classified as urgent/normal in background
2. **Primary user and critical action?** System automatically processes incoming messages
3. **Must-have vs nice-to-have?** Must: OpenAI integration, keyword fallback, logging. Nice: advanced ML models
4. **Real-time requirements?** Classification must complete within 3s of message receipt
5. **Performance constraints?** No impact on message send latency, <3s classification time
6. **Error/edge cases to handle?** OpenAI failures, empty messages, rate limiting, timeouts
7. **Data model changes?** Add priority, confidence, method, classificationTimestamp to Message model
8. **Service APIs required?** OpenAI classification API, Firestore triggers, logging service
9. **UI entry points and states?** No UI changes in this phase
10. **Security/permissions implications?** OpenAI API key security, Firestore security rules
11. **Dependencies or blocking integrations?** OpenAI API access, Firebase project setup
12. **Rollout strategy and metrics?** Backend deployment, accuracy monitoring, cost tracking
13. **What is explicitly out of scope?** UI components, user feedback, real-time UI updates

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
- Focus on backend implementation without UI dependencies
