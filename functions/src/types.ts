/**
 * TypeScript interfaces for Cloud Functions push notification system
 */

export interface MessageData {
  text: string;
  senderID: string;
  chatID: string;
  messageID: string;
}

export interface ChatData {
  id: string;
  members: string[];
  isGroupChat: boolean;
  lastMessage?: string;
  lastMessageTimestamp?: any;
  lastMessageSenderID?: string;
  unreadCount?: { [userId: string]: number };
}

export interface UserData {
  uid: string;
  displayName: string;
  fcmToken?: string;
}

export interface RecipientData {
  userID: string;
  displayName: string;
  fcmToken: string;
}

export interface SendResults {
  successCount: number;
  failureCount: number;
  invalidTokens: string[];
}

export enum NotificationError {
  INVALID_MESSAGE_DATA = 'Invalid message data',
  CHAT_NOT_FOUND = 'Chat not found',
  NO_RECIPIENTS = 'No valid recipients',
  FCM_SEND_FAILED = 'FCM send failed',
  TOKEN_FETCH_FAILED = 'Token fetch failed'
}
