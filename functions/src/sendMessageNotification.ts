/**
 * Cloud Function: Send push notifications when new messages are created
 * Triggered by: Firestore onCreate on chats/{chatID}/messages/{messageID}
 */

import * as functions from 'firebase-functions/v1';
import * as admin from 'firebase-admin';
import { MessageData } from './types';
import { fetchChatData, fetchMultipleUsers, removeInvalidToken } from './utils/firestore';
import { buildNotificationPayload, sendNotificationsBatch } from './utils/fcm';
import { logger } from './utils/logger';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Extract and validate message data from Firestore snapshot
 */
function extractMessageData(snapshot: admin.firestore.DocumentSnapshot): MessageData | null {
  const data = snapshot.data();
  
  if (!data) {
    logger.error('Message document has no data');
    return null;
  }
  
  const { text, senderID } = data;
  
  if (!text || !senderID) {
    logger.error('Message missing required fields', { 
      hasText: !!text, 
      hasSenderID: !!senderID 
    });
    return null;
  }
  
  return {
    text: text as string,
    senderID: senderID as string,
    chatID: snapshot.ref.parent.parent?.id || '',
    messageID: snapshot.id
  };
}

/**
 * Get recipient IDs by filtering out the sender
 */
function getRecipientIDs(members: string[], senderID: string): string[] {
  return members.filter(id => id !== senderID);
}

/**
 * Main Cloud Function: Send push notifications for new messages
 */
export const sendMessageNotification = functions.firestore
  .document('chats/{chatID}/messages/{messageID}')
  .onCreate(async (snapshot, context) => {
    const { chatID, messageID } = context.params;
    
    logger.info('Function triggered', { chatID, messageID });
    
    try {
      // Step 1: Extract and validate message data
      const messageData = extractMessageData(snapshot);
      if (!messageData) {
        logger.error('Invalid message data, exiting gracefully');
        return;
      }
      
      const { text, senderID } = messageData;
      logger.info('Message data extracted', { 
        chatID, 
        messageID, 
        senderID, 
        textLength: text.length 
      });
      
      // Step 2: Fetch chat data
      const chatData = await fetchChatData(chatID);
      if (!chatData) {
        logger.error('Chat not found, exiting gracefully', { chatID });
        return;
      }
      
      logger.info('Chat data fetched', { 
        chatID, 
        memberCount: chatData.members.length,
        isGroupChat: chatData.isGroupChat 
      });
      
      // Step 3: Compute recipients (CRITICAL: exclude sender)
      const recipientIDs = getRecipientIDs(chatData.members, senderID);
      
      if (recipientIDs.length === 0) {
        logger.warn('No recipients found (sender excluded)', { 
          chatID, 
          senderID, 
          totalMembers: chatData.members.length 
        });
        return;
      }
      
      logger.info('Recipients computed', { 
        chatID, 
        recipientCount: recipientIDs.length,
        senderExcluded: true 
      });
      
      // Step 4: Fetch recipient tokens
      const recipients = await fetchMultipleUsers(recipientIDs);
      
      if (recipients.length === 0) {
        logger.warn('No valid FCM tokens found', { 
          chatID, 
          requestedRecipients: recipientIDs.length 
        });
        return;
      }
      
      logger.info('Recipient tokens fetched', { 
        chatID, 
        validTokens: recipients.length,
        missingTokens: recipientIDs.length - recipients.length 
      });
      
      // Step 5: Build notification payload
      const senderName = recipients[0]?.displayName || 'Unknown User'; // Get sender name from first recipient for now
      const payload = buildNotificationPayload(
        senderName,
        text,
        chatID,
        senderID
      );
      
      logger.info('Notification payload built', { 
        chatID, 
        senderName, 
        payloadSize: JSON.stringify(payload).length 
      });
      
      // Step 6: Send notifications
      const tokens = recipients.map(r => r.fcmToken);
      const sendResults = await sendNotificationsBatch(tokens, payload);
      
      logger.info('Notifications sent', {
        chatID,
        successCount: sendResults.successCount,
        failureCount: sendResults.failureCount,
        invalidTokens: sendResults.invalidTokens.length
      });
      
      // Step 7: Cleanup invalid tokens
      if (sendResults.invalidTokens.length > 0) {
        logger.info('Cleaning up invalid tokens', { 
          count: sendResults.invalidTokens.length 
        });
        
        const cleanupPromises = sendResults.invalidTokens.map(token => {
          // Find userID by token (this is a simplified approach)
          const userWithInvalidToken = recipients.find(r => r.fcmToken === token);
          return userWithInvalidToken ? removeInvalidToken(userWithInvalidToken.userID) : Promise.resolve();
        });
        
        await Promise.all(cleanupPromises);
        logger.info('Invalid tokens cleaned up');
      }
      
      logger.info('Function completed successfully', { 
        chatID, 
        messageID,
        totalRecipients: recipients.length,
        successfulSends: sendResults.successCount 
      });
      
    } catch (error) {
      logger.error('Function execution failed', { 
        chatID, 
        messageID, 
        error: error instanceof Error ? error.message : String(error) 
      });
      // Don't throw - let the function complete gracefully
    }
  });
