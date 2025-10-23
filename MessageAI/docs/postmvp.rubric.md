# Messaging App Rubric — Checklist & Review Guide

Use this document to score your build, track progress, and capture evidence for demo day.

## 📊 Scoring Overview
- **Total Points**: 93 base points + 3 bonus = 96 possible
- **Target Score**: ≥ 80 points
- **Scoring Levels**: Excellent (highest tier) | Good (acceptable tier)

---

## 🚀 Core Messaging Features

### 1. Real-Time Message Delivery (12 points)

#### Excellent (11–12 pts) — Requirements
- ☐ p95 end-to-end latency < 200 ms on good Wi‑Fi (sent → server ack → render)
- ☐ 20+ messages rapidly: no visible lag or out-of-order renders
- ☐ Typing indicators appear within < 200 ms; hide < 500 ms after idle
- ☐ Presence (online/offline) flips propagate within < 500 ms for all online users

#### Good (9–10 pts) — Requirements
- ☐ Latency consistently < 300 ms
- ☐ Only minor delays under heavy load
- ☐ Typing indicators mostly responsive

### 2. Offline Message Persistence & Sync (12 points)

#### Excellent (11–12 pts) — Requirements
- ☐ Offline queue: compose 3 msgs in Airplane Mode → visible 'Queued' → auto-send on reconnect
- ☐ Force-quit → reopen: full chat history preserved
- ☐ Messages sent while offline appear to others once online
- ☐ 30s+ network drop → auto-reconnect; full sync completes in < 1 s
- ☐ Clear UI indicators: Connecting… / Offline / Sending X…

#### Good (9–10 pts) — Requirements
- ☐ Offline queuing works for most scenarios
- ☐ Reconnection works, may lose last 1–2 messages
- ☐ Connection status shown; minor sync delays (2–3 s)

### 3. Group Chat (11 points)

#### Excellent (10–11 pts) — Requirements
- ☐ 3+ users can message simultaneously with smooth performance
- ☐ Clear attribution (names/avatars) on each message
- ☐ Per-message read receipts show who has read
- ☐ Typing indicators support multiple users (e.g., "Alice & Bob are typing…")
- ☐ Member list with live online status

#### Good (8–9 pts) — Requirements
- ☐ Group chat works for 3–4 users with good attribution
- ☐ Read receipts mostly accurate
- ☐ Minor issues under heavy use

### 4. Mobile Lifecycle Handling (8 points)

#### Excellent (7–8 pts) — Requirements
- ☐ Backgrounding preserves socket or reconnects instantly
- ☐ Foregrounding performs instant sync of missed messages
- ☐ Push notifications deliver when app is closed; deep-link to thread
- ☐ No message loss during lifecycle transitions
- ☐ Battery friendly (no excessive background activity)

#### Good (5–6 pts) — Requirements
- ☐ Lifecycle mostly handled; reconnection 2–3 s
- ☐ Push notifications work; minor sync delays

### 5. Performance & UX (12 points)

#### Excellent (11–12 pts) — Requirements
- ☐ Cold launch → inbox in < 2 s; inbox → thread < 400 ms
- ☐ Smooth 60 FPS scrolling across 1000+ messages (list windowing)
- ☐ Optimistic UI: local echo instantly; retry/edit on failure
- ☐ Images load progressively with placeholders
- ☐ Keyboard handling: no layout jank; input stays pinned
- ☐ Professional layout and transitions

#### Good (9–10 pts) — Requirements
- ☐ Launch under 3 s; smooth scrolling across 500+ messages
- ☐ Optimistic updates work; keyboard handling good
- ☐ Only minor layout issues

---

## 🤖 AI Features & Intelligence

### 6. AI Features for Chosen Persona (13 points) — Remote Team Professional

#### Good (11–13 pts) — Requirements
- ☐ Implement 5: Thread Summarization, Action-Item Extraction, Smart Search, Priority Detection, Decision Tracking
- ☐ ≥ 80% command accuracy on a 20-case eval set (document expected vs actual)
- ☐ Response times 2–3 s typical; basic error handling and good UI integration
- ☐ Each feature links to source messages where applicable

#### Feature Evaluation by Persona — What to Verify
- ☐ Thread summarization captures key points
- ☐ Action items correctly extracted with assignee/due when present
- ☐ Smart search returns relevant messages and highlights matches
- ☐ Priority detection flags urgent messages accurately
- ☐ Decision tracking surfaces agreed-upon decisions with links

### 7. Persona Fit & Relevance (5 points)

