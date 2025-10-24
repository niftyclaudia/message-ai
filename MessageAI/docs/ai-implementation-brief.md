# AI Feature PR Briefs

This document contains high-level briefs for all AI-related Pull Requests in the MessageAI app. Each PR represents a logical, vertical slice of functionality focused on Calm Intelligence and focus preservation for remote professionals.

**Status:** 🚀 Ready to Start | 0 Completed

---

## Phase 1: Foundation

### PR #AI-001: RAG Pipeline Infrastructure

**Brief:** Establish the foundational RAG (Retrieval Augmented Generation) pipeline including vector database setup, OpenAI API integration, and embedding generation service. Create Pinecone/Weaviate vector index for messages with 1536 dimensions and cosine similarity metric using OpenAI's text-embedding-3-small model. Implement automatic embedding generation for all messages with <500ms indexing target. Create semantic search service that accepts natural language queries and returns relevant messages in <1s. Set up Firebase Cloud Functions for `generateEmbedding(messageId)` and `semanticSearch(query, userId, limit)`. Configure environment variables for `OPENAI_API_KEY`, `PINECONE_API_KEY`, and `PINECONE_ENV`. Store all messages in Firestore with searchable metadata and vector embeddings. This foundational infrastructure enables all AI features (Thread Summarization, Smart Search, Priority Detection, Decision Tracking) while remaining invisible to users at this stage.

**User Capability:** Backend can generate vector embeddings and perform semantic search across all messages (foundation for AI features)

**Dependencies:** None

**Complexity:** Complex

**Phase:** 1

---

### PR #AI-002: User Preference Storage System

**Brief:** Implement comprehensive user preference storage system to personalize AI behavior and categorization. Create Firestore schema under `/users/{userId}/preferences/` with structured fields for focus hours (10am-2pm daily), urgent contacts (manager, CTO, key clients), urgent keywords (production down, critical, urgent, ASAP), priority rules (@mentions with deadlines = urgent, FYIs = can wait), and communication tone (professional/friendly/supportive). Build `PreferencesService.swift` iOS service to manage preference CRUD operations with real-time sync. Create settings UI for trainers to configure preferences with clear explanations and examples. Implement 90-day auto-cleanup for privacy compliance. Store learning data from user overrides (when user manually changes AI categorization) to improve accuracy over time. Integrate preferences into AI system prompts so all AI features respect user's focus hours, urgency rules, and communication style. This ensures AI represents the user authentically and learns their unique prioritization patterns.

**User Capability:** Users can configure focus hours, urgent contacts, keywords, and AI behavior to personalize categorization

**Dependencies:** None

**Complexity:** Medium

**Phase:** 1

---

### PR #AI-003: Function Calling Framework

**Brief:** Build comprehensive function calling framework that enables AI to execute actions instead of just providing information. Define eight core functions with OpenAI function calling schema: `summarizeThread(threadId)` for thread digests, `extractActionItems(threadId, userId)` for task extraction, `searchMessages(query, filters)` for semantic search, `categorizeMessage(messageId)` for priority detection, `trackDecisions(threadId)` for decision logging, `detectSchedulingNeed(threadId)` to identify meeting requests, `checkCalendar(startDate, endDate)` for availability, and `suggestMeetingTimes(participants, duration)` for scheduling. Implement function execution handlers in Cloud Functions that validate parameters, execute actions safely, and return structured results. Create `FunctionCallingService.swift` iOS service to handle function call requests and responses. Add execution logging for debugging and audit trail. Include parameter validation, error handling for function failures, and fallback options when functions timeout. This framework transforms AI from passive information provider to active assistant that can take actions.

**User Capability:** Backend infrastructure supports AI function calling for all action-based features (enables future features)

**Dependencies:** None

**Complexity:** Complex

**Phase:** 1

---

### PR #AI-004: Memory & State Management System

**Brief:** Implement stateful memory system that enables AI to remember context across sessions and learn from user behavior. Create Firestore schema under `/users/{userId}/aiState/` with collections for sessionContext (current AI conversation, recent queries, last active time), taskState (action items tracked, decisions logged, completion status), learningData (categorization overrides, meeting preferences, tone feedback), and conversationHistory (AI chat messages, timestamps, topics). Build `MemoryService.swift` iOS service to manage state persistence with automatic sync. Implement session memory that remembers last 20 messages for context preservation enabling follow-up questions ("Who made that decision?"). Store user feedback on AI decisions to improve categorization accuracy over time. Add cross-session persistence so Maya's tasks and preferences survive app restarts. Include privacy controls with user-specific data isolation and transparent explanations of what's remembered. Handle memory cleanup for old conversations (90+ days) while preserving important decisions and action items.

