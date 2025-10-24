# PR Brief: Priority Inbox View

**For Agent:** Cody (Implementation)  
**Created by:** Brad (PR Brief Builder)  
**Date:** October 24, 2025  
**Source PRD:** [Tonight's UI Demo PRD](./pr-tonight-ui-demo.md) - Priority 1  
**Part of:** 4-view AI demo (PriorityInbox, ActionItems, DecisionHistory, SmartSearch)

---

## PR #AI-INBOX-001: Priority Inbox with AI Categorization

### Quick Brief

Build a Priority Inbox view with AI-categorized messages:

- **3 Sections:** Urgent (2-3), Can Wait (5-8), AI Handled (10-15) - collapsible with badges
- **Message Cards:** Avatar, name, preview, timestamp, "Why?" info button
- **Transparency Modal:** Shows AI reasoning with confidence levels, signals, evidence
- **Interactions:** Tap to open conversation, swipe to recategorize, pull to refresh
- **Design:** Calm Intelligence palette (#FF6B6B, #4A90E2, #95A5A6), 300ms spring animations
- **Implementation:** Mock data with 15-20 hardcoded messages, protocol-based for future Firebase swap
- **Empty State:** Supportive "All caught up! 🎉" when inbox clear

### Implementation Scope

**Dependencies:** None (mock data only)

**Complexity:** Medium (45-60 minutes)
- 2 new files (PriorityInboxView + ViewModel)
- 1 modification (ProfileView navigation link)
- 1 reusable component (ReasoningModal)
- Mock service protocol ready for Firebase

**Phase:** Demo/MVP  
**Priority:** 🔴 HIGH - Hero feature showing main value prop

---

## What You're Building

This is **the hero feature** - shows Maya going from 200 messages → 2 urgent in seconds. The "Why?" transparency modal demonstrates Calm Intelligence: AI explains itself humbly, not mysteriously.

---

## Technical Scope

### New Files to Create
1. **Views/AI/PriorityInboxView.swift**
   - 3 collapsible sections with badge counts
   - Message cards with tap/swipe interactions
   - Pull to refresh functionality
   - Empty state view

2. **ViewModels/AI/PriorityInboxViewModel.swift**
   - Mock data array with 15-20 categorized messages
   - Message recategorization logic
   - Section grouping and filtering
   - Refresh simulation

3. **Components/AI/ReasoningModal.swift** (reusable)
   - Transparency modal for AI explanations
   - Shows confidence badge, signals, evidence
   - Dismissible sheet presentation

### Files to Modify
- **Views/Profile/ProfileView.swift** - Add NavigationLink to Priority Inbox

---

## Mock Data Examples

### Urgent Messages (2-3)
```swift
"Production API down - need your help ASAP" (from CTO)
"Can you review the Q4 roadmap by tomorrow?" (@mentions, deadline)
"Client meeting moved to 2pm today" (schedule change, today)
```

### Can Wait Messages (5-8)
```swift
"Updated the docs, take a look when you can" (no urgency)
"FYI - Design team meeting notes" (informational)
"Thoughts on the new mockups?" (open-ended question)
"Shared the analytics report in Drive" (FYI)
```

### AI Handled Messages (10-15)
```swift
"Thanks!" (acknowledgment)
"👍" (emoji reaction)
"Got it, will do" (simple confirmation)
"Sounds good!" (agreement)
"Perfect, thanks for the update" (acknowledgment)
```

---

## UI Requirements

### Main View
- **3 Sections** with expandable/collapsible headers
  - 🔴 Urgent - Expanded by default, red badge
  - 🔵 Can Wait - Collapsed, blue badge
  - ⚪ AI Handled - Collapsed, gray badge

- **Message Cards** display:
  - Circular avatar (40pt) with sender initials fallback
  - Sender name (bold, .body font)
  - Message preview (1-2 lines, gray)
  - Timestamp (relative: "2h ago" or absolute: "Oct 23, 3:45 PM")
  - "Why?" info icon button (subtle, right side)

### Reasoning Modal (Tap "Why?")
- **Header:** "Why [Category]?"
- **Explanation:** AI reasoning text
- **Confidence Badge:** High/Moderate/Uncertain with color
- **Signals Detected:** Tag list (["@mentioned you", "deadline tomorrow"])
- **Evidence:** "View message" link (opens conversation)
- **Dismiss:** Swipe down or close button

### Interactions
- **Tap message** → Open conversation at that message
- **Tap "Why?"** → Show reasoning modal
- **Swipe message** → Manual recategorize (Urgent ↔ Can Wait)
- **Pull to refresh** → Reload inbox (simulated delay)
- **Tap section header** → Expand/collapse section

### Empty State
- Green checkmark icon
- "All caught up! 🎉"
- "No messages need your attention right now"
- Calm, celebratory tone

---

## Design Standards (Calm Intelligence)

### Colors
```swift
// Category colors
let urgentColor = Color(hex: "#FF6B6B")     // Soft red
let canWaitColor = Color(hex: "#4A90E2")    // Calm blue
let aiHandledColor = Color(hex: "#95A5A6")  // Muted gray
let successColor = Color(hex: "#2ECC71")    // Calm green

// Confidence badges
let highConfidence = Color.green.opacity(0.7)
let moderateConfidence = Color.orange.opacity(0.7)
let uncertainConfidence = Color.gray.opacity(0.7)
```

### Spacing
```swift
VStack(spacing: 16) {  // Between cards
    // Card content
}
.padding(20)  // Screen edges
.padding(.vertical, 12)  // Card internal padding
```

### Animations
```swift
.animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
.transition(.move(edge: .top).combined(with: .opacity))
```

### Typography
```swift
.font(.title2).bold()  // Section headers
.font(.body)  // Sender name, message text
.font(.caption).foregroundColor(.secondary)  // Timestamp, meta info
```

---

## Data Models

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
    // Note: Use reasoning.evidenceMessageID to link to source message
}

enum MessageCategory: String, CaseIterable {
    case urgent = "Urgent"
    case canWait = "Can Wait"
    case aiHandled = "AI Handled"
    
    var color: Color {
        switch self {
        case .urgent: return Color(hex: "#FF6B6B")
        case .canWait: return Color(hex: "#4A90E2")
        case .aiHandled: return Color(hex: "#95A5A6")
        }
    }
    
    var icon: String {
        switch self {
        case .urgent: return "exclamationmark.circle.fill"
        case .canWait: return "clock.circle.fill"
        case .aiHandled: return "checkmark.circle.fill"
        }
    }
}

struct PriorityReasoning {
    let explanation: String
    let confidence: ConfidenceLevel
    let signals: [String]
    let evidenceMessageID: String
}

enum ConfidenceLevel: String {
    case high = "High"
    case moderate = "Moderate"
    case uncertain = "Uncertain"
    
    var color: Color {
        switch self {
        case .high: return Color.green.opacity(0.7)
        case .moderate: return Color.orange.opacity(0.7)
        case .uncertain: return Color.gray.opacity(0.7)
        }
    }
}
```

---

## Mock Service Protocol

```swift
protocol PriorityInboxService {
    /// Fetch categorized messages (mock returns hardcoded array)
    func fetchInbox() async throws -> [PriorityInboxItem]
    
    /// Manually recategorize a message (mock updates local array)
    func recategorizeMessage(messageID: String, newCategory: MessageCategory) async throws
    
    /// Refresh inbox (mock re-sorts existing data with simulated delay)
    func refreshInbox() async throws -> [PriorityInboxItem]
}

// Mock implementation for tonight
class MockPriorityInboxService: PriorityInboxService {
    private var items: [PriorityInboxItem] = MockData.priorityInboxItems
    
    func fetchInbox() async throws -> [PriorityInboxItem] {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
        return items
    }
    
    func recategorizeMessage(messageID: String, newCategory: MessageCategory) async throws {
        if let index = items.firstIndex(where: { $0.id == messageID }) {
            items[index] = PriorityInboxItem(
                id: items[index].id,
                senderName: items[index].senderName,
                senderAvatarURL: items[index].senderAvatarURL,
                messagePreview: items[index].messagePreview,
                timestamp: items[index].timestamp,
                category: newCategory,
                reasoning: items[index].reasoning,
                sourceConversationID: items[index].sourceConversationID
            )
        }
    }
    
    func refreshInbox() async throws -> [PriorityInboxItem] {
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1s delay
        return items
    }
}
```

---

## Mock Data Implementation

Create this in your ViewModel or separate MockData file:

```swift
struct MockData {
    static let priorityInboxItems: [PriorityInboxItem] = [
        // URGENT (2-3 messages)
        PriorityInboxItem(
            id: "msg-urgent-1",
            senderName: "Sarah Chen (CTO)",
            senderAvatarURL: nil,
            messagePreview: "Production API down - need your help ASAP",
            timestamp: Date().addingTimeInterval(-7200), // 2h ago
            category: .urgent,
            reasoning: PriorityReasoning(
                explanation: "Critical production issue requiring immediate attention from engineering leadership",
                confidence: .high,
                signals: ["production", "ASAP", "from CTO", "outage", "need help"],
                evidenceMessageID: "msg-urgent-1"
            ),
            sourceConversationID: "conv-eng"
        ),
        PriorityInboxItem(
            id: "msg-urgent-2",
            senderName: "Jamie Parker",
            senderAvatarURL: nil,
            messagePreview: "Can you review the Q4 roadmap by tomorrow? @Maya",
            timestamp: Date().addingTimeInterval(-14400), // 4h ago
            category: .urgent,
            reasoning: PriorityReasoning(
                explanation: "You're mentioned by name with a specific deadline tomorrow",
                confidence: .high,
                signals: ["@mentioned you", "deadline tomorrow", "review request"],
                evidenceMessageID: "msg-urgent-2"
            ),
            sourceConversationID: "conv-product"
        ),
        
        // CAN WAIT (5-8 messages)
        PriorityInboxItem(
            id: "msg-wait-1",
            senderName: "Alex Thompson",
            senderAvatarURL: nil,
            messagePreview: "Updated the docs, take a look when you can",
            timestamp: Date().addingTimeInterval(-21600), // 6h ago
            category: .canWait,
            reasoning: PriorityReasoning(
                explanation: "Informational update with no urgency or deadline",
                confidence: .moderate,
                signals: ["when you can", "FYI", "no deadline"],
                evidenceMessageID: "msg-wait-1"
            ),
            sourceConversationID: "conv-docs"
        ),
        PriorityInboxItem(
            id: "msg-wait-2",
            senderName: "Design Team",
            senderAvatarURL: nil,
            messagePreview: "FYI - Design team meeting notes from today",
            timestamp: Date().addingTimeInterval(-28800), // 8h ago
            category: .canWait,
            reasoning: PriorityReasoning(
                explanation: "Meeting notes for your reference, no action required",
                confidence: .high,
                signals: ["FYI", "meeting notes", "informational"],
                evidenceMessageID: "msg-wait-2"
            ),
            sourceConversationID: "conv-design"
        ),
        PriorityInboxItem(
            id: "msg-wait-3",
            senderName: "Chris Lee",
            senderAvatarURL: nil,
            messagePreview: "Thoughts on the new mockups?",
            timestamp: Date().addingTimeInterval(-43200), // 12h ago
            category: .canWait,
            reasoning: PriorityReasoning(
                explanation: "Open-ended question with no deadline",
                confidence: .moderate,
                signals: ["thoughts?", "open question", "no urgency"],
                evidenceMessageID: "msg-wait-3"
            ),
            sourceConversationID: "conv-design"
        ),
        PriorityInboxItem(
            id: "msg-wait-4",
            senderName: "Analytics Bot",
            senderAvatarURL: nil,
            messagePreview: "Shared the weekly analytics report in Drive",
            timestamp: Date().addingTimeInterval(-57600), // 16h ago
            category: .canWait,
            reasoning: PriorityReasoning(
                explanation: "Automated report shared for reference",
                confidence: .high,
                signals: ["shared", "report", "automated"],
                evidenceMessageID: "msg-wait-4"
            ),
            sourceConversationID: "conv-analytics"
        ),
        
        // AI HANDLED (10-15 messages)
        PriorityInboxItem(
            id: "msg-handled-1",
            senderName: "Taylor Swift",
            senderAvatarURL: nil,
            messagePreview: "Thanks!",
            timestamp: Date().addingTimeInterval(-3600), // 1h ago
            category: .aiHandled,
            reasoning: PriorityReasoning(
                explanation: "Simple acknowledgment requiring no response",
                confidence: .high,
                signals: ["thanks", "acknowledgment", "no action"],
                evidenceMessageID: "msg-handled-1"
            ),
            sourceConversationID: "conv-random"
        ),
        PriorityInboxItem(
            id: "msg-handled-2",
            senderName: "Jordan Blake",
            senderAvatarURL: nil,
            messagePreview: "👍",
            timestamp: Date().addingTimeInterval(-5400), // 1.5h ago
            category: .aiHandled,
            reasoning: PriorityReasoning(
                explanation: "Emoji reaction, no response needed",
                confidence: .high,
                signals: ["emoji only", "reaction", "acknowledgment"],
                evidenceMessageID: "msg-handled-2"
            ),
            sourceConversationID: "conv-random"
        ),
        PriorityInboxItem(
            id: "msg-handled-3",
            senderName: "Sam Rivera",
            senderAvatarURL: nil,
            messagePreview: "Got it, will do",
            timestamp: Date().addingTimeInterval(-10800), // 3h ago
            category: .aiHandled,
            reasoning: PriorityReasoning(
                explanation: "Confirmation message, no follow-up needed",
                confidence: .high,
                signals: ["got it", "will do", "confirmation"],
                evidenceMessageID: "msg-handled-3"
            ),
            sourceConversationID: "conv-tasks"
        ),
        PriorityInboxItem(
            id: "msg-handled-4",
            senderName: "Morgan Kim",
            senderAvatarURL: nil,
            messagePreview: "Sounds good!",
            timestamp: Date().addingTimeInterval(-18000), // 5h ago
            category: .aiHandled,
            reasoning: PriorityReasoning(
                explanation: "Agreement statement, conversation concluded",
                confidence: .high,
                signals: ["sounds good", "agreement", "no action"],
                evidenceMessageID: "msg-handled-4"
            ),
            sourceConversationID: "conv-planning"
        ),
        PriorityInboxItem(
            id: "msg-handled-5",
            senderName: "Casey Moore",
            senderAvatarURL: nil,
            messagePreview: "Perfect, thanks for the update",
            timestamp: Date().addingTimeInterval(-25200), // 7h ago
            category: .aiHandled,
            reasoning: PriorityReasoning(
                explanation: "Acknowledgment of update, no response needed",
                confidence: .high,
                signals: ["perfect", "thanks", "acknowledgment"],
                evidenceMessageID: "msg-handled-5"
            ),
            sourceConversationID: "conv-updates"
        )
    ]
}
```

**Tip:** Add more AI Handled messages (5-10 more) for realistic demo. Use variations of "ok", "👌", "sure", "thanks!", etc.

---

## Acceptance Gates & Definition of Done

### Functional Requirements
- [ ] 3 sections display with correct badge counts (Urgent: 2-3, Can Wait: 5-8, AI Handled: 10-15)
- [ ] Reasoning modal shows confidence, signals, and evidence on tap "Why?"
- [ ] Tap message opens conversation at correct location
- [ ] Swipe to recategorize works (Urgent ↔ Can Wait)
- [ ] Pull to refresh works with loading indicator (0.5s delay)
- [ ] Empty state displays when no messages ("All caught up! 🎉")
- [ ] Navigation from ProfileView works

### UI/UX Requirements
- [ ] Colors match Calm Intelligence palette (#FF6B6B, #4A90E2, #95A5A6)
- [ ] Animations smooth (60fps, 300-400ms spring)
- [ ] UI looks calm and spacious (16-20pt padding)
- [ ] Dark mode works correctly
- [ ] Message cards show: avatar, name, preview, timestamp, "Why?" button
- [ ] Section headers collapsible with tap

### Code Quality
- [ ] ViewModel uses `@MainActor` and `@Published` properties
- [ ] No force-unwrapped optionals
- [ ] No crashes on interaction
- [ ] Builds without errors or warnings
- [ ] Protocol-based service (ready for Firebase swap)

### Nice to Have (if time)
- [ ] Haptic feedback on recategorize
- [ ] Badge animation on category change

---

## ViewModel Pattern (Use This)

```swift
@MainActor
class PriorityInboxViewModel: ObservableObject {
    @Published var items: [PriorityInboxItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let service: PriorityInboxService
    
    init(service: PriorityInboxService = MockPriorityInboxService()) {
        self.service = service
    }
    
    // Group items by category
    var urgentMessages: [PriorityInboxItem] {
        items.filter { $0.category == .urgent }
    }
    
    var canWaitMessages: [PriorityInboxItem] {
        items.filter { $0.category == .canWait }
    }
    
    var aiHandledMessages: [PriorityInboxItem] {
        items.filter { $0.category == .aiHandled }
    }
    
    func loadInbox() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await service.fetchInbox()
        } catch {
            self.error = error
        }
    }
    
    func recategorize(messageID: String, to category: MessageCategory) async {
        do {
            try await service.recategorizeMessage(messageID: messageID, newCategory: category)
            await loadInbox() // Refresh
        } catch {
            self.error = error
        }
    }
    
    func refresh() async {
        do {
            items = try await service.refreshInbox()
        } catch {
            self.error = error
        }
    }
}
```

---

## Testing Strategy

**Tonight:** Manual smoke testing only
- Build and run without errors
- Navigate from Profile → Priority Inbox
- Test all interactions (tap, swipe, pull-to-refresh)
- Verify dark mode
- Check animations feel calm

**Tomorrow (Add in Next PR):** 
- Unit tests: `MessageAITests/ViewModels/AI/PriorityInboxViewModelTests.swift` (Swift Testing)
- UI tests: `MessageAIUITests/AI/PriorityInboxUITests.swift` (XCTest)
- Coverage target: 80%+

See `MessageAI/agents/shared-standards.md` for testing patterns.

---

## Git Workflow

**Base Branch:** `develop`  
**Feature Branch:** `feat/pr-ai-inbox-001-priority-inbox`  
**PR Target:** `develop` (NOT `main`)  

**Commit Pattern:**
```bash
git checkout develop
git pull origin develop
git checkout -b feat/pr-ai-inbox-001-priority-inbox

