/**
 * Suggest Meeting Times Handler
 * Suggests optimal meeting times based on participant availability
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { SuggestMeetingTimesParams, MeetingTimeSuggestion, CalendarEvent } from '../schemas';
import { validateUserList } from '../../utils/permissionChecker';
import { logger } from '../../utils/logger';
import { checkCalendarHandler } from './checkCalendar';

export async function suggestMeetingTimesHandler(
  params: SuggestMeetingTimesParams,
  userId: string,
  context: functions.https.CallableContext
): Promise<MeetingTimeSuggestion[]> {
  const { participants, duration } = params;
  // TODO: preferredTimeRanges not implemented yet - would filter slots by time ranges

  logger.info('suggestMeetingTimes handler started', {
    userId,
    participantsCount: participants.length,
    duration,
  });

  // Validate participants
  const isValidUserList = await validateUserList(participants);
  if (!isValidUserList) {
    throw new Error('validation: Invalid participant list');
  }

  // Validate requesting user is in participants
  if (!participants.includes(userId)) {
    logger.warn('User not in participants list', { userId, participants });
  }

  try {
    const db = admin.firestore();
    
    // Default date range: next 7 days
    const now = new Date();
    const startDate = new Date(now);
    startDate.setHours(9, 0, 0, 0); // Start from 9 AM today
    const endDate = new Date(now);
    endDate.setDate(endDate.getDate() + 7); // 7 days ahead
    endDate.setHours(17, 0, 0, 0); // Until 5 PM

    // Fetch calendar events for all participants
    const participantCalendars = await Promise.all(
      participants.map(async (participantId) => {
        try {
          const events = await checkCalendarHandler(
            {
              userId: participantId,
              startDate: startDate.toISOString(),
              endDate: endDate.toISOString(),
            },
            participantId,
            context
          );
          return { participantId, events };
        } catch {
          // If can't fetch calendar, assume available
          return { participantId, events: [] };
        }
      })
    );

    // Find available time slots
    const suggestions: MeetingTimeSuggestion[] = [];
    const durationMs = duration * 60 * 1000; // Convert to milliseconds

    // Generate potential time slots (9 AM - 5 PM, every 30 minutes)
    const potentialSlots: Date[] = [];
    let currentTime = new Date(startDate);
    
    while (currentTime < endDate) {
      // Skip weekends
      if (currentTime.getDay() !== 0 && currentTime.getDay() !== 6) {
        // Only during work hours (9 AM - 5 PM)
        const hour = currentTime.getHours();
        if (hour >= 9 && hour < 17) {
          potentialSlots.push(new Date(currentTime));
        }
      }
      
      // Move to next 30-minute slot
      currentTime = new Date(currentTime.getTime() + 30 * 60 * 1000);
    }

    // Check each potential slot
    for (const slotStart of potentialSlots) {
      const slotEnd = new Date(slotStart.getTime() + durationMs);
      
      // Check if all participants are available
      const availableParticipants: string[] = [];
      let allAvailable = true;

      for (const { participantId, events } of participantCalendars) {
        // Check if participant has conflicts
        const hasConflict = events.some((event: CalendarEvent) => {
          const eventStart = new Date(event.startTime);
          const eventEnd = new Date(event.endTime);
          
          // Check overlap
          return slotStart < eventEnd && slotEnd > eventStart;
        });

        if (!hasConflict) {
          availableParticipants.push(participantId);
        } else {
          allAvailable = false;
        }
      }

      // If all participants available, add as suggestion
      if (allAvailable && availableParticipants.length === participants.length) {
        // Calculate score based on time preferences
        let score = 1.0;
        
        // Prefer mid-morning (10-11 AM) and early afternoon (2-3 PM)
        const hour = slotStart.getHours();
        if (hour === 10 || hour === 14) {
          score = 1.0;
        } else if (hour === 9 || hour === 11 || hour === 13 || hour === 15) {
          score = 0.9;
        } else {
          score = 0.7;
        }

        suggestions.push({
          id: db.collection('meetingSuggestions').doc().id,
          startTime: slotStart,
          endTime: slotEnd,
          availableParticipants,
          score,
          reasoning: allAvailable
            ? 'All participants available'
            : `${availableParticipants.length}/${participants.length} participants available`,
        });
      }
    }

    // Sort by score descending and limit to top 10
    suggestions.sort((a, b) => b.score - a.score);
    const topSuggestions = suggestions.slice(0, 10);

    logger.info('suggestMeetingTimes completed', {
      userId,
      suggestionsCount: topSuggestions.length,
    });

    return topSuggestions;
  } catch (error: any) {
    logger.error('suggestMeetingTimes failed', { error, userId });
    throw error;
  }
}

