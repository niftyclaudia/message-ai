# Function Calling Framework

**PR #AI-003** - OpenAI Function Calling Infrastructure

## Overview

This framework enables AI to execute actions through 8 core functions, transforming MessageAI from a passive chatbot to an active assistant.

## Architecture

```
functions/src/functionCalling/
├── schemas.ts                     # OpenAI function schemas + TypeScript types
├── validation.ts                  # Parameter validation utilities
├── orchestrator.ts                # Central router for function execution
└── handlers/                      # 8 function handlers
    ├── summarizeThread.ts         # Thread summarization
    ├── extractActionItems.ts      # Task extraction
    ├── searchMessages.ts          # Semantic search
    ├── categorizeMessage.ts       # Priority detection
    ├── trackDecisions.ts          # Decision logging
    ├── detectSchedulingNeed.ts    # Meeting request detection
    ├── checkCalendar.ts           # Calendar availability
    └── suggestMeetingTimes.ts     # Meeting time suggestions

utils/
├── executionLogger.ts             # Firestore execution logging
├── errorHandler.ts                # Error codes & fallback responses
└── permissionChecker.ts           # Access control
```

## Functions

### 1. summarizeThread(threadId, maxLength?)
Condenses a conversation to 2-3 sentences with key points.
- **Returns**: `ThreadSummary` with summary, keyPoints, participants, decisionCount, messageCount

### 2. extractActionItems(threadId, userId)
Finds tasks requiring action from conversation.
- **Returns**: `ActionItem[]` with task, deadline, assignee, sourceMessageId

### 3. searchMessages(query, userId, chatId?, limit?)
Semantic search across messages using RAG Pipeline.
- **Returns**: `SearchResult[]` with messageId, text, senderId, timestamp, relevanceScore

### 4. categorizeMessage(messageId, userId)
Detects priority level: urgent, canWait, aiHandled.
- **Returns**: `MessageCategory` with category, confidence, reasoning, signals

### 5. trackDecisions(threadId)
Finds and logs decision patterns.
- **Returns**: `Decision[]` with decisionText, participants, timestamp, confidence

### 6. detectSchedulingNeed(threadId)
Identifies meeting requests in thread.
- **Returns**: `SchedulingNeed` with detected, participants, suggestedDuration, urgency

### 7. checkCalendar(userId, startDate, endDate)
Fetches calendar availability (requires iOS EventKit sync).
- **Returns**: `CalendarEvent[]` with id, title, startTime, endTime

### 8. suggestMeetingTimes(participants, duration, preferredTimeRanges?)
Suggests optimal meeting times based on availability.
- **Returns**: `MeetingTimeSuggestion[]` with startTime, endTime, availableParticipants, score, reasoning

## Usage

### Backend (Cloud Functions)

```typescript
import { executeFunctionCall } from './functionCalling/orchestrator';

// Called by iOS via executeFunctionCall Cloud Function
const result = await executeFunctionCall(
  'summarizeThread',
  { threadId: 'chat123', maxLength: 300 },
  userId,
  context
);
```

### iOS (Swift)

```swift
import FirebaseFunctions

let service = FunctionCallingService(
  functions: Functions.functions(),
  currentUserId: Auth.auth().currentUser!.uid
)

// Summarize thread
let summary = try await service.summarizeThread(threadId: "chat123", maxLength: 300)
print(summary.summary) // "The team discussed..."

// Extract action items
let actionItems = try await service.extractActionItems(threadId: "chat123")
for item in actionItems {
    print("\(item.task) - Deadline: \(item.deadline)")
}

// Search messages
let results = try await service.searchMessages(query: "budget decision", limit: 10)
for result in results {
    print("\(result.text) - Score: \(result.relevanceScore)")
}
```

## Validation

All parameters validated before execution:
- **IDs**: Valid Firebase document format (alphanumeric, hyphens, underscores)
- **Numeric ranges**: limit 1-50, duration 15-180, maxLength 50-500
- **Date formats**: ISO 8601 (YYYY-MM-DDTHH:MM:SS)
- **Array lengths**: participants 2-10, preferredTimeRanges 0-5

## Error Handling

6 error types with fallback responses:
- `invalid_function` - Unknown function name
- `invalid_parameters` - Missing or invalid parameters
- `permission_denied` - User lacks access
- `timeout` - Execution exceeded 2 seconds
- `service_unavailable` - External service (OpenAI, RAG) down
- `internal_error` - Unexpected error

## Performance Targets

- **Execution latency**: <2s (p95)
- **Parameter validation**: <50ms
- **Concurrent requests**: 50+ without degradation
- **Logging overhead**: <10ms

## Execution Logging

All executions logged to Firestore `/functionExecutionLogs/{executionId}`:
```typescript
{
  executionId: string,
  functionName: string,
  parameters: object, // Sanitized
  userId: string,
  timestamp: Timestamp,
  duration: number, // ms
  status: "success" | "error" | "timeout",
  errorDetails?: string,
  resultSummary?: string
}
```

Logs auto-delete after 30 days for privacy.

## Testing

### Unit Tests
```bash
cd functions
npm test
```

### Integration Tests
1. Deploy to staging: `firebase deploy --only functions:executeFunctionCall`
2. Run iOS integration tests in Xcode
3. Monitor logs: `firebase functions:log`

## Deployment

### Environment Variables
```bash
# Set Firebase config
firebase functions:config:set \
  openai.api_key="sk-..." \
  pinecone.api_key="..." \
  pinecone.environment="us-central1-gcp" \
  pinecone.index="messageai"
```

### Deploy
```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:executeFunctionCall
```

## Dependencies

- **RAG Pipeline** (PR #AI-001): Required for semantic search (5 functions depend on it)
- **User Preferences** (PR #AI-002): Optional - enhances categorization when available
- **Memory/State** (PR #AI-004): Optional - stores execution history when available

## Future Enhancements

- Function chaining (execute multiple functions sequentially)
- Voice-based function calling
- Custom user-defined functions
- Real-time streaming results
- Advanced caching strategies
- Parallel function calling (OpenAI v2)

## Troubleshooting

### "openai_api_error"
- Check OpenAI API key is valid
- Verify Firebase Functions has network access
- Check rate limits

### "vector_db_error"
- Verify Pinecone connection
- Check RAG Pipeline is deployed (PR #AI-001)
- Verify vector index exists

### "timeout"
- Function exceeds 2s limit
- Optimize handler logic
- Reduce message fetch count
- Check RAG Pipeline performance

### "permission_denied"
- User not authenticated
- User not in chat members
- Requesting another user's data

## Monitoring

Dashboard metrics:
- Function call counts by type
- Error rates by function
- Latency p50/p95/p99
- Top error messages

Alerts:
- Error rate >5%
- p95 latency >2.5s
- Timeout rate >2%

## Contact

Questions? See:
- PRD: `MessageAI/docs/prds/pr-ai-003-prd.md`
- TODO: `MessageAI/docs/todos/pr-ai-003-todo.md`
- Shared Standards: `MessageAI/agents/shared-standards.md`

