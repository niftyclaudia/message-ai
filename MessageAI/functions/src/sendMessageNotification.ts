/**
 * Cloud Function to send push notifications for new messages
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from './utils/logger';
import { fetchChatData, fetchMultipleUsers, removeInvalidToken } from './utils/firestore';
import { sendNotificationToDevice } from './utils/fcm';

// Firestore collections
const MESSAGES_COLLECTION = 'messages';

/**
 * Firestore trigger that sends push notifications when new messages are created
 */
export const sendMessageNotification = onDocumentCreated(
  `${MESSAGES_COLLECTION}/{messageId}`,
  async (event) => {
    const messageId = event.params.messageId;
    const messageData = event.data?.data();

    if (!messageData) {
      logger.error('No message data found in trigger', { messageId });
      return;
    }

    try {
      logger.info('Message notification triggered', { messageId });

      // Get chat data to find recipients
      const chatData = await fetchChatData(messageData.chatID);
      if (!chatData) {
        logger.warn('Chat not found for message', { messageId, chatID: messageData.chatID });
        return;
      }

      // Get all chat members except the sender
      const recipientIDs = chatData.members.filter(memberID => memberID !== messageData.senderID);
      
      if (recipientIDs.length === 0) {
        logger.info('No recipients found for message', { messageId });
        return;
      }

      // Fetch recipient data (display names and FCM tokens)
      const recipients = await fetchMultipleUsers(recipientIDs);
      
      if (recipients.length === 0) {
        logger.warn('No valid recipients with FCM tokens found', { messageId });
        return;
      }

      // Send notifications to all recipients
      const notificationPromises = recipients.map(recipient => 
        sendNotificationToDevice({
          token: recipient.fcmToken,
          title: chatData.isGroupChat ? `${messageData.senderName || 'Someone'}` : 'New Message',
          body: messageData.text,
          data: {
            messageId,
            chatID: messageData.chatID,
            senderID: messageData.senderID,
            type: 'new_message'
          }
        }).catch(error => {
          logger.error('Failed to send notification to recipient', {
            messageId,
            recipientID: recipient.userID,
            error: error instanceof Error ? error.message : String(error)
          });
          
          // Remove invalid FCM token if it's a registration error
          if (error.code === 'messaging/registration-token-not-registered') {
            return removeInvalidToken(recipient.userID);
          }
          return Promise.resolve();
        })
      );

      await Promise.allSettled(notificationPromises);
      
      logger.info('Message notifications sent', {
        messageId,
        recipientsCount: recipients.length
      });

    } catch (error) {
      logger.error('Message notification failed', {
        messageId,
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined
      });
    }
  }
);
