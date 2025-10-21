# MessageAI - PR Brief List

**Project**: Cross-Platform Messaging App  
**Framework**: SwiftUI + Firebase  
**Target**: iOS Native Application  

---

## Phase 1: Core Foundation

### PR #1: Firebase Project Setup & Authentication Foundation

**Brief:** Establish the core Firebase infrastructure including project configuration, authentication setup, and basic user management. This PR creates the foundation for all subsequent features by implementing Firebase Auth with email/password and social login options, setting up Firestore database structure, and creating the basic user profile system. Includes proper error handling, offline persistence configuration, and security rules.

**Dependencies:** None

**Complexity:** Medium

**Phase:** 1

---

### PR #2: Core SwiftUI App Structure & Navigation

**Brief:** Build the fundamental SwiftUI app architecture with proper navigation patterns, state management, and basic UI components. This includes the main app structure, navigation controllers, basic theming, and the foundation for all screens. Implements proper SwiftUI patterns for data binding and state management that will support real-time updates throughout the app.

**Dependencies:** PR #1

**Complexity:** Medium

**Phase:** 1

---

### PR #3: User Profile Management & Contact System

**Brief:** Implement comprehensive user profile management including profile creation, editing, photo upload, and contact discovery. This PR creates the user collection in Firestore, implements profile CRUD operations, and establishes the contact system that will be used for starting conversations. Includes proper data validation and security rules.

**Dependencies:** PR #1, PR #2

**Complexity:** Medium

**Phase:** 1

---

### PR #3.5: Google Sign-In Authentication

**Brief:** Implement Google Sign-In as an authentication option alongside email/password. This PR extends the AuthService to support Google OAuth provider, adds a "Sign in with Google" button to authentication screens, and handles the complete OAuth flow including credential exchange, user profile mapping, and account linking. Provides a seamless social login experience that reduces signup friction and automatically populates user profile data (name, email, photo) from Google accounts.

**Dependencies:** PR #1, PR #2, PR #3

**Complexity:** Medium

**Phase:** 1

---

## Phase 2: 1-on-1 Chat

### PR #4: Conversation List Screen

**Brief:** Build the conversation list screen that displays all existing chats with the most recent message, timestamps, and online/offline status of other users. This PR implements the home screen that users see when they open the app, including proper data binding to Firestore and real-time updates when new messages arrive.

**Dependencies:** PR #1, PR #2, PR #3

**Complexity:** Medium

**Phase:** 2

---

### PR #5: Chat View Screen & Message Display

**Brief:** Build the chat view screen that displays messages in a conversation. This PR implements the core chat interface with message bubbles, proper scrolling, and message layout. Includes message timestamps and basic message status indicators.

**Dependencies:** PR #4

**Complexity:** Medium

**Phase:** 2

---

### PR #6: Real-Time Message Sending/Receiving

**Brief:** Implement real-time message sending and receiving using Firestore snapshot listeners. This PR adds the core messaging functionality with Firestore listeners, message creation, and real-time synchronization. Includes proper error handling and network failure management.

**Dependencies:** PR #5

**Complexity:** Complex

**Phase:** 2

---

### PR #7: Optimistic UI & Server Timestamps

**Brief:** Implement optimistic UI updates and server-synced timestamps. This PR ensures messages appear instantly in the UI while being sent to the server, and uses Firestore server timestamps to prevent time-sync issues. Includes proper status indicators for message delivery.

**Dependencies:** PR #6

**Complexity:** Medium

**Phase:** 2

---

### PR #8: Firestore Offline Persistence

**Brief:** Implement comprehensive offline message persistence and synchronization. This PR enables the app to work seamlessly offline by implementing Firestore offline cache, message queuing for offline sends, and proper sync when reconnecting. Users can read all previous messages and send new ones even without internet connectivity.

**Dependencies:** PR #6, PR #7

**Complexity:** Complex

**Phase:** 2

---

## Phase 3: Group Chats & Presence

### PR #9: Create New Chat Flow

**Brief:** Implement the "Create New Chat" flow for selecting 1 or 3+ users to start conversations. This PR adds the interface for starting new conversations, including user selection, contact list integration, and chat creation logic. Supports both one-on-one and group chat creation.

**Dependencies:** PR #4, PR #6

**Complexity:** Medium

**Phase:** 3

---

### PR #10: Group Chat Logic & Multi-User Support

**Brief:** Ensure group chat logic works seamlessly for sending messages to N members. This PR extends the messaging system to handle multiple participants, ensuring all existing features work with group chats. Includes proper member management and group chat UI.

**Dependencies:** PR #9

**Complexity:** Medium

**Phase:** 3

---

### PR #11: Online/Offline Presence Indicators

**Brief:** Integrate Firebase Realtime Database for online/offline presence indicators. This PR implements the presence system that shows when users are online/offline, using Firebase Realtime Database's superior onDisconnect hooks. Includes proper cleanup of presence data and handling of app state transitions.

**Dependencies:** PR #1, PR #3

**Complexity:** Medium

**Phase:** 3

---

## Phase 4: Polish & Notifications

### PR #12: Message Read Receipts

**Brief:** Implement message read receipts logic with client-side and Firestore updates. This PR adds read status tracking for messages, proper Firestore field updates when users view messages, and visual indicators for read receipts. Includes proper UI state management for read status.

**Dependencies:** PR #6, PR #7

**Complexity:** Medium

**Phase:** 4

---

### PR #13: APNs & Firebase Cloud Messaging Setup

**Brief:** Configure Apple Push Notification service and Firebase Cloud Messaging integration. This PR implements the complete push notification system including device token management, notification payload handling, and proper notification display. Includes background and foreground notification handling.

**Dependencies:** PR #1, PR #6

**Complexity:** Complex

**Phase:** 4

---

### PR #14: Cloud Functions for Push Notifications

**Brief:** Write and deploy Cloud Function to trigger push notifications when new messages are sent. This PR creates serverless backend functions that monitor Firestore for new messages and automatically send push notifications to all chat participants. Includes proper error handling and notification customization.

**Dependencies:** PR #13

**Complexity:** Complex

**Phase:** 4

---

### PR #15: Notification Testing & Validation

**Brief:** Test notifications across all app states (foreground, background, terminated) and validate proper delivery. This PR includes comprehensive testing of the notification system, ensuring notifications work correctly in all scenarios and app states.

**Dependencies:** PR #13, PR #14

**Complexity:** Medium

**Phase:** 4

---

### PR #16: Bug Fixing & UI Polish

**Brief:** Complete bug fixing and UI polish to ensure a production-ready application. This PR includes comprehensive testing, bug fixes, UI improvements, and final polish. Ensures the app meets all quality standards and provides an excellent user experience.

**Dependencies:** All previous PRs

**Complexity:** Medium

**Phase:** 4

---

## Implementation Summary

**Total PRs:** 17  
**Phase 1 (Core Foundation):** 4 PRs  
**Phase 2 (1-on-1 Chat):** 5 PRs  
**Phase 3 (Group Chats & Presence):** 3 PRs  
**Phase 4 (Polish & Notifications):** 5 PRs  

**Complexity Distribution:**
- Medium: 12 PRs  
- Complex: 5 PRs

**Key Dependencies:**
- PR #1 (Firebase Setup) is foundational for all features
- PR #3.5 (Google Sign-In) reduces signup friction and improves user onboarding
- PR #6 (Real-Time Messaging) is the core messaging foundation
- PR #7 (Optimistic UI) enables smooth user experience
- PR #8 (Offline Support) is critical for user experience
