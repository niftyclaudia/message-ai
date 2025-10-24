# PRD: Tonight's UI Demo Polish - Priority AI Views

**Feature**: AI Demo Views (Priority Inbox, Action Items, Decision History, Smart Search)

**Version**: 1.0

**Status**: Ready to Build

**Priority**: 🔴 URGENT - Demo Tonight  

**Estimated Time**: 3-4 hours  

**Target Release**: Tonight (October 24, 2025)

**Agent**: Pete (Planning) → Cody (Implementation)

**Links**: [Slack Integration PR-011](pr-011-prd.md), [AI Product Vision](../AI-PRODUCT-VISION.md), [Todo List](../todos/pr-tonight-ui-todo.md)

---

## 1. Summary

Build 4 AI-powered UI views with mock data to demonstrate MessageAI's Calm Intelligence features in a 2-minute stakeholder demo: Priority Inbox (message categorization), Action Items (task extraction), Decision History (FOMO relief), and Smart Search (semantic search).

---

## 2. Problem & Goals

### Problem
Stakeholders need to see all 6 AI features working together in a cohesive demo flow to understand MessageAI's product vision and secure next funding round. Currently, backend AI functions exist but lack user-facing UI for demo.

### Why Now?
Demo scheduled for tonight to showcase Maya's transformation story: from overwhelmed by 200 messages to in control with 2 urgent items in 2 minutes.

### Goals (Ordered by Priority)
- [ ] **G1** — Demonstrate Priority Inbox categorization (Urgent/Can Wait/AI Handled) with transparency
- [ ] **G2** — Show Action Item extraction from conversations with completion UX
- [ ] **G3** — Display Decision History timeline for FOMO relief
- [ ] **G4** — Prove Smart Search works with natural language queries
- [ ] **G5** — Complete 2-minute walkthrough showcasing all AI features cohesively
- [ ] **G6** — Gather stakeholder feedback on Calm Intelligence UX principles

---

## 3. Non-Goals / Out of Scope

Tonight's demo uses **mock data only**. Explicitly NOT doing:

- ❌ **Real Firebase backend integration** — Use hardcoded mock data arrays
- ❌ **Actual AI Cloud Function calls** — Mock responses inline in ViewModels
- ❌ **Production-ready error handling** — Demo happy path only (add error handling in future PR)
- ❌ **Full test coverage** — Smoke tests only to verify builds run
- ❌ **Offline persistence** — Not needed for single-device demo
- ❌ **Multi-device sync** — Single device presentation
- ❌ **Real-time Firestore listeners** — Static mock data
- ❌ **User authentication** — Assume logged in user
- ❌ **Performance optimization** — Small datasets only (<20 items per view)

**Rationale:** Prioritizing visual polish and cohesive demo flow over backend integration to meet tonight's deadline. Production implementation will follow in separate PRs.

---

## 🎯 Mission: Show Maya's Complete AI-Powered Day

**Demo Story:**
Maya opens MessageAI after 4-hour focus session → Sees prioritized messages → Checks action items → Searches for decision → Reviews decision log → Views Slack integration → Approves meeting time

**Success Metric:** Complete walkthrough in 2 minutes showing all 6 AI features working

---

## ✅ What's Already Done

- ✅ **Backend**: All Cloud Functions working (categorize, extract, search, track)
- ✅ **Models**: All Swift models exist (MessageCategory, ActionItem, Decision, etc)
- ✅ **Services**: FunctionCallingService with all methods
- ✅ **PR-11**: Slack thread mock with summarization working
- ✅ **Settings**: AI preferences, focus hours, priority rules UI

---

## 🚨 What's Missing (Build Tonight)

### Priority 1: PriorityInboxView (45 min) - **HERO FEATURE**
**Why First:** This is the main value prop - shows Maya's messages categorized

**What to Build:**
```
Views/AI/PriorityInboxView.swift
ViewModels/AI/PriorityInboxViewModel.swift
```

**UI Requirements:**
- **3 Sections** with badges:
  - 🔴 Urgent (2-3 messages) - Expanded by default
  - 🔵 Can Wait (5-8 messages) - Collapsed, tap to expand
  - ⚪ AI Handled (10-15 messages) - Collapsed, tap to expand