# After implementation
git add .
git commit -m "feat(ai-inbox): add priority inbox view with mock data

- Create PriorityInboxView with 3 collapsible sections
- Add PriorityInboxViewModel with mock service
- Implement reasoning modal for AI transparency
- Add navigation link from ProfileView
- Include 15+ mock messages with realistic categorization"

git push origin feat/pr-ai-inbox-001-priority-inbox
```

**PR Title:** `[AI-INBOX-001] Priority Inbox with AI Categorization`

---

## Why This Matters (Context for Cody)

This is **the hero feature** - the main value prop of MessageAI.

**Before:** Maya has 200 messages, spends 20 min overwhelmed trying to prioritize  
**After:** Opens app → sees 2 urgent, 6 can wait → in control in 2 minutes

The "Why?" transparency modal is critical - it proves our Calm Intelligence principle: **AI should explain itself humbly, not dictate mysteriously.**

This is what sells the vision to stakeholders tonight. Make it shine! ✨

---

## Future Production Path

**After Demo (Separate PRs):**
1. **Firebase Integration** - Replace MockPriorityInboxService with real Cloud Functions
2. **Real-time Updates** - Firestore listeners for live inbox changes  
3. **Full Test Coverage** - Unit tests (80%+), UI tests
4. **Offline Support** - Cache categorizations locally
5. **Custom Rules** - User-defined priority rules
6. **Notifications** - Push alerts for urgent messages

---

**Ready to Build?** You have everything you need! 🚀  
**Estimated Time:** 45-60 minutes  
**Questions?** Check parent PRD: [pr-tonight-ui-demo.md](./pr-tonight-ui-demo.md)

