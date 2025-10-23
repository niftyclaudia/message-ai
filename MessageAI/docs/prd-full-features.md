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
**Status:** ⏳ PLANNED

### 4 Categories

#### 2.1 Technical Implementation (4 pts)
- Audit folder structure and organization
- Review Firebase security rules (database, firestore, storage)
- Secrets management (GoogleService-Info.plist not in git)
- Document architecture with diagrams
- Prep for AI: function calling setup

#### 2.2 Authentication & Data Management (5 pts)
- ✅ Auth flow complete (sign up/in/out)
- Add password reset if missing
- ✅ Profile editing (name + avatar)
- Verify sync logic and offline cache
- Multi-device sync testing

#### 2.3 Repo & Setup (2 pts)
- Comprehensive README (setup, env template, architecture)
- One-command run or clear scripts
- Test setup on fresh clone

#### 2.4 Deployment (1 pt)
- TestFlight build OR simulator with clear instructions
- Test on real device
- Document access

### Key Deliverables
- Security audit complete
- Architecture documented
- Deployed build accessible

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

