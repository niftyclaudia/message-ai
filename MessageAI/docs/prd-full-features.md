# Message AI — Post-MVP Product Requirements

---

## 🎯 What It Is

Post-MVP enhancements to transform the messaging app from a solid MVP into an Excellent-tier product with AI-powered features tailored for Remote Team Professionals. Focus on performance optimization, technical excellence, and intelligent features that reduce message overload.

---

## 📊 Phase Overview

| Phase | Focus | Points | Status |
|-------|-------|--------|--------|
| Pre-Phase | MVP Completion | 0 | ✅ COMPLETE |
| Phase 1 | Core Performance | 43-45 | 🔄 IN PROGRESS |
| Phase 2 | Technical Polish | 12 | ⏳ PLANNED |
| Phase 3 | AI Features | 26 | ⏳ PLANNED |
| Phase 4 | Innovation Bonus | +3 | ⏳ PLANNED |
| Phase 5 | Evidence & Polish | 0 | ⏳ PLANNED |
| **TOTAL** | | **84-86** | **Target: ≥80** |  

---

## 🚀 Phase 1: Core Messaging Performance (43-45 points)

**Goal:** Optimize existing messaging to "Excellent" tier  
**Status:** 🔄 IN PROGRESS  
**Infrastructure:** ✅ PerformanceMonitor.swift ready, ✅ Typing indicators complete

### 5 Categories

#### 1.1 Real-Time Message Delivery (12 pts)
- Message latency p95 < 200ms (sent → ack → render)
- Burst test: 20+ rapid messages, no lag/out-of-order
- ✅ Typing indicators < 200ms (DONE)
- Presence propagation < 500ms

#### 1.2 Offline Persistence & Sync (12 pts)
- 3-msg offline queue in Airplane Mode → auto-send on reconnect
- Force-quit → full history preserved on reopen
- Network drop 30s+ → auto-reconnect, sync < 1s
- Clear UI: Connecting / Offline / Sending X messages

#### 1.3 Group Chat Enhancement (11 pts)
- 3+ users smooth simultaneous messaging
- Clear attribution (names/avatars)
- Per-message read receipts for groups
- ✅ Multi-user typing "Alice & Bob..." (DONE)
- Member list with live online status

#### 1.4 Mobile Lifecycle (8 pts)
- Backgrounding → instant reconnect
- Foregrounding → instant sync
- Push notification → deep-link to correct thread
- Zero message loss, battery friendly

#### 1.5 Performance & UX (12 pts)
- Cold launch < 2s, navigation < 400ms
- 60 FPS scrolling with 1000+ messages (list windowing)
- Optimistic UI instant, retry on failure
- Keyboard: no jank, input pinned
- Professional polish

### Key Deliverables
- Measure baselines with PerformanceMonitor
- Optimize bottlenecks
- Test all scenarios (offline, multi-user, lifecycle)
- Collect evidence (videos, metrics, screenshots)

---

## 🛠️ Phase 2: Technical Excellence & Deployment (12 points)

**Goal:** Polish implementation, security, and get it deployed  
**Status:** 🔄 IN PROGRESS - Dual-agent parallel sprint  
**Philosophy:** **Calm Intelligence** - Building a focus rehabilitation tool, not just a messaging app

### Phase 2 Update: Parallel Sprint Approach

Phase 2 has been reorganized into two parallel work streams (Flow A + Flow B) to accelerate development while integrating **Calm Intelligence** principles throughout.

**Reference**: See `MessageAI/docs/sprints/tomorrow-night-sprint-plan.md` for detailed sprint plan

---

### Flow A: UI/UX Polish (Agent A - develop branch)

**Goal:** Essential messaging features with Calm Intelligence principles

#### Core Features
- **Image Upload & Display** - Send/view images in conversations
  - Firebase Storage integration
  - Offline queueing
  - Lazy loading for performance
  - Calm progress indicators

- **Push Notifications** - Smart, gentle notifications
  - **Calm Intelligence**: Bundle rapid messages (3 in 30s = 1 notification)
  - Gentle defaults (soft sound, no vibration)
  - Deep linking to conversations
  - Don't notify if user actively viewing chat

- **Add Contacts** - Search and add users
  - Search by email/username
  - Gentle empty states
  - Create or navigate to existing chat

