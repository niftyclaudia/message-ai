/**
 * Check Calendar Handler
 * Fetches calendar availability for a user within a date range
 * 
 * NOTE: This requires iOS EventKit integration. For MVP, returns mock data.
 * In production, iOS app would need to sync calendar data to Firestore
 * or this function would call iOS-side calendar API.
 */

import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions/v1';
import { CheckCalendarParams, CalendarEvent } from '../schemas';
import { verifySelfRequest } from '../../utils/permissionChecker';
import { logger } from '../../utils/logger';
import { validateDateRange } from '../validation';

export async function checkCalendarHandler(
  params: CheckCalendarParams,
  userId: string,
  context: functions.https.CallableContext
): Promise<CalendarEvent[]> {
  const { userId: requestedUserId, startDate, endDate } = params;

  logger.info('checkCalendar handler started', {
    userId,
    requestedUserId,
    startDate,
    endDate,
  });

  // Verify user is requesting their own calendar
  if (!verifySelfRequest(userId, requestedUserId)) {
    throw new Error('permission_denied: Cannot access another user\'s calendar');
  }

  // Validate date range
  if (!validateDateRange(startDate, endDate)) {
    throw new Error('validation: Invalid date range');
  }

  try {
    const db = admin.firestore();
    const start = new Date(startDate);
    const end = new Date(endDate);

    // Try to fetch calendar events from Firestore
    // In production, iOS app would sync EventKit events to Firestore
    const eventsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('calendarEvents')
      .where('startTime', '>=', admin.firestore.Timestamp.fromDate(start))
      .where('startTime', '<=', admin.firestore.Timestamp.fromDate(end))
      .orderBy('startTime', 'asc')
      .get();

    if (eventsSnapshot.empty) {
      logger.info('No calendar events found', { userId, startDate, endDate });
      
      // Return empty array for now
      // In production, this might indicate calendar sync is not set up
      return [];
    }

    // Transform Firestore events to CalendarEvent format
    const events: CalendarEvent[] = eventsSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title || 'Untitled Event',
        startTime: data.startTime?.toDate() || new Date(),
        endTime: data.endTime?.toDate() || new Date(),
      };
    });

    logger.info('checkCalendar completed', {
      userId,
      eventsCount: events.length,
    });

    return events;
  } catch (error: any) {
    logger.error('checkCalendar failed', { error, userId });

    // If calendar collection doesn't exist, return empty array
    if (error.code === 'permission-denied' || error.code === 'not-found') {
      logger.info('Calendar collection not found or not accessible', { userId });
      return [];
    }

    throw error;
  }
}

