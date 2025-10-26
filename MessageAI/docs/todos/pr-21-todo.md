# PR 21 TODO: Focus Mode UI Foundation

**Feature**: Focus Mode Toggle & Two-Section List View  
**Status**: Ready for Development  
**Agent**: Pete  
**Target Release**: January 2025  

---

## 🎯 Overview

Build the Focus Mode UI foundation with an inline toggle switch and two-section conversation list (Priority / HOLDING). Users can activate Focus Mode to filter messages into priority and non-priority sections, with a clean placeholder state for held messages.

---

## 📋 Development Tasks

### Phase 1: Core Service Layer
- [ ] **1.1** Create `FocusModeService.swift`
  - [ ] Implement `@Published var isActive: Bool` property
  - [ ] Add `toggleFocusMode()` async method
  - [ ] Add `activateFocusMode()` and `deactivateFocusMode()` methods
  - [ ] Implement `filterChats(_ chats: [Chat]) -> (priority: [Chat], holding: [Chat])` method
  - [ ] Add `getCurrentSession() -> FocusSession?` method
  - [ ] Integrate UserDefaults persistence for state
  - [ ] Add error handling with fallback to normal list view

- [ ] **1.2** Create `FocusMode.swift` model
  - [ ] Define `FocusMode` struct with `isActive`, `activatedAt`, `sessionId` properties
  - [ ] Define `FocusSession` struct with `id`, `startTime`, `endTime`, `messageCount` properties
  - [ ] Add proper initializers and validation

- [ ] **1.3** Unit Tests for Service Layer
  - [ ] Test FocusModeService state management
  - [ ] Test filtering logic with various message priorities
  - [ ] Test UserDefaults persistence
  - [ ] Test error handling scenarios

### Phase 2: UI Components
- [ ] **2.1** Create `HoldingPlaceholderView.swift`
  - [ ] Design placeholder card with "Messages are waiting quietly for you" text
  - [ ] Add appropriate styling and spacing
  - [ ] Make it reusable and configurable

- [ ] **2.2** Update `ConversationListView.swift`
  - [ ] Add inline toggle switch to header layout
  - [ ] Implement two-section layout when Focus Mode is active
  - [ ] Add single-section layout when Focus Mode is inactive
  - [ ] Integrate FocusModeService via @StateObject
  - [ ] Add smooth slide animations between sections
  - [ ] Implement empty states for both sections

- [ ] **2.3** Update `ConversationListViewModel.swift`
  - [ ] Integrate FocusModeService
  - [ ] Add computed properties for filtered chats
  - [ ] Handle state changes and UI updates
  - [ ] Add optimistic UI updates (no loading states)

### Phase 3: Toggle Switch Implementation
- [ ] **3.1** Design Toggle Switch Component
  - [ ] Create custom toggle with teal background when active
  - [ ] Add dark gray background when inactive
  - [ ] Implement smooth handle animation
  - [ ] Add proper touch targets and accessibility

- [ ] **3.2** Header Layout Integration
  - [ ] Position toggle in header: `[Profile Icon] [Search Icon]` + `[Flow Mode ●] [Toggle Switch]`
  - [ ] Add Flow Mode indicator (teal dot) when active
  - [ ] Ensure proper spacing and alignment
  - [ ] Test on different screen sizes

### Phase 4: State Management & Persistence
- [ ] **4.1** UserDefaults Integration
  - [ ] Implement state persistence across app restarts
  - [ ] Add state validation on app launch
  - [ ] Handle corrupted state gracefully
  - [ ] Test state persistence thoroughly

- [ ] **4.2** SwiftUI State Management
  - [ ] Ensure @Published properties update UI reactively
  - [ ] Handle state changes during app backgrounding/foregrounding
  - [ ] Test state consistency across different app states

### Phase 5: Performance & Polish
- [ ] **5.1** Animation Optimization
  - [ ] Ensure 60fps animations during toggle
  - [ ] Optimize section transitions
  - [ ] Test with large message lists (100+ messages)
  - [ ] Profile with Instruments for performance

- [ ] **5.2** Error Handling & Edge Cases
  - [ ] Handle empty priority messages state
  - [ ] Handle empty holding messages state (hide section)
  - [ ] Handle filtering failures gracefully
  - [ ] Test memory pressure scenarios

### Phase 6: Testing & Validation
- [ ] **6.1** Unit Tests
  - [ ] FocusModeService comprehensive test coverage
  - [ ] Model validation tests
  - [ ] State persistence tests