**User Capability:** AI remembers conversation context and learns from user behavior to improve over time

**Dependencies:** PR #AI-002 (User Preferences for storing learning data)

**Complexity:** Medium

**Phase:** 1

---

### PR #AI-005: Error Handling & Fallback System

**Brief:** Implement comprehensive calm error handling across all AI features ensuring graceful degradation when services fail. Create unified error handling system for OpenAI API timeouts, Pinecone rate limits, invalid requests, network failures, service unavailable errors, and quota exceeded billing issues. Design user-friendly error messages in first-person supportive tone: "I'm having trouble right now. Want to try again?" (timeout), "I need a moment to catch up. Try again in 30 seconds" (rate limit), "I can't do that, but I can help you open the full thread instead" (invalid request), "Taking longer than expected. Want to open the full thread while I work?" (service down). Use calm blue/gray colors instead of red "ERROR" text. Implement retry mechanisms with exponential backoff for transient failures. Add fallback modes where core messaging works even when AI is unavailable. Store failed AI requests for later retry when service recovers. Include transparency in error messages explaining what went wrong in plain language. This ensures users never feel frustrated when AI features fail.

**User Capability:** App handles AI failures gracefully with calm, helpful error messages and fallback options

**Dependencies:** All AI features (cross-cutting concern, but can be built in parallel)

**Complexity:** Medium

**Phase:** 1

---

## Phase 2: Core AI Features - Batch 1

### PR #AI-006: Thread Summarization

**Brief:** Implement thread summarization feature that condenses long conversations into 2-3 sentence digestible summaries. Add long-press gesture on conversation list items triggering "Summarize Thread" contextual menu option with smooth haptic feedback. Create Cloud Function `summarizeThread(threadId)` that retrieves messages from Firestore, uses RAG pipeline to find key decisions and action items, and generates concise summary via OpenAI GPT-4. Build `ThreadSummaryView.swift` modal displaying AI-generated summary with transparency section showing confidence level, key signals identified (decisions made, action items, deadlines mentioned), and message count analyzed. Handle various thread lengths from 10 to 100+ messages with <2s response time target. Include loading state with animated typing indicator and error fallback offering to open full thread. Add "Show Original" button to view full conversation. This solves overwhelming re-entry problem by letting Maya process 50 messages in 5 seconds instead of 5 minutes.

**User Capability:** Users can long-press any conversation to get AI-generated 2-3 sentence summary of key points

**Dependencies:** PR #AI-001 (RAG Pipeline), PR #AI-003 (Function Calling), PR #AI-004 (Memory/State), PR #AI-005 (Error Handling)

**Complexity:** Complex

**Phase:** 2

---

### PR #AI-007: Action Item Extraction

