/**
 * Firestore trigger to update chat document when messages are created
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from '../utils/logger';
import { db } from '../utils/firestore';
import * as admin from 'firebase-admin';

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
      const chatDoc = await db.collection('chats').doc(chatId).get();
      const chatData = chatDoc.data();
      
      if (!chatData) {
        logger.warn('Chat document not found', { chatId });
        return;
      }

      // Get all members except the sender
      const members = chatData.members || [];
      const senderID = messageData.senderID;
      const recipientIDs = members.filter((memberID: string) => memberID !== senderID);

      // Prepare unread count updates for all recipients
      const unreadCountUpdates: { [key: string]: any } = {};
      recipientIDs.forEach((recipientID: string) => {
        unreadCountUpdates[`unreadCount.${recipientID}`] = admin.firestore.FieldValue.increment(1);
      });

      // Update the chat document with the new message info and unread counts
      await db.collection('chats').doc(chatId).update({
        lastMessage: messageData.text || '',
        lastMessageTimestamp: messageData.timestamp || new Date(),
        lastMessageSenderID: messageData.senderID || '',
        lastMessageID: messageId,
        ...unreadCountUpdates
      });

      logger.info('Chat document updated successfully', { 
        chatId, 
        messageId,
        lastMessage: messageData.text,
        lastMessageSenderID: messageData.senderID
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
