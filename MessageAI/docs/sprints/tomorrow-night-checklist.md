# Tomorrow Night Sprint Checklist

Quick reference checklist for both agents. Check off tasks as completed.

---

## Agent A: UI/UX Polish (develop branch)

### Quick Win
- [ ] "All Caught Up" state with green checkmark
- [ ] Calm empty state design
- [ ] Gentle fade-in animation

### Image Upload & Display
- [ ] Camera/gallery picker UI
- [ ] Image preview before send
- [ ] Firebase Storage upload service
- [ ] Progress indicator (calm design)
- [ ] Image display in message bubbles
- [ ] Tap to full-screen view
- [ ] Offline queueing
- [ ] Lazy loading for performance
- [ ] Tests: ImageUploadServiceTests
- [ ] Tests: ImageMessagingUITests

### Push Notifications
- [ ] FCM token management
- [ ] Notification permission request (gentle)
- [ ] Send notification on new message
- [ ] Smart bundling (3 in 30s = 1 notification)
- [ ] Gentle defaults (soft sound, no vibration)
- [ ] Deep linking to conversations
- [ ] Badge count for unread
- [ ] Don't notify if user in chat
- [ ] Cloud Function for notifications
- [ ] Tests: NotificationServiceTests
- [ ] Tests: NotificationFlowUITests

### Add Contacts
- [ ] User search by email/username
- [ ] Search results UI
- [ ] Tap to start conversation
- [ ] "User not found" gentle empty state
- [ ] Prevent adding self
- [ ] Create or navigate to existing chat
- [ ] Tests: UserSearchServiceTests
- [ ] Tests: AddContactUITests

### Delete Messages
- [ ] Long-press menu on messages
- [ ] "Delete" option
- [ ] Gentle confirmation dialog
- [ ] Delete from Firestore
- [ ] "Message deleted" placeholder
- [ ] Only allow own messages
- [ ] Offline queueing
- [ ] Tests: MessageServiceTests (deleteMessage)
- [ ] Tests: DeleteMessageUITests

### Final Polish
- [ ] All features work offline
- [ ] 60fps scrolling with images
- [ ] Calm visual design throughout
- [ ] All tests passing
- [ ] Code follows Swift best practices

---

## Agent B: AI Infrastructure (secondagent branch)

### Phase 1: Infrastructure
- [ ] Install OpenAI SDK in Cloud Functions
- [ ] Set up OpenAI API key in Firebase config
- [ ] Create `functions/src/ai/aiService.ts`
- [ ] Create OpenAI client wrapper
- [ ] Create prompt templates utility
- [ ] Create Swift AIService.swift
- [ ] Create AIResponse model with transparency
- [ ] Create AICache for results
- [ ] Test basic OpenAI call works
- [ ] Error handling (rate limits, API failure)
- [ ] Tests: AIServiceTests

**CHECKPOINT: Confirm infrastructure works before proceeding**

### Phase 2: Thread Summarization
- [ ] Cloud Function: summarizeThread.ts
- [ ] Prompt engineering with Calm Intelligence
- [ ] Parse response for summary + reasoning
- [ ] Swift method: summarizeThread()
- [ ] Fetch 50-100 recent messages
- [ ] ThreadSummary model
- [ ] ThreadSummarySheet UI with transparency
- [ ] Show reasoning, confidence, signals
- [ ] "Why did I focus on this?" expandable section
- [ ] Context menu on conversation list
- [ ] Loading state (gentle spinner)
- [ ] Cache summaries (1 hour TTL)
- [ ] Handle edge cases (empty, short threads)
- [ ] Tests: Thread summarization accuracy
- [ ] Tests: UI displays transparency correctly

**CHECKPOINT: Demo summarization to user**

### Phase 3: Action Item Extraction
- [ ] Cloud Function: extractActionItems.ts
- [ ] Prompt engineering for action items
- [ ] Parse JSON response
- [ ] ActionItem model with transparency
- [ ] Swift method: extractActionItems()
- [ ] ActionItemsSheet UI
- [ ] ActionItemCard with reasoning
- [ ] "Why is this an action item?" expandable
- [ ] Link to source messages
- [ ] Tap item → jump to message
- [ ] Button in ChatView toolbar
- [ ] Loading state
- [ ] Empty state (no items found)
- [ ] Handle assignee detection
- [ ] Handle due date parsing
- [ ] Tests: Action item extraction accuracy
- [ ] Tests: UI displays reasoning correctly

**CHECKPOINT: Status update**

### Phase 4 (BONUS - if time)
- [ ] Priority Detection OR Chatbot UI
- [ ] Transparent reasoning for priorities
- [ ] Tests for bonus feature

### Final Polish
- [ ] All AI responses < 3s
- [ ] Transparency displayed clearly
- [ ] Confidence calibrated appropriately
- [ ] Caching working (instant second calls)
- [ ] Error messages supportive (not harsh)
- [ ] Cost per call reasonable
- [ ] All tests passing

---

## Integration (After Both Complete)

### Testing
- [ ] Agent A features work in isolation
- [ ] Agent B features work in isolation
- [ ] No performance degradation from AI
- [ ] All features work offline
- [ ] Notifications work for AI features
- [ ] Overall app feels calm and supportive

### Merge
- [ ] Review Agent A code (develop branch)
- [ ] Review Agent B code (secondagent branch)
- [ ] Create integration branch
- [ ] Merge both branches
- [ ] Resolve any conflicts
- [ ] Final integration testing
- [ ] Create PR to develop
- [ ] Celebrate! 🎉

---

## Quick Status Check

**Agent A Progress**: ____ / 5 major features complete  
**Agent B Progress**: Phase ____ / 5 complete  
**Blockers**: ________________  
**ETA**: _____ hours remaining

---

## Final Validation

Before considering sprint complete, verify:

### Functionality
- [ ] Users can send/view images
- [ ] Notifications arrive and bundle correctly
- [ ] Users can find and add contacts
- [ ] Users can delete messages
- [ ] AI can summarize threads with transparency
- [ ] AI can extract action items with reasoning
- [ ] "All caught up" state appears when appropriate

### Performance
- [ ] Image upload < 2s (reasonable size)
- [ ] AI responses < 3s
- [ ] 60fps scrolling
- [ ] No UI blocking

### Calm Intelligence
- [ ] Notifications feel gentle (bundled, soft sound)
- [ ] AI explains reasoning clearly
- [ ] Empty states feel reassuring
- [ ] No aggressive or jarring elements
- [ ] Users can understand WHY for AI decisions

### Quality
- [ ] All tests pass
- [ ] No critical bugs
- [ ] Offline support works
- [ ] Error handling graceful
- [ ] Code follows standards

---

**Goal**: Transform messaging app into Calm Intelligence tool by tomorrow night ✓

**Philosophy**: Every feature supports mental spaciousness, not overwhelm.

