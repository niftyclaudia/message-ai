# PR Brief: Action Items View

**For Agent:** Cody (Implementation)  
**Created by:** Brad (PR Brief Builder)  
**Date:** October 24, 2025  
**Source PRD:** [Tonight's UI Demo PRD](./pr-tonight-ui-demo.md) - Priority 2  
**Part of:** 4-view AI demo (PriorityInbox, ActionItems, DecisionHistory, SmartSearch)

---

## PR #AI-TASKS-001: Action Items Extraction View

### Quick Brief

Build an Action Items view showing AI-extracted tasks from conversations:

- **Access:** Toolbar button (checklist icon) in ConversationListView → sheet modal
- **3 Sections:** Today (1-2 tasks), This Week (2-3 tasks), Later (2-3 tasks)
- **Task Cards:** Checkbox with smooth animation, task text, source ("From [Person] in [Chat]"), deadline badge, info button
- **Completion:** Tap checkbox → satisfying checkmark + fade out (300ms)
- **Transparency:** Info button shows extraction reasoning with signals, source excerpt
- **Navigation:** Tap task → opens source conversation at that message
- **Design:** Calm Intelligence - max 8 tasks, soft colors, no "OVERDUE" panic text
- **Empty State:** Green checkmark, "All caught up! 🎉", supportive message
- **Implementation:** Mock data with 7-8 hardcoded tasks, protocol-based for future Firebase

### Implementation Scope

**Dependencies:** None (mock data only)

**Complexity:** Simple (30-45 minutes)
- 2 new files (ActionItemsView + ViewModel)
- 1 modification (ConversationListView toolbar + sheet)
- Mock service protocol ready for Firebase

**Phase:** Demo/MVP  
**Priority:** 🟡 HIGH - Shows AI task extraction value

---

## What You're Building

This solves **Overwhelming Re-entry** - when Maya returns after focus time, she sees 2 tasks for today (not 200 messages). The AI does cognitive work for her, extracting actionable tasks from natural conversation.

---

## Technical Scope

### New Files to Create
1. **Views/AI/ActionItemsView.swift**
   - Sheet modal presentation
   - 3 urgency sections with badges
   - Task cards with checkboxes
   - Completion animations
   - Empty state view

2. **ViewModels/AI/ActionItemsViewModel.swift**
   - Mock data array with 7-8 tasks
   - Task completion logic
   - Section grouping by urgency
   - Filter pending/completed tasks

### Files to Modify
- **Views/ConversationListView.swift** - Add toolbar button and sheet presentation

---

## Mock Data Examples

### Today (1-2 tasks)
```swift
ActionItem(
    text: "Review Q4 roadmap",
    fromPerson: "Jamie",
    chatName: "#product-team",
    deadline: Date().addingTimeInterval(3600 * 4), // 4 hours
    urgency: .today,
    signals: ["mentioned you", "by end of day", "need your input"]
)

ActionItem(
    text: "Approve $15K marketing budget",
    fromPerson: "Chris",
    chatName: "Marketing Budget",
    deadline: Date().addingTimeInterval(3600 * 6),
    urgency: .today,
    signals: ["@you", "approval needed", "urgent"]
)
```

### This Week (2-3 tasks)
```swift
ActionItem(
    text: "Update API documentation",
    fromPerson: "Dave",
    chatName: "#engineering",
    deadline: Date().addingTimeInterval(86400 * 2), // 2 days
    urgency: .thisWeek,
    signals: ["I'll need you to", "by Friday"]
)

ActionItem(
    text: "Schedule 1:1 with new hire",
    fromPerson: "Alice",
    chatName: "Team",
    deadline: Date().addingTimeInterval(86400 * 3),
    urgency: .thisWeek,
    signals: ["can you", "this week"]
)
```

### Later (2-3 tasks)
```swift
ActionItem(
    text: "Research competitor pricing",
    fromPerson: "Jamie",
    chatName: "#strategy",
    deadline: nil,
    urgency: .later,
    signals: ["would be great if", "when you have time"]
)

ActionItem(
    text: "Plan team offsite",
    fromPerson: "Sarah",
    chatName: "Team",
    deadline: Date().addingTimeInterval(86400 * 30), // ~1 month
    urgency: .later,
    signals: ["eventually", "next month"]
)
```

---

## UI Requirements

### Sheet Modal
- **Presentation:** Slides up from bottom
- **Height:** .medium detent (60% screen height)
- **Dismissible:** Swipe down or tap outside
- **Header:** "Action Items" title with close button

### Section Headers
- **3 Sections** with urgency badges:
  - 📅 Today - Red badge, count
  - 📆 This Week - Orange badge, count
  - 📋 Later - Blue badge, count

### Task Cards
- **Checkbox** (left side)
  - ☐ Unchecked (tap to complete)
  - ✓ Checked (animated checkmark)
  - Fade out animation on completion (300ms)

- **Content:**
  - Task text (bold, .body font)
  - "From [Person] in [Chat Name]" (gray, .caption)
  - Deadline badge if exists ("Due Today", "Due Friday")
  - Info button (transparency reasoning)

- **Tap Behavior:**
  - Tap checkbox → Complete task (animation)
  - Tap card body → Open source conversation
  - Tap info button → Show reasoning modal

### Transparency Modal
- **Header:** "How I found this task"
- **Reasoning:** Explanation text
- **Signals:** Tag list of detected keywords
- **Source Excerpt:** Message preview with highlighted keywords
- **Confidence:** Badge (High/Moderate)
- **Action:** "View conversation" link

### Empty State
- Green checkmark icon (large)
- "All caught up! 🎉"
- "No action items right now"
- Calm, celebratory tone (not stark)

---

## Design Standards (Calm Intelligence)

### Colors
```swift
// Urgency colors
let todayColor = Color(hex: "#FF6B6B")       // Red (urgent)
let thisWeekColor = Color(hex: "#FFA500")    // Orange (moderate)
let laterColor = Color(hex: "#4A90E2")       // Blue (calm)
let successColor = Color(hex: "#2ECC71")     // Green (complete)

// Checkbox states
let uncheckedBorder = Color.gray.opacity(0.5)
let checkedFill = Color(hex: "#2ECC71")
```

### Animations
```swift
// Checkbox tap
.scaleEffect(isCompleted ? 1.2 : 1.0)
.animation(.spring(response: 0.2, dampingFraction: 0.6), value: isCompleted)

// Card completion fade
.opacity(isCompleted ? 0 : 1)
.animation(.easeOut(duration: 0.3), value: isCompleted)

// Checkmark appear
.scaleEffect(isCompleted ? 1.0 : 0.5)
.opacity(isCompleted ? 1 : 0)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
```

### Spacing
```swift
VStack(spacing: 12) {  // Between task cards
    // Task content
}
.padding(.horizontal, 20)
.padding(.vertical, 16)
```

---

## Data Models

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
    
    var color: Color {
        switch self {
        case .today: return Color(hex: "#FF6B6B")
        case .thisWeek: return Color(hex: "#FFA500")
        case .later: return Color(hex: "#4A90E2")
        }
    }
    
    var icon: String {
        switch self {
        case .today: return "calendar.badge.exclamationmark"
        case .thisWeek: return "calendar"
        case .later: return "calendar.badge.clock"
        }
    }
}

