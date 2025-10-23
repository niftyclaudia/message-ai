# Tomorrow Night Sprint Plan

**Timeline**: Must complete by tomorrow night (October 24, 2025)  
**Status**: Ready to begin  
**Philosophy**: Calm Intelligence - Building a focus rehabilitation tool

---

## Sprint Overview

This is a parallel dual-agent sprint to rapidly build UI/UX polish features and AI infrastructure simultaneously, integrating Calm Intelligence principles throughout.

**Goal**: Transform the messaging app from MVP to a differentiated "Calm Intelligence" product with AI-powered features.

---

## Dual Work Tree Setup

### Work Tree A (UI/UX)
- **Location**: `messagingapp` (main work tree)
- **Branch**: `develop`
- **Agent**: Agent A (UI/UX Polish Agent)
- **Template**: `MessageAI/agents/develop/agent-a-ui-polish-template.md`

### Work Tree B (AI Infrastructure)
- **Location**: `messagingapp/secondagent` 
- **Branch**: `secondagent`
- **Agent**: Agent B (AI Infrastructure Agent)
- **Template**: `MessageAI/agents/secondagent/agent-b-ai-infra-template.md`

**Why parallel work trees?**
- Agents work simultaneously without merge conflicts
- Independent testing and commits
- Merge both branches when complete

---

## Flow A: UI/UX Polish (Agent A)

**Mission**: Essential messaging features with Calm Intelligence principles

### Priority 1: Quick Win
- [ ] "All Caught Up" state (30 minutes)
  - Ambient reassurance when inbox clear
  - Calm design with green checkmark
  - Files: Update `ConversationListView.swift`

### Priority 2: Core Features
- [ ] Image Upload & Display (4-5 hours) ⭐ BIGGEST FEATURE
  - Send/view images in conversations
  - Offline queueing
  - Lazy loading for performance
  - Files: `ImageUploadService.swift`, `ImageMessageView.swift`, `ImagePickerView.swift`
  
- [ ] Push Notifications (3-4 hours) ⭐ CRITICAL
  - Smart bundling (3 messages = 1 notification)
  - Gentle defaults (soft sound, no vibration)
  - Deep linking to conversations
  - Files: `NotificationService.swift`, `PushNotificationHandler.swift`, Cloud Function

- [ ] Add Contacts (2-3 hours)
  - Search users by email/username
  - Start new conversations
  - Files: `UserSearchService.swift`, `AddContactView.swift`

- [ ] Delete Messages (2 hours)
  - Long-press to delete
  - Gentle confirmation
  - Offline queueing
  - Files: Update `MessageService.swift`, `MessageRow.swift`

### Estimated Total: 10-12 hours

### Success Criteria
- [ ] Images send/display smoothly (< 2s upload)
- [ ] Notifications bundle rapid messages (3 in 30s = 1 notification)
- [ ] "All caught up" provides ambient reassurance
- [ ] Contact search is intuitive
- [ ] All features work offline
- [ ] 60fps scrolling maintained
- [ ] All tests pass
- [ ] Features feel calm and supportive (not aggressive)

---

## Flow B: AI Infrastructure & Features (Agent B)

**Mission**: Transparent, supportive AI features

### Phase 1: Infrastructure (4-5 hours) ⭐ FOUNDATION
- [ ] OpenAI + Cloud Functions setup
- [ ] Swift AI service layer
- [ ] Error handling (rate limits, failures)
- [ ] Test basic prompt → response with transparency
- Files: `functions/src/ai/`, `AIService.swift`, `AIResponse.swift`

**Checkpoint**: Confirm Phase 1 works before proceeding

### Phase 2: Thread Summarization (2-3 hours) ⭐ HIGH VALUE
- [ ] Long-press conversation → "Summarize Thread"
- [ ] AI analyzes 50-100 messages
- [ ] Display summary with transparency
  - "I analyzed 47 messages and focused on decisions. High confidence."
- [ ] Show reasoning on demand
- [ ] Cache results
- Files: `summarizeThread.ts`, `ThreadSummarySheet.swift`, `ThreadSummary.swift`

**Checkpoint**: Demo summarization to user

### Phase 3: Action Item Extraction (2-3 hours) ⭐ HIGH VALUE
- [ ] Button in chat: "Find Action Items"
- [ ] Extract tasks with assignee, due date, source message
- [ ] Display with transparency
  - "I identified this as an action item because Sarah used 'can you' and mentioned Friday"
- [ ] Link to source messages
- Files: `extractActionItems.ts`, `ActionItemsSheet.swift`, `ActionItem.swift`

**Checkpoint**: Status update

### Phase 4 (BONUS - if time allows): ⚡
**Option A**: Priority Detection
- Analyze urgency with transparent reasoning
- "Urgent because: @mentioned + deadline + from manager"

**Option B**: Chatbot UI
- Floating button → Chat with AI
- "What did I miss?" functionality
- Full-screen modal

### Estimated Total: 10-12 hours

### Success Criteria
- [ ] OpenAI integration works securely
- [ ] Thread summarization < 3s response time
- [ ] Action item extraction accurate (test 10+ conversations)
- [ ] Transparency displayed clearly (reasoning, confidence, signals)
- [ ] Error handling graceful
- [ ] Caching works (instant second requests)
- [ ] Cost < $0.01 per summary
- [ ] All tests pass
- [ ] **Users understand WHY AI made each decision**

---

## Integration & Coordination

### Checkpoints
Both agents check in at these milestones:

**Agent A**:
1. After "All Caught Up" state complete
2. After image upload complete
3. After notifications working
4. Final completion

