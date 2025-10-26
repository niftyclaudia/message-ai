/**
 * Utility to log all messages with their priority, text, and timestamp
 */

import { logger } from './logger';
import { db } from './firestore';

/**
 * Logs all messages across all chats with their priority, text, and timestamp
 * This is useful for debugging classification issues
 */
export async function logAllMessagesWithPriority(): Promise<void> {
  try {
    logger.info('Starting to log all messages with priority data...');

    // Get all chats
    const chatsSnapshot = await db.collection('chats').get();
    
    if (chatsSnapshot.empty) {
      logger.info('No chats found');
      return;
    }

    let totalMessages = 0;
    let urgentMessages = 0;
    let normalMessages = 0;
    let unclassifiedMessages = 0;

    // Process each chat
    for (const chatDoc of chatsSnapshot.docs) {
      const chatId = chatDoc.id;
      const chatData = chatDoc.data();
      
      logger.info(`\n=== CHAT: ${chatId} ===`);
      logger.info(`Chat Members: ${JSON.stringify(chatData.members)}`);
      logger.info(`Last Message: "${chatData.lastMessage || 'N/A'}"`);
      logger.info(`Last Message Time: ${chatData.lastMessageTimestamp?.toDate?.() || 'N/A'}`);
      logger.info(`Last Message Sender: ${chatData.lastMessageSenderID || 'N/A'}`);

      // Get all messages in this chat
      const messagesSnapshot = await db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', 'desc')
        .get();

      if (messagesSnapshot.empty) {
        logger.info('No messages in this chat');
        continue;
      }

      logger.info(`\n--- MESSAGES (${messagesSnapshot.size} total) ---`);

      // Process each message
      for (const messageDoc of messagesSnapshot.docs) {
        const messageData = messageDoc.data();
        const messageId = messageDoc.id;
        
        totalMessages++;
        
        // Extract message details
        const text = messageData.text || '';
        const timestamp = messageData.timestamp?.toDate?.() || new Date();
        const senderId = messageData.senderID || '';
        const priority = messageData.priority || 'unclassified';
        const confidence = messageData.classificationConfidence || 0;
        const classificationMethod = messageData.classificationMethod || 'none';
        const classificationTimestamp = messageData.classificationTimestamp?.toDate?.() || null;
        
        // Count by priority
        if (priority === 'urgent') {
          urgentMessages++;
        } else if (priority === 'normal') {
          normalMessages++;
        } else {
          unclassifiedMessages++;
        }

        // Log message details
        logger.info(`\nMessage ID: ${messageId}`);
        logger.info(`Text: "${text}"`);
        logger.info(`Timestamp: ${timestamp.toISOString()}`);
        logger.info(`Sender: ${senderId}`);
        logger.info(`Priority: ${priority}`);
        logger.info(`Confidence: ${confidence}`);
        logger.info(`Classification Method: ${classificationMethod}`);
        logger.info(`Classification Time: ${classificationTimestamp?.toISOString() || 'Not classified'}`);
        logger.info(`Read By: ${JSON.stringify(messageData.readBy || [])}`);
        logger.info(`Status: ${messageData.status || 'unknown'}`);
        
        // Highlight urgent messages
        if (priority === 'urgent') {
          logger.info(`🚨 URGENT MESSAGE DETECTED: "${text}"`);
        }
      }
    }

    // Summary
    logger.info(`\n=== SUMMARY ===`);
    logger.info(`Total Messages: ${totalMessages}`);
    logger.info(`Urgent Messages: ${urgentMessages}`);
    logger.info(`Normal Messages: ${normalMessages}`);
    logger.info(`Unclassified Messages: ${unclassifiedMessages}`);
    
    if (totalMessages > 0) {
      logger.info(`Urgent Percentage: ${((urgentMessages / totalMessages) * 100).toFixed(2)}%`);
      logger.info(`Normal Percentage: ${((normalMessages / totalMessages) * 100).toFixed(2)}%`);
      logger.info(`Unclassified Percentage: ${((unclassifiedMessages / totalMessages) * 100).toFixed(2)}%`);
    }

  } catch (error) {
    logger.error('Failed to log messages with priority', {
      error: error instanceof Error ? error.message : String(error)
    });
    throw error;
  }
}

/**
 * Logs messages for a specific chat
 * @param chatId - The chat ID to log messages for
 */
export async function logMessagesForChat(chatId: string): Promise<void> {
  try {
    logger.info(`Logging messages for chat: ${chatId}`);

    // Get chat info
    const chatDoc = await db.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      logger.warn(`Chat ${chatId} not found`);
      return;
    }

    const chatData = chatDoc.data()!;
    logger.info(`\n=== CHAT: ${chatId} ===`);
    logger.info(`Chat Members: ${JSON.stringify(chatData.members)}`);
    logger.info(`Last Message: "${chatData.lastMessage || 'N/A'}"`);

    // Get all messages in this chat
    const messagesSnapshot = await db
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', 'desc')
      .get();

    if (messagesSnapshot.empty) {
      logger.info('No messages in this chat');
      return;
    }

    logger.info(`\n--- MESSAGES (${messagesSnapshot.size} total) ---`);

    // Process each message
    for (const messageDoc of messagesSnapshot.docs) {
      const messageData = messageDoc.data();
      const messageId = messageDoc.id;
      
      const text = messageData.text || '';
      const timestamp = messageData.timestamp?.toDate?.() || new Date();
      const senderId = messageData.senderID || '';
      const priority = messageData.priority || 'unclassified';
      const confidence = messageData.classificationConfidence || 0;
      const classificationMethod = messageData.classificationMethod || 'none';
      const classificationTimestamp = messageData.classificationTimestamp?.toDate?.() || null;

      logger.info(`\nMessage ID: ${messageId}`);
      logger.info(`Text: "${text}"`);
      logger.info(`Timestamp: ${timestamp.toISOString()}`);
      logger.info(`Sender: ${senderId}`);
      logger.info(`Priority: ${priority}`);
      logger.info(`Confidence: ${confidence}`);
      logger.info(`Classification Method: ${classificationMethod}`);
      logger.info(`Classification Time: ${classificationTimestamp?.toISOString() || 'Not classified'}`);
      
      if (priority === 'urgent') {
        logger.info(`🚨 URGENT MESSAGE: "${text}"`);
      }
    }

  } catch (error) {
    logger.error('Failed to log messages for chat', {
      chatId,
      error: error instanceof Error ? error.message : String(error)
    });
    throw error;
  }
}
