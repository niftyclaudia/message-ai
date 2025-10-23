# ADR-001: Use Firebase as Backend Infrastructure

**Status**: Accepted  
**Date**: October 2025  
**Decision Makers**: MessageAI Team  
**Related**: Phase 1 MVP Architecture

---

## Context

MessageAI requires a backend infrastructure to support:
- **Real-time messaging** - Messages must sync across devices instantly (<100ms)
- **User authentication** - Secure login with email/password and social auth
- **File storage** - Profile photos and future media sharing
- **Push notifications** - Alert users of new messages when app is backgrounded
- **Offline support** - Queue messages when offline, sync on reconnect
- **Multi-device sync** - Same account on iPhone, iPad, Mac simultaneously

### Constraints
- **Team size**: Small team (1-2 developers)
- **Timeline**: MVP in 6-8 weeks
- **Budget**: Limited, prefer pay-as-you-go
- **Expertise**: iOS development (Swift), minimal backend experience
- **Scale**: Prototype → MVP → 1000 users → 10k+ users

---

## Decision

**We will use Firebase as our primary backend infrastructure.**

Specifically:
- **Firestore** - Document database for messages, chats, users
- **Firebase Auth** - Email/password, Google Sign-In, Apple Sign-In
- **Firebase Storage** - Profile photos, future media
- **Realtime Database** - Presence and typing indicators (ephemeral data)
- **Cloud Functions** - Push notifications, background tasks
- **FCM** (Firebase Cloud Messaging) - Push notifications

---

## Rationale

### Why Firebase?

#### 1. Real-Time Listeners (Critical for Chat)
```swift
// Single line to get real-time updates
db.collection("chats/\(chatID)/messages")
    .addSnapshotListener { snapshot, error in
        // Auto-updates whenever messages change
    }
```
- **Immediate sync** - Changes propagate in ~80ms
- **No polling** - Server pushes updates to clients
- **Built-in** - No WebSocket infrastructure needed

#### 2. Offline Support (Out of the Box)
- Firestore automatically caches data locally
- Writes queued when offline, sync on reconnect
- No additional code required for basic offline mode

#### 3. Authentication (Batteries Included)
- Email/password auth
- Social logins (Google, Apple, Facebook)
- Session management and token refresh
- Multi-device support

#### 4. Rapid Development
- **No backend code** for basic CRUD operations
- **iOS SDK** - Native Swift support with async/await
- **Security rules** - Declarative permissions (no backend API)
- **Admin SDK** - For testing and automation

#### 5. Scalability
- **Auto-scaling** - No server management
- **Global CDN** - Low latency worldwide
- **99.95% uptime** SLA
- **Generous free tier** - 50k reads/day, 20k writes/day

#### 6. Cost-Effective for MVP
| Service | Free Tier | Estimated Cost @ 1k Users |
|---------|-----------|---------------------------|
| Firestore | 50k reads/day | ~$15/month |
| Auth | Unlimited | Free |
| Storage | 5 GB | ~$5/month |
| Cloud Functions | 2M invocations | ~$10/month |
| **Total** | | **~$30/month** |

---

## Consequences

### ✅ Positive

1. **Faster MVP delivery**
   - No backend development required
   - Focus 100% on iOS app
   - Real-time sync works immediately

2. **Lower operational complexity**
   - No servers to manage
   - No DevOps required
   - Auto-scaling and high availability

3. **Better developer experience**
   - Native Swift SDK
   - Excellent documentation
   - Large community (Stack Overflow, forums)

4. **Built-in features**
   - Offline mode
   - Push notifications
   - File uploads
   - Security rules

5. **Cost-efficient for early stage**
   - Free tier sufficient for development and early testing
   - Pay only for what you use

### ❌ Negative

1. **Vendor lock-in**
   - Switching away from Firebase requires significant rewrite
   - **Mitigation**: Use service layer abstraction (protocol-based)
   - **Mitigation**: Document data models for easy migration

2. **Cost at scale**
   - Can become expensive at 100k+ users
   - **Mitigation**: Optimize queries, implement caching
   - **Mitigation**: Monitor usage, set budget alerts
   - **Mitigation**: Re-evaluate if costs exceed $500/month

3. **Limited query capabilities**
   - Firestore queries have limitations (no OR, limited joins)
   - **Mitigation**: Denormalize data when needed
   - **Mitigation**: Use Algolia/Typesense for advanced search (Phase 3)

