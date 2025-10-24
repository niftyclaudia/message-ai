/**
 * Permission Checking Utilities
 * Validates user access to resources before function execution
 */

import * as admin from 'firebase-admin';
import { logger } from './logger';

export type ResourceType = 'message' | 'thread' | 'chat' | 'calendar';

/**
 * Check if user has access to a specific resource
 */
export async function checkUserAccess(
  userId: string,
  resourceId: string,
  resourceType: ResourceType
): Promise<boolean> {
  try {
    const db = admin.firestore();

    switch (resourceType) {
      case 'message': {
        // Check if user is sender or member of chat containing the message
        const messageDoc = await db.collection('messages').doc(resourceId).get();
        
        if (!messageDoc.exists) {
          logger.warn('Message not found', { resourceId, userId });
          return false;
        }

        const message = messageDoc.data();
        if (!message) return false;

        // User is sender
        if (message.senderID === userId) {
          return true;
        }

        // User is member of the chat
        if (message.chatID) {
          return await checkUserAccess(userId, message.chatID, 'chat');
        }

        return false;
      }

      case 'thread':
      case 'chat': {
        // Check if user is member of the chat/thread
        const chatDoc = await db.collection('chats').doc(resourceId).get();
        
        if (!chatDoc.exists) {
          logger.warn('Chat not found', { resourceId, userId });
          return false;
        }

        const chat = chatDoc.data();
        if (!chat) return false;

        // Check if user is in members array
        if (Array.isArray(chat.members) && chat.members.includes(userId)) {
          return true;
        }

        return false;
      }

      case 'calendar': {
        // User can only access their own calendar
        return userId === resourceId;
      }

      default:
        logger.error('Unknown resource type', { resourceType });
        return false;
    }
  } catch (error) {
    logger.error('Error checking user access', { error, userId, resourceId, resourceType });
    return false;
  }
}

/**
 * Check if user can access multiple resources (all must be accessible)
 */
export async function checkMultipleAccess(
  userId: string,
  resources: Array<{ id: string; type: ResourceType }>
): Promise<boolean> {
  try {
    const accessChecks = resources.map((resource) =>
      checkUserAccess(userId, resource.id, resource.type)
    );

    const results = await Promise.all(accessChecks);
    return results.every((result) => result === true);
  } catch (error) {
    logger.error('Error checking multiple access', { error, userId, resources });
    return false;
  }
}

/**
 * Get all chats/threads user is a member of
 */
export async function getUserChats(userId: string): Promise<string[]> {
  try {
    const db = admin.firestore();
    
    const chatsSnapshot = await db
      .collection('chats')
      .where('members', 'array-contains', userId)
      .get();

    return chatsSnapshot.docs.map((doc) => doc.id);
  } catch (error) {
    logger.error('Error getting user chats', { error, userId });
    return [];
  }
}

/**
 * Verify user is making request for themselves
 */
export function verifySelfRequest(requestingUserId: string, targetUserId: string): boolean {
  if (requestingUserId !== targetUserId) {
    logger.warn('User attempted to access another user\'s data', {
      requestingUserId,
      targetUserId,
    });
    return false;
  }
  return true;
}

/**
 * Check if user exists in Firebase Auth
 */
export async function userExists(userId: string): Promise<boolean> {
  try {
    await admin.auth().getUser(userId);
    return true;
  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      return false;
    }
    logger.error('Error checking if user exists', { error, userId });
    return false;
  }
}

/**
 * Get chat members
 */
export async function getChatMembers(chatId: string): Promise<string[]> {
  try {
    const db = admin.firestore();
    const chatDoc = await db.collection('chats').doc(chatId).get();
    
    if (!chatDoc.exists) {
      return [];
    }

    const chat = chatDoc.data();
    if (!chat || !Array.isArray(chat.members)) {
      return [];
    }

    return chat.members;
  } catch (error) {
    logger.error('Error getting chat members', { error, chatId });
    return [];
  }
}

/**
 * Check if all users in array exist and are accessible
 */
export async function validateUserList(userIds: string[]): Promise<boolean> {
  try {
    if (!Array.isArray(userIds) || userIds.length === 0) {
      return false;
    }

    // Check if all user IDs are valid format
    const validFormat = userIds.every(
      (id) => typeof id === 'string' && id.length > 0 && id.length <= 128
    );

    if (!validFormat) {
      return false;
    }

    // For now, assume valid format means valid users
    // In production, might want to verify existence in Auth
    return true;
  } catch (error) {
    logger.error('Error validating user list', { error, userIds });
    return false;
  }
}

