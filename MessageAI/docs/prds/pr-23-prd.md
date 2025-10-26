# PRD: Focus Mode Summarization

**Feature**: Focus Mode Summarization

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 4 of Focus Mode Implementation

**Links**: [Focus Mode Phases], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

AI-generated summaries when Focus Mode ends, providing users with overview, action items, and decisions from ALL unread priority messages (both before and during Focus Mode), not just session-based messages.

---

## 2. Problem & Goals

- **User Problem**: After a Focus Mode session, users need to quickly understand what happened, what decisions were made, and what actions are required from ALL their unread priority messages, not just messages that arrived during the session.
- **Why Now**: Phase 4 builds on the classification engine (Phase 1) and Focus Mode UI (Phase 2-3) to provide intelligent summary of all unread priority content.
- **Goals**:
  - [x] G1 — Generate comprehensive summaries of ALL unread priority messages in <10s
  - [x] G2 — Extract actionable items and decisions with >85% accuracy from complete unread priority context
  - [x] G3 — Provide smooth modal presentation with export/share functionality

---

## 3. Non-Goals / Out of Scope

- [ ] Not doing real-time summarization during Focus Mode (only at session end)
- [ ] Not doing multi-language summarization (English only for v1)
- [ ] Not doing voice-to-text integration for summaries
- [ ] Not doing automatic calendar integration for action items
- [ ] Not doing session-based message filtering (summaries include ALL unread priority messages)

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Summary generation <10s, 60% of users view summaries, 10% use export
- **System**: Summary generation latency <10s, OpenAI API cost <$2/summary, modal presentation <500ms
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%, summary relevance >4.5/5 user rating

---

## 5. Users & Stories

- As a **busy professional**, I want to get a summary of ALL my unread priority messages when Focus Mode ends so that I can quickly understand what happened and what I need to do next.
- As a **team lead**, I want to see action items extracted from all unread priority discussions so that I can track follow-ups and decisions.
- As a **project manager**, I want to export summaries of all unread priority content so that I can share key decisions with stakeholders.

---

## 6. Experience Specification (UX)

- **Entry points**: Focus Mode deactivation triggers summary generation of ALL unread priority messages
- **Visual behavior**: Modal slides up from bottom with summary content, loading spinner during generation, export/share buttons
- **Loading/disabled/error states**: Loading spinner with "Generating summary..." text, error state with retry button, empty state if no unread priority messages
- **Performance**: Modal appears <500ms after deactivation, summary generates <10s, smooth animations at 60fps

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Generate summary on Focus Mode deactivation ✅
- **MUST**: Include ALL unread priority messages (before + during Focus Mode) ✅
- **MUST**: Include overview, action items, and key decisions ✅
- **MUST**: Cache summaries in Firestore for re-viewing ✅
- **MUST**: Handle empty state gracefully (no unread priority messages) ✅
- **SHOULD**: Provide export/share functionality ✅
- **SHOULD**: Show classification confidence in summary metadata ✅

**Acceptance gates per requirement:**
- [x] [Gate] When user deactivates Focus Mode → Summary generates in <10s
- [x] [Gate] Summary includes ALL unread priority messages from all time periods
- [x] [Gate] Summary includes overview + action items + decisions sections
- [x] [Gate] Summary cached in Firestore with unique ID
- [x] [Gate] Empty state shows "No unread priority messages to summarize"
- [x] [Gate] Export button generates shareable text/PDF
- [x] [Gate] Error case: API failure shows retry button, no crash

---

## 8. Data Model

New Firestore collections and schemas for focus summaries.

```swift
// FocusSummary Document  
{
  id: String,
  userID: String,
  generatedAt: Timestamp,
  overview: String,
  actionItems: [String],
  keyDecisions: [String],
  messageCount: Int,
  urgentMessageCount: Int,
  confidence: Float, // 0.0-1.0
  exportData: String?, // Cached export format
  focusModeSessionID: String? // Optional: ID of the Focus Mode session that triggered this summary
}

// FocusSession Document (simplified - only for tracking Focus Mode sessions)
{
  id: String,
  userID: String,
  startTime: Timestamp,
  endTime: Timestamp,
  status: String // "active", "completed"
}
```

- **Validation rules**: Users can only read/write their own summaries
- **Indexing/queries**: Index on userID + generatedAt for chronological summaries

---

## 9. API / Service Contracts

Specify concrete service layer methods for summary generation and management.

```swift
// Summary generation
func generateFocusSummary() async throws -> FocusSummary
func getSummary(summaryID: String) async throws -> FocusSummary?
func getRecentSummaries(limit: Int = 10) async throws -> [FocusSummary]

// Focus Mode session management (simplified)
func createFocusSession() async throws -> String
func endFocusSession(sessionID: String) async throws
func getActiveSession() async throws -> FocusSession?

// Export functionality
func exportSummary(summary: FocusSummary, format: ExportFormat) async throws -> Data
```

