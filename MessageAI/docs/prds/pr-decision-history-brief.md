# PR Brief: Decision History View

**For Agent:** Cody (Implementation)  
**Created by:** Brad (PR Brief Builder)  
**Date:** October 24, 2025  
**Source PRD:** [Tonight's UI Demo PRD](./pr-tonight-ui-demo.md) - Priority 3  
**Part of:** 4-view AI demo (PriorityInbox, ActionItems, DecisionHistory, SmartSearch)

---

## PR #AI-DECISIONS-001: Decision History Timeline

### Quick Brief

Build a Decision History view showing AI-tracked team decisions in a timeline:

- **Access:** Profile tab → "Decision History" navigation link
- **Timeline:** Chronological cards (newest first) with decision text, participants, timestamp, chat context
- **Filters:** Segmented picker (Last Week / Last Month / All Time) at top
- **Search:** Natural language bar ("Find budget decisions...") 
- **Cards:** Show decision text, participant avatars (max 3 + count), confidence badge, tap to open source conversation
- **Transparency:** "Why?" button reveals detection reasoning, signals, participant agreement
- **Design:** Calm Intelligence - spacious layout, soft dividers, muted colors
- **Empty State:** Supportive "No major decisions tracked yet" message
- **Implementation:** Mock data with 5-6 hardcoded decisions, protocol-based for future Firebase

### Implementation Scope

**Dependencies:** None (mock data only)

**Complexity:** Medium (30-45 minutes)
- 2 new files (DecisionHistoryView + ViewModel)
- 1 modification (ProfileView navigation)
- Mock service protocol ready for Firebase

**Phase:** Demo/MVP  
**Priority:** 🟡 HIGH - Solves Digital FOMO problem

---

## What You're Building

This solves **Digital FOMO** - when Maya returns from vacation, she sees important decisions at a glance (not 500 messages). The AI tracks team consensus so she never misses critical context.

---

## Technical Scope

### New Files to Create
1. **Views/AI/DecisionHistoryView.swift**
   - Timeline layout with chronological ordering
   - Decision cards with participant info
   - Filter toolbar (Last Week/Month/All Time)
   - Search bar with natural language placeholder
   - Transparency modal for detection reasoning
   - Empty state view

2. **ViewModels/AI/DecisionHistoryViewModel.swift**
   - Mock data array with 5-6 decisions
   - Time-based filtering logic
   - Search/keyword matching
   - Decision grouping by date

### Files to Modify
- **Views/Profile/ProfileView.swift** - Add NavigationLink to Decision History

---

## Mock Data Examples

### Recent Decisions (Last Week)
```swift
// High confidence - 2 days ago
Decision(
    decisionText: "Decided to use Stripe for payments",
    participants: ["Jamie", "Chris"],
    chatContext: "#product-team",
    confidence: .high,
    signals: ["we've decided", "approved", "consensus"]
)

// High confidence - 5 days ago
Decision(
    decisionText: "Q4 launch postponed to January",
    participants: ["Jamie", "Dave", "Sarah"],
    chatContext: "#product-team",
    confidence: .high,
    signals: ["team decided", "postponing", "agreed to"]
)

// High confidence - 1 week ago
Decision(
    decisionText: "Hired Sarah as Senior Designer",
    participants: ["Alice", "Jamie"],
    chatContext: "Hiring",
    confidence: .high,
    signals: ["approved", "offer accepted", "joining"]
)
```

### Older Decisions (Last Month)
```swift
// Moderate confidence - 2 weeks ago
Decision(
    decisionText: "Switched to REST API instead of GraphQL",
    participants: ["Dave", "Engineering Team"],
    chatContext: "#engineering",
    confidence: .moderate,
    signals: ["decided to go with", "switching", "final choice"]
)

// High confidence - 2.5 weeks ago
Decision(
    decisionText: "Approved $50K marketing budget for Q4",
    participants: ["Jamie", "Chris"],
    chatContext: "Marketing Budget",
    confidence: .high,
    signals: ["approved", "$50K", "budget finalized"]
)
```

**Note:** Full Decision model includes `id`, `timestamp`, `chatID`, `sourceMessageID`, and `detectionSignals` array. See Data Models section below.

---

## UI Requirements

### Navigation
- **Entry Point:** Profile tab → "Decision History" NavigationLink
- **Header:** "Decision History" title with back button

### Filter Toolbar
- **3 Segmented Buttons:** Last Week (default) / Last Month / All Time
- **Style:** Rounded segmented picker, subtle gray background

### Search Bar
- **Placeholder:** "Find budget decisions..." (natural language hint)
- **Position:** Below filters, always visible
- **Behavior:** Real-time keyword filtering on decisionText
- **Clear Button:** Appears when typing

### Timeline Cards

Each decision card displays:

**Content:**
- Decision text (bold, `.title3`)
- Participant avatars (overlapping, max 3 + count badge if more)
- Participant names (comma-separated)
- Timestamp (relative: "2 days ago" or absolute: "Oct 22, 3:45 PM")
- Chat context badge ("From #product-team" - subtle gray)
- Confidence badge (High/Moderate - color-coded, right side)
- Soft divider below card

**Tap Behaviors:**
- Tap card body → Open source conversation at message
- Tap "Why?" button → Show transparency modal
- Tap avatar → (Future: participant profile)

### Transparency Modal

When user taps "Why?" on a decision card:

- **Header:** "How I detected this decision"
- **Detection Reasoning:** Explanation of why AI flagged this
- **Signals:** Tag cloud of keywords (e.g., "we've decided", "approved")
- **Participants:** List of who participated/agreed
- **Confidence Badge:** High/Moderate with explanation
- **Action Button:** "View conversation" → opens source chat

### Empty State
- Icon: Magnifying glass or document (calm, not alarming)
- Primary: "No major decisions tracked yet"
- Secondary: "I'll log decisions as your team makes them"
- Tone: Supportive and reassuring

---

## Design Standards (Calm Intelligence)

### Color Palette
```swift
// Confidence badges
let highConfidence = Color(hex: "#2ECC71").opacity(0.7)      // Green
let moderateConfidence = Color(hex: "#FFA500").opacity(0.7)  // Orange
let uncertainConfidence = Color(hex: "#95A5A6").opacity(0.7) // Gray

// Supporting UI
let dividerColor = Color.gray.opacity(0.2)
let contextBadgeBackground = Color.gray.opacity(0.15)
```

### Layout & Typography
```swift
// Card spacing
VStack(spacing: 20) { /* Between cards */ }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)

// Text styles
.font(.title3).bold()                            // Decision text
.font(.body)                                      // Participant names
.font(.caption).foregroundColor(.secondary)       // Timestamp, chat context
.font(.caption2)                                  // Confidence badge
```

### Animations
```swift
// Card appearance
.transition(.move(edge: .bottom).combined(with: .opacity))
.animation(.spring(response: 0.35, dampingFraction: 0.8), value: decisions)

// Filter transitions
.animation(.easeInOut(duration: 0.2), value: selectedFilter)
```

---

## Data Models

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

struct Participant: Identifiable {
    let id: String
    let name: String
    let avatarURL: String?
}

enum ConfidenceLevel: String {
    case high = "High"
    case moderate = "Moderate"
    case uncertain = "Uncertain"
    
    var color: Color {
        switch self {
        case .high: return Color(hex: "#2ECC71").opacity(0.7)
        case .moderate: return Color(hex: "#FFA500").opacity(0.7)
        case .uncertain: return Color(hex: "#95A5A6").opacity(0.7)
        }
    }
}

enum TimeFilter: String, CaseIterable {
    case lastWeek = "Last Week"
    case lastMonth = "Last Month"
    case allTime = "All Time"
    
    var daysBack: Int? {
        switch self {
        case .lastWeek: return 7
        case .lastMonth: return 30
        case .allTime: return nil
        }
    }
}
```

---

## Mock Service Protocol

```swift
protocol DecisionHistoryService {
    /// Fetch decisions with time filter (mock returns 5-6 decisions)
    func fetchDecisions(filter: TimeFilter) async throws -> [Decision]
    
    /// Search decisions by query (mock filters by keyword matching)
    func searchDecisions(query: String) async throws -> [Decision]
}

// Mock implementation
class MockDecisionHistoryService: DecisionHistoryService {
    private let decisions: [Decision] = MockData.decisions  // Hardcoded 5-6 decisions
    
    func fetchDecisions(filter: TimeFilter) async throws -> [Decision] {
        try await Task.sleep(nanoseconds: 400_000_000) // Simulate network
        
        guard let daysBack = filter.daysBack else { return decisions }
        
        let cutoffDate = Date().addingTimeInterval(-Double(daysBack * 86400))
        return decisions.filter { $0.timestamp >= cutoffDate }
    }
    
    func searchDecisions(query: String) async throws -> [Decision] {
        try await Task.sleep(nanoseconds: 300_000_000)
        
        guard !query.isEmpty else { return decisions }
        
        let lowercased = query.lowercased()
        return decisions.filter {
            $0.decisionText.lowercased().contains(lowercased) ||
            $0.chatContext.lowercased().contains(lowercased) ||
            $0.participants.contains { $0.name.lowercased().contains(lowercased) }
        }
    }
}
```

---

## ViewModel Structure

```swift
@MainActor
class DecisionHistoryViewModel: ObservableObject {
    @Published var decisions: [Decision] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedFilter: TimeFilter = .lastWeek
    @Published var searchQuery = ""
    
    private let service: DecisionHistoryService
    
    init(service: DecisionHistoryService = MockDecisionHistoryService()) {
        self.service = service
    }
    
    var filteredDecisions: [Decision] {
        guard !searchQuery.isEmpty else { return decisions }
        
        let query = searchQuery.lowercased()
        return decisions.filter {
            $0.decisionText.lowercased().contains(query) ||
            $0.chatContext.lowercased().contains(query)
        }
    }
    
    func loadDecisions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            decisions = try await service.fetchDecisions(filter: selectedFilter)
        } catch {
            self.error = error
        }
    }
    
    func applyFilter(_ filter: TimeFilter) async {
        selectedFilter = filter
        await loadDecisions()
    }
}
```

---

## Integration with ProfileView

```swift
// Add to ProfileView.swift

