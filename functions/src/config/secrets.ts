/**
 * Centralized Secret Definitions
 * 
 * All secrets are defined here using defineSecret() from firebase-functions/params.
 * This uses Google Secret Manager for secure, encrypted storage.
 * 
 * Local Development: Reads from .env file
 * Production: Reads from Google Secret Manager
 */

import { defineSecret } from 'firebase-functions/params';

// OpenAI API Key
export const openaiApiKey = defineSecret('OPENAI_API_KEY');

// Pinecone Configuration
export const pineconeApiKey = defineSecret('PINECONE_API_KEY');

// Google Calendar OAuth Credentials
export const googleCalendarClientId = defineSecret('GOOGLE_CALENDAR_CLIENT_ID');
export const googleCalendarClientSecret = defineSecret('GOOGLE_CALENDAR_CLIENT_SECRET');

/**
 * Helper function to get all secrets as an array
 * Useful for functions that need multiple secrets
 */
export const allSecrets = [
  openaiApiKey,
  pineconeApiKey,
  googleCalendarClientId,
  googleCalendarClientSecret,
];

/**
 * Get AI-related secrets only
 */
export const aiSecrets = [
  openaiApiKey,
  pineconeApiKey,
];

/**
 * Get Google Calendar secrets only
 */
export const calendarSecrets = [
  googleCalendarClientId,
  googleCalendarClientSecret,
];

