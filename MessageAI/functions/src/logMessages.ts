/**
 * Cloud Function to log all messages with priority data
 * This can be called manually for debugging purposes
 */

import { onCall } from 'firebase-functions/v2/https';
import { logger } from './utils/logger';
import { logAllMessagesWithPriority, logMessagesForChat } from './utils/messageLogger';

/**
 * HTTP callable function to log all messages with priority data
 * Usage: Call this function from the Firebase console or via HTTP
 */
export const logAllMessages = onCall(async (request) => {
  try {
    logger.info('Log all messages function called');
    
    await logAllMessagesWithPriority();
    
    return {
      success: true,
      message: 'All messages logged successfully. Check the function logs for details.'
    };
    
  } catch (error) {
    logger.error('Failed to log all messages', {
      error: error instanceof Error ? error.message : String(error)
    });
    
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error)
    };
  }
});

/**
 * HTTP callable function to log messages for a specific chat
 * Usage: Call with { chatId: "your-chat-id" }
 */
export const logChatMessages = onCall(async (request) => {
  try {
    const { chatId } = request.data;
    
    if (!chatId) {
      return {
        success: false,
        error: 'chatId is required'
      };
    }
    
    logger.info('Log chat messages function called', { chatId });
    
    await logMessagesForChat(chatId);
    
    return {
      success: true,
      message: `Messages for chat ${chatId} logged successfully. Check the function logs for details.`
    };
    
  } catch (error) {
    logger.error('Failed to log chat messages', {
      error: error instanceof Error ? error.message : String(error)
    });
    
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error)
    };
  }
});
