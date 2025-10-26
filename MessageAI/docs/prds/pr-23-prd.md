# PRD: Session Summarization

**Feature**: Focus Mode Session Summarization

**Version**: 1.0

**Status**: Ready for Development

**Agent**: Pete

**Target Release**: Phase 4 of Focus Mode Implementation

**Links**: [Focus Mode Phases], [TODO], [Designs], [Tracking Issue]

---

## 1. Summary

AI-generated summaries when Focus Mode ends, providing users with overview, action items, and decisions from their focused messaging session.

---

## 2. Problem & Goals

- **User Problem**: After a Focus Mode session, users need to quickly understand what happened, what decisions were made, and what actions are required without scrolling through all messages.
- **Why Now**: Phase 4 builds on the classification engine (Phase 1) and Focus Mode UI (Phase 2-3) to provide intelligent session closure.
- **Goals**:
  - [ ] G1 — Generate comprehensive session summaries in <10s for 80% of sessions
  - [ ] G2 — Extract actionable items and decisions with >85% accuracy
  - [ ] G3 — Provide smooth modal presentation with export/share functionality

---

## 3. Non-Goals / Out of Scope

- [ ] Not doing real-time summarization during Focus Mode (only at session end)
- [ ] Not doing multi-language summarization (English only for v1)
- [ ] Not doing voice-to-text integration for summaries
- [ ] Not doing automatic calendar integration for action items

---

## 4. Success Metrics

Reference `MessageAI/agents/shared-standards.md` for metric templates:
- **User-visible**: Summary generation <10s, 60% of users view summaries, 10% use export
- **System**: Summary generation latency <10s, OpenAI API cost <$2/session, modal presentation <500ms
- **Quality**: 0 blocking bugs, all gates pass, crash-free >99%, summary relevance >4.5/5 user rating

---

## 5. Users & Stories

- As a **busy professional**, I want to get a summary of my Focus Mode session so that I can quickly understand what happened and what I need to do next.
- As a **team lead**, I want to see action items extracted from our focused discussions so that I can track follow-ups and decisions.
- As a **project manager**, I want to export session summaries so that I can share key decisions with stakeholders who weren't in the session.

---

## 6. Experience Specification (UX)

- **Entry points**: Focus Mode deactivation triggers summary generation
- **Visual behavior**: Modal slides up from bottom with summary content, loading spinner during generation, export/share buttons
- **Loading/disabled/error states**: Loading spinner with "Generating summary..." text, error state with retry button, empty state if no messages
- **Performance**: Modal appears <500ms after deactivation, summary generates <10s, smooth animations at 60fps

---

## 7. Functional Requirements (Must/Should)

- **MUST**: Generate summary on Focus Mode deactivation
- **MUST**: Include overview, action items, and key decisions
- **MUST**: Cache summaries in Firestore for re-viewing
- **MUST**: Handle empty sessions gracefully (no messages during Focus Mode)
- **SHOULD**: Provide export/share functionality
- **SHOULD**: Show classification confidence in summary metadata

**Acceptance gates per requirement:**
- [Gate] When user deactivates Focus Mode → Summary generates in <10s
- [Gate] Summary includes overview + action items + decisions sections
- [Gate] Summary cached in Firestore with session ID
- [Gate] Empty session shows "No messages during this Focus Mode session"
- [Gate] Export button generates shareable text/PDF
- [Gate] Error case: API failure shows retry button, no crash

---

## 8. Data Model

New Firestore collections and schemas for session summaries.

```swift
// FocusSession Document
{
  id: String,
  userID: String,
  startTime: Timestamp,
  endTime: Timestamp,
  messageCount: Int,
  urgentMessageCount: Int,
  status: String // "active", "completed", "summarized"
}

// FocusSummary Document  
{
  id: String,
  sessionID: String,
  userID: String,
  generatedAt: Timestamp,
  overview: String,
  actionItems: [String],
  keyDecisions: [String],
  messageCount: Int,
  confidence: Float, // 0.0-1.0
  exportData: String? // Cached export format
}
```

- **Validation rules**: Users can only read/write their own summaries, summaries require valid session ID
- **Indexing/queries**: Index on userID + generatedAt for chronological summaries

---

## 9. API / Service Contracts

Specify concrete service layer methods for summary generation and management.

```swift
// Summary generation
func generateSessionSummary(sessionID: String) async throws -> FocusSummary
func getSessionSummary(sessionID: String) async throws -> FocusSummary?
func getRecentSummaries(limit: Int = 10) async throws -> [FocusSummary]

// Session management
func createFocusSession() async throws -> String
func endFocusSession(sessionID: String) async throws
func getActiveSession() async throws -> FocusSession?

// Export functionality
func exportSummary(summary: FocusSummary, format: ExportFormat) async throws -> Data
```