**Agent B**:
1. After Phase 1 (infrastructure) complete
2. After Phase 2 (summarization) complete
3. After Phase 3 (action items) complete
4. Final completion

### Shared Resources
Both agents can reference:
- `MessageAI/docs/calm-intelligence-vision.md` - Core philosophy
- `MessageAI/agents/shared-standards.md` - Code standards
- `MessageAI/docs/sprints/tomorrow-night-checklist.md` - Task list

### No Conflicts Expected
- Agent A works in `MessageAI/Services/`, `MessageAI/Views/` (non-AI)
- Agent B works in `functions/src/ai/`, `MessageAI/Services/AI/`, `MessageAI/Views/AI/`
- Minimal overlap

---

## Calm Intelligence Integration

Both flows MUST integrate these principles:

### 1. Silence by Design
- **Agent A**: Gentle notifications, smart bundling, quiet hours
- **Agent B**: Don't over-alert, summarize instead of constant pings

### 2. Ambient Reassurance
- **Agent A**: "All caught up" states, calm empty states
- **Agent B**: "You're up to date" from AI, celebrate completion

### 3. Adaptive Prioritization
- **Agent A**: Notification bundling based on context
- **Agent B**: Priority based on emotional/temporal context, not just frequency

### 4. Transparency-First AI
- **Agent B**: Every AI decision includes reasoning, confidence, signals
- **Agent A**: Clear feedback on all actions

---

## What's Out of Scope

**Not doing tomorrow night**:
- ❌ Dark mode (planned for future, light mode for now)
- ❌ Focus Mode / Scheduled summaries (Phase 3, later)
- ❌ Advanced analytics (future)
- ❌ Multiple AI models comparison (stick with GPT-4)
- ❌ Full chatbot (only if time allows in Phase 5)
- ❌ Marketing materials (future)
- ❌ Onboarding for Calm Intelligence philosophy (future)

**Acceptable shortcuts for tomorrow**:
- Basic error messages (can polish later)
- Simple caching strategy (can optimize later)
- Light mode only (dark mode later)
- Limited prompt engineering (can improve later)

---

## Testing Strategy

### Agent A Testing
- Swift Testing (@Test) for services
- XCTest for UI flows
- Test offline behavior for all features
- Test multi-device sync
- Test notification bundling

### Agent B Testing
- Swift Testing (@Test) for AI services
- Test with real OpenAI API (small test set)
- Test error scenarios (API down, rate limits)
- Test transparency UI
- Test caching behavior

### Integration Testing (After Both Complete)
- [ ] AI features work with real conversations
- [ ] No performance degradation from AI features
- [ ] Notifications work for AI-generated insights
- [ ] Overall app feels calm and supportive

---

## Merge Strategy

**After both agents complete**:

```bash
# Merge Flow A (develop branch)
cd messagingapp
git checkout develop
git pull origin develop
# Review and test

# Merge Flow B (secondagent branch)
cd messagingapp/secondagent
git checkout secondagent  
git pull origin secondagent
# Review and test

# Create integration branch
git checkout -b feat/calm-intelligence-integration

# Merge both
git merge develop
git merge secondagent
# Resolve any conflicts (unlikely)

# Final testing
# Create PR to develop

# Deploy 🚀
```

---

## Success Metrics

### User Experience
- [ ] Users can send images smoothly
- [ ] Notifications feel calm and bundled
- [ ] AI provides helpful, transparent insights
- [ ] App feels supportive, not overwhelming
- [ ] All features work offline

### Technical
- [ ] All tests pass (Agent A + Agent B)
- [ ] Performance maintained (60fps, < 3s AI responses)
- [ ] Error handling graceful
- [ ] Cost per AI call reasonable
- [ ] No critical bugs

### Calm Intelligence
- [ ] Features support mental spaciousness
- [ ] Transparency builds trust
- [ ] Users understand AI reasoning
- [ ] Design feels calm (gentle notifications, spacious layouts)

---

## Timeline

**Start**: Now (October 23, 2025 evening)  
**End**: Tomorrow night (October 24, 2025)  
**Available time**: ~24 hours with breaks

**Realistic schedule**:
- Agent A: 10-12 hours of work (image upload is biggest chunk)
- Agent B: 10-12 hours of work (infrastructure setup is biggest chunk)
- Buffer: 2-4 hours for testing, integration, unexpected issues

**Critical path**:
1. Both agents start simultaneously
2. Agent A: Quick win ("All caught up") → Image upload → Notifications → Rest
3. Agent B: Infrastructure → Summarization → Action items → (Bonus if time)
4. Integration and final testing

---

## Communication

**Status updates in this format**:
```
Agent: A or B
✅ Completed: [List completed tasks]
🔄 In Progress: [Current task with % if applicable]
⏳ Next: [Next planned task]
⚠️ Blockers: [Any blockers or None]
⏰ Time estimate: [Hours remaining]
```

**Check in frequency**: After each major milestone (see checkpoints above)

---

## References

- **Agent A Template**: `MessageAI/agents/develop/agent-a-ui-polish-template.md`
- **Agent B Template**: `MessageAI/agents/secondagent/agent-b-ai-infra-template.md`
- **Checklist**: `MessageAI/docs/sprints/tomorrow-night-checklist.md`
- **Vision**: `MessageAI/docs/calm-intelligence-vision.md`
- **Shared Standards**: `MessageAI/agents/shared-standards.md`
- **AI Architecture**: `MessageAI/docs/ai-architecture-guide.md`

---

## Let's Build! 🚀

Two agents, two work trees, one goal: Transform this messaging app into a Calm Intelligence tool that helps users stay focused and reduce overwhelm.

**Remember**: This isn't about building faster communication. It's about building mental spaciousness. Every feature decision should support that goal.

