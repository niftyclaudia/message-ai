# PRD: Focus Mode UI Foundation

**Feature**: Focus Mode Toggle & Two-Section List View

**Version**: 1.0

**Status**: ✅ Complete - Ready for Review

**Agent**: Cody

**Target Release**: January 2025

**Commit**: 4b6aa7c

**Links**: [PR Brief: focus-mode-pr-briefs.md], [TODO: pr-21-todo.md], [Designs: User Mockups], [Tracking Issue: PR #21]

---

## 1. Summary

Build the Focus Mode UI foundation with an inline toggle switch and two-section conversation list (Priority / HOLDING). Users can activate Focus Mode to filter messages into priority and non-priority sections, with a clean placeholder state for held messages.

---

## 2. Problem & Goals

- **Problem**: Users need a way to focus on urgent messages while keeping non-urgent ones accessible but not distracting
- **Why now**: PR #20 classification engine is complete, providing the priority data needed for filtering
- **Goals**:
  - [x] G1 — Users can toggle Focus Mode on/off with a single tap
  - [x] G2 — Messages automatically filter into Priority vs HOLDING sections when Focus Mode is active
  - [x] G3 — Focus Mode state persists across app restarts
  - [x] G4 — Smooth animations and responsive UI (60fps)

---

## 3. Non-Goals / Out of Scope

- [x] AI integration (handled in PR #22) ✅ Complete
- [x] Real-time classification updates (handled in PR #22) ✅ Complete
- [ ] Summary generation (handled in PR #23)
- [ ] Search functionality (handled in PR #24)
- [ ] Custom urgency keywords or user training
- [ ] Multi-device sync of Focus Mode state

---

## 4. Success Metrics

- **User-visible**: Toggle responds in <300ms, smooth section transitions
- **System**: UI animations at 60fps, no crashes during 100 toggle cycles
- **Quality**: 0 blocking bugs, state persists across app kills, all acceptance gates pass

---

## 5. Users & Stories

- As a busy professional, I want to toggle Focus Mode on/off so that I can quickly switch between focused and normal message viewing
- As a user, I want to see my urgent messages in a Priority section so that I can focus on what matters most
- As a user, I want to see that non-urgent messages are being held so that I know they're not lost, just waiting

---

## 6. Experience Specification (UX)

### Entry Points and Flows
- **Primary**: Inline toggle switch in ConversationListView header
- **Layout**: `[Profile Icon] [Search Icon]` + `[Flow Mode ●] [Toggle Switch]`

### Visual Behavior
- **Focus Mode OFF**: Single conversation list showing all messages
- **Focus Mode ON**: Two-section list:
  - **PRIORITY (X)**: Messages with `priority: "urgent"`
  - **HOLDING (X)**: Placeholder card with "Messages are waiting quietly for you"
- **Toggle States**: 
  - Active: Teal background with white handle on right
  - Inactive: Dark gray background with handle on left
- **Flow Mode Indicator**: Small teal dot (●) next to "Flow Mode" text when active

### Loading/Disabled/Error States
- **Loading**: Smooth slide transition when toggling (no loading spinner needed)
- **Empty States**: 
  - No priority messages: "No urgent messages right now"
  - No holding messages: Hide HOLDING section entirely
- **Error**: Graceful fallback to normal list view if filtering fails

### Performance
- Toggle response: <300ms
- Section transitions: 60fps animations
- List rendering: Smooth scrolling with 100+ messages

---

## 7. Functional Requirements (Must/Should)

### MUST
- FocusModeService manages isActive state with UserDefaults persistence
- ConversationListView filters messages based on `message.priority` field
- Toggle switch responds immediately with visual feedback
- State persists across app restarts and backgrounding
- Two-section layout when Focus Mode active, single section when inactive

### SHOULD
- Smooth slide animations between sections
- Optimistic UI updates (no loading states for toggle)
- Graceful error handling if message filtering fails

### Acceptance Gates
- [Gate] Toggle Focus Mode → sections appear/disappear in <300ms
- [Gate] Focus Mode ON → messages filter into correct sections
- [Gate] Focus Mode OFF → all messages show in single list
- [Gate] Kill app and restart → Focus Mode state preserved
- [Gate] 100 toggle cycles → no crashes or memory leaks

---

## 8. Data Model

No new Firestore collections. Uses existing message priority field from PR #20:

```swift
// Existing Message model (from PR #20)
struct Message {
    let id: String
    let text: String
    let priority: String? // "urgent" | "normal" | nil
    let classifiedAt: Date?
    // ... other existing fields
}

// New Focus Mode model
struct FocusMode {
    let isActive: Bool
    let activatedAt: Date?
    let sessionId: String?
}
```

- **Validation**: Priority field already validated in PR #20
- **Indexing**: No new indexes needed (using existing message queries)

---

## 9. API / Service Contracts

```swift
// FocusModeService
class FocusModeService: ObservableObject {
    @Published var isActive: Bool = false
    
    func toggleFocusMode() async
    func activateFocusMode() async
    func deactivateFocusMode() async
    func filterChats(_ chats: [Chat]) -> (priority: [Chat], holding: [Chat])
    func getCurrentSession() -> FocusSession?
}

// FocusSession model
struct FocusSession {
    let id: String
    let startTime: Date
    let endTime: Date?
    let messageCount: Int
}
```

- **Pre-conditions**: User must be authenticated
- **Post-conditions**: UI updates immediately, state persisted
- **Error handling**: Fallback to normal list view, log errors
- **Parameters**: No external parameters needed for basic toggle
- **Return values**: Void for toggle methods, filtered arrays for filtering

---

## 10. UI Components to Create/Modify

- `Services/FocusModeService.swift` — State management and filtering logic
- `Models/FocusMode.swift` — Data models for Focus Mode state
- `Views/ConversationListView.swift` — Add toggle and two-section layout
- `ViewModels/ConversationListViewModel.swift` — Integrate FocusModeService
- `Views/Components/HoldingPlaceholderView.swift` — Placeholder card for HOLDING section

---

## 11. Integration Points

- **UserDefaults**: Persist Focus Mode state
- **SwiftUI State Management**: @Published properties for reactive UI
- **Existing Message Model**: Use priority field from PR #20
- **ConversationListView**: Modify existing list to support two sections

---

## 12. Test Plan & Acceptance Gates

### Happy Path
- [ ] Toggle Focus Mode on → sections appear with correct messages
- [ ] Toggle Focus Mode off → single list shows all messages
- [ ] Gate: Toggle responds in <300ms

### Edge Cases
- [ ] No priority messages → show "No urgent messages" state
- [ ] No holding messages → hide HOLDING section
- [ ] App backgrounded/foregrounded → state preserved
- [ ] Memory pressure → no crashes during filtering

### Multi-User
- [ ] Multiple users can have different Focus Mode states
- [ ] No real-time sync needed (local state only)

### Performance
- [ ] Smooth 60fps animations during toggle
- [ ] List scrolling smooth with 100+ messages
- [ ] No memory leaks during 100 toggle cycles

---

## 13. Definition of Done

- [x] FocusModeService implemented
- [x] ConversationListView updated with toggle and sections
- [x] HoldingPlaceholderView component created
- [x] State persistence working across app restarts
- [x] UI animations smooth at 60fps
- [x] Documentation updated
- [ ] Unit tests for FocusModeService (pending)
- [ ] Integration tests (pending)

---

## 14. Risks & Mitigations

- **Risk**: UI performance with large message lists → Mitigation: Efficient filtering, lazy loading
- **Risk**: State management bugs → Mitigation: Comprehensive unit tests, UserDefaults validation
- **Risk**: Animation jank → Mitigation: Use SwiftUI animations, profile with Instruments

---

## 15. Rollout & Telemetry

- **Feature flag**: No (simple UI feature, low risk)
- **Metrics**: Toggle usage, section distribution, state persistence success rate
- **Manual validation**: Test on device with 100+ messages, verify smooth performance

---

## 16. Open Questions

- Q1: Should we add haptic feedback for toggle? (Nice-to-have)
- Q2: Should HOLDING section show message count in header? (Yes, per design)

---

## 17. Appendix: Out-of-Scope Backlog

Items deferred for future PRs:
- [x] Real-time AI classification integration (PR #22) ✅ Complete
- [x] User feedback on message priority (PR #22) ✅ Complete
- [ ] Session summarization (PR #23)
- [ ] Semantic search (PR #24)
- [ ] Custom urgency keywords
- [ ] Multi-device sync

---

## Preflight Questionnaire

1. **Smallest end-to-end user outcome**: User toggles Focus Mode and sees messages filter into Priority/HOLDING sections
2. **Primary user and critical action**: Busy professional toggling Focus Mode to focus on urgent messages
3. **Must-have vs nice-to-have**: Toggle + filtering (must), smooth animations (should)
4. **Real-time requirements**: None (local state only)
5. **Performance constraints**: <300ms toggle response, 60fps animations
6. **Error/edge cases**: Empty sections, filtering failures, state corruption
7. **Data model changes**: None (use existing priority field)
8. **Service APIs required**: FocusModeService for state management
9. **UI entry points**: Inline toggle in ConversationListView header
10. **Security/permissions**: None (local feature)
11. **Dependencies**: PR #20 classification engine (completed)
12. **Rollout strategy**: Direct deployment (low risk UI feature)
13. **Out of scope**: AI integration, real-time updates, summarization

---

## Authoring Notes

- Focus on clean, simple UI implementation
- Use existing message priority data from PR #20
- Prioritize smooth animations and responsive feel
- Test thoroughly with large message lists
- Keep service layer simple and deterministic
