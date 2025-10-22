/**
 * Unit tests for sendMessageNotification Cloud Function
 */

import { sendMessageNotification } from '../sendMessageNotification';
// Mock Firebase Admin and Functions
jest.mock('firebase-admin', () => ({
  initializeApp: jest.fn(),
  firestore: jest.fn(() => ({
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        get: jest.fn(),
        update: jest.fn()
      }))
    }))
  })),
  messaging: jest.fn(() => ({
    sendMulticast: jest.fn()
  })),
  FieldValue: {
    delete: jest.fn()
  }
}));

jest.mock('firebase-functions', () => ({
  firestore: {
    document: jest.fn(() => ({
      onCreate: jest.fn()
    }))
  }
}));

// Mock utility functions
jest.mock('../utils/firestore', () => ({
  fetchChatData: jest.fn(),
  fetchMultipleUsers: jest.fn(),
  removeInvalidToken: jest.fn()
}));

jest.mock('../utils/fcm', () => ({
  buildNotificationPayload: jest.fn(),
  sendNotificationsBatch: jest.fn()
}));

import { fetchChatData, fetchMultipleUsers, removeInvalidToken } from '../utils/firestore';
import { buildNotificationPayload, sendNotificationsBatch } from '../utils/fcm';

describe('sendMessageNotification', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should process valid message and send notifications', async () => {
    // Mock data
    const mockMessageData = {
      text: 'Hello world!',
      senderID: 'user1',
      chatID: 'chat123',
      messageID: 'msg456'
    };

    const mockChatData = {
      id: 'chat123',
      members: ['user1', 'user2', 'user3'],
      isGroupChat: true
    };

    const mockRecipients = [
      { userID: 'user2', displayName: 'User 2', fcmToken: 'token2' },
      { userID: 'user3', displayName: 'User 3', fcmToken: 'token3' }
    ];

    const mockPayload = {
      notification: { title: 'User 1', body: 'Hello world!' },
      data: { chatID: 'chat123', senderID: 'user1' }
    };

    const mockSendResults = {
      successCount: 2,
      failureCount: 0,
      invalidTokens: []
    };

    // Setup mocks
    (fetchChatData as jest.Mock).mockResolvedValue(mockChatData);
    (fetchMultipleUsers as jest.Mock).mockResolvedValue(mockRecipients);
    (buildNotificationPayload as jest.Mock).mockReturnValue(mockPayload);
    (sendNotificationsBatch as jest.Mock).mockResolvedValue(mockSendResults);

    // Create mock snapshot and context
    const mockSnapshot = {
      data: () => mockMessageData,
      ref: {
        parent: { parent: { id: 'chat123' } }
      },
      id: 'msg456'
    };

    const mockContext = {
      params: { chatID: 'chat123', messageID: 'msg456' }
    };

    // Execute function
    const functionRef = sendMessageNotification as any;
    await functionRef.onCreate(mockSnapshot, mockContext);

    // Verify calls
    expect(fetchChatData).toHaveBeenCalledWith('chat123');
    expect(fetchMultipleUsers).toHaveBeenCalledWith(['user2', 'user3']); // Sender excluded
    expect(buildNotificationPayload).toHaveBeenCalledWith(
      'User 2', // First recipient's name
      'Hello world!',
      'chat123',
      'user1'
    );
    expect(sendNotificationsBatch).toHaveBeenCalledWith(['token2', 'token3'], mockPayload);
  });

  it('should handle missing chat document gracefully', async () => {
    const mockSnapshot = {
      data: () => ({ text: 'Hello', senderID: 'user1' }),
      ref: { parent: { parent: { id: 'chat123' } } },
      id: 'msg456'
    };

    const mockContext = {
      params: { chatID: 'chat123', messageID: 'msg456' }
    };

    (fetchChatData as jest.Mock).mockResolvedValue(null);

    const functionRef = sendMessageNotification as any;
    await functionRef.onCreate(mockSnapshot, mockContext);

    expect(fetchChatData).toHaveBeenCalledWith('chat123');
    expect(fetchMultipleUsers).not.toHaveBeenCalled();
    expect(sendNotificationsBatch).not.toHaveBeenCalled();
  });

  it('should handle no recipients after excluding sender', async () => {
    const mockChatData = {
      id: 'chat123',
      members: ['user1'], // Only sender
      isGroupChat: false
    };

    const mockSnapshot = {
      data: () => ({ text: 'Hello', senderID: 'user1' }),
      ref: { parent: { parent: { id: 'chat123' } } },
      id: 'msg456'
    };

    const mockContext = {
      params: { chatID: 'chat123', messageID: 'msg456' }
    };

    (fetchChatData as jest.Mock).mockResolvedValue(mockChatData);

    const functionRef = sendMessageNotification as any;
    await functionRef.onCreate(mockSnapshot, mockContext);

    expect(fetchChatData).toHaveBeenCalledWith('chat123');
    expect(fetchMultipleUsers).not.toHaveBeenCalled();
    expect(sendNotificationsBatch).not.toHaveBeenCalled();
  });

  it('should handle no valid FCM tokens', async () => {
    const mockChatData = {
      id: 'chat123',
      members: ['user1', 'user2'],
      isGroupChat: false
    };

    const mockSnapshot = {
      data: () => ({ text: 'Hello', senderID: 'user1' }),
      ref: { parent: { parent: { id: 'chat123' } } },
      id: 'msg456'
    };

    const mockContext = {
      params: { chatID: 'chat123', messageID: 'msg456' }
    };

    (fetchChatData as jest.Mock).mockResolvedValue(mockChatData);
    (fetchMultipleUsers as jest.Mock).mockResolvedValue([]); // No valid tokens

    const functionRef = sendMessageNotification as any;
    await functionRef.onCreate(mockSnapshot, mockContext);

    expect(fetchChatData).toHaveBeenCalledWith('chat123');
    expect(fetchMultipleUsers).toHaveBeenCalledWith(['user2']);
    expect(sendNotificationsBatch).not.toHaveBeenCalled();
  });

  it('should clean up invalid tokens', async () => {
    const mockChatData = {
      id: 'chat123',
      members: ['user1', 'user2'],
      isGroupChat: false
    };

    const mockRecipients = [
      { userID: 'user2', displayName: 'User 2', fcmToken: 'token2' }
    ];

    const mockSendResults = {
      successCount: 0,
      failureCount: 1,
      invalidTokens: ['token2']
    };

    const mockSnapshot = {
      data: () => ({ text: 'Hello', senderID: 'user1' }),
      ref: { parent: { parent: { id: 'chat123' } } },
      id: 'msg456'
    };

    const mockContext = {
      params: { chatID: 'chat123', messageID: 'msg456' }
    };

    (fetchChatData as jest.Mock).mockResolvedValue(mockChatData);
    (fetchMultipleUsers as jest.Mock).mockResolvedValue(mockRecipients);
    (buildNotificationPayload as jest.Mock).mockReturnValue({});
    (sendNotificationsBatch as jest.Mock).mockResolvedValue(mockSendResults);
    (removeInvalidToken as jest.Mock).mockResolvedValue(undefined);

    const functionRef = sendMessageNotification as any;
    await functionRef.onCreate(mockSnapshot, mockContext);

    expect(removeInvalidToken).toHaveBeenCalledWith('user2');
  });
});