- **Message Cards** show:
  - Sender avatar + name
  - Message preview (1-2 lines)
  - Timestamp
  - "Why?" info button → Shows AI reasoning

- **Reasoning Modal** (tap "Why?"):
  - "Why Urgent:" with explanation
  - Confidence: High/Moderate/Uncertain (badge)
  - Signals detected: ["@mentioned you", "deadline tomorrow", "from manager"]
  - Evidence: Link to actual message text

- **Actions**:
  - Tap message → Open chat
  - Swipe → Manual recategorize (Urgent ↔ Can Wait)
  - Pull to refresh

**Mock Data** (hardcode 15-20 messages):
```swift
// Urgent examples:
"Production API down - need your help ASAP" (from CTO)
"Can you review the Q4 roadmap by tomorrow?" (@mentions, deadline)

// Can Wait examples:
"Updated the docs, take a look when you can" (no urgency)
"FYI - Design team meeting notes" (informational)

// AI Handled examples:
"Thanks!" (acknowledgment)
"👍" (emoji reaction)
"Got it, will do" (simple confirmation)
```

**Calm Intelligence:**
- Spacious cards with whitespace
- Soft colors: Red (urgent) = #FF6B6B, Blue = #4A90E2, Gray = #95A5A6
- Gentle animations (300ms spring)
- Empty state: "All caught up! 🎉" (green checkmark)

**Acceptance:**
- [ ] Shows 3 sections with correct badges
- [ ] Reasoning modal works with transparency
- [ ] Tap opens conversation
- [ ] Looks calm and spacious (not cramped)
- [ ] Dark mode works

---

### Priority 2: ActionItemsView (30 min)
**Why Second:** Shows AI extracted tasks from conversations

**What to Build:**
```
Views/AI/ActionItemsView.swift
ViewModels/AI/ActionItemsViewModel.swift
```

**UI Requirements:**
- **Toolbar Button** (checklist icon) in ConversationListView
- **Sheet Modal** slides up from bottom

- **3 Sections** grouped by urgency:
  - 📅 Today (1-2 tasks) - Red badge
  - 📆 This Week (2-3 tasks) - Orange badge  
  - 📋 Later (2-3 tasks) - Blue badge

- **Task Cards** show:
  - ☐ Checkbox (tap to complete → ✓ animation)
  - Task text (bold)
  - "From [Person] in [Chat Name]" (gray, smaller)
  - Deadline badge if mentioned ("Due Tomorrow")
  - Tap → Opens source message in chat

- **Transparency** (tap info icon):
  - "I found this task because:"
  - Signals: ["I'll", "by Friday", "@mentioned you"]
  - Source message excerpt with highlighted keywords

- **Empty State:**
  - "All caught up! 🎉"
  - "No action items right now"
  - Calm green checkmark

**Mock Data** (7-8 tasks):
```swift
// Today:
"Review Q4 roadmap" (from Jamie, due today)
"Approve $15K marketing budget" (from Chris, @mentioned)

// This Week:
"Update API documentation" (by Friday)
"Schedule 1:1 with new hire" (this week)

// Later:
"Research competitor pricing" (no deadline)
"Plan team offsite" (next month)
```

**Calm Intelligence:**
- Not overwhelming - max 8 tasks shown
- Completion animation: Soft checkmark + fade out
- Supportive empty state
- No red "OVERDUE" panic text

**Acceptance:**
- [ ] Toolbar button launches sheet
- [ ] Tasks grouped by urgency
- [ ] Checkboxes work with animation
- [ ] Tap task opens source conversation
- [ ] Transparency reasoning shows
- [ ] Empty state feels celebratory

---

### Priority 3: DecisionHistoryView (30 min)
**Why Third:** Shows AI-tracked decisions for FOMO relief

**What to Build:**
```
Views/AI/DecisionHistoryView.swift
ViewModels/AI/DecisionHistoryViewModel.swift
```

**UI Requirements:**
- **Navigation** from Profile tab → "Decision History"
- **Timeline View** (chronological, newest first)

- **Decision Cards**:
  - Decision text (bold): "Team decided to use Stripe for payments"
  - Participants (avatars + names)
  - When: "2 days ago" or "Oct 22, 3:45 PM"
  - Chat context: "From #product-team chat"
  - Confidence badge: High/Moderate
  - Tap → Opens source conversation