- **Delete Messages** - User control over their messages
  - Long-press to delete with gentle confirmation
  - Offline queueing
  - Calm visual feedback

- **"All Caught Up" State** - Ambient reassurance
  - **Calm Intelligence**: Psychological relief when inbox clear
  - Green checkmark with calm design
  - Reduces FOMO

**Agent A Template**: `MessageAI/agents/develop/agent-a-ui-polish-template.md`

---

### Flow B: AI Infrastructure & Features (Agent B - secondagent branch)

**Goal:** Transparent, supportive AI features

#### AI Infrastructure
- OpenAI GPT-4 integration via Cloud Functions
- Swift AI service layer
- Transparent response models (reasoning, confidence, signals)
- Error handling and caching

#### AI Features (2-3 features)
- **Thread Summarization** - Long-press conversation → AI summary
  - **Calm Intelligence**: "I analyzed 47 messages and focused on decisions. High confidence."
  - Show reasoning, confidence, and signals
  - Cache results

- **Action Item Extraction** - Find tasks with transparency
  - **Calm Intelligence**: "I identified this as an action item because Sarah said 'can you' and mentioned Friday"
  - Link to source messages
  - Show assignee, due date, reasoning

- **Priority Detection** (bonus) - Adaptive prioritization
  - **Calm Intelligence**: Not frequency-based, but emotional/temporal context
  - Explain why: "@mentioned + deadline + from manager"

- **Chatbot UI** (bonus if time) - Morning recap assistant
  - Floating button for easy access
  - "What did I miss?" functionality

**Agent B Template**: `MessageAI/agents/secondagent/agent-b-ai-infra-template.md`

---

### Calm Intelligence Integration (Both Flows)

**Four Core Principles Applied**:

1. **Silence by Design**
   - Flow A: Smart notification bundling, gentle defaults
   - Flow B: Summaries instead of constant pings

2. **Ambient Reassurance**
   - Flow A: "All caught up" states
   - Flow B: "You're up to date" from AI

3. **Adaptive Prioritization**
   - Flow A: Context-aware notification timing
   - Flow B: Emotional/temporal context, not just frequency

4. **Transparency-First AI**
   - Flow B: Every AI decision includes reasoning, confidence, signals
   - Flow A: Clear feedback on all actions

**Reference**: See `MessageAI/docs/calm-intelligence-vision.md` for full philosophy

---

### Original Phase 2 Categories (Integrated into Flows)

