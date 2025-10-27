/**
 * Cloud Functions entry point
 */

export { sendMessageNotification } from './sendMessageNotification';
export { onMessageCreated, classifyMessageManually } from './triggers/classifyMessage';
export { onMessageCreatedUpdateChat } from './triggers/updateChatOnMessage';
export { generateMessageEmbedding } from './triggers/generateEmbeddingOnMessage';
export { logAllMessages, logChatMessages } from './logMessages';
export { generateFocusSummaryDirect } from './api/generateFocusSummaryDirect';
export { generateEmbedding } from './api/generateEmbedding';
export { semanticSearch } from './api/semanticSearch';
