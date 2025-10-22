# Alice's Memory Bank

I am Alice, an expert software engineer with a unique characteristic: my memory resets completely between sessions. This isn't a limitation - it's what drives me to maintain perfect documentation. After each reset, I rely ENTIRELY on my Memory Bank to understand the project and continue work effectively. I MUST read ALL memory bank files at the start of EVERY task - this is not optional.

## Memory Bank Structure

The Memory Bank consists of core files and optional context files, all in Markdown format. Files build upon each other in a clear hierarchy:

### Core

**Answer in one sentence**
1. Brief
   - Foundation document that shapes all other files
   - Created at project start if it doesn't exist
   - Defines core requirements and goals
   - Source of truth for project scope

2. Context
   - Why this project exists
   - Problems it solves
   - How it should work
   - User experience goals

3. Active Context
   - Current work focus
   - Recent changes
   - Next steps
   - Active decisions and considerations
   - Important patterns and preferences
   - Learnings and project insights

4. System Patterns
   - System architecture
   - Key technical decisions
   - Design patterns in use
   - Component relationships
   - Critical implementation paths

5. Tech Context
   - Technologies used
   - Development setup
   - Technical constraints
   - Dependencies
   - Tool usage patterns

6. Progress (skip because not currently in development)
   - What works
   - What's left to build
   - Current status
   - Known issues
   - Evolution of project decisions

---

## 1. Brief

**Project:** Message AI — Building Cross-Platform Messaging Apps

**Tagline:** Building Cross-Platform Messaging Apps

**What It Is:** A native iOS chat application focused on simplicity, reliability, and a seamless user experience. It provides core messaging features, including one-on-one chats, group chats, and real-time synchronization, supported by robust offline capabilities.

**Core Requirements (10 Hard Requirements):**
1. One-on-one Chat Functionality
2. Real-time Message Delivery (2+ users)
3. Message Persistence (Survives App Restarts)
4. Optimistic UI Updates
5. Online/Offline Status Indicators
6. Message Timestamps
7. User Authentication (Accounts/Profiles)
8. Basic Group Chat Functionality (3+ users)
9. Message Read Receipts
10. Push Notifications (Foreground)

**Success Criteria (Must Have - P0 MVP):**
- ✅ Users can successfully create an account and log in
- ✅ Users can start and participate in 1-on-1 conversations
- ✅ Users can start and participate in group (3+ user) conversations
- ✅ New messages are delivered in real-time (sub-3-second latency) to all participants
- ✅ Messages are persisted locally; all chats are viewable on app restart with no internet
- ✅ Sent messages appear in the UI instantly (Optimistic UI)
- ✅ Users can see "online" or "offline" status for other users
- ✅ All messages display an accurate, server-synced timestamp
- ✅ Users can see "Read" receipts on messages they have sent
- ✅ Users receive a push notification when the app is in the foreground or background

---

## 2. Context

**Why This Project Exists:**
- Building a modern, cross-platform messaging application that prioritizes simplicity and reliability
- Creating a seamless user experience for real-time communication
- Demonstrating expertise in iOS development with SwiftUI and Firebase integration

**Problems It Solves:**
- Need for reliable real-time messaging with offline capabilities
- Cross-platform messaging solution that works consistently
- Modern chat experience with optimistic UI and real-time updates
- Secure user authentication and message persistence

**How It Should Work:**
- Intuitive user journey from onboarding to active communication
- Real-time message delivery with optimistic UI updates
- Offline-first approach with local message persistence
- Push notifications for background message delivery
- Clean, modern interface built with SwiftUI

**User Experience Goals:**
- Seamless onboarding and authentication
- Instant message delivery with visual feedback
- Reliable offline functionality
- Clear presence indicators and read receipts
- Smooth group chat creation and management

---

## 3. Active Context

**Current Work Focus:**
- Project is in planning/design phase
- Memory bank documentation is being completed
- Ready to begin implementation following the 4-phase milestone plan

**Recent Changes:**
- Created comprehensive PRD with technical specifications
- Defined database schema for Firestore
- Selected technology stack (SwiftUI + Firebase)
- Established implementation milestones

**Next Steps:**
- Phase 1: Core Foundation
  - Setup Firebase project (Auth, Firestore, FCM)
  - Implement User Authentication (Sign up, Log in, Log out)
  - Create basic SwiftUI app structure and navigation
  - Build `users` collection and basic user profile model

**Active Decisions and Considerations:**
- SwiftUI chosen over UIKit for faster development and better data binding
- Firebase selected as Backend-as-a-Service for comprehensive feature coverage
- Firestore for main database, Realtime Database for presence indicators
- Optimistic UI pattern for instant user feedback

