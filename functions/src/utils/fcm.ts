/**
 * FCM (Firebase Cloud Messaging) helper functions
 */

import * as admin from 'firebase-admin';
import { SendResults } from '../types';
import { logger } from './logger';

/**
 * Build FCM notification payload
 */
export function buildNotificationPayload(
  senderName: string,
  messageText: string,
  chatID: string,
  senderID: string
): any {
  const truncatedText = messageText.length > 100 
    ? messageText.substring(0, 97) + '...' 
    : messageText;
  
  return {
    notification: {
      title: senderName,
      body: truncatedText
    },
    data: {
      chatID,
      senderID,
      messageText,
      timestamp: new Date().toISOString()
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          contentAvailable: true
        }
      },
      headers: {
        'apns-priority': '10'
      }
    }
  };
}

/**
 * Send notifications to multiple FCM tokens
 */
export async function sendNotificationsBatch(
  tokens: string[], 
  payload: any
): Promise<SendResults> {
  try {
    if (tokens.length === 0) {
      logger.warn('No tokens provided for notification sending');
      return { successCount: 0, failureCount: 0, invalidTokens: [] };
    }

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: payload.notification,
      data: payload.data,
      apns: payload.apns
    });

    const results: SendResults = {
      successCount: response.successCount,
      failureCount: response.failureCount,
      invalidTokens: []
    };

    // Identify invalid tokens for cleanup
    response.responses.forEach((resp: any, index: number) => {
      if (!resp.success) {
        const error = resp.error;
        if (error?.code === 'messaging/invalid-registration-token' ||
            error?.code === 'messaging/registration-token-not-registered') {
          results.invalidTokens.push(tokens[index]);
        }
        logger.warn('FCM send failed for token', { 
          token: tokens[index], 
          error: error?.message 
        });
      }
    });

    logger.info('FCM batch send completed', {
      totalTokens: tokens.length,
      successCount: results.successCount,
      failureCount: results.failureCount,
      invalidTokens: results.invalidTokens.length
    });

    return results;
  } catch (error) {
    logger.error('FCM batch send failed', error);
    throw error;
  }
}