- **Filters** (top bar):
  - "Last Week" | "Last Month" | "All Time"
  - Search bar for natural language ("Find budget decisions")

- **Transparency** (tap "Why?"):
  - "I detected this decision because:"
  - Signals: ["we've decided", "approved", "let's go with"]
  - Participants who agreed

- **Empty State:**
  - "No major decisions tracked yet"
  - "I'll log decisions as your team makes them"
  - Calm illustration

**Mock Data** (5-6 decisions):
```swift
"Decided to use Stripe for payments" (Jamie, Chris approved, 2 days ago)
"Q4 launch postponed to January" (Team consensus, 5 days ago)
"Hired Sarah as Senior Designer" (Alice approved, 1 week ago)
"Switched to REST API instead of GraphQL" (Dave decided, 2 weeks ago)
```

**Calm Intelligence:**
- Spacious timeline (not cramped)
- Soft dividers between decisions
- Muted colors (not aggressive)
- Search is helpful, not mandatory

**Acceptance:**
- [ ] Timeline shows decisions chronologically
- [ ] Filters work (Last Week/Month/All)
- [ ] Tap opens source conversation
- [ ] Transparency shows signals
- [ ] Empty state is supportive
- [ ] Search placeholder hints at natural language

---

### Priority 4: SmartSearchView (30 min)
**Why Fourth:** Shows semantic search working

**What to Build:**
```
Views/AI/SmartSearchView.swift (or enhance existing search)
ViewModels/AI/SmartSearchViewModel.swift
```

**UI Requirements:**
- **Search Bar** prominent in ConversationListView
- **Placeholder**: "Find the budget decision..." (hints at natural language)

- **Results List**:
  - Message preview with context
  - Sender + timestamp
  - Chat name badge
  - Relevance score: "95% match" (subtle, gray)
  - Matched keywords highlighted in preview
  - Tap → Opens conversation at that message

- **Loading State**:
  - Calm animated search icon
  - "Searching your conversations..." (not aggressive)

- **Transparency** (bottom of results):
  - "I searched for: [interpreted query]"
  - "Found X relevant messages"
  - Search time: "0.8s"

- **Empty State**:
  - "No matches found"
  - "Try broader terms: 'payment decision' instead of 'Stripe pricing tier 3'"
  - Helpful, not harsh

**Mock Data** (4-5 search results):
```swift
// Query: "Find the payment processor decision"
Results:
1. "We've decided to go with Stripe..." (Jamie, #product-team, 95% match)
2. "Chris approved the $5K/month Stripe plan" (Chris, #product-team, 87% match)
3. "Stripe integration is live!" (Dave, #engineering, 72% match)
```

**Calm Intelligence:**
- Search feels smart, not mechanical
- Relevance scores subtle (not prominent)
- Results feel confident, not exhaustive
- Helpful suggestions on no results

**Acceptance:**
- [ ] Search bar accepts natural language
- [ ] Results show with relevance scores
- [ ] Matched keywords highlighted
- [ ] Loading state is calm
- [ ] Empty state is helpful
- [ ] Tap opens exact message in chat

---

## 8. Data Model (Mock Data Structures)

### PriorityInboxItem
```swift
struct PriorityInboxItem: Identifiable {
    let id: String
    let senderName: String
    let senderAvatarURL: String?
    let messagePreview: String
    let timestamp: Date
    let category: MessageCategory
    let reasoning: PriorityReasoning
    let sourceConversationID: String
}

enum MessageCategory: String, CaseIterable {
    case urgent = "Urgent"
    case canWait = "Can Wait"
    case aiHandled = "AI Handled"
}

struct PriorityReasoning {
    let whyUrgent: String
    let confidence: ConfidenceLevel
    let signals: [String]
    let evidenceMessageID: String
}

enum ConfidenceLevel: String {
    case high = "High"
    case moderate = "Moderate"
    case uncertain = "Uncertain"
}
```

### ActionItem
```swift
struct ActionItem: Identifiable {
    let id: String
    let text: String
    let fromPerson: String
    let chatName: String
    let deadline: Date?
    let urgency: ActionItemUrgency
    let sourceMessageID: String
    let sourceConversationID: String
    let extractionReasoning: ExtractionReasoning
    var isCompleted: Bool = false
}

enum ActionItemUrgency: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case later = "Later"
}

struct ExtractionReasoning {
    let why: String
    let signals: [String]
    let sourceExcerpt: String
    let confidence: ConfidenceLevel
}
```