struct ExtractionReasoning {
    let explanation: String
    let signals: [String]
    let sourceExcerpt: String
    let confidence: ConfidenceLevel
}

enum ConfidenceLevel: String {
    case high = "High"
    case moderate = "Moderate"
    case uncertain = "Uncertain"
}
```

---

## Mock Service Protocol

```swift
protocol ActionItemService {
    /// Fetch all action items grouped by urgency (mock returns 7-8 tasks)
    func fetchActionItems() async throws -> [ActionItem]
    
    /// Mark action item as complete (mock updates isCompleted flag)
    func completeActionItem(id: String) async throws
    
    /// Fetch action items filtered by urgency
    func fetchActionItems(urgency: ActionItemUrgency) async throws -> [ActionItem]
}

// Mock implementation
class MockActionItemService: ActionItemService {
    private var items: [ActionItem] = MockData.actionItems
    
    func fetchActionItems() async throws -> [ActionItem] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3s delay
        return items.filter { !$0.isCompleted }
    }
    
    func completeActionItem(id: String) async throws {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isCompleted = true
        }
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s delay
    }
    
    func fetchActionItems(urgency: ActionItemUrgency) async throws -> [ActionItem] {
        return items.filter { $0.urgency == urgency && !$0.isCompleted }
    }
}
```

---

## Mock Data Implementation

Create this in your ViewModel or separate MockData file:

```swift
struct MockData {
    static let actionItems: [ActionItem] = [
        // TODAY (1-2 tasks) - Red badge
        ActionItem(
            id: "task-today-1",
            text: "Review Q4 roadmap",
            fromPerson: "Jamie",
            chatName: "#product-team",
            deadline: Date().addingTimeInterval(3600 * 4), // 4 hours from now
            urgency: .today,
            sourceMessageID: "msg-roadmap",
            sourceConversationID: "conv-product",
            extractionReasoning: ExtractionReasoning(
                explanation: "Task detected with explicit deadline and direct mention",
                signals: ["mentioned you", "by end of day", "need your input"],
                sourceExcerpt: "Hey @Maya, can you review the Q4 roadmap by end of day? Need your input on the timeline.",
                confidence: .high
            ),
            isCompleted: false
        ),
        ActionItem(
            id: "task-today-2",
            text: "Approve $15K marketing budget",
            fromPerson: "Chris",
            chatName: "Marketing Budget",
            deadline: Date().addingTimeInterval(3600 * 6), // 6 hours from now
            urgency: .today,
            sourceMessageID: "msg-budget",
            sourceConversationID: "conv-marketing",
            extractionReasoning: ExtractionReasoning(
                explanation: "Approval needed with urgency indicated",
                signals: ["@you", "approval needed", "urgent", "today"],
                sourceExcerpt: "@Maya - urgent: need your approval on the $15K marketing budget for Q4 by today.",
                confidence: .high
            ),
            isCompleted: false
        ),
        
        // THIS WEEK (2-3 tasks) - Orange badge
        ActionItem(
            id: "task-week-1",
            text: "Update API documentation",
            fromPerson: "Dave",
            chatName: "#engineering",
            deadline: Date().addingTimeInterval(86400 * 2), // 2 days from now
            urgency: .thisWeek,
            sourceMessageID: "msg-docs",
            sourceConversationID: "conv-eng",
            extractionReasoning: ExtractionReasoning(
                explanation: "Task with specific deadline this week",
                signals: ["I'll need you to", "by Friday", "documentation"],
                sourceExcerpt: "Dave: I'll need you to update the API docs by Friday for the launch.",
                confidence: .high
            ),
            isCompleted: false
        ),
        ActionItem(
            id: "task-week-2",
            text: "Schedule 1:1 with new hire",
            fromPerson: "Alice",
            chatName: "Team",
            deadline: Date().addingTimeInterval(86400 * 3), // 3 days from now
            urgency: .thisWeek,
            sourceMessageID: "msg-onboarding",
            sourceConversationID: "conv-team",
            extractionReasoning: ExtractionReasoning(
                explanation: "Scheduling request with this week timeframe",
                signals: ["can you", "this week", "schedule"],
                sourceExcerpt: "Alice: Can you schedule a 1:1 with Sarah (new hire) this week? She needs mentorship on the codebase.",
                confidence: .moderate
            ),
            isCompleted: false
        ),
        ActionItem(
            id: "task-week-3",
            text: "Prepare slides for team standup",
            fromPerson: "Jordan",
            chatName: "#product-team",
            deadline: Date().addingTimeInterval(86400 * 4), // 4 days from now
            urgency: .thisWeek,
            sourceMessageID: "msg-standup",
            sourceConversationID: "conv-product",
            extractionReasoning: ExtractionReasoning(
                explanation: "Presentation task with upcoming meeting",
                signals: ["would you mind", "Thursday standup", "slides"],
                sourceExcerpt: "Would you mind preparing a few slides on the roadmap for Thursday's standup?",
                confidence: .moderate
            ),
            isCompleted: false
        ),
        
        // LATER (2-3 tasks) - Blue badge
        ActionItem(
            id: "task-later-1",
            text: "Research competitor pricing",
            fromPerson: "Jamie",
            chatName: "#strategy",
            deadline: nil,
            urgency: .later,
            sourceMessageID: "msg-research",
            sourceConversationID: "conv-strategy",
            extractionReasoning: ExtractionReasoning(
                explanation: "Research task with no immediate deadline",
                signals: ["would be great if", "when you have time", "research"],
                sourceExcerpt: "Would be great if you could research competitor pricing when you have time. No rush.",
                confidence: .moderate
            ),
            isCompleted: false
        ),
        ActionItem(
            id: "task-later-2",
            text: "Plan team offsite",
            fromPerson: "Sarah",
            chatName: "Team",
            deadline: Date().addingTimeInterval(86400 * 30), // ~1 month from now
            urgency: .later,
            sourceMessageID: "msg-offsite",
            sourceConversationID: "conv-team",
            extractionReasoning: ExtractionReasoning(
                explanation: "Planning task with distant deadline",
                signals: ["eventually", "next month", "plan"],
                sourceExcerpt: "Sarah: We should plan a team offsite for next month. Can you take the lead on finding a venue?",
                confidence: .moderate
            ),
            isCompleted: false
        )
    ]
}
```

**Tip:** Add 1-2 more tasks for realism. Total should be 7-8 tasks across all urgency levels.

---

## ViewModel Structure

```swift
@MainActor
class ActionItemsViewModel: ObservableObject {
    @Published var items: [ActionItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let service: ActionItemService
    
    init(service: ActionItemService = MockActionItemService()) {
        self.service = service
    }
    
    var todayItems: [ActionItem] {
        items.filter { $0.urgency == .today && !$0.isCompleted }
    }
    
    var thisWeekItems: [ActionItem] {
        items.filter { $0.urgency == .thisWeek && !$0.isCompleted }
    }
    
    var laterItems: [ActionItem] {
        items.filter { $0.urgency == .later && !$0.isCompleted }
    }
    
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await service.fetchActionItems()
        } catch {
            self.error = error
        }
    }
    
    func completeItem(_ item: ActionItem) async {
        // Optimistic update
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].isCompleted = true
        }
        
        do {
            try await service.completeActionItem(id: item.id)
        } catch {
            // Rollback on error
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index].isCompleted = false
            }
            self.error = error
        }
    }
}
```

---

## Integration with ConversationListView

```swift
// Add to ConversationListView.swift