#### 2.1 Technical Implementation (4 pts)
- ✅ Audit folder structure and organization (PR #6 complete)
- ✅ Review Firebase security rules (PR #6 complete)
- ✅ Secrets management (PR #6 complete)
- 🔄 Document architecture with diagrams (Flow A/B integration)
- 🔄 Prep for AI: function calling setup (Flow B)

#### 2.2 Authentication & Data Management (5 pts)
- ✅ Auth flow complete (PR #7 complete)
- ✅ Password reset functionality (PR #7 complete)
- ✅ Profile editing (PR #7 complete)
- ✅ Verify sync logic and offline cache (PR #7 complete)
- ✅ Multi-device sync testing (PR #7 complete)

#### 2.3 Repo & Setup (2 pts)
- ⏳ Comprehensive README (after sprint)
- ⏳ One-command run or clear scripts (after sprint)
- ⏳ Test setup on fresh clone (after sprint)

#### 2.4 Deployment (1 pt)
- ⏳ TestFlight build OR simulator instructions (after sprint)
- ⏳ Test on real device (after sprint)
- ⏳ Document access (after sprint)

### Key Deliverables
- Flow A features working (images, notifications, contacts, delete)
- Flow B AI features working (summarization + action items with transparency)
- Calm Intelligence principles integrated throughout
- All tests passing
- Documentation updated
- Ready for deployment preparation

---

## 🤖 Phase 3: AI Features for Remote Team Professional (26 points)

**Goal:** Build AI intelligence to reduce message overload  
**Status:** ⏳ PLANNED  
**Persona:** Remote workers drowning in Slack/Teams messages

### 3 Categories + Infrastructure

#### Infrastructure Setup
- Choose AI API (OpenAI GPT-4 or Anthropic Claude)
- Setup vector DB (Pinecone / Firebase / n8n)
- Message indexing pipeline (Cloud Function)
- AI service layer (AIService, VectorSearchService, EmbeddingService)

#### 3.1 Implement 5 Core AI Features (13 pts)
**Target: ≥ 80% accuracy, 2-3s response times**

1. **Thread Summarization** - Skip reading 100+ messages
2. **Action-Item Extraction** - Never miss tasks/deadlines  
3. **Smart Search** - Find by meaning, not exact words
4. **Priority Detection** - Surface urgent messages automatically
5. **Decision Tracking** - Track what was decided + who agreed

Each feature:
- Links back to source messages
- Service + UI implementation
- 20-case eval set for testing

#### 3.2 Persona Fit & Relevance (5 pts)
- Map each feature to Remote Team Professional pain points
- Minimal, detox-focused UX (no spam)
- User testing with 2-3 remote workers
- Document how features reduce overload

#### 3.3 Advanced AI Capabilities (8 pts)
- Implement ONE advanced feature well:
  - Function-calling with cite-back OR
  - RAG (vector search + generation)
- Performance optimization (caching, batching)
- Edge case handling (empty results, rate limits)

### Key Deliverables
- 5 AI features working at ≥80% accuracy
- Persona mapping document
- One advanced capability (RAG or function-calling)
- Evaluation data with 20 test cases

---

## 🎯 Phase 4: Innovation Bonus (+3 points)

**Goal:** Beginner-friendly UI for AI insights + smart filtering  
**Status:** ⏳ PLANNED

### 4.1 Insights Sheet (+1.5 pts)
**Unified AI dashboard in one view**

- Bottom sheet with 4 sections:
  1. Summary (thread summary)
  2. Decisions (who/what/when)
  3. Action Items (assignee/due)
  4. Next Check-in (AI suggestion)
- Tap any item → jump to source message with highlight
- Smooth animations

### 4.2 Priority Sections (+1.5 pts)
**Heuristic-based conversation filtering**

- 4-section conversation list:
  1. **Urgent** - @mentions, time keywords, due < 48h
  2. **Needs Reply** - Questions, direct requests
  3. **FYI** - Announcements/updates
  4. **Later** - Default bucket
- Fast heuristic (regex/keywords), no AI calls
- p95 latency < 150ms, 60 FPS scrolling
- Manual override: long-press → change priority → persists forever
- Offline-capable

### Key Deliverables
- InsightsSheetView with jump-to-message
- PriorityClassificationService with heuristics
- Manual override persisting to Firestore

---

## 📋 Phase 5: Evidence Collection & Final Polish (0 points)

**Goal:** Document everything for demo day  
**Status:** ⏳ PLANNED

### Evidence to Collect

**Performance Metrics:**
- Latency histogram (p95 screenshot)
- Offline queue & reconnect video
- 3-user demo: typing, receipts, presence
- 60 FPS profiler trace with 1000+ messages

**AI Evaluation:**
- 20-example eval table with accuracy %
- Expected vs actual for each feature
- Links to source messages

**Setup & Build:**
- README setup screenshots
- TestFlight link OR simulator instructions
- Build access documented

**Final Testing:**
- End-to-end user flow on real device
- All features working together
- No crashes, smooth experience

### Key Deliverables
- postmvp-completion-report.md with rubric checklist
- README updated with all evidence
- Videos, screenshots, metrics documented

---

## 🎯 Quick Summary

### What's Done ✅
- **Pre-Phase:** Typing indicators, PerformanceMonitor, docs consolidated
- **MVP:** All 10 P0 + 3 P1 features complete

### What's Next 🔄
- **Phase 1 (NOW):** Measure & optimize core messaging performance
- **Phase 2:** Polish tech, deploy to TestFlight
- **Phase 3:** Build 5 AI features for Remote Team Professionals
- **Phase 4:** Insights dashboard + Priority filtering
- **Phase 5:** Collect all evidence, final polish

### Target 🎯
**84-86 points** (need ≥80)

---

## 📌 Note

This is a **high-level roadmap**. Detailed PRDs and TODOs will be created when we start each phase. See `memory-bank.md` for current status and `phase1-performance-optimization.md` for detailed Phase 1 tasks.