### Decision
```swift
struct Decision: Identifiable {
    let id: String
    let decisionText: String
    let participants: [Participant]
    let timestamp: Date
    let chatContext: String
    let chatID: String
    let sourceMessageID: String
    let confidence: ConfidenceLevel
    let detectionSignals: [String]
}

struct Participant {
    let id: String
    let name: String
    let avatarURL: String?
}
```

### SearchResult
```swift
struct SearchResult: Identifiable {
    let id: String
    let messagePreview: String
    let senderName: String
    let timestamp: Date
    let chatName: String
    let chatID: String
    let messageID: String
    let relevanceScore: Double // 0.0 to 1.0
    let matchedKeywords: [String]
}
```

**Note:** Tonight using in-memory arrays. Future production will use Firestore documents with these schemas.

---

## 9. API / Service Contracts

Tonight using **mock implementations**. Future production will connect to Firebase/Cloud Functions.

### PriorityInboxService Protocol
```swift
protocol PriorityInboxService {
    /// Fetch categorized messages (mock returns hardcoded array)
    func fetchInbox() async throws -> [PriorityInboxItem]
    
    /// Manually recategorize a message (mock updates local array)
    func recategorizeMessage(messageID: String, newCategory: MessageCategory) async throws
    
    /// Refresh inbox (mock re-sorts existing data)
    func refreshInbox() async throws -> [PriorityInboxItem]
}
```

### ActionItemService Protocol
```swift
protocol ActionItemService {
    /// Fetch all action items grouped by urgency (mock returns 7-8 hardcoded tasks)
    func fetchActionItems() async throws -> [ActionItem]
    
    /// Mark action item as complete (mock updates isCompleted flag)
    func completeActionItem(id: String) async throws
    
    /// Fetch action items filtered by urgency
    func fetchActionItems(urgency: ActionItemUrgency) async throws -> [ActionItem]
}
```

### DecisionHistoryService Protocol
```swift
protocol DecisionHistoryService {
    /// Fetch decisions with optional time filter (mock returns 5-6 decisions)
    func fetchDecisions(filter: TimeFilter) async throws -> [Decision]
    
    /// Search decisions by natural language query (mock filters by keyword)
    func searchDecisions(query: String) async throws -> [Decision]
}

enum TimeFilter: String, CaseIterable {
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case allTime = "All Time"
}
```

### SmartSearchService Protocol
```swift
protocol SmartSearchService {
    /// Semantic search (mock returns keyword-matched results with fake relevance scores)
    func search(query: String) async throws -> [SearchResult]
}
```

**Implementation Strategy:**
- Tonight: Create `Mock[Service]` classes that return hardcoded arrays
- Production: Create `Firebase[Service]` classes that call Cloud Functions + Firestore
- ViewModels depend on protocols, making it easy to swap implementations

---

## 10. UI Components to Create/Modify

### New Files to Create
- `Views/AI/PriorityInboxView.swift` — Main priority inbox screen with 3 sections
- `ViewModels/AI/PriorityInboxViewModel.swift` — Manages inbox state and mock data
- `Views/AI/ActionItemsView.swift` — Action items sheet modal with grouped tasks
- `ViewModels/AI/ActionItemsViewModel.swift` — Manages action items state and completion
- `Views/AI/DecisionHistoryView.swift` — Timeline view of tracked decisions
- `ViewModels/AI/DecisionHistoryViewModel.swift` — Manages decision history state and filtering
- `Views/AI/SmartSearchView.swift` — Enhanced search with semantic results
- `ViewModels/AI/SmartSearchViewModel.swift` — Manages search state and mock results
- `Components/AI/ReasoningModal.swift` — Reusable transparency modal for AI explanations
- `Components/AI/CalmEmptyStateView.swift` — Reusable empty state component

### Files to Modify
- `Views/Profile/ProfileView.swift` — Add navigation links to Priority Inbox and Decision History
- `Views/ConversationListView.swift` — Add toolbar button for Action Items sheet

---

## 11. Threading & Concurrency

**Tonight (Mock Data):**
- All data synchronous (no threading needed)
- ViewModels use `@MainActor` and `@Published` for SwiftUI reactivity