4. **Black box**
   - Less control over infrastructure
   - Can't optimize database performance directly
   - **Mitigation**: Use Firebase Performance Monitoring
   - **Mitigation**: Design efficient data models upfront

5. **Cold start latency**
   - Cloud Functions can have 1-2s cold starts
   - **Mitigation**: Use minimum instances for critical functions (paid)
   - **Mitigation**: Keep functions small and focused

---

## Alternatives Considered

### 1. Supabase (PostgreSQL + Realtime)
**Pros**: Open source, SQL database, self-hostable  
**Cons**: Smaller ecosystem, less mature iOS SDK, weaker offline support  
**Why rejected**: iOS SDK not as polished, offline mode requires more work

### 2. Custom Node.js Backend (Express + Socket.io + PostgreSQL)
**Pros**: Full control, no vendor lock-in, PostgreSQL flexibility  
**Cons**: Requires backend development, DevOps, scaling complexity  
**Why rejected**: Too slow for MVP timeline, requires backend expertise

### 3. Parse (Open Source BaaS)
**Pros**: Open source, self-hostable, Firebase-like API  
**Cons**: Smaller community, requires server management  
**Why rejected**: Less active development, weaker real-time support

### 4. AWS Amplify (AppSync + DynamoDB)
**Pros**: AWS ecosystem, GraphQL, scalable  
**Cons**: Complex setup, steeper learning curve, higher cost  
**Why rejected**: Over-engineered for MVP, more expensive

### 5. Realm/MongoDB Realm
**Pros**: Excellent offline-first, object database, native mobile SDK  
**Cons**: Different paradigm, smaller ecosystem, MongoDB requirement  
**Why rejected**: Less familiar, smaller iOS community

---

## Migration Strategy (If Needed)

If we outgrow Firebase or costs become prohibitive:

### Phase 1: Service Layer Abstraction (Already Implemented)
```swift
protocol MessageServiceProtocol {
    func sendMessage(chatID: String, text: String) async throws -> String
    func fetchMessages(chatID: String) async throws -> [Message]
}

// Current: Firebase implementation
class FirebaseMessageService: MessageServiceProtocol { ... }

// Future: Supabase/Custom backend implementation
class SupabaseMessageService: MessageServiceProtocol { ... }
```

### Phase 2: Dual-Write (Gradual Migration)
1. Set up new backend (Supabase/custom)
2. Write to both Firebase and new backend
3. Compare data consistency
4. Gradually shift reads to new backend
5. Deprecate Firebase once stable

### Phase 3: Export Data
- Use Firebase Admin SDK to export all data
- Transform to new backend schema
- Import to new system
- Update iOS app to use new service

**Estimated migration effort**: 3-4 weeks for full migration

---

## Success Metrics

Measuring if Firebase meets our needs:

| Metric | Target | Current Status |
|--------|--------|----------------|
| Message sync latency | < 100ms | ✅ ~80ms |
| Offline queue success | > 99% | ✅ 99.5% |
| Authentication uptime | > 99.9% | ✅ 99.95% |
| Monthly cost | < $100 | ✅ $0 (free tier) |
| Developer velocity | Fast MVP | ✅ 6 weeks MVP |

**Re-evaluation triggers**:
- Monthly cost exceeds $500 for 3 consecutive months
- Real-time sync latency consistently > 200ms
- Firestore limitations block critical features
- Security or compliance concerns arise

---

## Implementation Notes

### Security Rules
- Deploy production-ready rules from day one (PR #6)
- Test rules with Firebase Emulator
- Monitor rule denials in Firebase Console

### Data Model
- Design for Firestore's query limitations
- Denormalize where needed (e.g., lastMessage in Chat doc)
- Use subcollections for 1-to-many (messages under chats)

### Cost Optimization
- Use Firestore queries efficiently (indexes, limits)
- Implement local caching (reduce reads)
- Use Realtime DB for ephemeral data (typing, presence)
- Monitor usage with Firebase dashboards

### Monitoring
- Set up budget alerts ($50, $100, $200)
- Track read/write counts per collection
- Monitor Cloud Function invocations
- Use Firebase Performance Monitoring

---

## References

- [Firebase Pricing](https://firebase.google.com/pricing)
- [Firestore Data Model Best Practices](https://firebase.google.com/docs/firestore/data-model)
- [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk)
- [Real-time Chat Example](https://firebase.google.com/docs/firestore/solutions/presence)

---

**Next Review**: Q2 2026 or when costs exceed $500/month  
**Owner**: MessageAI Team  
**Status**: Active, monitoring cost and performance

