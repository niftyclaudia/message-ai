/**
 * Detect Scheduling Need Handler
 * Identifies meeting requests and scheduling needs in a thread
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { DetectSchedulingNeedParams, SchedulingNeed } from '../schemas';
import { checkUserAccess } from '../../utils/permissionChecker';
import { logger } from '../../utils/logger';
import { initializeOpenAI } from '../../utils/openai';

export async function detectSchedulingNeedHandler(
  params: DetectSchedulingNeedParams,
  userId: string,
  context: functions.https.CallableContext
): Promise<SchedulingNeed> {
  const { threadId } = params;

  logger.info('detectSchedulingNeed handler started', {
    userId,
    threadId,
  });

  // Verify user has access to this thread
  const hasAccess = await checkUserAccess(userId, threadId, 'thread');
  if (!hasAccess) {
    throw new Error('permission_denied: You do not have access to this thread');
  }

  try {
    // Fetch messages from the thread
    const db = admin.firestore();
    const messagesSnapshot = await db
      .collection('messages')
      .where('chatID', '==', threadId)
      .orderBy('timestamp', 'desc')
      .limit(50) // Last 50 messages
      .get();

    if (messagesSnapshot.empty) {
      return {
        detected: false,
        participants: [],
        suggestedDuration: 30,
        urgency: 'low',
      };
    }

    // Extract message texts and participants
    const messages = messagesSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        text: data.text || '',
        senderId: data.senderID || '',
      };
    });

    const conversationText = messages.map((m) => m.text).join('\n');
    const participants = Array.from(new Set(messages.map((m) => m.senderId)));

    // Use OpenAI to detect scheduling needs
    const openai = initializeOpenAI();

    const systemPrompt = `You are an AI assistant that detects scheduling needs in conversations.

Analyze the conversation and determine:
1. detected: true if there's a meeting/call request (phrases like "let's meet", "schedule a call", "when are you free", etc.)
2. suggestedDuration: estimated meeting duration in minutes (15, 30, 60, etc.)
3. urgency: "high" (ASAP, urgent), "medium" (this week), or "low" (flexible timing)

Look for:
- Explicit meeting requests ("Let's have a meeting", "Can we chat?")
- Scheduling phrases ("When are you free?", "What time works?")
- Call requests ("Let's hop on a call", "Quick sync?")

Format as JSON.`;

    const response = await openai.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: `Detect scheduling needs in this conversation:\n\n${conversationText.substring(0, 2000)}` },
      ],
      temperature: 0.3,
      max_tokens: 150,
    });

    const resultText = response.choices[0]?.message?.content;
    if (!resultText) {
      throw new Error('OpenAI returned empty response');
    }

    // Parse JSON response
    const parsed = JSON.parse(resultText);

    const result: SchedulingNeed = {
      detected: parsed.detected === true,
      participants,
      suggestedDuration: Math.max(15, Math.min(parsed.suggestedDuration || 30, 180)),
      urgency: ['high', 'medium', 'low'].includes(parsed.urgency)
        ? parsed.urgency
        : 'medium',
    };

    logger.info('detectSchedulingNeed completed', {
      userId,
      threadId,
      detected: result.detected,
      urgency: result.urgency,
    });

    return result;
  } catch (error: any) {
    logger.error('detectSchedulingNeed failed', { error, userId, threadId });

    // Check if OpenAI is down
    if (error.message?.includes('openai') || error.response?.status >= 500) {
      throw new Error('service_unavailable: Scheduling detection service temporarily unavailable');
    }

    throw error;
  }
}

