/**
 * Cloud Function trigger to generate summaries when Focus Mode sessions end
 */

import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { logger } from '../utils/logger';
import { getFirestore } from 'firebase-admin/firestore';
import { generateSessionSummary, Message } from '../services/threadSummarization';

const db = getFirestore();

export interface FocusSession {
  id: string;
  userID: string;
  startTime: Date;
  endTime?: Date;
  messageCount: number;
  urgentMessageCount: number;
  status: 'active' | 'completed' | 'summarized';
}

/**
 * Trigger that fires when a FocusSession document is updated
 * Generates a summary when session status changes to 'completed'
 */
export const generateSummary = onDocumentUpdated(
  {
    document: 'focusSessions/{sessionId}',
    secrets: ['OPENAI_API_KEY']
  },
  async (event) => {
    try {
      const sessionId = event.params.sessionId;
      const beforeData = event.data?.before.data() as FocusSession;
      const afterData = event.data?.after.data() as FocusSession;

      // Only process if status changed from 'active' to 'completed'
      if (beforeData?.status !== 'active' || afterData?.status !== 'completed') {
        logger.info('Session status not changed to completed, skipping summary generation', {
          sessionId,
          beforeStatus: beforeData?.status,
          afterStatus: afterData?.status
        });
        return;
      }

      logger.info('Focus session completed, generating summary', {
        sessionId,
        userID: afterData.userID,
        messageCount: afterData.messageCount,
        urgentMessageCount: afterData.urgentMessageCount
      });

      // Check if summary already exists
      const existingSummary = await db
        .collection('focusSummaries')
        .where('sessionID', '==', sessionId)
        .limit(1)
        .get();

      if (!existingSummary.empty) {
        logger.info('Summary already exists for session', { sessionId });
        return;
      }

      // Get ALL unread priority messages for the user (not just session-based)
      // Fetch user's chats
      const chatsSnapshot = await db
        .collection('chats')
        .where('members', 'array-contains', afterData.userID)
        .get();

      const messages: Message[] = [];
      
      // Fetch messages from each chat's subcollection
      for (const chatDoc of chatsSnapshot.docs) {
        const chatId = chatDoc.id;
        
        // Get all messages from this chat's subcollection
        const messagesSnapshot = await db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('priority', '==', 'urgent')
          .orderBy('timestamp', 'asc')
          .get();

        // Filter out messages already read by user
        messagesSnapshot.docs.forEach(doc => {
          const data = doc.data();
          const readBy = data.readBy || [];
          
          // Only include unread priority messages
          if (!readBy.includes(afterData.userID)) {
            messages.push({
              id: doc.id,
              text: data.text,
              senderID: data.senderID,
              timestamp: data.timestamp.toDate(),
              priority: data.priority
            });
          }
        });
      }

      logger.info('✅ Fetched UNREAD PRIORITY messages for summary', {
        sessionId,
        userID: afterData.userID,
        totalChats: chatsSnapshot.size,
        unreadPriorityMessages: messages.length
      });
      
      // If no unread priority messages, skip summary generation
      if (messages.length === 0) {
        logger.info('No unread priority messages to summarize', {
          sessionId,
          userID: afterData.userID
        });
        
        // Update session to indicate no messages to summarize
        await db.collection('focusSessions').doc(sessionId).update({
          status: 'completed',
          summaryError: 'No unread priority messages to summarize'
        });
        
        return;
      }

      // Calculate session duration
      const sessionDuration = afterData.endTime && afterData.startTime
        ? Math.round((afterData.endTime.getTime() - afterData.startTime.getTime()) / (1000 * 60))
        : 0;

      // Generate summary
      const summaryResult = await generateSessionSummary(messages, sessionDuration);

      // Count urgent messages
      const urgentMessageCount = messages.filter(msg => msg.priority === 'urgent').length;

      // Save summary to Firestore
      const summaryData = {
        sessionID: sessionId,
        userID: afterData.userID,
        generatedAt: new Date(),
        overview: summaryResult.summary.overview,
        actionItems: summaryResult.summary.actionItems,
        keyDecisions: summaryResult.summary.keyDecisions,
        messageCount: summaryResult.summary.messageCount,
        urgentMessageCount: urgentMessageCount,
        confidence: summaryResult.summary.confidence,
        processingTimeMs: summaryResult.summary.processingTimeMs,
        method: summaryResult.method,
        sessionDuration: sessionDuration
      };

      const summaryRef = await db.collection('focusSummaries').add(summaryData);

      // Update session status to 'summarized'
      await db.collection('focusSessions').doc(sessionId).update({
        status: 'summarized',
        summaryID: summaryRef.id,
        summaryGeneratedAt: new Date()
      });

      logger.info('Summary generated and saved successfully', {
        sessionId,
        summaryId: summaryRef.id,
        userID: afterData.userID,
        messageCount: messages.length,
        sessionDuration,
        confidence: summaryResult.summary.confidence,
        processingTimeMs: summaryResult.summary.processingTimeMs,
        method: summaryResult.method
      });

    } catch (error) {
      logger.error('Error generating summary', {
        error: error instanceof Error ? error.message : String(error),
        sessionId: event.params.sessionId
      });

      // Update session status to indicate summary generation failed
      try {
        await db.collection('focusSessions').doc(event.params.sessionId).update({
          status: 'completed',
          summaryError: error instanceof Error ? error.message : String(error),
          summaryFailedAt: new Date()
        });
      } catch (updateError) {
        logger.error('Failed to update session with error status', {
          error: updateError instanceof Error ? updateError.message : String(updateError),
          sessionId: event.params.sessionId
        });
      }
    }
  }
);
