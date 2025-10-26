/**
 * Firebase Cloud Messaging utilities
 */

import * as admin from 'firebase-admin';
import { logger } from './logger';

export interface NotificationPayload {
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Send a push notification to a specific device
 * @param payload - Notification payload with token, title, body, and data
 */
export async function sendNotificationToDevice(payload: NotificationPayload): Promise<void> {
  try {
    const message = {
      token: payload.token,
      notification: {
        title: payload.title,
        body: payload.body
      },
      data: payload.data || {},
      android: {
        priority: 'high' as const,
        notification: {
          sound: 'default',
          priority: 'high' as const
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    
    logger.info('Notification sent successfully', {
      messageId: response,
      token: payload.token.substring(0, 20) + '...'
    });

  } catch (error) {
    logger.error('Failed to send notification', {
      error: error instanceof Error ? error.message : String(error),
      code: (error as any)?.code,
      token: payload.token.substring(0, 20) + '...'
    });
    throw error;
  }
}
