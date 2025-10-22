/**
 * Unit tests for Firestore utility functions
 */

import { fetchChatData, fetchMultipleUsers, removeInvalidToken } from '../firestore';
import * as admin from 'firebase-admin';

// Mock Firebase Admin
jest.mock('firebase-admin', () => ({
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn(),
        update: jest.fn()
      }))
    }))
  })),
  FieldValue: {
    delete: jest.fn()
  }
}));

describe('Firestore Utils', () => {
  let mockDb: any;
  
  beforeEach(() => {
    jest.clearAllMocks();
    mockDb = (admin.firestore as any)();
  });

  describe('fetchChatData', () => {
    it('should return chat data when document exists', async () => {
      const mockChatData = {
        members: ['user1', 'user2', 'user3'],
        isGroupChat: true
      };
      
      const mockDoc = {
        exists: true,
        data: () => mockChatData
      };
      
      mockDb.collection().doc().get.mockResolvedValue(mockDoc);
      
      const result = await fetchChatData('chat123');
      
      expect(result).toEqual({
        id: 'chat123',
        members: ['user1', 'user2', 'user3'],
        isGroupChat: true
      });
    });

    it('should return null when document does not exist', async () => {
      const mockDoc = {
        exists: false,
        data: () => undefined
      };
      
      mockDb.collection().doc().get.mockResolvedValue(mockDoc);
      
      const result = await fetchChatData('nonexistent');
      
      expect(result).toBeNull();
    });
  });

  describe('fetchMultipleUsers', () => {
    it('should return users with FCM tokens', async () => {
      const userIDs = ['user1', 'user2', 'user3'];
      const mockDocs = [
        { exists: true, data: () => ({ displayName: 'User 1', fcmToken: 'token1' }) },
        { exists: true, data: () => ({ displayName: 'User 2', fcmToken: 'token2' }) },
        { exists: true, data: () => ({ displayName: 'User 3' }) } // No FCM token
      ];
      
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockDocs[0])
        .mockResolvedValueOnce(mockDocs[1])
        .mockResolvedValueOnce(mockDocs[2]);
      
      const result = await fetchMultipleUsers(userIDs);
      
      expect(result).toHaveLength(2);
      expect(result[0]).toEqual({
        userID: 'user1',
        displayName: 'User 1',
        fcmToken: 'token1'
      });
      expect(result[1]).toEqual({
        userID: 'user2',
        displayName: 'User 2',
        fcmToken: 'token2'
      });
    });

    it('should handle missing user documents', async () => {
      const userIDs = ['user1', 'user2'];
      const mockDocs = [
        { exists: true, data: () => ({ displayName: 'User 1', fcmToken: 'token1' }) },
        { exists: false, data: () => undefined }
      ];
      
      mockDb.collection().doc().get
        .mockResolvedValueOnce(mockDocs[0])
        .mockResolvedValueOnce(mockDocs[1]);
      
      const result = await fetchMultipleUsers(userIDs);
      
      expect(result).toHaveLength(1);
      expect(result[0].userID).toBe('user1');
    });
  });

  describe('removeInvalidToken', () => {
    it('should remove FCM token from user document', async () => {
      const mockUpdate = jest.fn().mockResolvedValue(undefined);
      mockDb.collection().doc().update = mockUpdate;
      
      await removeInvalidToken('user123');
      
      expect(mockUpdate).toHaveBeenCalledWith({
        fcmToken: admin.firestore.FieldValue.delete()
      });
    });
  });
});
