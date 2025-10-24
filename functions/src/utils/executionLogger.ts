/**
 * Function Execution Logging
 * Logs all function executions to Firestore for debugging and monitoring
 */

import * as admin from 'firebase-admin';
import { logger } from './logger';
import { sanitizeParameters } from '../functionCalling/validation';

export interface FunctionExecutionLog {
  executionId: string;
  functionName: string;
  parameters: Record<string, any>; // Sanitized
  userId: string;
  timestamp: admin.firestore.Timestamp;
  duration: number; // milliseconds
  status: 'success' | 'error' | 'timeout';
  errorDetails?: string;
  resultSummary?: string;
}

/**
 * Log a function execution to Firestore
 */
export async function logExecution(
  functionName: string,
  params: Record<string, any>,
  userId: string,
  duration: number,
  status: 'success' | 'error' | 'timeout',
  errorDetails?: string,
  resultSummary?: string
): Promise<void> {
  try {
    const db = admin.firestore();
    const executionId = db.collection('functionExecutionLogs').doc().id;
    
    const logEntry: FunctionExecutionLog = {
      executionId,
      functionName,
      parameters: sanitizeParameters(params),
      userId,
      timestamp: admin.firestore.Timestamp.now(),
      duration,
      status,
      errorDetails,
      resultSummary,
    };
    
    await db.collection('functionExecutionLogs').doc(executionId).set(logEntry);
    
    logger.info('Function execution logged', {
      executionId,
      functionName,
      status,
      duration,
    });
  } catch (error) {
    // Don't fail the function if logging fails
    logger.error('Failed to log execution', { error, functionName });
  }
}

/**
 * Query execution logs with filters
 */
export interface LogFilters {
  functionName?: string;
  userId?: string;
  status?: 'success' | 'error' | 'timeout';
  startDate?: Date;
  endDate?: Date;
  limit?: number;
}

export async function queryExecutionLogs(
  filters: LogFilters
): Promise<FunctionExecutionLog[]> {
  try {
    const db = admin.firestore();
    let query: admin.firestore.Query = db.collection('functionExecutionLogs');
    
    // Apply filters
    if (filters.functionName) {
      query = query.where('functionName', '==', filters.functionName);
    }
    
    if (filters.userId) {
      query = query.where('userId', '==', filters.userId);
    }
    
    if (filters.status) {
      query = query.where('status', '==', filters.status);
    }
    
    if (filters.startDate) {
      query = query.where(
        'timestamp',
        '>=',
        admin.firestore.Timestamp.fromDate(filters.startDate)
      );
    }
    
    if (filters.endDate) {
      query = query.where(
        'timestamp',
        '<=',
        admin.firestore.Timestamp.fromDate(filters.endDate)
      );
    }
    
    // Order by timestamp descending
    query = query.orderBy('timestamp', 'desc');
    
    // Apply limit
    const limit = filters.limit || 50;
    query = query.limit(limit);
    
    const snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as FunctionExecutionLog);
  } catch (error) {
    logger.error('Failed to query execution logs', { error, filters });
    throw error;
  }
}

/**
 * Clean up old logs (older than 30 days)
 * Should be called by scheduled function
 */
export async function cleanupOldLogs(daysToKeep: number = 30): Promise<number> {
  try {
    const db = admin.firestore();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - daysToKeep);
    
    const oldLogs = await db
      .collection('functionExecutionLogs')
      .where('timestamp', '<', admin.firestore.Timestamp.fromDate(cutoffDate))
      .limit(500) // Delete in batches
      .get();
    
    if (oldLogs.empty) {
      logger.info('No old logs to cleanup');
      return 0;
    }
    
    const batch = db.batch();
    oldLogs.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    
    logger.info('Old logs cleaned up', {
      count: oldLogs.size,
      cutoffDate: cutoffDate.toISOString(),
    });
    
    return oldLogs.size;
  } catch (error) {
    logger.error('Failed to cleanup old logs', { error });
    throw error;
  }
}