NavigationLink(destination: DecisionHistoryView()) {
    HStack {
        Image(systemName: "list.bullet.clipboard")
            .foregroundColor(.blue)
        Text("Decision History")
        Spacer()
        Image(systemName: "chevron.right")
            .foregroundColor(.gray)
    }
    .padding()
}
```

---

## Definition of Done

### Core Functionality
- [ ] DecisionHistoryView builds and runs without errors
- [ ] Navigation from ProfileView works
- [ ] Timeline displays decisions chronologically (newest first)
- [ ] Decision cards show: text, participants, timestamp, context, confidence
- [ ] Participant avatars overlapping (max 3 visible + count badge)
- [ ] Time filters work (Last Week / Last Month / All Time)
- [ ] Search bar filters by keyword in real-time
- [ ] Tap card → opens source conversation
- [ ] "Why?" button → shows transparency modal with signals
- [ ] Empty state displays when no decisions
- [ ] Dark mode compatible

### Design Quality
- [ ] Colors match Calm Intelligence palette
- [ ] Spacious layout with soft dividers
- [ ] Animations feel smooth and calm
- [ ] Confidence badges subtle (not prominent)

### Nice to Have (if time)
- [ ] Group decisions by date (Today, This Week, Earlier)
- [ ] Export decisions to Notes
- [ ] Share decision via Messages

---

## Acceptance Criteria

**Timeline & Navigation:**
- Timeline shows newest decisions first
- Filters correctly limit decisions by time range
- Tap opens source conversation at exact message

**Search & Transparency:**
- Search filters in real-time (helpful, not mandatory)
- Transparency modal clearly explains detection reasoning
- Signals shown as tag list

**UI Feel:**
- Layout feels spacious and calm (not cramped)
- Empty state is supportive (not alarming)
- Confidence badges are subtle
- Animations are smooth

---

## Future Production Path

**Next PRs (after demo):**
1. **Firebase Integration** - Real Cloud Functions for decision tracking
2. **Real-time Updates** - Firestore listeners for new decisions
3. **Advanced Search** - Semantic search using embeddings
4. **Decision Categories** - Auto-categorize (product, hiring, technical, etc.)
5. **Export/Share** - Share decisions externally
6. **Decision Impact Tracking** - Follow-up on decisions made
7. **Full Test Coverage** - Unit + UI tests (80%+)

---

## Why This PR Matters

**Solves Digital FOMO:**  
Maya missed 3 days while on vacation. Instead of scrolling 500 messages, she opens Decision History:
- ✅ Team decided to use Stripe
- ✅ Q4 launch postponed  
- ✅ Sarah hired as designer

**Peace of Mind:**  
You can disconnect without anxiety. The AI tracks what matters.

**Builds Trust:**  
Transparent reasoning ("Why?") shows detection signals. Not a black box.

---

**Next Step:** Ready for Cody to implement  
**Branch:** `feat/ai-decision-history`  
**Target:** `develop`  
**Time:** 30-45 minutes