@State private var showActionItems = false

// In body:
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button {
            showActionItems = true
        } label: {
            Image(systemName: "checklist")
                .foregroundColor(.primary)
        }
    }
}
.sheet(isPresented: $showActionItems) {
    ActionItemsView()
}
```

---

## Acceptance Gates & Definition of Done

### Functional Requirements
- [ ] Toolbar button in ConversationListView launches sheet
- [ ] 3 sections display with correct urgency grouping (Today/This Week/Later)
- [ ] Task cards show all fields (text, source, deadline badge if exists)
- [ ] Checkboxes work with smooth completion animation
- [ ] Completed tasks fade out gracefully (300ms)
- [ ] Tap task opens source conversation at that message
- [ ] Info button shows transparency reasoning modal
- [ ] Empty state displays when all tasks complete ("All caught up! 🎉")
- [ ] Sheet dismisses correctly (swipe down or tap outside)

### UI/UX Requirements
- [ ] Colors match urgency levels (Red #FF6B6B, Orange #FFA500, Blue #4A90E2)
- [ ] Completion animation feels satisfying and calm (checkmark + fade)
- [ ] UI feels spacious (not cramped) - 12pt spacing between cards
- [ ] Dark mode compatible
- [ ] Transparency modal shows signals, source excerpt, confidence
- [ ] Max 8 tasks shown (not overwhelming)
- [ ] No aggressive "OVERDUE" panic text
- [ ] Empty state supportive and celebratory

### Code Quality
- [ ] ViewModel uses `@MainActor` and `@Published` properties
- [ ] No force-unwrapped optionals
- [ ] No crashes on interaction
- [ ] Builds without errors or warnings
- [ ] Protocol-based service (ready for Firebase swap)
- [ ] Optimistic UI update on completion (instant feedback)

### Nice to Have (if time)
- [ ] Haptic feedback on task completion
- [ ] Undo completion (tap completed checkbox again)
- [ ] Badge animation on count change

---

## Testing Strategy

**Tonight:** Manual smoke testing only
- Build and run without errors
- Launch sheet from ConversationListView toolbar
- Test all interactions (checkbox, tap task, info button)
- Verify completion animation feels satisfying
- Check dark mode
- Test empty state

**Tomorrow (Add in Next PR):**
- Unit tests: `MessageAITests/ViewModels/AI/ActionItemsViewModelTests.swift` (Swift Testing)
- UI tests: `MessageAIUITests/AI/ActionItemsUITests.swift` (XCTest)
- Coverage target: 80%+

See `MessageAI/agents/shared-standards.md` for testing patterns.

---

## Git Workflow

**Base Branch:** `develop`  
**Feature Branch:** `feat/pr-ai-tasks-001-action-items`  
**PR Target:** `develop` (NOT `main`)

**Commit Pattern:**
```bash
git checkout develop
git pull origin develop
git checkout -b feat/pr-ai-tasks-001-action-items