**Future Production:** Follow Swift concurrency best practices - background threads for Firestore/AI calls, main thread for UI updates via `@MainActor`

---

## 12. Test Plan & Acceptance Gates

### Tonight (Smoke Tests Only)
- [ ] All 4 views build and run without errors
- [ ] Complete demo script runs in < 2 minutes  
- [ ] No crashes or visual glitches
- [ ] Dark mode works correctly
- [ ] Navigation and tap interactions functional
- [ ] All acceptance criteria met (see Priority 1-4 sections above)

### Future Production (Add Before Launch)
- **Unit Tests:** ViewModel tests using Swift Testing (`@Test`, `#expect`)
- **UI Tests:** Navigation and interaction tests using XCTest
- **Coverage Target:** 80%+ for ViewModels, key flows covered in UI tests

See `MessageAI/agents/shared-standards.md` for detailed testing requirements.

---

## 13. Performance Requirements

**Tonight (Mock Data):** Instant loads (<300ms), 60fps animations, small datasets

**Future Production:** Must meet Phase 1 targets - View load <400ms, AI operations p95 <2s, scrolling 60fps with 1000+ messages. See `shared-standards.md` for details.

---

## 14. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| **Mock data doesn't reflect real AI behavior** | Demo feels fake, stakeholders skeptical | Use realistic examples based on actual Cloud Function outputs; show transparency reasoning |
| **4 views in 3-4 hours is aggressive** | Not ready for demo | Prioritize PriorityInboxView (hero feature) first; cut SmartSearch if time runs out |
| **Dark mode issues** | Demo looks unprofessional | Test dark mode for each view before moving to next; use semantic colors |
| **Animations feel janky** | Violates Calm Intelligence principles | Use 300-400ms spring animations consistently; test on physical device |
| **Navigation breaks existing app** | Can't show full demo flow | Test complete demo script after each view integration |
| **Stakeholders want to interact (not just watch)** | Mock data breaks if they deviate from script | Add error handling for unexpected taps; guide demo with narration |
| **Demo runs long (>2 minutes)** | Lose stakeholder attention | Practice demo script 3x; cut steps if needed |

---

## 15. Integration Points

**Tonight:** Mock services, SwiftUI state management, NavigationLink + sheets for navigation

**Future:** Connect to Firebase (Firestore + Cloud Functions), use existing `FunctionCallingService`

---

## 🎨 Calm Intelligence Design Standards

### Colors (Use Throughout)
```swift
// Urgent
Color(hex: "#FF6B6B") // Soft red, not harsh

// Can Wait  
Color(hex: "#4A90E2") // Calm blue

// AI Handled / Low priority
Color(hex: "#95A5A6") // Muted gray

// Success / Complete
Color(hex: "#2ECC71") // Calm green

// Background (Dark Mode)
Color(hex: "#1E1E1E") // Deep space
```

### Animations (Use Throughout)
```swift
// All transitions
.animation(.spring(response: 0.35, dampingFraction: 0.8), value: state)

// Appear animations
.transition(.move(edge: .bottom).combined(with: .opacity))

// Success moments
.scaleEffect(completed ? 1.1 : 1.0)
.opacity(completed ? 0 : 1)
```

### Spacing (Use Throughout)
```swift
VStack(spacing: 16) // Cards
.padding(20) // Screen edges
.padding(.vertical, 12) // Card internal
```

### Typography
```swift
.font(.title2).bold() // Section headers
.font(.body) // Message text
.font(.caption).foregroundColor(.secondary) // Meta info
```

---

## 📱 Navigation & Integration

### Add to ProfileView
```swift
// Add these navigation links:
NavigationLink("Priority Inbox") {
    PriorityInboxView()
}
NavigationLink("Decision History") {
    DecisionHistoryView()
}
NavigationLink("Slack Integration (Demo)") {
    MockSlackThreadView() // Already exists
}
```

### Add to ConversationListView
```swift
// Toolbar items:
.toolbar {
    // Action Items button
    ToolbarItem(placement: .navigationBarTrailing) {
        Button { showActionItems = true } {
            Image(systemName: "checklist")
        }
    }
}

// Sheets:
.sheet(isPresented: $showActionItems) {
    ActionItemsView()
}
```

