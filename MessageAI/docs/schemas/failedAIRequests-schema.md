# Firestore Schema: failedAIRequests

**Collection:** `/failedAIRequests/{requestId}`

**Purpose:** Track and manage failed AI operations for retry queue and monitoring.

**Created by:** PR-AI-005 - Error Handling & Fallback System

---

## Document Structure

```typescript
{
  id: string;                      // Unique request ID (UUID)
  userId: string;                  // Hashed user ID (privacy-preserving, SHA256 first 16 chars)
  feature: AIFeature;              // "summarization" | "actionItemExtraction" | "semanticSearch" | "priorityDetection" | "decisionTracking" | "proactiveScheduling"
  errorType: AIErrorType;          // "timeout" | "rateLimit" | "serviceUnavailable" | "networkFailure" | "invalidRequest" | "quotaExceeded" | "unknown"
  timestamp: Timestamp;            // When error occurred
  retryCount: number;              // Number of retry attempts (0-4)
  nextRetryAt: Timestamp;          // When to retry next (exponential backoff)
  requestContext: {
    messageId?: string;            // Message ID if relevant
    threadId?: string;             // Thread ID if relevant
    query?: string;                // Hashed search query if relevant (SHA256 first 16 chars)
  };
  errorDetails: {
    message: string;               // Error message for debugging
    statusCode?: number;           // HTTP status code if applicable
  };
  resolved: boolean;               // Whether error has been resolved/handled
  resolvedAt?: Timestamp;          // When error was resolved
}
```

---

## Indexes

### Composite Indexes (defined in firestore.indexes.json)

1. **User Activity Index:**
   - Fields: `userId` (ASC), `timestamp` (DESC)
   - Purpose: Query user's error history

2. **Feature Analytics Index:**
   - Fields: `feature` (ASC), `errorType` (ASC), `timestamp` (DESC)
   - Purpose: Monitor error rates by feature and type

3. **Retry Queue Index:**
   - Fields: `resolved` (ASC), `nextRetryAt` (ASC)
   - Purpose: Process retry queue efficiently

---

## Security Rules

- **Write:** Open to Cloud Functions service account (authenticated writes)
- **Read:** Restricted (admin/monitoring only)
- **Privacy:** User IDs and queries are hashed before storage

---

## Lifecycle

1. **Creation:** When AI operation fails, ErrorLogger writes document
2. **Updates:** Retry queue job updates `retryCount`, `nextRetryAt`, `resolved`
3. **Resolution:** Mark `resolved=true` when:
   - Retry succeeds
   - Max retries exceeded (4 attempts)
   - Error type not retryable
4. **Cleanup:** Resolved documents older than 30 days deleted by cleanup job (future PR)

---

## Privacy Considerations

- ✅ User IDs hashed (SHA256 first 16 chars)
- ✅ Search queries hashed (SHA256 first 16 chars)
- ✅ NO message content stored
- ✅ NO PII (personally identifiable information)
- ✅ Minimal context for debugging

---

## Monitoring Queries

### Error rate by feature (last 24h)
```typescript
db.collection('failedAIRequests')
  .where('timestamp', '>', last24Hours)
  .where('feature', '==', 'summarization')
  .get()
```

### Pending retry queue
```typescript
db.collection('failedAIRequests')
  .where('resolved', '==', false)
  .where('nextRetryAt', '<=', now)
  .limit(50)
  .get()
```

### Error rate by type
```typescript
db.collection('failedAIRequests')
  .where('errorType', '==', 'timeout')
  .where('timestamp', '>', last24Hours)
  .get()
```

---

## Related Files

- **Swift Models:** `MessageAI/Models/AIError.swift`, `AIContext.swift`
- **Cloud Functions:** `functions/src/utils/errorHandling.ts`, `functions/src/jobs/retryQueue.ts`
- **Swift Services:** `Services/AI/ErrorLogger.swift`, `Services/AI/RetryQueue.swift`

