# Cloud Functions for Push Notifications

This directory contains Firebase Cloud Functions that automatically send push notifications when new messages are created in the MessageAI app.

## Overview

The `sendMessageNotification` function is triggered whenever a new message is created in Firestore. It:
1. Extracts message data and validates it
2. Fetches chat information to get all participants
3. Excludes the sender from recipients (critical!)
4. Fetches FCM tokens for all recipients
5. Sends push notifications via Firebase Cloud Messaging
6. Handles errors gracefully and cleans up invalid tokens

## File Structure

```
functions/
├── src/
│   ├── index.ts                           # Main export file
│   ├── sendMessageNotification.ts         # Core Cloud Function
│   ├── types.ts                          # TypeScript interfaces
│   └── utils/
│       ├── logger.ts                     # Structured logging
│       ├── firestore.ts                  # Firestore helper functions
│       └── fcm.ts                        # FCM notification helpers
├── package.json                          # Dependencies and scripts
├── tsconfig.json                         # TypeScript configuration
└── jest.config.js                       # Test configuration
```

## Key Features

- **Sender Exclusion**: Automatically excludes the message sender from notifications
- **Error Handling**: Graceful error handling with detailed logging
- **Token Cleanup**: Removes invalid FCM tokens from user documents
- **Performance**: Parallel Firestore reads and optimized FCM sending
- **Logging**: Structured JSON logging for debugging

## Development

### Prerequisites
- Node.js 18+
- Firebase CLI
- Firebase project with Firestore and FCM enabled

### Setup
```bash
cd functions
npm install
```

### Build
```bash
npm run build
```

### Test
```bash
npm test
```

### Deploy
```bash
firebase deploy --only functions
```

## Configuration

The function is configured to:
- **Runtime**: Node.js 18
- **Memory**: 256MB
- **Timeout**: 60 seconds
- **Region**: us-central1
- **Trigger**: Firestore onCreate on `chats/{chatID}/messages/{messageID}`

## Data Flow

1. **Message Created** → Firestore write to `chats/{chatID}/messages/{messageID}`
2. **Function Triggers** → Cloud Function automatically executes
3. **Data Extraction** → Extract chatID, messageID, senderID, text
4. **Chat Lookup** → Fetch chat document to get members array
5. **Recipient Filtering** → Remove sender from members list
6. **Token Retrieval** → Fetch FCM tokens for all recipients
7. **Notification Sending** → Send push notifications via FCM
8. **Error Handling** → Log results and clean up invalid tokens

## Error Handling

The function handles these scenarios gracefully:
- Missing chat documents
- Users without FCM tokens
- Invalid FCM tokens (automatically cleaned up)
- FCM API failures
- Network timeouts

## Monitoring

View function logs in Firebase Console:
```bash
firebase functions:log
```

Key metrics to monitor:
- Function execution count
- Execution time (target: <500ms warm, <3s cold)
- Error rate (target: <1%)
- FCM send success rate

## Testing

The function includes comprehensive unit tests for:
- Data extraction and validation
- Chat data fetching
- Recipient filtering (sender exclusion)
- FCM token retrieval
- Notification payload building
- Error scenarios

## Security

- Uses Firebase Admin SDK with service account authentication
- Validates all input data before processing
- Handles sensitive FCM tokens securely
- No user data stored in function logs

## Performance

Optimized for:
- **Cold start**: <3 seconds
- **Warm execution**: <500ms
- **Total delivery**: <2 seconds
- **Parallel processing**: Multiple Firestore reads
- **Efficient FCM**: Batch notification sending
