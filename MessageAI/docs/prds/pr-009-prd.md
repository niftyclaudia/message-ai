# PRD: Priority Message Detection

**Feature**: Priority Message Detection

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Sprint 3

**Links**: [PR Brief], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

Automatically detect and categorize incoming messages as urgent, can-wait, or AI-handled using AI-powered analysis, enabling users to focus on high-priority communications while reducing cognitive load from message triage.

---

## 2. Problem & Goals

- **User Problem**: Users are overwhelmed by message volume and struggle to identify which messages require immediate attention vs. can wait, leading to missed urgent communications and inefficient time management.

- **Why Now**: With the AI infrastructure in place (PR #AI-001 RAG Pipeline), we can now implement intelligent message categorization to improve user productivity and reduce notification fatigue.

- **Goals (ordered, measurable)**:
  - [ ] G1 — Automatically categorize 90%+ of messages with 85%+ accuracy
  - [ ] G2 — Reduce time to identify urgent messages from 30+ seconds to <2 seconds
  - [ ] G3 — Decrease notification interruptions by 40% through smart filtering

---

## 3. Non-Goals / Out of Scope

- [ ] Not implementing user-defined priority rules (future PR)
- [ ] Not creating separate priority inbox UI (future PR)
- [ ] Not implementing priority-based notification sounds (future PR)
- [ ] Not auto-responding to AI-handled messages (future PR)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:

- **User-visible**: Message categorization time <2s, 40% reduction in notification interruptions
- **System**: p95 message latency <200ms, app load <2s, 60fps with 1000+ messages
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%, 85%+ categorization accuracy

---

## 5. Users & Stories

- As a **busy professional**, I want messages automatically categorized so that I can focus on urgent items first.
- As a **team lead**, I want urgent messages from my team highlighted so that I don't miss critical updates.
- As a **remote worker**, I want non-urgent messages filtered so that I can maintain focus during deep work.
- As a **mobile user**, I want priority indicators on messages so that I can quickly scan my inbox.

---

## 6. Experience Specification (UX)

- **Entry points and flows**: Automatic categorization on message receipt, visible in chat list and conversation view
- **Visual behavior**: Priority badges (🔴 Urgent, 🟡 Can Wait, 🤖 AI Handled), subtle background colors, priority indicators in message bubbles
- **Loading/disabled/error states**: Loading spinner during AI processing, fallback to neutral categorization on AI failure
- **Performance**: See targets in `MessageAI/agents/shared-standards.md`

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Automatically categorize every incoming message as urgent/can_wait/ai_handled
- **MUST**: Real-time delivery per MessageAI/agents/shared-standards.md (<200ms p95)
- **MUST**: Offline persistence and queue (3-message queue, force-quit recovery)
- **MUST**: Graceful degradation when AI service unavailable (fallback to neutral categorization)
- **SHOULD**: Optimistic UI with immediate visual feedback
- **SHOULD**: User preference to disable AI categorization

**Acceptance gates per requirement:**
- [Gate] When message received → categorization appears in <200ms
- [Gate] Offline: messages queue and categorize on reconnect
- [Gate] Error case: AI failure shows neutral categorization; no partial writes
- [Gate] User disables AI → all messages show neutral priority

---

## 8. Data Model

Describe new/changed Firestore collections, schemas, invariants.

Reference examples in `MessageAI/agents/shared-standards.md` for common patterns.

```swift
// Enhanced Message model with priority categorization
struct Message: Codable, Identifiable {
    let id: String
    let text: String
    let senderID: String
    let timestamp: Date
    let readBy: [String]
    let type: MessageType
    
    // NEW: AI categorization fields
    let categoryPrediction: CategoryPrediction?
    let embeddingGenerated: Bool
    let searchableMetadata: SearchableMetadata?
}

struct CategoryPrediction: Codable {
    let category: MessageCategory
    let confidence: Double
    let reasoning: String
    let timestamp: Date
}

enum MessageCategory: String, Codable, CaseIterable {
    case urgent = "urgent"
    case canWait = "can_wait"
    case aiHandled = "ai_handled"
}

struct SearchableMetadata: Codable {
    let keywords: [String]
    let participants: [String]
    let decisionMade: Bool
    let urgencyIndicators: [String]
}
```

- **Validation rules**: Firebase security rules allow participants to read categorization data
- **Indexing/queries**: Firestore listeners for real-time updates, composite indexes for category-based queries

---

## 9. API / Service Contracts

Specify concrete service layer methods. Reference examples in `MessageAI/agents/shared-standards.md`.

```swift
// Priority Detection Service
protocol PriorityDetectionService {
    func categorizeMessage(_ message: Message) async throws -> CategoryPrediction
    func getCategorizedMessages(chatID: String, category: MessageCategory?) async throws -> [Message]
    func updateUserPreferences(_ preferences: PriorityPreferences) async throws
    func isAICategorizationEnabled() async throws -> Bool
}

// Cloud Function integration
func categorizeMessage(messageID: String, text: String, context: MessageContext) async throws -> CategoryPrediction
```

- **Pre/post-conditions**: Message must exist, user must be authenticated, AI service must be available
- **Error handling strategy**: Graceful degradation to neutral categorization on AI failure
- **Parameters and types**: Message content, sender context, conversation history
- **Return values**: CategoryPrediction with confidence score and reasoning

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Views/Conversation/MessageRow.swift` — Display priority badges and visual indicators
- `Views/ChatList/ChatRow.swift` — Show priority indicators in chat list
- `Views/AI/PriorityInboxView.swift` — Filtered view of messages by priority
- `Components/PriorityBadge.swift` — Reusable priority indicator component
- `Services/AI/PriorityDetectionService.swift` — Business logic for categorization
- `ViewModels/AI/PriorityInboxViewModel.swift` — State management for priority filtering

---

## 11. Integration Points

- **Firebase Authentication** — User context for personalization
- **Firestore** — Real-time message updates and categorization storage
- **Cloud Functions** — AI-powered categorization processing
- **FCM** — Priority-based notification routing
- **State management** — SwiftUI @StateObject patterns for real-time updates

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] Message received → automatically categorized within 200ms
  - [ ] Gate: Categorization appears in UI with correct priority badge
  - [ ] Gate: User can filter messages by priority category
  
- **Edge Cases**
  - [ ] Empty message handled gracefully
  - [ ] AI service unavailable → fallback to neutral categorization
  - [ ] Offline behavior → messages queue and categorize on reconnect
  
- **Multi-User**
  - [ ] Real-time sync <200ms across devices
  - [ ] Concurrent messages categorized correctly
  - [ ] Gate: 3+ users see consistent categorization
  
- **Performance (see shared-standards.md)**
  - [ ] App load <2s with categorization enabled
  - [ ] Smooth 60fps scrolling with 1000+ categorized messages
  - [ ] Message latency <200ms p95

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] Service methods implemented + unit tests (Swift Testing)
- [ ] SwiftUI views with all states (loading, error, success)
- [ ] Real-time sync verified across 2+ devices
- [ ] Offline persistence tested (3-message queue, force-quit recovery)
- [ ] All acceptance gates pass
- [ ] AI error handling with graceful degradation
- [ ] Performance targets met (p95 <200ms, 60fps scrolling)
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: AI categorization accuracy below 85% → **Mitigation**: Implement confidence thresholds and user feedback loop
- **Risk**: Performance impact on message delivery → **Mitigation**: Async processing, optimistic UI, background categorization
- **Risk**: AI service downtime blocks messaging → **Mitigation**: Graceful degradation, fallback to neutral categorization
- **Risk**: User privacy concerns with AI analysis → **Mitigation**: Transparent AI indicators, opt-out option, local processing where possible

---

## 15. Rollout & Telemetry

- **Feature flag**: Yes (gradual rollout 5% → 20% → 50% → 100%)
- **Metrics**: Categorization accuracy, user engagement with priority features, AI service performance
- **Manual validation steps**: Test categorization accuracy with sample messages, verify offline behavior, measure performance impact

---

## 16. Open Questions

- Q1: Should categorization be personalized per user or global?
- Q2: How to handle group messages with mixed urgency levels?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] User-defined priority rules and keywords
- [ ] Separate priority inbox UI
- [ ] Priority-based notification sounds
- [ ] Auto-response to AI-handled messages
- [ ] Priority-based message scheduling

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User sees incoming message automatically categorized with priority badge
2. **Primary user and critical action?** Busy professional receiving urgent message with clear priority indicator
3. **Must-have vs nice-to-have?** Must-have: automatic categorization, nice-to-have: user preferences
4. **Real-time requirements?** Yes, categorization must appear within 200ms of message receipt
5. **Performance constraints?** p95 <200ms, 60fps scrolling with 1000+ messages
6. **Error/edge cases to handle?** AI service unavailable, offline scenarios, empty messages
7. **Data model changes?** Add CategoryPrediction to Message model, new Firestore fields
8. **Service APIs required?** PriorityDetectionService with categorization methods
9. **UI entry points and states?** Message bubbles, chat list, priority filtering view
10. **Security/permissions implications?** Users can only see categorization for their messages
11. **Dependencies or blocking integrations?** Requires AI infrastructure (PR #AI-001)
12. **Rollout strategy and metrics?** Gradual rollout with accuracy and performance monitoring
13. **What is explicitly out of scope?** User-defined rules, separate inbox UI, auto-responses

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
- Implement graceful AI error handling per PR #AI-005 standards