- **Pre/post-conditions**: Session must be ended before summary generation, valid session ID required
- **Error handling**: API failures, empty sessions, network timeouts
- **Parameters and types**: Session IDs as strings, export formats as enum
- **Return values**: FocusSummary objects, Data for exports

---

## 10. UI Components to Create/Modify

List SwiftUI views/files with one-line purpose each.

- `Views/FocusSummaryView.swift` — Modal presentation of generated summary
- `Views/FocusSummaryRow.swift` — Individual summary item in history list
- `Services/SummaryService.swift` — Summary generation and caching logic
- `Services/FocusSessionService.swift` — Session lifecycle management
- `Models/FocusSummary.swift` — Summary data model
- `Models/FocusSession.swift` — Session data model
- `ViewModels/FocusSummaryViewModel.swift` — Summary modal state management

---

## 11. Integration Points

- **Firebase Authentication** — User session validation
- **Firestore** — Summary storage and retrieval
- **OpenAI API** — GPT-4 summarization via Cloud Functions
- **FocusModeService** — Session start/end triggers
- **State management** — SwiftUI @StateObject for modal presentation

---

## 12. Test Plan & Acceptance Gates

Define BEFORE implementation. Use checkboxes.

Reference testing standards from `MessageAI/agents/shared-standards.md`.

- **Happy Path**
  - [ ] User deactivates Focus Mode → Summary generates and displays
  - [ ] Gate: Summary appears in <10s with overview, actions, decisions
  
- **Edge Cases**
  - [ ] Empty session handled gracefully
  - [ ] API failure shows retry option
  - [ ] Network timeout handled
  
- **Multi-User**
  - [ ] Summary generation doesn't block other users
  - [ ] Concurrent session endings handled
  
- **Performance** (see shared-standards.md)
  - [ ] Modal presentation <500ms
  - [ ] Summary generation <10s
  - [ ] Smooth 60fps animations

---

## 13. Definition of Done

See standards in `MessageAI/agents/shared-standards.md`:
- [ ] SummaryService implemented + unit tests (Swift Testing)
- [ ] FocusSummaryView modal with all states
- [ ] Real-time summary generation verified
- [ ] Export functionality tested
- [ ] All acceptance gates pass
- [ ] Docs updated

---

## 14. Risks & Mitigations

- **Risk**: OpenAI API costs → Mitigation: Token limits, caching, batch processing
- **Risk**: Summary generation failures → Mitigation: Retry logic, graceful degradation
- **Risk**: Poor summary quality → Mitigation: Prompt engineering, user feedback loop
- **Risk**: Modal presentation jank → Mitigation: Use SwiftUI animations, profile with Instruments

---

## 15. Rollout & Telemetry

- **Feature flag**: Yes - gradual rollout for summary generation
- **Metrics**: Summary generation time, user viewing rate, export usage, API costs
- **Manual validation steps**: Test with various message types, verify export formats

---

## 16. Open Questions

- Q1: Should summaries include message timestamps or just content?
- Q2: What export formats are most valuable (text, PDF, markdown)?

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future:
- [ ] Real-time summarization during Focus Mode
- [ ] Multi-language support
- [ ] Voice-to-text integration
- [ ] Calendar integration for action items
- [ ] Summary templates/customization

---

## Preflight Questionnaire

Answer these to drive vertical slice and acceptance gates:

1. **Smallest end-to-end user outcome for this PR?** User deactivates Focus Mode and sees a comprehensive summary of their session
2. **Primary user and critical action?** Busy professional ending Focus Mode session to get summary
3. **Must-have vs nice-to-have?** Must: Summary generation, Modal display. Nice: Export, caching
4. **Real-time requirements?** Summary generation should complete within 10s of session end
5. **Performance constraints?** Modal presentation <500ms, summary generation <10s, 60fps animations
6. **Error/edge cases to handle?** Empty sessions, API failures, network timeouts, invalid sessions
7. **Data model changes?** New FocusSession and FocusSummary collections in Firestore
8. **Service APIs required?** SummaryService, FocusSessionService, OpenAI integration via Cloud Functions
9. **UI entry points and states?** Modal triggered by Focus Mode deactivation, loading/error/success states
10. **Security/permissions implications?** Users can only access their own summaries, session validation
11. **Dependencies or blocking integrations?** Requires Phase 1-3 complete, OpenAI API access
12. **Rollout strategy and metrics?** Feature flag for gradual rollout, track generation time and usage
13. **What is explicitly out of scope?** Real-time summarization, multi-language, voice integration

---

## Authoring Notes

- Write Test Plan before coding
- Favor vertical slice that ships standalone
- Keep service layer deterministic
- SwiftUI views are thin wrappers
- Test offline/online thoroughly
- Reference `MessageAI/agents/shared-standards.md` throughout