### Search Integration
```swift
// Enhance existing search or add semantic search mode
.searchable(text: $searchQuery, prompt: "Find the budget decision...")
```

---

## ✅ Definition of Done (Tonight)

### Must Have:
- [ ] All 4 views build and run without errors
- [ ] Mock data displays correctly in all views
- [ ] Navigation works (Profile → views, toolbar → sheets)
- [ ] Tap interactions work (open chat, show reasoning, etc)
- [ ] Dark mode looks good
- [ ] Animations feel calm (300-400ms, spring)
- [ ] Colors match Calm Intelligence palette
- [ ] Empty states are supportive

### Nice to Have (if time):
- [ ] Haptic feedback on key actions
- [ ] Loading state animations
- [ ] Swipe gestures
- [ ] Pull to refresh

### Demo Ready:
- [ ] Can walk through complete flow in 2 minutes
- [ ] Screenshots look polished
- [ ] No crashes or broken UI
- [ ] Feels cohesive with existing app

---

## 🚀 Build Order (3-4 hours)

### Hour 1: PriorityInboxView (Most Important)
- Create view + viewmodel
- Add 3 sections with mock data
- Implement reasoning modal
- Add navigation from Profile

**Checkpoint:** Can see categorized messages with reasoning

### Hour 2: ActionItemsView
- Create view + viewmodel  
- Add toolbar button in ConversationListView
- Implement sheet with grouped tasks
- Add completion checkboxes

**Checkpoint:** Can extract and complete tasks

### Hour 3: DecisionHistoryView
- Create view + viewmodel
- Add timeline with mock decisions
- Implement filters
- Add navigation from Profile

**Checkpoint:** Can view decision log

### Hour 4: SmartSearchView + Polish
- Enhance search or create new view
- Add mock search results
- Polish all views:
  - Fix any layout issues
  - Add missing animations
  - Test navigation flow
  - Take screenshots

**Checkpoint:** Complete demo flow works end-to-end

---

## 🎬 Demo Script (Test This)

1. **Open app** → Profile tab → "Priority Inbox"
   - See: 2 Urgent, 6 Can Wait, 12 AI Handled
   - Tap "Why?" on urgent message → See reasoning
   - ✓ Shows AI categorization working

2. **Tap toolbar** → Action Items sheet
   - See: 2 Today, 3 This Week, 3 Later
   - Check off a task → See completion animation
   - ✓ Shows task extraction working

3. **Search** → Type "payment decision"
   - See: 3 relevant results with match scores
   - Tap result → Opens conversation
   - ✓ Shows semantic search working

4. **Profile** → "Decision History"
   - See: 5 decisions chronologically
   - Tap decision → Opens source chat
   - ✓ Shows decision tracking working

5. **Profile** → "Slack Integration (Demo)"
   - See: Mock Slack thread
   - Tap "Summarize" → See AI summary
   - ✓ Shows PR-11 working

6. **Complete flow:** <2 minutes, all features visible

---

## 4. Success Metrics

### Tonight's Demo Success Criteria

**User-Visible:**
- [ ] Demo walkthrough completes in < 2 minutes
- [ ] All 6 AI features visible (4 new views + settings + Slack)
- [ ] < 10 taps to complete full demo flow
- [ ] Stakeholders understand Maya's transformation story

**System Performance (Mock Data):**
- [ ] View load time < 300ms
- [ ] Navigation transitions < 200ms
- [ ] Animations run at 60fps
- [ ] Zero crashes during demo
- [ ] Dark mode works correctly

**Calm Intelligence Checklist:**
- [ ] Colors are soft (not harsh): #FF6B6B, #4A90E2, #95A5A6
- [ ] Spacing is generous (not cramped): 16-20pt padding
- [ ] Animations are slow (300-400ms spring)
- [ ] Empty states are supportive (not stark): "All caught up! 🎉"
- [ ] Reasoning is transparent (not black-box): "Why?" buttons show signals
- [ ] Tone is humble ("I think" not "This is"): First-person AI voice

**Quality:**
- [ ] 0 blocking bugs preventing demo
- [ ] All acceptance gates pass (see section 12)
- [ ] No linter errors
- [ ] No force-unwrapped optionals causing crashes
- [ ] All views compatible with iPhone 13+ screen sizes

