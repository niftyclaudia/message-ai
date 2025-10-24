# PR Brief: Tonight's UI Demo Polish

**Created by:** Brad (PR Brief Builder)  
**Date:** October 24, 2025  
**Source PRD:** [pr-tonight-ui-demo.md](./pr-tonight-ui-demo.md)

---

## PR #DEMO-001: AI Demo Views - Priority UI Features

**Brief:** Build 4 AI-powered UI views with mock data to demonstrate MessageAI's Calm Intelligence features in a 2-minute stakeholder demo tonight. Includes Priority Inbox (message categorization with AI reasoning transparency), Action Items (task extraction with completion UX), Decision History (chronological timeline for FOMO relief), and Smart Search (semantic search with natural language). This is a demo-first implementation using hardcoded mock data arrays with realistic AI-generated examples, designed to tell Maya's transformation story: from 200 overwhelmed messages to 2 urgent items in 2 minutes. All views follow Calm Intelligence design principles (soft colors, generous spacing, 300ms spring animations, supportive empty states) and include "Why?" transparency modals showing AI reasoning. Navigation integrated into existing ProfileView and ConversationListView with toolbar buttons and sheets.

**Dependencies:** None (all backend Cloud Functions already exist, using mock data for demo)

**Complexity:** Medium  
- 8 new files (4 views + 4 view models)
- 2 file modifications (ProfileView, ConversationListView navigation)
- Mock service protocols for future Firebase swap
- 3-4 hour aggressive timeline

**Phase:** 1 (Demo/MVP)

**Priority:** 🔴 URGENT - Demo Tonight

---

## Technical Scope

### New Files to Create
1. **Views/AI/PriorityInboxView.swift** - 3-section inbox (Urgent/Can Wait/AI Handled)
2. **ViewModels/AI/PriorityInboxViewModel.swift** - Mock data with 15-20 categorized messages
3. **Views/AI/ActionItemsView.swift** - Sheet modal with grouped tasks (Today/This Week/Later)
4. **ViewModels/AI/ActionItemsViewModel.swift** - Mock data with 7-8 action items
5. **Views/AI/DecisionHistoryView.swift** - Timeline of tracked decisions
6. **ViewModels/AI/DecisionHistoryViewModel.swift** - Mock data with 5-6 decisions
7. **Views/AI/SmartSearchView.swift** - Semantic search results with relevance scores
8. **ViewModels/AI/SmartSearchViewModel.swift** - Mock search with keyword matching

### Files to Modify
- **Views/Profile/ProfileView.swift** - Add navigation links to Priority Inbox and Decision History
- **Views/ConversationListView.swift** - Add toolbar button for Action Items sheet

---

## Demo Flow (2 Minutes)

1. **Priority Inbox** (30s) - Open from Profile → See categorized messages → Tap "Why?" to show AI reasoning
2. **Action Items** (30s) - Tap toolbar → See grouped tasks → Complete one with animation
3. **Smart Search** (30s) - Search "payment decision" → See semantic results → Open conversation
4. **Decision History** (30s) - Navigate from Profile → See timeline → Filter by Last Week

**Success:** Stakeholders see all 6 AI features (4 new + settings + Slack PR-11) working cohesively

---

## Key Constraints

### In Scope (Tonight)
- ✅ Mock data hardcoded in ViewModels
- ✅ Calm Intelligence design (soft colors, gentle animations, transparent AI reasoning)
- ✅ Navigation and tap interactions
- ✅ Dark mode compatibility
- ✅ Smoke tests (builds run, no crashes)

### Out of Scope (Future PRs)
- ❌ Real Firebase/Cloud Functions integration
- ❌ Production error handling
- ❌ Full test coverage (80%+ unit/UI tests)
- ❌ Offline persistence and real-time sync
- ❌ Performance optimization for large datasets

---

## Design Standards (Calm Intelligence)

**Colors:**
- Urgent: `#FF6B6B` (soft red, not harsh)
- Can Wait: `#4A90E2` (calm blue)
- AI Handled: `#95A5A6` (muted gray)
- Success: `#2ECC71` (calm green)

