# Cloud Functions for MessageAI

This directory contains Firebase Cloud Functions for MessageAI, including notification delivery and the RAG (Retrieval Augmented Generation) pipeline for AI features.

## Functions Overview

### Notification Functions
- **`sendMessageNotification`**: Sends push notifications when new messages are created

### RAG Pipeline Functions (NEW)
- **`generateEmbedding`**: Generates vector embeddings for messages (HTTP Callable)
- **`semanticSearch`**: Performs semantic search across messages (HTTP Callable)
- **`onMessageCreated`**: Auto-generates embeddings when messages are created (Firestore Trigger)

## RAG Pipeline Architecture

The RAG pipeline enables AI features by:
1. **Embedding Generation**: Converting message text into 1536-dimensional vectors using OpenAI's `text-embedding-3-small` model
2. **Vector Storage**: Storing embeddings in Pinecone for fast similarity search
3. **Semantic Search**: Finding relevant messages by meaning, not just keywords

### Components

#### Core Utilities (`src/utils/`)
- **`openai.ts`**: OpenAI API client with retry logic
- **`pinecone.ts`**: Pinecone vector database client
- **`firestore.ts`**: Firestore helper functions
- **`logger.ts`**: Structured logging

#### RAG Modules (`src/rag/`)
- **`embeddings.ts`**: Embedding generation and metadata extraction
- **`vectorSearch.ts`**: Vector database operations (upsert, query)
- **`semanticQuery.ts`**: High-level semantic search orchestration

#### Cloud Functions (`src/`)
- **`generateEmbedding.ts`**: Manual embedding generation endpoint
- **`semanticSearch.ts`**: Semantic search endpoint
- **`triggers/onMessageCreated.ts`**: Automatic embedding generation on new messages

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

Required packages:
- `firebase-functions`
- `firebase-admin`
- `openai` (for embeddings)
- `@pinecone-database/pinecone` (for vector storage)

### 2. Configure Environment Variables

#### For Local Development

Create `functions/.env.local` (NEVER commit this file):

```bash
OPENAI_API_KEY=sk-proj-your-key-here
PINECONE_API_KEY=pcsk-your-key-here
PINECONE_ENVIRONMENT=us-east-1-aws
PINECONE_INDEX=messageai-prod
```

#### For Production Deployment

Set Firebase Functions config:

```bash
firebase functions:config:set openai.api_key="sk-proj-..."
firebase functions:config:set pinecone.api_key="pcsk-..."
firebase functions:config:set pinecone.environment="us-east-1-aws"
firebase functions:config:set pinecone.index="messageai-prod"
```

Verify configuration:

```bash
firebase functions:config:get
```

### 3. Set Up External Services

#### OpenAI API
1. Sign up at https://platform.openai.com
2. Create API key with embeddings access
3. Add to environment variables

#### Pinecone Vector Database
1. Sign up at https://www.pinecone.io
2. Create index with these specifications:
   - **Name**: `messageai-prod`
   - **Dimensions**: 1536 (matches OpenAI text-embedding-3-small)
   - **Metric**: Cosine similarity
   - **Cloud**: AWS (or your preference)
   - **Region**: us-east-1 (or closest to your users)
3. Get API key and environment name
4. Add to environment variables

## Development Workflow

### Build TypeScript

```bash
npm run build
```

### Run Emulators Locally

```bash
npm run serve
```

This starts the Firebase emulators for testing functions locally.

### Deploy to Firebase

```bash
# Deploy all functions
npm run deploy

# Deploy specific function
firebase deploy --only functions:generateEmbedding
```

## Testing

### Unit Tests

```bash
npm test
```

Tests are located in `src/__tests__/`

### Manual Testing

#### Test Embedding Generation

```javascript
// Call from iOS or test script
const result = await firebase.functions().httpsCallable('generateEmbedding')({
  messageId: 'your-message-id'
});
console.log(result.data);
```

#### Test Semantic Search

```javascript
const result = await firebase.functions().httpsCallable('semanticSearch')({
  query: 'payment processor decision',
  userId: 'your-user-id',
  limit: 10
});
console.log(result.data.results);
```

## Performance Targets

- **Embedding Generation**: <500ms (p95)
- **Semantic Search**: <1s (p95)
- **Auto-trigger (onMessageCreated)**: <500ms

## Monitoring

### Cloud Logging

View function logs:

```bash
firebase functions:log
```

### Key Metrics to Monitor

- **Embedding generation latency** (p50, p95, p99)
- **Semantic search latency** (p50, p95, p99)
- **Error rates** by type (OpenAI, Pinecone, Firestore)
- **API costs** (OpenAI embeddings, Pinecone queries)
- **Success rates** (embedding generation, search queries)

### Alerts

Set up alerts for:
- Embedding error rate >5%
- Search latency p95 >1.5s
- Daily OpenAI cost >$100
- Pinecone failures >10/hour

## Cost Estimates

### OpenAI Embeddings
- **Model**: text-embedding-3-small
- **Cost**: ~$0.0001 per 1K tokens (~$0.10 per 1M tokens)
- **Example**: 10K messages/day = ~$1/month

### Pinecone
- **Free tier**: 1 index, 100K vectors
- **Paid**: Starting at ~$70/month for 1M vectors
- **Cost per query**: Minimal (included in plan)

## Troubleshooting

### "Missing environment variables" error
- Verify Firebase Functions config: `firebase functions:config:get`
- For local testing, ensure `.env.local` exists with all keys

### "OpenAI rate limit" error
- Check your OpenAI usage limits
- Upgrade OpenAI tier if needed
- Function retries 3x with exponential backoff automatically

### "Pinecone connection failed" error
- Verify Pinecone API key and environment
- Check index exists and has correct dimensions (1536)
- Ensure Pinecone account is active

### Slow embedding generation (>500ms)
- Check OpenAI API status
- Profile with Cloud Logging to find bottleneck
- Consider caching identical message text

### Semantic search returns no results
- Verify messages have `embeddingGenerated: true` in Firestore
- Check Pinecone index has vectors (use Pinecone dashboard)
- Try lowering `minScore` threshold (default 0.7)

## Architecture Decisions

### Why Pinecone?
- Managed vector database (no infrastructure to maintain)
- Fast similarity search (<1s for millions of vectors)
- Easy setup and good documentation
- Can migrate to self-hosted Weaviate later if cost is an issue

### Why OpenAI text-embedding-3-small?
- 1536 dimensions (good balance of accuracy and speed)
- Cost-effective ($0.10 per 1M tokens)
- High-quality embeddings for semantic search
- Can upgrade to text-embedding-3-large (3072 dims) if needed

### Why auto-trigger on message creation?
- Messages become searchable immediately
- No manual sync needed
- Graceful degradation (core messaging works even if trigger fails)

## Future Enhancements

- [ ] Hybrid search (vector + keyword fallback)
- [ ] Multi-modal embeddings (images, files)
- [ ] On-device embeddings (CoreML for privacy)
- [ ] Embedding cache for identical messages
- [ ] Advanced ranking (boost by contact importance, urgency)
- [ ] PII redaction before OpenAI API calls

## Related Documentation

- **PRD**: `MessageAI/docs/prds/pr-ai-001-prd.md`
- **TODO**: `MessageAI/docs/todos/pr-ai-001-todo.md`
- **Architecture**: `MessageAI/docs/architecture.md`
- **AI Product Vision**: `MessageAI/docs/AI-PRODUCT-VISION.md`

## Contact

For questions or issues with the RAG pipeline, refer to the PRD or contact the team.