**Stakeholder Feedback:**
- [ ] Collect feedback on Calm Intelligence UX
- [ ] Note any confusion points for iteration
- [ ] Gauge interest in funding next phase

---

## 🎯 Why This Matters

**From AI Product Vision:**
> "Users spend LESS time in app but feel MORE in control."

These 4 views are **the demo** of Calm Intelligence:
1. **PriorityInboxView** = Impossible Prioritization solved
2. **ActionItemsView** = Overwhelming Re-entry solved  
3. **SmartSearchView** = Information buried → instantly found
4. **DecisionHistoryView** = Digital FOMO eliminated

**Maya's transformation:**
- Before: 200 messages, 20 min overwhelmed
- After: 2 urgent, 6 can wait → 2 min in control

**This is what we're building tonight.** 🚀

---

## 16. Definition of Done (Tonight)

### Code Quality
- [ ] All 4 ViewModels created with `@MainActor` and `@Published` properties
- [ ] All 4 Views created with SwiftUI best practices
- [ ] Mock service protocols defined (ready for Firebase swap)
- [ ] No force-unwrapped optionals (`!`) in production code
- [ ] No hardcoded magic numbers (use named constants)
- [ ] Proper Swift types (no `Any` or untyped dictionaries)
- [ ] Functions have explicit parameter and return types

### UI/UX Standards
- [ ] Follows Calm Intelligence color palette (#FF6B6B, #4A90E2, #95A5A6, #2ECC71)
- [ ] Animations use 300-400ms spring (response: 0.35, damping: 0.8)
- [ ] Spacing consistent (16-20pt padding, 16pt card spacing)
- [ ] Typography follows standards (.title2 headers, .body text, .caption meta)
- [ ] Dark mode tested and working
- [ ] All views support iPhone 13+ screen sizes

### Navigation & Integration
- [ ] ProfileView navigation links added (Priority Inbox, Decision History)
- [ ] ConversationListView toolbar button added (Action Items)
- [ ] Search integration added or enhanced
- [ ] Tapping messages opens source conversation correctly
- [ ] All sheets/modals dismiss properly

### Demo Readiness
- [ ] Complete demo script runs in < 2 minutes
- [ ] All 6 checkpoints verified (see Demo Script section)
- [ ] Screenshots captured for documentation
- [ ] No crashes during full walkthrough
- [ ] Practiced demo 3x successfully

### Testing (Smoke Tests Only Tonight)
- [ ] App builds without errors
- [ ] All new views load correctly
- [ ] Navigation doesn't break existing features
- [ ] Dark mode works
- [ ] No console errors or warnings

**Deferred to Production PR:**
- Full unit test coverage (Swift Testing)
- Full UI test coverage (XCTest)
- Performance benchmarking
- Error handling
- Firebase integration

---

## 17. Post-Demo: Production Requirements

**Immediate Next Steps:**
1. Firebase integration (real Cloud Functions)
2. Full test coverage (80%+ target)
3. PR-AI-005 error handling implementation
4. Performance optimization for production scale

**Future Enhancements:** Real-time sync, offline support, customization rules, notifications, Apple Reminders integration

**Open Questions for Production:** Priority Inbox as default screen? Refresh frequency? Privacy settings for Slack integration?

See separate production PRD for detailed requirements.

---

## Quick Start Commands

```bash
# Create the files
touch MessageAI/MessageAI/Views/AI/PriorityInboxView.swift
touch MessageAI/MessageAI/ViewModels/AI/PriorityInboxViewModel.swift
touch MessageAI/MessageAI/Views/AI/ActionItemsView.swift
touch MessageAI/MessageAI/ViewModels/AI/ActionItemsViewModel.swift
touch MessageAI/MessageAI/Views/AI/DecisionHistoryView.swift
touch MessageAI/MessageAI/ViewModels/AI/DecisionHistoryViewModel.swift
touch MessageAI/MessageAI/Views/AI/SmartSearchView.swift
touch MessageAI/MessageAI/ViewModels/AI/SmartSearchViewModel.swift

# Add to Xcode project (do manually in Xcode)
```

---

**Status:** Ready to build  
**Time Estimate:** 3-4 hours  
**Priority:** 🔴 URGENT - Demo tonight  
**Dependencies:** None (all backend ready)  

**Let's ship this!** 🎉

