/**
 * Firestore Constants
 * 
 * Central location for all collection names and field names used in Firestore.
 * This prevents typos and makes refactoring easier.
 */

/**
 * Collection names used in Firestore
 */
export const COLLECTIONS = {
  CHATS: 'chats',
  MESSAGES: 'messages',
  FOCUS_SUMMARIES: 'focusSummaries',
  FOCUS_SESSIONS: 'focusSessions',
  USERS: 'users',
  CLASSIFICATION_LOGS: 'classificationLogs'
} as const;

/**
 * Common field names used across Firestore documents
 */
export const FIELDS = {
  // User & Auth
  USER_ID: 'userID',
  SENDER_ID: 'senderID',
  MEMBERS: 'members',
  
  // Message fields
  TEXT: 'text',
  TIMESTAMP: 'timestamp',
  PRIORITY: 'priority',
  READ_BY: 'readBy',
  
  // Chat fields
  LAST_MESSAGE: 'lastMessage',
  LAST_MESSAGE_TIMESTAMP: 'lastMessageTimestamp',
  LAST_MESSAGE_ID: 'lastMessageID',
  
  // Session fields
  SESSION_ID: 'sessionID',
  GENERATED_AT: 'generatedAt',
  
  // Classification fields
  CLASSIFICATION: 'classification',
  CONFIDENCE: 'confidence',
  CLASSIFIED_AT: 'classifiedAt'
} as const;

/**
 * Priority levels for messages
 */
export const PRIORITY_LEVELS = {
  URGENT: 'urgent',
  NORMAL: 'normal',
  LOW: 'low'
} as const;

