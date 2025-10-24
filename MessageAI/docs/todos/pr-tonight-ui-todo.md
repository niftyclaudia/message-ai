# TODO: Tonight's UI Demo - 4 Priority Views

**Goal**: Complete demo flow showing all AI features  
**Time**: 3-4 hours  
**Status**: Ready to start  

---

## 🎯 Demo Flow We're Building

```
Open app 
  → PriorityInboxView (categorized messages) 
  → Tap toolbar → ActionItemsView (tasks)
  → Search → SmartSearchView (semantic search)
  → Decision History → DecisionHistoryView (decisions)
  → Slack Integration → Already done! ✅
  → Calendar → Already mocked! ✅
```

---

## Hour 1: PriorityInboxView (HERO FEATURE) ⏱️ 45 min

### Setup
- [ ] Create `Views/AI/PriorityInboxView.swift`
- [ ] Create `ViewModels/AI/PriorityInboxViewModel.swift`
- [ ] Add navigation in ProfileView

### UI Components
- [ ] 3 sections with badges (Urgent 🔴, Can Wait 🔵, AI Handled ⚪)
- [ ] Message cards with sender, preview, timestamp
- [ ] "Why?" info button on each card
- [ ] Reasoning modal showing:
  - [ ] AI explanation
  - [ ] Confidence badge
  - [ ] Signals detected
  - [ ] Evidence link
- [ ] Tap message → Opens chat
- [ ] Empty state: "All caught up! 🎉"

### Mock Data (15-20 messages)
- [ ] 2-3 Urgent: "@mentions", "deadline", "production issue"
- [ ] 5-8 Can Wait: "FYI", "when you can", "questions"
- [ ] 10-15 AI Handled: "Thanks!", "👍", "Got it"

