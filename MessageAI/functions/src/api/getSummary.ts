/**
 * API endpoint to retrieve session summaries
 */

import { onRequest } from 'firebase-functions/v2/https';
import { logger } from '../utils/logger';
import { getFirestore } from 'firebase-admin/firestore';
import { COLLECTIONS, FIELDS } from '../constants/firestore';

const db = getFirestore();

export interface GetSummaryRequest {
  sessionID: string;
  userID: string;
}

export interface GetSummaryResponse {
  success: boolean;
  summary?: {
    id: string;
    sessionID: string;
    userID: string;
    generatedAt: Date;
    overview: string;
    actionItems: string[];
    keyDecisions: string[];
    messageCount: number;
    confidence: number;
    exportData?: string;
  };
  error?: string;
}

/**
 * HTTP endpoint to get a session summary
 * GET /getSummary?sessionID={sessionID}&userID={userID}
 */
export const getSummary = onRequest(
  { cors: true },
  async (request, response) => {
    try {
      // Only allow GET requests
      if (request.method !== 'GET') {
        response.status(405).json({
          success: false,
          error: 'Method not allowed. Use GET.'
        });
        return;
      }

      const { sessionID, userID } = request.query;

      // Validate required parameters
      if (!sessionID || !userID) {
        response.status(400).json({
          success: false,
          error: 'Missing required parameters: sessionID and userID'
        });
        return;
      }

      // Validate user authentication (in production, verify JWT token)
      if (typeof userID !== 'string' || userID.trim().length === 0) {
        response.status(401).json({
          success: false,
          error: 'Invalid userID'
        });
        return;
      }

      logger.info('Getting summary for session', { sessionID, userID });

      // Get summary from Firestore
      const summaryDoc = await db
        .collection(COLLECTIONS.FOCUS_SUMMARIES)
        .where(FIELDS.SESSION_ID, '==', sessionID)
        .where(FIELDS.USER_ID, '==', userID)
        .limit(1)
        .get();

      if (summaryDoc.empty) {
        logger.info('Summary not found', { sessionID, userID });
        response.status(404).json({
          success: false,
          error: 'Summary not found for this session'
        });
        return;
      }

      const summaryData = summaryDoc.docs[0].data();
      const summaryId = summaryDoc.docs[0].id;

      // Convert Firestore timestamps to Date objects
      const summary: GetSummaryResponse['summary'] = {
        id: summaryId,
        sessionID: summaryData.sessionID,
        userID: summaryData.userID,
        generatedAt: summaryData.generatedAt.toDate(),
        overview: summaryData.overview,
        actionItems: summaryData.actionItems || [],
        keyDecisions: summaryData.keyDecisions || [],
        messageCount: summaryData.messageCount || 0,
        confidence: summaryData.confidence || 0.0,
        exportData: summaryData.exportData
      };

      logger.info('Summary retrieved successfully', { 
        sessionID, 
        userID, 
        summaryId,
        messageCount: summary.messageCount,
        confidence: summary.confidence
      });

      response.status(200).json({
        success: true,
        summary
      });

    } catch (error) {
      logger.error('Error getting summary', { 
        error: error instanceof Error ? error.message : String(error),
        sessionID: request.query.sessionID,
        userID: request.query.userID
      });

      response.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }
);