#### Excellent (5 pts) — Requirements
- ☐ AI features clearly map to daily pain points for Remote Team Professionals
- ☐ Each feature demonstrates contextual value and daily usefulness
- ☐ Overall experience feels purpose-built (not generic)

### 8. Advanced AI Capabilities (8 points)

#### Good (7–8 pts) — Requirements
- ☐ At least one advanced capability works well (e.g., function-calling with cite-back, vector search/RAG)
- ☐ Handles most scenarios correctly; minor edge-case issues acceptable
- ☐ Meets most performance targets; good framework usage

---

## 🛠️ Technical Implementation

### 9. Technical Implementation (4 points)

#### Good (4 pts) — Requirements
- ☐ Solid app structure and folder organization
- ☐ Secrets/keys mostly secure and environment-scoped
- ☐ Function calling wired and tested
- ☐ Basic RAG path in place (if applicable)

### 10. Authentication & Data Management (5 points)

#### Good (4 pts) — Requirements
- ☐ Functional authentication with user profiles
- ☐ Good user management (names, avatars)
- ☐ Basic sync logic and local storage/cache works
- ☐ Minor issues acceptable

### 11. Repo & Setup (2 points)

#### Good (2 pts) — Requirements
- ☐ README includes setup steps, env template, and architecture overview
- ☐ One-command run or clear scripts; setup mostly clear

### 12. Deployment (1 point)

#### Good (1 pt) — Requirements
- ☐ Deployed build accessible (TestFlight/APK/Web) with minor issues acceptable
- ☐ Works on most devices or simulator with clear instructions

---

## 🎯 Innovation Bonus (+3 points)

### Insights + Priority Sections (Beginner-Friendly)

#### Acceptance Checks
- ☐ Insights sheet shows: Summary, Decisions (with who/what/when), Action Items (assignee/due), Next Check‑in
- ☐ Each insight item links back to source message (jump-to highlight)
- ☐ Four Priority Sections (Urgent / Needs Reply / FYI / Later) filter instantly at 60 FPS
- ☐ Manual priority override persists and never auto-reclassifies

#### Priority Classification — Heuristic v1 (ASAP Path)
- ☐ Urgent: @mentions or time-sensitive language (ASAP, EOD, by Friday) or due < 48h
- ☐ Needs Reply: has question mark or direct request (can you / please)
- ☐ FYI: announcements/updates
- ☐ Later: default bucket if no signals
- ☐ p95 classification latency < 150 ms per new message
- ☐ Offline: heuristic applies; online: stays the same (no jank)
---

## 📋 Evidence to Capture (Attach to README / Demo)

### Performance Metrics
- ☐ Latency histogram (sent → ack → render) and p95 screenshot
- ☐ Offline queue & reconnect timeline (screenshots/video)
- ☐ 3-user demo: typing, receipts, presence (short clip)
- ☐ Profiler trace: 60 FPS with 1000+ messages (windowing proof)
- ☐ AI eval table: 20 examples with accuracy % and links to sources
- ☐ Setup & build instructions screenshot; store links to builds

---

## 📈 Progress Tracker

| Category | Target Level | Status | Notes / Proof to Collect |
|----------|-------------|--------|-------------------------|
| **Real-Time Delivery** (12 pts) | Excellent | Need | p95 < 200 ms; burst test; typing/presence timings |
| **Offline/Persistence** (12 pts) | Excellent | Need | Airplane/force-quit/long-drop tests |
| **Group Chat** (11 pts) | Good | Need | 3+ users, receipts, multi-typing, roster |
| **Mobile Lifecycle** (8 pts) | Excellent | Need | bg/fg sync, push deep-link |
| **Performance & UX** (12 pts) | Excellent | Need | 60 FPS over 1000+, optimistic UI |
| **AI Features** (13 pts) | Good | Need | 5 features + 80% eval |
| **Persona Fit** (5 pts) | Excellent | Need | Map features → pain points |
| **Advanced AI** (8 pts) | Good | Need | One advanced capability solid |
| **Technical Impl** (4 pts) | Excellent | Need | Keys, func-calling, RAG basics |
| **Auth & Data** (5 pts) | Good | Need | Auth, profiles, local cache |
| **Repo & Setup** (2 pts) | Good | Need | README, scripts, diagram |
| **Deployment** (1 pt) | Good | Need | TestFlight/APK/Web link |
| **Innovation** (+3 pts) | 3 pts | Need | Insights + Priority Sections demo |

---

## 🎯 Final Scoring Summary

- **Total Possible Points**: 93 base + 3 bonus = **96 points**
- **Target Score**: **≥ 80 points**
- **Current Status**: Track progress using the table above

