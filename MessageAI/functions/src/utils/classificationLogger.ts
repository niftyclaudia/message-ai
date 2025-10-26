/**
 * Classification logging utilities for analytics and monitoring
 */

import { logger } from './logger';
import { ClassificationResult } from '../services/openaiClient';
import { db } from './firestore';
import { COLLECTIONS, PRIORITY_LEVELS } from '../constants/firestore';

// Use the constant from the centralized file
const CLASSIFICATION_LOGS_COLLECTION = COLLECTIONS.CLASSIFICATION_LOGS;

export interface ClassificationLog {
  messageID: string;
  originalText: string;
  classificationResult: string;
  confidence: number;
  method: string;
  processingTimeMs: number;
  timestamp: Date;
  errorMessage?: string;
}

/**
 * Log a classification result to Firestore for analytics
 * @param messageID - ID of the message that was classified
 * @param originalText - Original message text
 * @param result - Classification result
 * @param error - Optional error that occurred during classification
 */
export async function logClassification(
  messageID: string,
  originalText: string,
  result: ClassificationResult,
  error?: Error
): Promise<void> {
  try {
    const logEntry: ClassificationLog = {
      messageID,
      originalText: originalText.substring(0, 500), // Truncate for storage
      classificationResult: result.priority,
      confidence: result.confidence,
      method: result.method,
      processingTimeMs: result.processingTimeMs,
      timestamp: result.timestamp,
      errorMessage: error?.message
    };

    // Write to Firestore
    await db.collection(CLASSIFICATION_LOGS_COLLECTION).add(logEntry);
    
    logger.info('Classification logged successfully', {
      messageID,
      priority: result.priority,
      confidence: result.confidence,
      method: result.method,
      processingTimeMs: result.processingTimeMs
    });

  } catch (logError) {
    // Don't fail the main classification process if logging fails
    logger.error('Failed to log classification', {
      messageID,
      error: logError instanceof Error ? logError.message : String(logError),
      originalError: error?.message
    });
  }
}

/**
 * Get classification statistics for a time period
 * @param startDate - Start date for statistics
 * @param endDate - End date for statistics
 * @returns Promise with classification statistics
 */
export async function getClassificationStats(
  startDate: Date,
  endDate: Date
): Promise<{
  totalClassifications: number;
  urgentCount: number;
  normalCount: number;
  averageConfidence: number;
  averageProcessingTime: number;
  methodBreakdown: Record<string, number>;
  errorRate: number;
}> {
  try {
    const logs = await db
      .collection(CLASSIFICATION_LOGS_COLLECTION)
      .where('timestamp', '>=', startDate)
      .where('timestamp', '<=', endDate)
      .get();

    const stats = {
      totalClassifications: 0,
      urgentCount: 0,
      normalCount: 0,
      totalConfidence: 0,
      totalProcessingTime: 0,
      methodBreakdown: {} as Record<string, number>,
      errorCount: 0
    };

    logs.forEach((doc: any) => {
      const data = doc.data() as ClassificationLog;
      stats.totalClassifications++;
      
      if (data.classificationResult === PRIORITY_LEVELS.URGENT) {
        stats.urgentCount++;
      } else {
        stats.normalCount++;
      }
      
      stats.totalConfidence += data.confidence;
      stats.totalProcessingTime += data.processingTimeMs;
      
      stats.methodBreakdown[data.method] = (stats.methodBreakdown[data.method] || 0) + 1;
      
      if (data.errorMessage) {
        stats.errorCount++;
      }
    });

    return {
      totalClassifications: stats.totalClassifications,
      urgentCount: stats.urgentCount,
      normalCount: stats.normalCount,
      averageConfidence: stats.totalClassifications > 0 ? stats.totalConfidence / stats.totalClassifications : 0,
      averageProcessingTime: stats.totalClassifications > 0 ? stats.totalProcessingTime / stats.totalClassifications : 0,
      methodBreakdown: stats.methodBreakdown,
      errorRate: stats.totalClassifications > 0 ? stats.errorCount / stats.totalClassifications : 0
    };

  } catch (error) {
    logger.error('Failed to get classification stats', { error: error instanceof Error ? error.message : String(error) });
    throw error;
  }
}

/**
 * Get recent classification logs for debugging
 * @param limit - Maximum number of logs to return
 * @returns Promise with recent classification logs
 */
export async function getRecentClassificationLogs(limit: number = 50): Promise<ClassificationLog[]> {
  try {
    const logs = await db
      .collection(CLASSIFICATION_LOGS_COLLECTION)
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();

    return logs.docs.map((doc: any) => doc.data() as ClassificationLog);

  } catch (error) {
    logger.error('Failed to get recent classification logs', { error: error instanceof Error ? error.message : String(error) });
    throw error;
  }
}

/**
 * Clean up old classification logs to manage storage costs
 * @param olderThanDays - Delete logs older than this many days
 * @returns Promise with number of logs deleted
 */
export async function cleanupOldClassificationLogs(olderThanDays: number = 30): Promise<number> {
  try {
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);

    const oldLogs = await db
      .collection(CLASSIFICATION_LOGS_COLLECTION)
      .where('timestamp', '<', cutoffDate)
      .get();

    const batch = db.batch();
    oldLogs.docs.forEach((doc: any) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    
    logger.info('Cleaned up old classification logs', {
      deletedCount: oldLogs.docs.length,
      olderThanDays
    });

    return oldLogs.docs.length;

  } catch (error) {
    logger.error('Failed to cleanup old classification logs', { error: error instanceof Error ? error.message : String(error) });
    throw error;
  }
}