# After implementation
git add .
git commit -m "feat(ai-tasks): add action items view with completion

- Create ActionItemsView with 3 urgency sections
- Add ActionItemsViewModel with mock service
- Implement satisfying completion animation (checkmark + fade)
- Add transparency modal for extraction reasoning
- Add toolbar button in ConversationListView
- Include 7-8 mock tasks with realistic extraction"

git push origin feat/pr-ai-tasks-001-action-items
```

**PR Title:** `[AI-TASKS-001] Action Items Extraction View`

---

## Why This Matters (Context for Cody)

This solves **Overwhelming Re-entry** - Maya's breakthrough moment.

**Before:** Returns after 4-hour focus session → 200 messages → 20 min overwhelmed  
**After:** Returns → Opens Action Items sheet → Sees 2 tasks for today → In control in 30 seconds

**Key UX:** The completion animation is critical - checkmark + fade must feel **satisfying and calm**, not rushed or stressful. This is Calm Intelligence in action.

**Why it works:** AI extracts tasks from natural conversation ("can you review this by Friday?") without users needing to manually create tasks. This proves AI "gets it."

Make those checkmarks feel *chef's kiss* satisfying! ✨

---

## Future Production Path

**After Demo (Separate PRs):**
1. **Firebase Integration** - Real Cloud Functions for task extraction
2. **Real-time Updates** - Listen for new tasks from conversations
3. **Full Test Coverage** - Unit + UI tests (80%+)
4. **Apple Reminders Integration** - Sync with iOS Reminders app
5. **Custom Rules** - User-defined task patterns
6. **Snooze/Reschedule** - Defer tasks to later
7. **Subtasks** - Break down large tasks

---

**Ready to Build?** You have everything you need! 🚀  
**Estimated Time:** 30-45 minutes  
**Questions?** Check parent PRD: [pr-tonight-ui-demo.md](./pr-tonight-ui-demo.md)