### Polish
- [ ] Spacious cards with whitespace
- [ ] Soft colors (#FF6B6B, #4A90E2, #95A5A6)
- [ ] 300ms spring animations
- [ ] Dark mode works

**✅ Checkpoint:** Can see categorized messages with reasoning modal

---

## Hour 2: ActionItemsView ⏱️ 30 min

### Setup
- [ ] Create `Views/AI/ActionItemsView.swift`
- [ ] Create `ViewModels/AI/ActionItemsViewModel.swift`
- [ ] Add toolbar button (checklist icon) in ConversationListView
- [ ] Wire up sheet presentation

### UI Components
- [ ] Sheet modal slides from bottom
- [ ] 3 sections: Today 📅, This Week 📆, Later 📋
- [ ] Task cards with:
  - [ ] Checkbox (☐ → ✓ animation)
  - [ ] Task text (bold)
  - [ ] Source: "From [Person] in [Chat]"
  - [ ] Deadline badge if present
  - [ ] Tap → Opens source message
- [ ] Transparency modal (tap info icon)
- [ ] Empty state: "All caught up! 🎉"

### Mock Data (7-8 tasks)
- [ ] 2 Today: "Review Q4 roadmap", "Approve budget"
- [ ] 3 This Week: "Update docs", "Schedule 1:1"
- [ ] 3 Later: "Research pricing", "Plan offsite"

### Polish
- [ ] Completion animation (checkmark + fade)
- [ ] Max 8 tasks shown (not overwhelming)
- [ ] Supportive empty state
- [ ] No red panic text

**✅ Checkpoint:** Can extract and complete tasks from toolbar

---

## Hour 3: DecisionHistoryView ⏱️ 30 min

### Setup
- [ ] Create `Views/AI/DecisionHistoryView.swift`
- [ ] Create `ViewModels/AI/DecisionHistoryViewModel.swift`
- [ ] Add navigation in ProfileView

### UI Components
- [ ] Timeline view (chronological, newest first)
- [ ] Decision cards with:
  - [ ] Decision text (bold)
  - [ ] Participants (avatars + names)
  - [ ] Timestamp ("2 days ago")
  - [ ] Chat context badge
  - [ ] Confidence badge
  - [ ] Tap → Opens source conversation
- [ ] Filters: Last Week | Last Month | All Time
- [ ] Search bar: "Find budget decisions..."
- [ ] Transparency modal (tap "Why?")
- [ ] Empty state: "No major decisions tracked yet"

### Mock Data (5-6 decisions)
- [ ] "Decided to use Stripe" (2 days ago)
- [ ] "Q4 launch postponed" (5 days ago)
- [ ] "Hired Sarah as Senior Designer" (1 week ago)
- [ ] "Switched to REST API" (2 weeks ago)

### Polish
- [ ] Spacious timeline (not cramped)
- [ ] Soft dividers between items
- [ ] Muted colors
- [ ] Search hints at natural language

**✅ Checkpoint:** Can view decision log with filters

---

## Hour 4: SmartSearchView + Final Polish ⏱️ 30-60 min

### Setup
- [ ] Create `Views/AI/SmartSearchView.swift` (or enhance existing)
- [ ] Create `ViewModels/AI/SmartSearchViewModel.swift`
- [ ] Update search in ConversationListView

### UI Components
- [ ] Search bar with placeholder: "Find the budget decision..."
- [ ] Results list with:
  - [ ] Message preview + context
  - [ ] Sender + timestamp
  - [ ] Chat name badge
  - [ ] Relevance score: "95% match" (subtle)
  - [ ] Highlighted keywords
  - [ ] Tap → Opens conversation at message
- [ ] Loading state: Calm animated icon
- [ ] Transparency footer showing interpreted query
- [ ] Empty state with helpful suggestions

### Mock Data (4-5 results)
- [ ] Query: "payment processor decision"
- [ ] Results with 95%, 87%, 72% relevance
- [ ] Different chats and senders

### Polish
- [ ] Search feels smart, not mechanical
- [ ] Subtle relevance scores
- [ ] Helpful on no results

**✅ Checkpoint:** Search works with natural language

---

## Final Polish (If Time) ✨

### Navigation & Integration
- [ ] ProfileView has all navigation links
- [ ] ConversationListView toolbar buttons work
- [ ] All sheets/modals present correctly
- [ ] Navigation stack works (no crashes)

### Calm Intelligence Polish
- [ ] All colors match palette
- [ ] All animations 300-400ms spring
- [ ] All spacing generous (16-20pt)
- [ ] All empty states supportive
- [ ] Dark mode looks good everywhere

### Test Complete Demo Flow
- [ ] Profile → Priority Inbox → See categorized messages ✓
- [ ] Tap "Why?" → See reasoning ✓
- [ ] Toolbar → Action Items → See tasks ✓
- [ ] Check off task → See animation ✓
- [ ] Search "payment" → See results ✓
- [ ] Profile → Decision History → See timeline ✓
- [ ] Profile → Slack Integration → See mock ✓
- [ ] Complete flow in <2 min ✓

### Screenshots & Demo Prep
- [ ] Take screenshots of each view
- [ ] Test on iPhone simulator (14 Pro)
- [ ] Verify no crashes
- [ ] Practice demo script (2 min)

---

## ✅ Definition of Done

### Must Pass Before Demo:
- [ ] All 4 views build without errors
- [ ] Mock data displays correctly
- [ ] Navigation works end-to-end
- [ ] Tap interactions work
- [ ] Dark mode doesn't break
- [ ] No crashes during demo flow

### Calm Intelligence Checklist:
- [ ] Colors are soft (not harsh)
- [ ] Spacing is generous (not cramped)  
- [ ] Animations are calm (300-400ms)
- [ ] Empty states are supportive
- [ ] Reasoning is transparent
- [ ] Tone is humble

---

## 🚀 Quick Start

```bash
# Hour 1: PriorityInboxView
touch MessageAI/MessageAI/Views/AI/PriorityInboxView.swift
touch MessageAI/MessageAI/ViewModels/AI/PriorityInboxViewModel.swift

# Hour 2: ActionItemsView  
touch MessageAI/MessageAI/Views/AI/ActionItemsView.swift
touch MessageAI/MessageAI/ViewModels/AI/ActionItemsViewModel.swift

# Hour 3: DecisionHistoryView
touch MessageAI/MessageAI/Views/AI/DecisionHistoryView.swift
touch MessageAI/MessageAI/ViewModels/AI/DecisionHistoryViewModel.swift

# Hour 4: SmartSearchView
touch MessageAI/MessageAI/Views/AI/SmartSearchView.swift
touch MessageAI/MessageAI/ViewModels/AI/SmartSearchViewModel.swift

# Then add to Xcode project manually
```

---

## 📊 Progress Tracker

**Hour 1:** PriorityInboxView - ⬜ Not Started  
**Hour 2:** ActionItemsView - ⬜ Not Started  
**Hour 3:** DecisionHistoryView - ⬜ Not Started  
**Hour 4:** SmartSearchView + Polish - ⬜ Not Started  

**Overall:** 0/4 views complete (0%)

---

**Time Started:** ___________  
**Expected Done:** ___________ (3-4 hours later)  
**Demo Ready:** ⬜

**Let's ship this! 🎉**