- **Pre/post-conditions**: Focus Mode must be deactivated before summary generation
- **Error handling**: API failures, no unread priority messages, network timeouts
- **Parameters and types**: Summary IDs as strings, export formats as enum
- **Return values**: FocusSummary objects, Data for exports

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Views/FocusSummaryView.swift` — Modal presentation of generated summary ✅
- `Views/FocusSummaryRow.swift` — Individual summary item in history list ✅
- `Services/SummaryService.swift` — Summary generation and caching logic ✅
- `Services/FocusSessionService.swift` — Focus Mode session lifecycle management ✅
- `Models/FocusSummary.swift` — Summary data model ✅
- `Models/FocusSession.swift` — Focus Mode session data model ✅
- `ViewModels/FocusSummaryViewModel.swift` — Summary modal state management ✅

---

## 11. Integration Points

- **Firebase Authentication** — User session validation
- **Firestore** — Summary storage and retrieval
- **OpenAI API** — GPT-4 summarization via Cloud Functions
- **FocusModeService** — Focus Mode start/end triggers
- **MessageService** — Fetching all unread priority messages
- **AIClassificationService** — Determining message priority
- **State management** — SwiftUI @StateObject for modal presentation

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [x] User deactivates Focus Mode → Summary generates and displays
  - [x] Gate: Summary appears in <10s with overview, actions, decisions
  - [x] Gate: Summary includes ALL unread priority messages from all time periods
  
- **Edge Cases**
  - [x] No unread priority messages handled gracefully
  - [x] API failure shows retry option
  - [x] Network timeout handled
  
- **Multi-User**
  - [x] Summary generation doesn't block other users
  - [x] Concurrent Focus Mode deactivations handled
  
- **Performance** (see shared-standards.md)
  - [x] Modal presentation <500ms
  - [x] Summary generation <10s
  - [x] Smooth 60fps animations

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [x] SummaryService implemented + unit tests (Swift Testing)
- [x] FocusSummaryView modal with all states
- [x] Summary generation includes ALL unread priority messages verified
- [x] Export functionality tested
- [x] All acceptance gates pass
- [x] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: OpenAI API costs → Mitigation: Token limits, caching, batch processing
- **Risk**: Summary generation failures → Mitigation: Retry logic, graceful degradation
- **Risk**: Poor summary quality → Mitigation: Prompt engineering, user feedback loop
- **Risk**: Modal presentation jank → Mitigation: Use SwiftUI animations, profile with Instruments
- **Risk**: Large number of unread priority messages → Mitigation: Message truncation, pagination, smart filtering

---

## 15. Rollout & Telemetry

- **Feature flag**: Yes - gradual rollout for summary generation
- **Metrics**: Summary generation time, user viewing rate, export usage, API costs, unread priority message count
- **Manual validation steps**: Test with various message types, verify export formats, test with large numbers of unread priority messages

---

## 16. Open Questions

- Q1: Should summaries include message timestamps or just content?
- Q2: What export formats are most valuable (text, PDF, markdown)?
- Q3: How many unread priority messages should be included before truncation?
- Q4: Should summaries prioritize recent unread messages over older ones?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Real-time summarization during Focus Mode
- [ ] Multi-language support
- [ ] Voice-to-text integration
- [ ] Calendar integration for action items
- [ ] Summary templates/customization
- [ ] Session-based message filtering (summaries will include ALL unread priority messages)

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User deactivates Focus Mode and sees a comprehensive summary of ALL their unread priority messages
2. **Primary user and critical action?** Busy professional ending Focus Mode to get summary of all unread priority content
3. **Must-have vs nice-to-have?** Must: Summary generation of all unread priority messages, Modal display. Nice: Export, caching
4. **Real-time requirements?** Summary generation should complete within 10s of Focus Mode deactivation
5. **Performance constraints?** Modal presentation <500ms, summary generation <10s, 60fps animations
6. **Error/edge cases to handle?** No unread priority messages, API failures, network timeouts, large message volumes
7. **Data model changes?** New FocusSummary collection in Firestore, simplified FocusSession model
8. **Service APIs required?** SummaryService, FocusSessionService, MessageService, AIClassificationService, OpenAI integration via Cloud Functions
9. **UI entry points and states?** Modal triggered by Focus Mode deactivation, loading/error/success states
10. **Security/permissions implications?** Users can only access their own summaries
11. **Dependencies or blocking integrations?** Requires Phase 1-3 complete (✅ PR #20-22 complete), OpenAI API access
12. **Rollout strategy and metrics?** Feature flag for gradual rollout, track generation time and usage
13. **What is explicitly out of scope?** Real-time summarization, multi-language, voice integration, session-based filtering

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
