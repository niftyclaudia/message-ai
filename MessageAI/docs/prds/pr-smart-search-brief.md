# PR Brief: Smart Search View

**Created by:** Brad (PR Brief Builder)  
**Date:** October 24, 2025  
**Source PRD:** [pr-tonight-ui-demo.md](./pr-tonight-ui-demo.md)

---

## PR #AI-SEARCH-001: Semantic Smart Search

**Brief:** Build a Smart Search view (or enhance existing search) that performs semantic search using natural language queries instead of exact keyword matching. The search bar has a helpful placeholder ("Find the budget decision...") hinting at conversational queries. Results display message preview with context, sender name and timestamp, chat name badge, relevance score (subtle, e.g., "95% match"), and matched keywords highlighted in preview text. Tapping a result opens the conversation at that specific message. Includes calm loading state with animated search icon and supportive text ("Searching your conversations..."), transparent footer showing interpreted query and search time, and helpful empty state with suggestions ("Try broader terms: 'payment decision' instead of 'Stripe pricing tier 3'"). Uses mock data with 4-5 hardcoded search results demonstrating semantic matching. Integrated into ConversationListView's existing search bar or added as enhanced mode. Proves AI understands intent, not just keywords. Follows Calm Intelligence: relevance scores subtle (not prominent), results feel confident (not exhaustive), helpful suggestions on no results.

**Dependencies:** None (mock data implementation)

**Complexity:** Simple  
- 2 new files (view + view model) OR enhance existing search
- 1 file modification (ConversationListView search integration)
- Mock service protocol
- 30 minutes estimated

**Phase:** 1 (Demo/MVP)

**Priority:** Medium (Shows semantic search value)

---

## Technical Scope

### New Files to Create
1. **Views/AI/SmartSearchView.swift** (or enhance existing search)
   - Search bar with natural language placeholder
   - Results list with relevance scores
   - Highlighted matched keywords
   - Loading state animation
   - Transparency footer
   - Empty state with suggestions

2. **ViewModels/AI/SmartSearchViewModel.swift**
   - Mock search with keyword matching + relevance scoring
   - Query interpretation
   - Result ranking simulation
   - Highlight keyword extraction

### Files to Modify
- **Views/ConversationListView.swift** - Integrate Smart Search or add toggle for semantic mode

---

## Mock Data Examples

### Sample Query: "Find the payment decision"

```swift
SearchResult(
    messagePreview: "We've decided to go with Stripe for payment processing. Chris approved the $5K/month plan.",
    senderName: "Jamie",
    timestamp: Date().addingTimeInterval(-86400 * 2), // 2 days ago
    chatName: "#product-team",
    chatID: "chat-1",
    messageID: "msg-123",
    relevanceScore: 0.95,
    matchedKeywords: ["decided", "payment", "Stripe"]
)

SearchResult(
    messagePreview: "Chris approved the Stripe budget. $5K/month starting next quarter.",
    senderName: "Chris",
    timestamp: Date().addingTimeInterval(-86400 * 2),
    chatName: "#product-team",
    chatID: "chat-1",
    messageID: "msg-124",
    relevanceScore: 0.87,
    matchedKeywords: ["approved", "Stripe", "budget"]
)

SearchResult(
    messagePreview: "Stripe integration is live! Payment flow tested and working.",
    senderName: "Dave",
    timestamp: Date().addingTimeInterval(-86400 * 1), // 1 day ago
    chatName: "#engineering",
    chatID: "chat-2",
    messageID: "msg-125",
    relevanceScore: 0.72,
    matchedKeywords: ["Stripe", "payment"]
)
```

### Sample Query: "Who approved the budget?"

```swift
SearchResult(
    messagePreview: "Jamie and Chris approved the Q4 marketing budget of $50K.",
    senderName: "Alice",
    timestamp: Date().addingTimeInterval(-86400 * 5),
    chatName: "Marketing Budget",
    chatID: "chat-3",
    messageID: "msg-200",
    relevanceScore: 0.93,
    matchedKeywords: ["approved", "budget"]
)

SearchResult(
    messagePreview: "Budget approved! Let's move forward with the campaign.",
    senderName: "Chris",
    timestamp: Date().addingTimeInterval(-86400 * 5),
    chatName: "Marketing Budget",
    chatID: "chat-3",
    messageID: "msg-201",
    relevanceScore: 0.81,
    matchedKeywords: ["budget", "approved"]
)
```

---

## UI Requirements

### Search Bar
- **Placeholder:** "Find the budget decision..." or "Search conversations..."
- **Position:** Top of ConversationListView (existing search or new mode toggle)
- **Behavior:** 
  - Accepts natural language queries
  - Shows results as user types (debounced 300ms)
  - Clear button on right side