**Brief:** Build action item extraction feature that scans all conversations and surfaces tasks requiring user attention. Add toolbar button (checklist icon) in conversation list that triggers action item scan across all active conversations. Create Cloud Function `extractActionItems(userId)` that uses RAG pipeline to find messages containing action items, deadlines, @mentions with tasks, and commitment phrases (I'll, I will, by Friday). Implement `ActionItemsView.swift` displaying extracted tasks grouped by urgency (Today, This Week, Later) with task details, source conversation, deadline if mentioned, and who assigned it. Include transparency reasoning for each task showing exact message text and keywords that triggered extraction. Add task completion checkboxes that update task state in Memory/State system. Handle edge cases like no tasks found (celebratory "All caught up! 🎉" message), ambiguous tasks flagged for review, and extraction from group conversations. This ensures Maya never misses a task buried in message flood.

**User Capability:** Users can tap toolbar button to extract all action items from conversations with deadlines and context

**Dependencies:** PR #AI-001 (RAG Pipeline), PR #AI-003 (Function Calling), PR #AI-004 (Memory/State), PR #AI-005 (Error Handling)

**Complexity:** Complex

**Phase:** 2

---

### PR #AI-008: Smart Search (Semantic Search)

**Brief:** Implement natural language search that finds relevant messages by meaning rather than exact keyword matching. Replace or enhance existing search with semantic search powered by RAG pipeline that accepts queries like "Find the payment processor decision" or "What did the team say about the launch date?" Create `SmartSearchView.swift` with search bar, loading states, and results list showing matching messages with context snippets and relevance scores. Build Cloud Function `searchMessages(query, userId, filters)` that generates query embedding, performs vector similarity search in Pinecone, retrieves top relevant messages from Firestore, and ranks by relevance. Display results with message preview, sender name, timestamp, conversation context, and relevance percentage. Include filters for date range and specific conversations. Add transparency showing search interpretation and why results were surfaced. Handle no results gracefully with suggestions to broaden search. Target <2s search response time and 90%+ relevance accuracy. This transforms entire message history into instantly searchable knowledge base.

**User Capability:** Users can search conversations using natural language queries and get semantically relevant results

**Dependencies:** PR #AI-001 (RAG Pipeline), PR #AI-002 (User Preferences for filters), PR #AI-003 (Function Calling), PR #AI-004 (Memory/State), PR #AI-005 (Error Handling)

**Complexity:** Complex

**Phase:** 2

---

## Phase 3: Core AI Features - Batch 2

### PR #AI-009: Priority Message Detection

**Brief:** Implement intelligent message categorization system that automatically sorts messages into Urgent, Can Wait, and AI Handled buckets with transparent reasoning. Create background Cloud Function `categorizeMessage(messageId)` triggered on new messages that analyzes sender relationship (from urgent contacts list), message content (urgent keywords, deadlines, @mentions), temporal context (today/tomorrow mentioned, overdue follow-ups), and conversation patterns. Store categorization in Firestore with reasoning data (confidence level, signals identified, evidence links). Build `PriorityInboxView.swift` dashboard showing three-section layout: Urgent (red badge, 2 messages), Can Wait (blue badge, 8 messages), AI Handled (gray badge, 15 messages collapsed by default). Display transparency reasoning when tapping category explanation icon showing why message was categorized and confidence level. Allow manual override by dragging messages between categories which feeds learning data back to Memory/State system. Respect User Preferences for urgent contacts and keywords in categorization logic. This solves impossible prioritization problem letting Maya check phone 3 times per day instead of 30.

**User Capability:** AI automatically categorizes messages as Urgent/Can Wait/AI Handled with transparent reasoning

**Dependencies:** PR #AI-001 (RAG Pipeline), PR #AI-002 (User Preferences), PR #AI-003 (Function Calling), PR #AI-004 (Memory/State for learning), PR #AI-005 (Error Handling)

**Complexity:** Complex

**Phase:** 3

---

### PR #AI-010: Decision Tracking

**Brief:** Build decision detection and tracking system that automatically identifies when decisions are made in conversations and logs them in queryable history. Create Cloud Function `trackDecisions(threadId)` that uses RAG pipeline to detect decision patterns in messages including approval language (approved, decided, let's go with, confirmed), authority signals (manager giving green light), consensus indicators (team agrees, everyone on board), and commitment phrases (we'll move forward, starting Monday). Store detected decisions in Firestore under `/users/{userId}/decisions/` with structured fields for decision text, participants, timestamp, conversation context, and confidence score. Implement `DecisionHistoryView.swift` showing chronological decision log with filters by date range, conversation, and decision type. Add decision detail view showing full context, who made decision, related messages, and affected topics. Enable natural language queries like "What decisions were made last week?" or "Show me all budget decisions." Include transparency reasoning showing signals that triggered decision detection. This solves digital FOMO by letting Maya disconnect confidently knowing she can instantly catch up on key decisions.

**User Capability:** AI automatically detects and logs decisions from conversations with queryable history

**Dependencies:** PR #AI-001 (RAG Pipeline), PR #AI-003 (Function Calling), PR #AI-004 (Memory/State), PR #AI-005 (Error Handling)

**Complexity:** Complex

**Phase:** 3

---

### PR #AI-011: Proactive Assistant (Meeting Scheduling)

**Brief:** Implement proactive meeting scheduling assistant that detects scheduling needs and suggests optimal meeting times respecting focus hours. Create Cloud Function `detectSchedulingNeed(threadId)` that identifies meeting requests in messages using phrases like "let's meet," "can we chat," "schedule a call," or "find time." Build `checkCalendar(startDate, endDate)` function integrating with iOS Calendar API to fetch user availability. Implement `suggestMeetingTimes(participants, duration)` that analyzes calendars, respects User Preferences focus hours (10am-2pm protected), avoids back-to-back meetings, and suggests 3 optimal times ranked by convenience. Create proactive notification system that alerts user when meeting request detected showing suggested times with one-tap booking. Build `MeetingSuggestionsView.swift` modal displaying AI reasoning (who wants to meet, why AI picked these times, focus hours respected), suggested times with calendar preview, and action buttons (Book, Suggest Different Times, Ignore). Store meeting suggestions in Memory/State for follow-up if ignored. This reduces scheduling back-and-forth from 5+ messages to 1 saving 100 minutes per week.

**User Capability:** AI detects meeting requests and proactively suggests optimal times respecting focus hours

**Dependencies:** PR #AI-001 (RAG Pipeline for detection), PR #AI-002 (User Preferences for focus hours), PR #AI-003 (Function Calling), PR #AI-004 (Memory/State), PR #AI-005 (Error Handling)

**Complexity:** Complex

**Phase:** 3

---

## Phase 4: Integration & Polish

### PR #AI-012: Transparency & Confidence System

**Brief:** Implement comprehensive transparency system across all AI features that explains reasoning, shows confidence levels, and links to evidence. Create unified `AITransparencyView.swift` component showing three transparency elements: (1) Reasoning text in first-person supportive language explaining why AI made decision, (2) Confidence badge (High/Moderate/Uncertain) with color coding (green/yellow/orange), (3) Evidence links showing exact messages, keywords, or signals that triggered AI decision. Add transparency sections to Thread Summarization (messages analyzed, key signals found), Action Item Extraction (task phrases detected, deadline mentioned), Priority Detection (urgency signals, sender relationship), Decision Tracking (approval language found), and Smart Search (relevance reasoning). Implement tap-to-expand evidence showing highlighted message excerpts with matched keywords. Include confidence calibration where AI admits uncertainty ("I'm not sure about this one") when confidence below 70%. Store transparency data with all AI results in Firestore. Add settings toggle for "Show AI Reasoning" defaulting to ON for trust building. This builds user trust through understanding unlike black-box AI systems.

**User Capability:** All AI features show transparent reasoning, confidence levels, and evidence for decisions

**Dependencies:** All Phase 2 & 3 AI features (PR #AI-006 through PR #AI-011)

**Complexity:** Medium

**Phase:** 4

---

### PR #AI-013: AI Feature Integration Testing

**Brief:** Implement comprehensive integration testing suite ensuring all AI features work seamlessly together and meet performance targets. Create test suite covering cross-feature workflows: Priority Detection → Thread Summarization (urgent message gets summarized), Smart Search → Decision Tracking (search finds logged decisions), Action Items → Proactive Assistant (detected tasks trigger scheduling suggestions), Memory/State → Priority Detection (learning improves categorization). Build performance tests validating targets: message indexing <500ms, semantic search <1s, full AI response <2s, all features working under load (100+ messages). Test error scenarios: OpenAI timeout during summarization (shows fallback), Pinecone unavailable during search (uses keyword fallback), rate limit during batch categorization (queues for retry). Create real-world test data mimicking Maya's use case: 150 messages across 8 conversations after 4-hour focus session. Implement automated test runner measuring accuracy metrics: summarization quality 90%+, action item extraction 95%+, priority detection 95%+, search relevance 90%+. Document test results and identified issues for fixes before production.

**User Capability:** All AI features work reliably together with validated performance and accuracy targets

**Dependencies:** All Phase 1, 2, 3 features (PR #AI-001 through PR #AI-011)

**Complexity:** Complex

**Phase:** 4

---

### PR #AI-014: Calm Intelligence UX Polish

**Brief:** Polish all AI features to embody Calm Intelligence design philosophy with gentle interactions, ambient reassurance, and spacious UI. Implement calm visual language: soft blues and greens (no aggressive reds), generous whitespace, slow deliberate animations (300ms+ transitions), readable typography with comfortable sizing. Add ambient reassurance elements: "All caught up ✓" state when no urgent messages with calm green checkmark, progress indicators showing "Notification interruptions down 67% this week," end-of-session summary showing "You handled 12 conversations today ✓," and supportive empty states with helpful next actions. Create gentle feedback patterns: soft haptics on AI actions, calm sound effects (optional), subtle loading states avoiding anxiety, no red urgent badges unless truly urgent. Implement forgiving interactions: easy undo for AI actions, manual override for all AI decisions, no permanent consequences, clear cancel options. Add onboarding flow teaching Calm Intelligence principles with example scenarios showing how AI reduces interruptions and preserves focus. Polish dark mode with Cosmos.com aesthetic (deep space, subtle glows, sophisticated). This ensures every AI interaction feels calming not anxiety-inducing.

**User Capability:** All AI features have polished calm UI with gentle feedback, ambient reassurance, and forgiving interactions

**Dependencies:** All Phase 2 & 3 AI features (PR #AI-006 through PR #AI-011)

**Complexity:** Medium

**Phase:** 4

---

### PR #AI-015: Production Deployment & Monitoring

**Brief:** Deploy all AI features to production with gradual rollout, comprehensive monitoring, and feedback collection system. Implement feature flags for each AI capability enabling gradual rollout: 5% users (alpha testers), 20% users (early adopters), 50% users (beta), 100% users (general availability). Set up monitoring dashboard tracking AI system health metrics: API response times (target <2s), error rates (target <1%), embedding generation speed (target <500ms), search accuracy (user satisfaction), categorization agreement rate (manual overrides), and OpenAI/Pinecone quota usage. Create alerting system for critical issues: API timeouts exceeding 5%, error rate above 2%, quota nearing limit, user satisfaction dropping below 80%. Implement user feedback collection with in-app feedback buttons on all AI results asking "Was this helpful?" with optional comment field. Build admin analytics dashboard showing feature adoption (which AI features used most), user satisfaction by feature, common error patterns, and cost analysis (OpenAI tokens, Pinecone queries). Store production logs for debugging AI issues. Include rollback plan for disabling features if critical issues found. This ensures stable, monitored production deployment.

**User Capability:** AI features deployed to production with monitoring, feedback collection, and gradual rollout

**Dependencies:** All AI features (PR #AI-001 through PR #AI-014)

**Complexity:** Medium

**Phase:** 4

---

## 📊 Summary

### Project Progress
- **Phase 1 (Foundation):** 0/5 Complete (0%)
- **Phase 2 (Core Features - Batch 1):** 0/3 Complete (0%)
- **Phase 3 (Core Features - Batch 2):** 0/3 Complete (0%)
- **Phase 4 (Integration & Polish):** 0/4 Complete (0%)

### Overall Status
- **Total PRs:** 15
- **Completed:** 0 (0%)
- **In Progress:** 0
- **Pending:** 15 (100%)

### Parallel Development Strategy
**Phase 1:** All 5 foundation PRs can be developed in parallel since they have minimal dependencies:
- Agent 1: PR #AI-001 (RAG Pipeline), PR #AI-003 (Function Calling), PR #AI-005 (Error Handling)
- Agent 2: PR #AI-002 (User Preferences), PR #AI-004 (Memory/State)

**Phase 2:** 3 features developed in parallel after Phase 1 complete:
- Agent 1: PR #AI-008 (Smart Search - infrastructure heavy)
- Agent 2: PR #AI-006 (Thread Summarization), PR #AI-007 (Action Items - UI heavy)

**Phase 3:** 3 features developed in parallel after Phase 2 complete:
- Agent 1: PR #AI-009 (Priority Detection), PR #AI-010 (Decision Tracking)
- Agent 2: PR #AI-011 (Proactive Assistant)

**Phase 4:** Integration and polish - both agents collaborate:
- Both: PR #AI-012 (Transparency), PR #AI-013 (Testing), PR #AI-014 (UX Polish), PR #AI-015 (Deployment)

### Next Steps
Start with Phase 1 parallel development using 2 worktrees:

```bash
# Agent 1 worktree (main repo)
cd /Users/claudiaalban/Desktop/MessagingApp
git checkout -b feat/ai-foundation-batch-1

# Agent 2 worktree (parallel)
git worktree add ../MessagingApp-worktree2 -b feat/ai-foundation-batch-2
```

**Agent 1 starts with:**
1. PR #AI-001 - RAG Pipeline Infrastructure
2. PR #AI-003 - Function Calling Framework
3. PR #AI-005 - Error Handling System

**Agent 2 starts with:**
1. PR #AI-002 - User Preference Storage
2. PR #AI-004 - Memory & State Management

Both agents can work simultaneously without conflicts since PRs are independent.

---

## Feature-to-Requirement Mapping

| AI Requirement | PRs That Implement It |
|----------------|----------------------|
| **RAG Pipeline** | PR #AI-001 (Infrastructure), PR #AI-006 (Thread Summary), PR #AI-007 (Action Items), PR #AI-008 (Smart Search), PR #AI-009 (Priority Detection), PR #AI-010 (Decision Tracking), PR #AI-011 (Proactive Assistant) |
| **User Preferences** | PR #AI-002 (Storage System), PR #AI-009 (Priority Detection), PR #AI-011 (Meeting Scheduling) |
| **Function Calling** | PR #AI-003 (Framework), All Phase 2 & 3 features use it |
| **Memory/State** | PR #AI-004 (System), PR #AI-006 (Thread summaries), PR #AI-007 (Task completion), PR #AI-009 (Learning from overrides), PR #AI-010 (Decision history) |
| **Error Handling** | PR #AI-005 (System) + All features implement calm error UX |

---

## Assignment Demo Coverage

**Demo 1: Overwhelming Re-entry Recovery**
Maya returns from 4-hour focus session to 150 unread messages:
- Uses PR #AI-006 (Thread Summarization) - 47 messages → 2-sentence digest
- Uses PR #AI-007 (Action Item Extraction) - 3 tasks from 150 messages
- Uses PR #AI-001 (RAG Pipeline) - retrieves and analyzes all messages
- Uses PR #AI-004 (Memory/State) - tracks summaries and action items
- **Success Metric:** 150 messages processed in <1 minute vs 20+ minutes manual

**Demo 2: Impossible Prioritization Solved**
Maya receives 20 messages during meeting (1 urgent production issue, 19 noise):
- Uses PR #AI-009 (Priority Detection) - 1 Urgent, 5 Can Wait, 14 AI Handled
- Uses PR #AI-008 (Smart Search) - "Find Q4 roadmap" → instant result
- Uses PR #AI-002 (User Preferences) - urgent contacts and keywords
- Uses PR #AI-004 (Memory/State) - learns from manual overrides
- **Success Metric:** 1 interruption instead of 20, <2s search, 95%+ accuracy

Both demos fully functional after Phase 3 completion.

---

## Success Metrics

### AI Quality Targets
- Thread Summarization: 90%+ user satisfaction, <2s response
- Action Item Extraction: 95%+ accuracy (no missed tasks), <2s response
- Smart Search: <2s response, 90%+ relevance
- Priority Detection: 95%+ accuracy, transparent reasoning
- Decision Tracking: 90%+ pattern detection accuracy
- Proactive Assistant: 85%+ useful suggestions

### Technical Performance
- Message indexing: <500ms
- Semantic search: <1s
- Full AI response: <2s
- Error rate: <1% of requests
- Uptime: 99.9%

### User Experience (Calm Intelligence Metrics)
- Interruption reduction: 67% vs traditional messaging app
- Focus preservation: 3+ hours uninterrupted deep work
- User sentiment: "More in control, less overwhelmed"
- Trust indicators: Users understand and agree with AI decisions (95%+)
- Engagement quality: More focus time, less app time

---

**Author:** Brad Agent (PR Brief Builder)  
**Status:** Ready for Implementation  
**Delivery:** ASAP via 2-agent parallel development strategy  
**Team Size:** 2 agents in 2 worktrees  
**Expected Outcome:** Production-ready AI features delivering Calm Intelligence, 67% interruption reduction, and 3+ hours focus preservation

---

**Questions or Need Clarification?**
- Project: MessageAI - Calm Intelligence Communication
- Product Vision: MessageAI/docs/AI-PRODUCT-VISION.md
- Assignment Spec: MessageAI/docs/ai-assignment-specification.md

---

Each PR delivers a complete, testable AI capability that builds incrementally toward the Calm Intelligence vision where users spend LESS time in app but feel MORE in control.
