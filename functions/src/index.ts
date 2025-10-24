/**
 * Cloud Functions entry point
 */

import * as admin from 'firebase-admin';

// Initialize Firebase Admin (only once)
admin.initializeApp();

// Export existing functions
export { sendMessageNotification } from './sendMessageNotification';

// Export RAG Pipeline functions
export { generateEmbeddingFunction as generateEmbedding } from './generateEmbedding';
export { semanticSearchFunction as semanticSearch } from './semanticSearch';
export { onMessageCreatedTrigger as onMessageCreated } from './triggers/onMessageCreated';

// Export Memory Management functions (PR-004)
export { memoryCleanup, memoryCleanupManual } from './cleanup/memoryCleanup';

// Export Function Calling framework
export { executeFunctionCallFunction as executeFunctionCall } from './functionCalling/orchestrator';

// Export Error Handling & Retry Queue (PR-AI-005)
export { retryQueueScheduled } from './jobs/retryQueue';
