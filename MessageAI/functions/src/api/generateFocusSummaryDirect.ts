/**
 * HTTP callable Cloud Function to generate Focus Mode summaries directly
 * No session tracking required - just generates summary for ALL unread priority messages
 */

import { onCall } from 'firebase-functions/v2/https';
import { logger } from '../utils/logger';
import { db } from '../utils/firestore';
import { generateSessionSummary, Message } from '../services/threadSummarization';

/**
 * Generate a Focus Mode summary directly (no session required)
 * Fetches ALL unread priority messages and generates a summary
 */
export const generateFocusSummaryDirect = onCall(
  { secrets: ['OPENAI_API_KEY'] },
  async (request) => {
    try {
      // Get authenticated user ID (onCall handles auth automatically)
      const userID = request.auth?.uid;
      if (!userID) {
        throw new Error('Not authenticated');
      }

      logger.info('🔄 Generating Focus Mode summary (direct)', { userID });

      // Get ALL unread priority messages for the user
      const chatsSnapshot = await db
        .collection('chats')
        .where('members', 'array-contains', userID)
        .get();

      const messages: Message[] = [];

      // Fetch messages from each chat's subcollection
      for (const chatDoc of chatsSnapshot.docs) {
        const chatId = chatDoc.id;

        // Get urgent messages from this chat's subcollection
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
          if (!readBy.includes(userID)) {
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

      logger.info('✅ Fetched UNREAD PRIORITY messages', {
        userID,
        totalChats: chatsSnapshot.size,
        unreadPriorityMessages: messages.length
      });

      // If no unread priority messages, return empty summary
      if (messages.length === 0) {
        logger.info('No unread priority messages to summarize', { userID });

        // Create empty summary
        const summaryRef = db.collection('focusSummaries').doc();
        const summaryData = {
          id: summaryRef.id,
          userID: userID,
          generatedAt: new Date(),
          overview: 'No unread priority messages at this time.',
          actionItems: [],
          keyDecisions: [],
          messageCount: 0,
          urgentMessageCount: 0,
          confidence: 1.0,
          processingTimeMs: 0,
          method: 'empty',
          sessionDuration: 0
        };

        await summaryRef.set(summaryData);

        return { summaryId: summaryRef.id };
      }

      // Generate summary
      const summaryResult = await generateSessionSummary(messages, 0);

      // Count urgent messages
      const urgentMessageCount = messages.filter(msg => msg.priority === 'urgent').length;

      // Save summary to Firestore with ID in the data
      const summaryRef = db.collection('focusSummaries').doc();
      const summaryData = {
        id: summaryRef.id, // IMPORTANT: Include ID in data!
        userID: userID,
        generatedAt: new Date(),
        overview: summaryResult.summary.overview,
        actionItems: summaryResult.summary.actionItems,
        keyDecisions: summaryResult.summary.keyDecisions,
        messageCount: summaryResult.summary.messageCount,
        urgentMessageCount: urgentMessageCount,
        confidence: summaryResult.summary.confidence,
        processingTimeMs: summaryResult.summary.processingTimeMs,
        method: summaryResult.method,
        sessionDuration: 0
      };

      await summaryRef.set(summaryData);

      logger.info('✅ Summary generated and saved', {
        userID,
        summaryId: summaryRef.id,
        messageCount: messages.length,
        urgentMessageCount,
        confidence: summaryResult.summary.confidence,
        method: summaryResult.method
      });

      return { summaryId: summaryRef.id };

    } catch (error) {
      logger.error('❌ Failed to generate summary', {
        error: error instanceof Error ? error.message : String(error)
      });

      throw new Error(error instanceof Error ? error.message : 'Failed to generate summary');
    }
  }
);

