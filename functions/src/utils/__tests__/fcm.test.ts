/**
 * Unit tests for FCM utility functions
 */

import { buildNotificationPayload, sendNotificationsBatch } from '../fcm';
import * as admin from 'firebase-admin';

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  messaging: jest.fn(() => ({
    sendMulticast: jest.fn()
  }))
}));

describe('FCM Utils', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('buildNotificationPayload', () => {
    it('should build correct payload for normal message', () => {
      const payload = buildNotificationPayload(
        'John Doe',
        'Hello world!',
        'chat123',
        'user456'
      );

      expect(payload.notification).toEqual({
        title: 'John Doe',
        body: 'Hello world!'
      });

      expect(payload.data).toEqual({
        chatID: 'chat123',
        senderID: 'user456',
        messageText: 'Hello world!',
        timestamp: expect.any(String)
      });

      expect(payload.apns).toEqual({
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
      });
    });

    it('should truncate long messages to 100 characters', () => {
      const longMessage = 'A'.repeat(150);
      const payload = buildNotificationPayload(
        'John Doe',
        longMessage,
        'chat123',
        'user456'
      );

      expect(payload.notification?.body).toBe('A'.repeat(97) + '...');
      expect(payload.data?.messageText).toBe(longMessage); // Full message in data
    });

    it('should not truncate messages under 100 characters', () => {
      const shortMessage = 'Hello world!';
      const payload = buildNotificationPayload(
        'John Doe',
        shortMessage,
        'chat123',
        'user456'
      );

      expect(payload.notification?.body).toBe(shortMessage);
    });
  });

  describe('sendNotificationsBatch', () => {
    it('should send notifications to all tokens', async () => {
      const mockResponse = {
        successCount: 2,
        failureCount: 1,
        responses: [
          { success: true },
          { success: true },
          { 
            success: false, 
            error: { 
              code: 'messaging/invalid-registration-token',
              message: 'Invalid token'
            }
          }
        ]
      };

      (admin.messaging().sendEachForMulticast as jest.Mock).mockResolvedValue(mockResponse);

      const tokens = ['token1', 'token2', 'token3'];
      const payload = buildNotificationPayload('John', 'Hello', 'chat1', 'user1');

      const result = await sendNotificationsBatch(tokens, payload);

      expect(result).toEqual({
        successCount: 2,
        failureCount: 1,
        invalidTokens: ['token3']
      });

      expect(admin.messaging().sendEachForMulticast).toHaveBeenCalledWith({
        tokens,
        notification: payload.notification,
        data: payload.data,
        apns: payload.apns
      });
    });

    it('should handle empty token array', async () => {
      const result = await sendNotificationsBatch([], {} as any);

      expect(result).toEqual({
        successCount: 0,
        failureCount: 0,
        invalidTokens: []
      });

      expect(admin.messaging().sendEachForMulticast).not.toHaveBeenCalled();
    });

    it('should identify different types of FCM errors', async () => {
      const mockResponse = {
        successCount: 1,
        failureCount: 2,
        responses: [
          { success: true },
          { 
            success: false, 
            error: { 
              code: 'messaging/invalid-registration-token',
              message: 'Invalid token'
            }
          },
          { 
            success: false, 
            error: { 
              code: 'messaging/registration-token-not-registered',
              message: 'Token not registered'
            }
          }
        ]
      };

      (admin.messaging().sendEachForMulticast as jest.Mock).mockResolvedValue(mockResponse);

      const tokens = ['token1', 'token2', 'token3'];
      const result = await sendNotificationsBatch(tokens, {} as any);

      expect(result.invalidTokens).toEqual(['token2', 'token3']);
    });
  });
});
