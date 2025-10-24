/**
 * memoryCleanup.ts
 * PR-004: Memory & State Management System
 * 
 * Scheduled Cloud Function that runs daily at midnight UTC to clean up
 * AI memory data older than 90 days while preserving important items.
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from '../utils/logger';

// Ensure Firebase Admin is initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Scheduled function that runs daily at midnight UTC to cleanup old memory data
 * - Removes learning data entries older than 90 days
 * - Removes conversation history entries older than 90 days
 * - Preserves decisions flagged as important
 * - Batch deletes for efficiency (max 500 per batch)
 */
export const memoryCleanup = functions.pubsub
  .schedule('0 0 * * *') // Daily at midnight UTC
  .timeZone('UTC')
  .onRun(async (context) => {
    logger.info('Starting memory cleanup job');
    
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 90); // 90 days ago
      const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoffDate);
      
      let totalDeleted = 0;
      let totalErrors = 0;
      
      // Get all users
      const usersSnapshot = await db.collection('users').get();
      
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        
        try {
          // Clean up learning data entries
          const learningDeleted = await cleanupLearningData(userId, cutoffTimestamp);
          totalDeleted += learningDeleted;
          
          // Clean up conversation history entries
          const conversationDeleted = await cleanupConversationHistory(userId, cutoffTimestamp);
          totalDeleted += conversationDeleted;
          
          logger.info(`Cleaned up ${learningDeleted + conversationDeleted} entries for user ${userId}`);
        } catch (error) {
          totalErrors++;
          logger.error(`Error cleaning up memory for user ${userId}:`, error);
        }
      }
      
      logger.info(`Memory cleanup complete. Deleted: ${totalDeleted}, Errors: ${totalErrors}`);
      
      // Alert if too many errors
      if (totalErrors > 10) {
        logger.error(`WARNING: Memory cleanup had ${totalErrors} errors!`);
      }
      
      return {
        success: true,
        totalDeleted,
        totalErrors,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error('Memory cleanup job failed:', error);
      throw error;
    }
  });

/**
 * Cleans up learning data entries older than cutoff date
 */
async function cleanupLearningData(
  userId: string,
  cutoffTimestamp: admin.firestore.Timestamp
): Promise<number> {
  let deletedCount = 0;
  
  // Query old learning data entries
  const learningRef = db
    .collection('users')
    .doc(userId)
    .collection('aiState')
    .doc('learningData')
    .collection('entries');
  
  const oldEntriesSnapshot = await learningRef
    .where('timestamp', '<', cutoffTimestamp)
    .limit(500) // Batch limit
    .get();
  
  if (oldEntriesSnapshot.empty) {
    return 0;
  }
  
  // Batch delete
  const batch = db.batch();
  oldEntriesSnapshot.docs.forEach(doc => {
    batch.delete(doc.ref);
    deletedCount++;
  });
  
  await batch.commit();
  
  return deletedCount;
}

/**
 * Cleans up conversation history entries older than cutoff date
 * Preserves entries linked to important decisions
 */
async function cleanupConversationHistory(
  userId: string,
  cutoffTimestamp: admin.firestore.Timestamp
): Promise<number> {
  let deletedCount = 0;
  
  // Query old conversation history entries
  const conversationRef = db
    .collection('users')
    .doc(userId)
    .collection('aiState')
    .doc('conversationHistory')
    .collection('entries');
  
  const oldEntriesSnapshot = await conversationRef
    .where('timestamp', '<', cutoffTimestamp)
    .limit(500) // Batch limit
    .get();
  
  if (oldEntriesSnapshot.empty) {
    return 0;
  }
  
  // Get important decision IDs to preserve related conversations
  const taskStateDoc = await db
    .collection('users')
    .doc(userId)
    .collection('aiState')
    .doc('taskState')
    .get();
  
  let importantDecisionIds: string[] = [];
  if (taskStateDoc.exists) {
    const taskState = taskStateDoc.data();
    if (taskState && taskState.decisions) {
      importantDecisionIds = taskState.decisions
        .filter((d: any) => d.isImportant)
        .map((d: any) => d.id);
    }
  }
  
  // Batch delete (skip entries linked to important decisions)
  const batch = db.batch();
  oldEntriesSnapshot.docs.forEach(doc => {
    const data = doc.data();
    
    // Check if this conversation is linked to an important decision
    const isImportantConversation = data.contextUsed?.some((contextId: string) =>
      importantDecisionIds.includes(contextId)
    );
    
    // Only delete if not linked to important items
    if (!isImportantConversation) {
      batch.delete(doc.ref);
      deletedCount++;
    }
  });
  
  await batch.commit();
  
  return deletedCount;
}

/**
 * Manual trigger for testing (HTTP function)
 */
export const memoryCleanupManual = functions.https.onRequest(async (req, res) => {
  // Only allow in development or with admin authentication
  if (process.env.NODE_ENV === 'production') {
    res.status(403).send('Manual cleanup not allowed in production');
    return;
  }
  
  try {
    logger.info('Manual memory cleanup triggered');
    
    // Create a mock context
    const mockContext = {
      eventId: 'manual-trigger',
      timestamp: new Date().toISOString(),
      eventType: 'manual',
      resource: {}
    } as any;
    
    const result = await memoryCleanup.run(mockContext);
    
    res.status(200).json({
      success: true,
      message: 'Memory cleanup completed',
      result
    });
  } catch (error) {
    logger.error('Manual cleanup failed:', error);
    res.status(500).json({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

