# Agent B: AI Infrastructure & Features Agent

**Mission**: Transparent, supportive AI features  
**Branch**: `secondagent` AND merge with `develop` branch  
**Timeline**: Complete by tomorrow night  
**Parallel Work**: Agent A building UI/UX in `develop` branch

---

## Philosophy

Building **"Calm Intelligence"** - AI must be transparent, supportive, restorative. Every AI decision builds or erodes trust.

**Read full philosophy**: `MessageAI/docs/calm-intelligence-vision.md`  
**AI Architecture**: `MessageAI/docs/ai-architecture-guide.md`

---

## Your Tasks (Sequential Phases)

### Phase 1: AI Infrastructure ⭐⭐⭐ Foundation (4-5 hours)
- OpenAI GPT-4 + Cloud Functions setup
- Swift AI service layer
- Transparent response models (reasoning, confidence, signals)
- Error handling and caching
- Files: `functions/src/ai/`, `AIService.swift`, `AIResponse.swift`
- Tests: `AIServiceTests.swift`

**CHECKPOINT**: Confirm infrastructure works before proceeding

---

### Phase 2: Thread Summarization ⭐⭐⭐ High Value (2-3 hours)
- Long-press conversation → AI summary
- **Transparency**: "I analyzed 47 messages and focused on decisions. High confidence."
- Show reasoning, confidence, signals on demand
- Cache results
- Files: `summarizeThread.ts`, `ThreadSummarySheet.swift`, `ThreadSummary.swift`

**CHECKPOINT**: Demo to user

---

### Phase 3: Action Item Extraction ⭐⭐⭐ High Value (2-3 hours)
- Button in chat: "Find Action Items"
- Extract tasks with assignee, due date, source message
- **Transparency**: "I identified this because Sarah said 'can you' and mentioned Friday"
- Link to source messages
- Files: `extractActionItems.ts`, `ActionItemsSheet.swift`, `ActionItem.swift`

**CHECKPOINT**: Status update

---

### Phase 4 (BONUS if time): ⚡
**Option A**: Priority Detection with transparent reasoning  
**Option B**: Chatbot UI (floating button, morning recap)

---

## Calm Intelligence - Transparency First (CRITICAL)

**Every AI response must include:**
```swift
struct AIResponse {
    let result: String              // The answer/summary/items
    let reasoning: String            // "I focused on X because Y"
    let confidence: Double           // 0.0 - 1.0
    let signals: [String]            // ["@mention", "deadline keyword"]
    let sourceMessageIds: [String]   // For linking back
}
```

**Example UI**:
- Show summary/result prominently
- Below: "I analyzed 47 messages. High confidence."
- Expandable: "Why did I focus on this?" → Show reasoning + signals
- Tap to see source messages

**This is your competitive advantage!** Other AI apps are black boxes. You build trust through explanation.

---

## Technical Details

### OpenAI Setup
- API: GPT-4 (you have keys)
- Deployment: Cloud Functions (secure)
- Cost: ~$0.005-0.01 per summary

### Example Prompt (Transparency Built-in)
```typescript
const systemPrompt = `You are a supportive AI assistant.
Be transparent: explain your reasoning.
Be humble: express uncertainty when appropriate.
Use first-person: "I focused on..." not "Summary focuses on..."

Return JSON:
{
  "summary": "3-5 sentences",
  "reasoning": "I focused on decisions because...",
  "confidence": 0.85,
  "signals": ["decision keywords", "action verbs"]
}`;
```

---

## Standards & References

**Code Standards**: `MessageAI/agents/secondagent/shared-standards.md`
- Swift Testing (@Test) for services
- Test with real OpenAI API (small test set)
- Error handling: Rate limits, API failures
- Caching: 1 hour TTL for summaries

**Existing Patterns**:
- `functions/src/sendMessageNotification.ts` - Cloud Function patterns
- `MessageAI/Services/MessageService.swift` - Firestore queries

**Sprint Coordination**: `MessageAI/docs/sprints/tomorrow-night-sprint-plan.md`

---

## Success Criteria

- [ ] OpenAI integration works securely
- [ ] Thread summarization < 3s with transparency
- [ ] Action items accurate (test 10+ conversations)
- [ ] Transparency displayed clearly (reasoning, confidence)
- [ ] Error handling graceful
- [ ] Caching works (instant second call)
- [ ] Cost < $0.01 per summary
- [ ] All tests pass
- [ ] **Users understand WHY for every AI decision**

---

## Workflow

1. **Phase 1**: Infrastructure → Test → Check in
2. **Phase 2**: Summarization → Test → Demo
3. **Phase 3**: Action items → Test → Update
4. **Phase 4**: Bonus if time

**Check in after each phase!**

---

## Quick Start

```bash
# You're on secondagent branch
git checkout secondagent
git pull origin secondagent

# Set up OpenAI
cd functions
npm install openai
firebase functions:config:set openai.key="sk-..."

# Work and commit
git add .
git commit -m "feat(ai): Add transparent thread summarization"

# Push
git push origin secondagent
```

**Status Format**:
```
✅ Completed: [phases]
🔄 In Progress: [current phase with %]
⏳ Next: [next phase]
⚠️ Blockers: [blockers or None]
💰 Cost: [OpenAI spend]
```

Begin with Phase 1: AI Infrastructure Setup.
