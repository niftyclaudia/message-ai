/**
 * Type definitions for Cloud Functions
 */

export interface ChatData {
  id: string;
  members: string[];
  isGroupChat: boolean;
}

export interface RecipientData {
  userID: string;
  displayName: string;
  fcmToken: string;
}