**Animations:**
- 300-400ms spring animations (response: 0.35, dampingFraction: 0.8)
- Gentle transitions, no jarring movements

**Spacing:**
- 16-20pt padding on screen edges
- 16pt spacing between cards
- Generous whitespace (not cramped)

**Transparency:**
- Every AI decision has "Why?" button
- Shows signals detected, confidence level, evidence
- First-person humble tone ("I think" not "This is")

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **4 views in 3-4 hours is aggressive** | Not ready for demo | Prioritize PriorityInboxView first (hero feature), cut SmartSearch if needed |
| **Mock data feels fake** | Stakeholders skeptical | Use realistic examples based on actual Cloud Function outputs, show transparency |
| **Demo runs long (>2 minutes)** | Lose attention | Practice 3x, cut steps if needed, focus on hero moments |
| **Navigation breaks existing app** | Can't complete demo | Test full flow after each view integration |

---

## Definition of Done

**Must Have:**
- [ ] All 4 views build and run without errors
- [ ] Mock data displays correctly in all views
- [ ] Navigation works (Profile → views, toolbar → sheets)
- [ ] Tap interactions work (open chat, show reasoning, complete tasks)
- [ ] Dark mode looks good
- [ ] Animations feel calm (300-400ms spring)
- [ ] Colors match Calm Intelligence palette
- [ ] Empty states are supportive
- [ ] Complete demo walkthrough in < 2 minutes
- [ ] Zero crashes during demo

**Nice to Have (if time):**
- [ ] Haptic feedback on key actions
- [ ] Pull to refresh
- [ ] Swipe gestures for recategorization

---

## Build Order (Priority Sequence)

1. **Hour 1: PriorityInboxView** - Most important, hero feature showing message categorization
2. **Hour 2: ActionItemsView** - Shows task extraction and completion UX
3. **Hour 3: DecisionHistoryView** - Shows decision tracking for FOMO relief
4. **Hour 4: SmartSearchView + Polish** - Semantic search + fix any issues + screenshot capture

**Checkpoint after each hour:** Verify that component works standalone before moving to next

---

## Post-Demo: Production Path

**Immediate Next Steps (Separate PRs):**
1. **Firebase Integration** - Replace mock services with real Cloud Functions calls
2. **Full Test Coverage** - 80%+ unit tests (Swift Testing), comprehensive UI tests
3. **Error Handling** - Implement PR-AI-005 error handling patterns
4. **Performance Optimization** - Handle 1000+ messages, <400ms load times

**Future Enhancements:**
- Real-time Firestore listeners for live updates
- Offline persistence with sync
- Customizable priority rules
- Push notifications for urgent items
- Apple Reminders integration for action items

---

## Success Metrics (Tonight)

**Demo Quality:**
- [ ] < 2 minute walkthrough showing all 6 features
- [ ] Stakeholders understand Maya's transformation story
- [ ] No crashes or broken UI
- [ ] Feels cohesive with existing app

**Calm Intelligence Validation:**
- [ ] Stakeholder feedback confirms "calm" feeling
- [ ] Transparency features land well (not overwhelming)
- [ ] UI feels spacious and supportive (not cramped or harsh)

**Business Goal:**
- [ ] Secure stakeholder buy-in for next funding round
- [ ] Demonstrate product vision with working prototype
- [ ] Collect feedback for iteration priorities

---

## Why This PR Matters

From the AI Product Vision: *"Users spend LESS time in app but feel MORE in control."*

These 4 views demonstrate the core value proposition:
- **PriorityInboxView** = Impossible Prioritization → solved
- **ActionItemsView** = Overwhelming Re-entry → solved
- **DecisionHistoryView** = Digital FOMO → eliminated
- **SmartSearchView** = Information Buried → instantly found

**Maya's transformation is the story:**
- Before: 200 messages, 20 minutes overwhelmed, anxiety
- After: 2 urgent items, 2 minutes in control, calm

This is the demo that sells the vision. 🚀

---

**Next Agent:** Cody (iOS) for implementation  
**Branch:** `feat/demo-ui-polish-tonight`  
**Target:** `develop` branch  
**Timeline:** 3-4 hours (start immediately)