### Results List
- **Layout:** Vertical scroll, newest/most relevant first
- **Result Cards:**
  - Message preview (2-3 lines, matched keywords **bold**)
  - Sender name + avatar (left side)
  - Timestamp (relative: "2 days ago")
  - Chat name badge (subtle, gray background)
  - Relevance score (right side, subtle: "95%" or "★★★★☆")
  - Tap → Opens conversation at that message

### Loading State
- Animated search icon (pulsing or rotating)
- "Searching your conversations..."
- Calm animation (not aggressive spinner)
- Appears after 300ms delay (avoid flash for fast searches)

### Transparency Footer (Bottom of Results)
- **Interpreted Query:** "I searched for: [query interpretation]"
- **Result Count:** "Found 3 relevant messages"
- **Search Time:** "0.8s" (subtle, gray)
- Collapsible/dismissible

### Empty State (No Results)
- Magnifying glass icon (large, calm)
- "No matches found"
- **Helpful Suggestion:** "Try broader terms: 'payment decision' instead of 'Stripe pricing tier 3'"
- Not harsh or critical tone

### Highlight Matched Keywords
- **In Preview Text:** Bold or different color (not yellow highlight background)
- Subtle emphasis that aids scanning
- Example: "We've **decided** to go with **Stripe** for **payment** processing."

---

## Design Standards (Calm Intelligence)

### Colors
```swift
// Relevance score
let highRelevance = Color(hex: "#2ECC71")     // Green (90%+)
let mediumRelevance = Color(hex: "#FFA500")   // Orange (70-89%)
let lowRelevance = Color(hex: "#95A5A6")      // Gray (<70%)

// Matched keywords
let keywordHighlight = Color.blue.opacity(0.7)  // Subtle blue emphasis

// Chat badge
let chatBadgeBackground = Color.gray.opacity(0.15)
```

### Spacing
```swift
VStack(spacing: 12) {  // Between result cards
    // Result content
}
.padding(.horizontal, 20)
.padding(.vertical, 12)
```

### Typography
```swift
.font(.body)  // Message preview
.font(.subheadline)  // Sender name
.font(.caption).foregroundColor(.secondary)  // Timestamp, chat name
.font(.caption2)  // Relevance score
```

### Animations
```swift
// Results appear
.transition(.move(edge: .bottom).combined(with: .opacity))
.animation(.spring(response: 0.35, dampingFraction: 0.8), value: results)

// Loading state
.rotationEffect(.degrees(isSearching ? 360 : 0))
.animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isSearching)
```

---

## Data Models

```swift
struct SearchResult: Identifiable {
    let id: String
    let messagePreview: String
    let senderName: String
    let senderAvatarURL: String?
    let timestamp: Date
    let chatName: String
    let chatID: String
    let messageID: String
    let relevanceScore: Double  // 0.0 to 1.0
    let matchedKeywords: [String]
}

struct SearchMetadata {
    let interpretedQuery: String
    let resultCount: Int
    let searchTimeSeconds: Double
}
```

---

## Mock Service Protocol

```swift
protocol SmartSearchService {
    /// Semantic search (mock returns keyword-matched results with fake relevance scores)
    func search(query: String) async throws -> (results: [SearchResult], metadata: SearchMetadata)
}

// Mock implementation
class MockSmartSearchService: SmartSearchService {
    private let allResults: [SearchResult] = MockData.searchableMessages
    
    func search(query: String) async throws -> (results: [SearchResult], metadata: SearchMetadata) {
        let startTime = Date()
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay (simulate search)
        
        guard !query.isEmpty else {
            return ([], SearchMetadata(interpretedQuery: "", resultCount: 0, searchTimeSeconds: 0))
        }
        
        // Simple keyword matching (production would use embeddings)
        let keywords = query.lowercased().split(separator: " ").map(String.init)
        let results = allResults.compactMap { result -> SearchResult? in
            let messageText = result.messagePreview.lowercased()
            let matchingKeywords = keywords.filter { messageText.contains($0) }
            
            guard !matchingKeywords.isEmpty else { return nil }
            
            // Fake relevance score based on keyword matches
            let score = Double(matchingKeywords.count) / Double(keywords.count)
            
            return SearchResult(
                id: result.id,
                messagePreview: result.messagePreview,
                senderName: result.senderName,
                senderAvatarURL: result.senderAvatarURL,
                timestamp: result.timestamp,
                chatName: result.chatName,
                chatID: result.chatID,
                messageID: result.messageID,
                relevanceScore: min(score + 0.1, 1.0), // Boost slightly
                matchedKeywords: matchingKeywords
            )
        }
        .sorted { $0.relevanceScore > $1.relevanceScore }  // Sort by relevance
        
        let searchTime = Date().timeIntervalSince(startTime)
        let metadata = SearchMetadata(
            interpretedQuery: query,
            resultCount: results.count,
            searchTimeSeconds: searchTime
        )
        
        return (results, metadata)
    }
}
```

