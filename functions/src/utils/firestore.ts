/**
 * Firestore helper functions for Cloud Functions
 */

import * as admin from 'firebase-admin';
import { ChatData, RecipientData } from '../types';
import { logger } from './logger';

const db = admin.firestore();

/**
 * Fetch chat document data by chatID
 */
export async function fetchChatData(chatID: string): Promise<ChatData | null> {
  try {
    const chatDoc = await db.collection('chats').doc(chatID).get();
    
    if (!chatDoc.exists) {
      logger.warn('Chat document not found', { chatID });
      return null;
    }
    
    const data = chatDoc.data();
    return {
      id: chatID,
      members: data?.members || [],
      isGroupChat: data?.isGroupChat || false
    };
  } catch (error) {
    logger.error('Failed to fetch chat data', error);
    throw error;
  }
}

/**
 * Fetch multiple users and their FCM tokens in parallel
 */
export async function fetchMultipleUsers(userIDs: string[]): Promise<RecipientData[]> {
  try {
    const userPromises = userIDs.map(userID => 
      db.collection('users').doc(userID).get()
    );
    
    const userDocs = await Promise.all(userPromises);
    const recipients: RecipientData[] = [];
    
    userDocs.forEach((userDoc, index) => {
      if (userDoc.exists) {
        const data = userDoc.data();
        if (data?.fcmToken) {
          recipients.push({
            userID: userIDs[index],
            displayName: data.displayName || 'Unknown User',
            fcmToken: data.fcmToken
          });
        } else {
          logger.warn('User has no FCM token', { userID: userIDs[index] });
        }
      } else {
        logger.warn('User document not found', { userID: userIDs[index] });
      }
    });
    
    logger.info('Fetched recipient tokens', { 
      requested: userIDs.length, 
      found: recipients.length 
    });
    
    return recipients;
  } catch (error) {
    logger.error('Failed to fetch user tokens', error);
    throw error;
  }
}

/**
 * Remove invalid FCM token from user document
 */
export async function removeInvalidToken(userID: string): Promise<void> {
  try {
    await db.collection('users').doc(userID).update({
      fcmToken: admin.firestore.FieldValue.delete()
    });
    logger.info('Removed invalid FCM token', { userID });
  } catch (error) {
    logger.error('Failed to remove invalid token', { userID, error });
    throw error;
  }
}