**Important Patterns and Preferences:**
- Offline-first architecture with local persistence
- Real-time updates using Firestore snapshot listeners
- Server timestamps for consistent message ordering
- Cloud Functions for push notification triggers

**Learnings and Project Insights:**
- Firebase provides comprehensive solution for all 10 hard requirements
- SwiftUI's data binding is ideal for real-time chat applications
- Optimistic UI significantly improves perceived performance
- Offline persistence is crucial for mobile messaging apps

---

## 4. System Patterns

**System Architecture:**
- **Frontend:** Native iOS app built with SwiftUI
- **Backend:** Firebase Backend-as-a-Service
- **Database:** Firestore (NoSQL) for main data, Realtime Database for presence
- **Authentication:** Firebase Authentication
- **Push Notifications:** Firebase Cloud Messaging + Apple Push Notification service
- **Server Logic:** Cloud Functions for push notification triggers

**Key Technical Decisions:**
- **SwiftUI over UIKit:** Faster development, better data binding, cross-platform potential
- **Firebase over custom backend:** Comprehensive feature coverage, real-time capabilities, offline support
- **Firestore over SQL:** NoSQL structure fits chat data model, real-time listeners, offline cache
- **Optimistic UI:** Immediate user feedback, then server confirmation

**Design Patterns in Use:**
- **MVVM Architecture:** SwiftUI views with ViewModels for state management
- **Repository Pattern:** Data access layer for Firebase operations
- **Observer Pattern:** Firestore snapshot listeners for real-time updates
- **Offline-First:** Local persistence with sync when online

**Component Relationships:**
- **Authentication Service:** Handles user sign-up, login, session management
- **Chat Service:** Manages chat creation, message sending, real-time updates
- **Presence Service:** Tracks online/offline status using Realtime Database
- **Notification Service:** Handles push notification registration and delivery

**Critical Implementation Paths:**
1. **User Flow:** Onboarding → Home → Chat → Real-time messaging
2. **Message Flow:** User input → Optimistic UI → Firestore write → Real-time sync
3. **Offline Flow:** Local cache → Queue messages → Sync when online
4. **Notification Flow:** New message → Cloud Function → FCM → Push notification

---

## 5. Tech Context

**Technologies Used:**
- **Frontend:** SwiftUI (iOS 13+), Xcode
- **Backend:** Firebase (Auth, Firestore, FCM, Cloud Functions)
- **Database:** Firestore (NoSQL), Realtime Database (presence)
- **Push Notifications:** Apple Push Notification service (APNs)
- **Authentication:** Firebase Auth (email/password, social auth)

**Development Setup:**
- **Platform:** iOS native development
- **Minimum Target:** iOS 13+ (>90% market adoption in 2025)
- **IDE:** Xcode
- **Language:** Swift
- **Framework:** SwiftUI

**Technical Constraints:**
- iOS 13+ minimum deployment target
- Firebase project configuration required
- Apple Developer account for push notifications
- APNs certificate setup for production

**Dependencies:**
- Firebase iOS SDK
- SwiftUI framework
- iOS 13+ deployment target
- Xcode 11+ for SwiftUI support

**Tool Usage Patterns:**
- **Firebase Console:** Project configuration, authentication setup, database management
- **Xcode:** iOS development, SwiftUI interface building, testing
- **Cloud Functions:** Serverless backend logic for push notifications
- **Firestore Security Rules:** Data access control and validation

**Database Schema (Firestore NoSQL):**
```
users (Collection)
├── {userID} (Document)
    ├── uid: "string"
    ├── displayName: "string"
    ├── email: "string"
    └── profilePhotoURL: "string" (optional)

chats (Collection)
├── {chatID} (Document)
    ├── members: ["userID_A", "userID_B", "userID_C"] (Array)
    ├── lastMessage: "string"
    ├── lastMessageTimestamp: Timestamp
    ├── isGroupChat: true/false
    └── messages (Sub-collection)
        └── {messageID} (Document)
            ├── text: "string"
            ├── senderID: "string"
            ├── timestamp: Timestamp (serverTimestamp)
            └── readBy: ["userID_A", "userID_B"] (Array)
```

**Implementation Milestones:**
- **Phase 1:** Core Foundation (Auth, basic structure)
- **Phase 2:** 1-on-1 Chat (real-time messaging, optimistic UI)
- **Phase 3:** Group Chats & Presence (multi-user chats, online status)
- **Phase 4:** Polish & Notifications (read receipts, push notifications)