---

## ViewModel Structure

```swift
@MainActor
class SmartSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [SearchResult] = []
    @Published var metadata: SearchMetadata?
    @Published var isSearching = false
    @Published var error: Error?
    
    private let service: SmartSearchService
    private var searchTask: Task<Void, Never>?
    
    init(service: SmartSearchService = MockSmartSearchService()) {
        self.service = service
    }
    
    func search() {
        // Cancel previous search
        searchTask?.cancel()
        
        // Debounce: wait 300ms before searching
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            guard !Task.isCancelled else { return }
            
            isSearching = true
            defer { isSearching = false }
            
            do {
                let (searchResults, searchMetadata) = try await service.search(query: query)
                
                guard !Task.isCancelled else { return }
                
                results = searchResults
                metadata = searchMetadata
            } catch {
                self.error = error
            }
        }
    }
    
    func clear() {
        query = ""
        results = []
        metadata = nil
        searchTask?.cancel()
    }
}
```

---

## Integration Options

### Option 1: Enhance Existing Search (Recommended)
Replace existing keyword search in ConversationListView with semantic search.

```swift
// In ConversationListView.swift
@StateObject private var searchViewModel = SmartSearchViewModel()

.searchable(text: $searchViewModel.query, prompt: "Find the budget decision...")
.onChange(of: searchViewModel.query) { _ in
    Task { await searchViewModel.search() }
}
.overlay {
    if !searchViewModel.results.isEmpty {
        SmartSearchResultsView(results: searchViewModel.results)
    }
}
```

### Option 2: Add Toggle for Semantic Mode
Keep existing search, add toggle to enable semantic mode.

```swift
@State private var isSemanticSearchEnabled = false

.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("AI Search") {
            isSemanticSearchEnabled.toggle()
        }
    }
}
```

---

## Definition of Done

**Must Have:**
- [ ] SmartSearchView builds and runs without errors
- [ ] Search bar accepts natural language queries
- [ ] Results display with relevance scores
- [ ] Matched keywords highlighted in preview text
- [ ] Tap result opens conversation at correct message
- [ ] Loading state displays during search (calm animation)
- [ ] Empty state provides helpful suggestions
- [ ] Transparency footer shows interpreted query and timing
- [ ] Dark mode compatible
- [ ] Debounced search (300ms) to avoid excessive calls

**Nice to Have (if time):**
- [ ] Recent searches saved
- [ ] Search suggestions dropdown
- [ ] Filter by chat or date range
- [ ] Voice search integration

---

## Acceptance Criteria

- [ ] Search accepts natural language (not just keywords)
- [ ] Results ranked by relevance (most relevant first)
- [ ] Matched keywords highlighted (aids scanning)
- [ ] Loading state is calm (not aggressive spinner)
- [ ] Empty state is helpful (not harsh)
- [ ] Tap opens exact message in conversation
- [ ] Relevance scores subtle (not prominent)
- [ ] Results feel confident (not exhaustive)

---

## Future Production Path

**Next PRs (after demo):**
1. **Firebase Integration** - Connect to Cloud Functions semantic search
2. **Embeddings** - Use OpenAI/Pinecone for true semantic matching
3. **Advanced Filters** - By chat, date, sender, attachments
4. **Search History** - Save and suggest recent searches
5. **Voice Search** - Siri integration for hands-free search
6. **Search Analytics** - Track common queries to improve UX
7. **Full Test Coverage** - Unit + UI tests (80%+)

---

## Why This PR Matters

**Shows AI "Gets It":** Maya types "Who approved the budget?" and finds the answer instantly. Not keyword matching ("approved" + "budget"), but understanding intent.

**Information Retrieval Solved:** No more scrolling through 500 messages to find "that payment thing Jamie mentioned last week." Just ask.

**Calm Intelligence:** Search feels smart but not show-offy. Relevance scores are subtle. Empty state is helpful, not critical. 🎯

---

**Next Agent:** Cody iOS for implementation  
**Branch:** `feat/ai-smart-search`  
**Target:** `develop` branch  
**Estimated Time:** 30 minutes

