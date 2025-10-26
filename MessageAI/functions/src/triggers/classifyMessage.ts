/**
 * Firestore trigger for automatic message classification
 */

import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { logger } from '../utils/logger';
import { db } from '../utils/firestore';
import { classifyMessage } from '../services/aiPrioritization';
import { logClassification } from '../utils/classificationLogger';

// Firestore collections - using full path for subcollections

/**
 * Firestore trigger that automatically classifies new messages
 * Triggered when a new message document is created
 */
export const onMessageCreated = onDocumentCreated(
  `chats/{chatId}/messages/{messageId}`,
  async (event) => {
    const messageId = event.params.messageId;
    const chatId = event.params.chatId;
    const messageData = event.data?.data();

    if (!messageData) {
      logger.error('No message data found in trigger', { messageId });
      return;
    }

    try {
      logger.info('Message classification triggered', { messageId });

      // Extract message text
      const messageText = messageData.text;
      if (!messageText || typeof messageText !== 'string') {
        logger.warn('No valid message text found', { messageId });
        return;
      }

      // Skip classification if already classified
      if (messageData.priority) {
        logger.info('Message already classified, skipping', { 
          messageId, 
          existingPriority: messageData.priority 
        });
        return;
      }

      // Classify the message
      const startTime = Date.now();
      const classificationResult = await classifyMessage(messageText);
      const totalProcessingTime = Date.now() - startTime;

      // Update the message document with classification results
      await updateMessageWithClassification(chatId, messageId, classificationResult);

      // Log the classification for analytics
      await logClassification(messageId, messageText, classificationResult);

      logger.info('Message classification completed', {
        messageId,
        priority: classificationResult.priority,
        confidence: classificationResult.confidence,
        method: classificationResult.method,
        totalProcessingTimeMs: totalProcessingTime
      });

    } catch (error) {
      logger.error('Message classification failed', {
        messageId,
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined
      });

      // Log the error for monitoring
      await logClassification(
        messageId,
        messageData.text || '',
        {
          priority: 'normal',
          confidence: 0.0,
          method: 'fallback',
          processingTimeMs: 0,
          timestamp: new Date()
        },
        error instanceof Error ? error : new Error(String(error))
      );
    }
  }
);

/**
 * Update a message document with classification results
 * @param chatId - ID of the chat containing the message
 * @param messageId - ID of the message to update
 * @param classificationResult - Classification result to apply
 */
async function updateMessageWithClassification(
  chatId: string,
  messageId: string,
  classificationResult: {
    priority: string;
    confidence: number;
    method: string;
    processingTimeMs: number;
    timestamp: Date;
  }
): Promise<void> {
  try {
    const updateData = {
      priority: classificationResult.priority,
      classificationConfidence: classificationResult.confidence,
      classificationMethod: classificationResult.method,
      classificationTimestamp: classificationResult.timestamp
    };

    await db.collection('chats').doc(chatId).collection('messages').doc(messageId).update(updateData);

    logger.info('Message updated with classification', {
      messageId,
      priority: classificationResult.priority,
      confidence: classificationResult.confidence,
      method: classificationResult.method
    });

  } catch (error) {
    logger.error('Failed to update message with classification', {
      messageId,
      error: error instanceof Error ? error.message : String(error)
    });
    throw error;
  }
}

/**
 * Manual classification function for testing or reprocessing
 * @param chatId - ID of the chat containing the message
 * @param messageId - ID of the message to classify
 * @returns Promise with classification result
 */
export async function classifyMessageManually(chatId: string, messageId: string): Promise<{
  success: boolean;
  result?: any;
  error?: string;
}> {
  try {
    // Get the message document
    const messageDoc = await db.collection('chats').doc(chatId).collection('messages').doc(messageId).get();
    
    if (!messageDoc.exists) {
      return {
        success: false,
        error: 'Message not found'
      };
    }

    const messageData = messageDoc.data();
    if (!messageData?.text) {
      return {
        success: false,
        error: 'No message text found'
      };
    }

    // Classify the message
    const classificationResult = await classifyMessage(messageData.text);

    // Update the message
    await updateMessageWithClassification(chatId, messageId, classificationResult);

    // Log the classification
    await logClassification(messageId, messageData.text, classificationResult);

    return {
      success: true,
      result: classificationResult
    };

  } catch (error) {
    logger.error('Manual classification failed', {
      messageId,
      error: error instanceof Error ? error.message : String(error)
    });

    return {
      success: false,
      error: error instanceof Error ? error.message : String(error)
    };
  }
}
