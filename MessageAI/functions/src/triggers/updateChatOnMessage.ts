/**
 * Firestore trigger to update chat document when messages are created
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from '../utils/logger';
import { db } from '../utils/firestore';
import * as admin from 'firebase-admin';
import { COLLECTIONS, FIELDS } from '../constants/firestore';

/**
 * Updates the chat document when a new message is created
 * This ensures the conversation list shows the most recent message preview
 */
export const onMessageCreatedUpdateChat = onDocumentCreated(
  `chats/{chatId}/messages/{messageId}`,
  async (event) => {
    const chatId = event.params.chatId;
    const messageId = event.params.messageId;
    const messageData = event.data?.data();

    if (!messageData) {
      logger.warn('No message data found in chat update trigger', { messageId });
      return;
    }

    try {
      logger.info('Updating chat document with new message', { chatId, messageId });

      // Get the chat document to access members
      const chatDoc = await db.collection(COLLECTIONS.CHATS).doc(chatId).get();
      const chatData = chatDoc.data();
      
      if (!chatData) {
        logger.warn('Chat document not found', { chatId });
        return;
      }

      // Get all members except the sender
      const members = chatData[FIELDS.MEMBERS] || [];
      const senderID = messageData[FIELDS.SENDER_ID];
      const recipientIDs = members.filter((memberID: string) => memberID !== senderID);

      // Prepare unread count updates for all recipients
      const unreadCountUpdates: { [key: string]: any } = {};
      recipientIDs.forEach((recipientID: string) => {
        unreadCountUpdates[`unreadCount.${recipientID}`] = admin.firestore.FieldValue.increment(1);
      });

      // Update the chat document with the new message info and unread counts
      await db.collection(COLLECTIONS.CHATS).doc(chatId).update({
        [FIELDS.LAST_MESSAGE]: messageData[FIELDS.TEXT] || '',
        [FIELDS.LAST_MESSAGE_TIMESTAMP]: messageData[FIELDS.TIMESTAMP] || new Date(),
        lastMessageSenderID: messageData[FIELDS.SENDER_ID] || '',
        [FIELDS.LAST_MESSAGE_ID]: messageId,
        ...unreadCountUpdates
      });

      logger.info('Chat document updated successfully', { 
        chatId, 
        messageId,
        lastMessage: messageData[FIELDS.TEXT],
        lastMessageSenderID: messageData[FIELDS.SENDER_ID]
      });

    } catch (error) {
      logger.error('Failed to update chat document', {
        chatId,
        messageId,
        error: error instanceof Error ? error.message : String(error)
      });
    }
  }
);