- [ ] **6.2** Integration Tests
  - [ ] End-to-end toggle functionality
  - [ ] State persistence across app restarts
  - [ ] Performance under load (100 toggle cycles)

- [ ] **6.3** UI Tests
  - [ ] Toggle switch interaction
  - [ ] Section transitions
  - [ ] Empty state handling
  - [ ] Accessibility testing

---

## ✅ Acceptance Gates

### Performance Gates
- [ ] **Gate 1**: Toggle Focus Mode → sections appear/disappear in <300ms
- [ ] **Gate 2**: Focus Mode ON → messages filter into correct sections
- [ ] **Gate 3**: Focus Mode OFF → all messages show in single list
- [ ] **Gate 4**: Kill app and restart → Focus Mode state preserved
- [ ] **Gate 5**: 100 toggle cycles → no crashes or memory leaks

### Functional Gates
- [ ] **Gate 6**: Toggle responds immediately with visual feedback
- [ ] **Gate 7**: State persists across app restarts and backgrounding
- [ ] **Gate 8**: Two-section layout when Focus Mode active, single section when inactive
- [ ] **Gate 9**: Smooth slide animations between sections
- [ ] **Gate 10**: Graceful error handling if message filtering fails

### Quality Gates
- [ ] **Gate 11**: UI animations smooth at 60fps
- [ ] **Gate 12**: No blocking bugs
- [ ] **Gate 13**: All unit tests pass
- [ ] **Gate 14**: All integration tests pass
- [ ] **Gate 15**: All UI tests pass

---

## 🎨 Design Specifications

### Toggle Switch States
- **Active**: Teal background with white handle on right
- **Inactive**: Dark gray background with handle on left
- **Flow Mode Indicator**: Small teal dot (●) next to "Flow Mode" text when active

### Section Layouts
- **Focus Mode OFF**: Single conversation list showing all messages
- **Focus Mode ON**: Two-section list:
  - **PRIORITY (X)**: Messages with `priority: "urgent"`
  - **HOLDING (X)**: Placeholder card with "Messages are waiting quietly for you"

### Empty States
- **No priority messages**: "No urgent messages right now"
- **No holding messages**: Hide HOLDING section entirely

---

## 🔧 Technical Requirements

### Dependencies
- PR #20 classification engine (completed)
- Existing Message model with priority field
- UserDefaults for state persistence
- SwiftUI for reactive UI updates

### Performance Targets
- Toggle response: <300ms
- Section transitions: 60fps animations
- List rendering: Smooth scrolling with 100+ messages
- Memory: No leaks during 100 toggle cycles

### Error Handling
- Fallback to normal list view if filtering fails
- Graceful handling of corrupted state
- Log errors for debugging
- No crashes under memory pressure

---

## 📝 Definition of Done

- [ ] FocusModeService implemented + unit tests
- [ ] ConversationListView updated with toggle and sections
- [ ] HoldingPlaceholderView component created
- [ ] State persistence working across app restarts
- [ ] All acceptance gates pass
- [ ] UI animations smooth at 60fps
- [ ] Documentation updated
- [ ] Code review completed
- [ ] Performance testing completed
- [ ] Accessibility testing completed

---

## 🚀 Rollout Strategy

- **Feature flag**: No (simple UI feature, low risk)
- **Metrics**: Toggle usage, section distribution, state persistence success rate
- **Manual validation**: Test on device with 100+ messages, verify smooth performance
- **Deployment**: Direct deployment after all gates pass

---

## 📊 Success Metrics

### User-Visible
- Toggle responds in <300ms
- Smooth section transitions
- Intuitive user experience

### System
- UI animations at 60fps
- No crashes during 100 toggle cycles
- State persistence success rate >99%

### Quality
- 0 blocking bugs
- All acceptance gates pass
- Comprehensive test coverage

---

## 🔍 Open Questions

- Q1: Should we add haptic feedback for toggle? (Nice-to-have)
- Q2: Should HOLDING section show message count in header? (Yes, per design)

---

## 📚 References

- [PRD: pr-21-prd.md](../prds/pr-21-prd.md)
- [PR Brief: focus-mode-pr-briefs.md](../pr-brief/focus-mode-pr-briefs.md)
- [Architecture: architecture.md](../architecture.md)
- [PR #20: Classification Engine (completed)]

---

*Created by Pete Agent - Planning & PRD Creation*  
*Last Updated: January 2025*
