/**
 * Environment configuration (BRIDGE FILE)
 * 
 * This file bridges the old validateEnvVars() pattern with new defineSecret() approach.
 * Eventually, all utilities should accept API keys as parameters instead of using this.
 * 
 * TODO: Migrate remaining utilities to accept apiKey parameters (see migration guide)
 */

import { logger } from '../utils/logger';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Re-export firestore for utilities that need it
export const firestore = admin.firestore();

interface EnvConfig {
  openaiApiKey: string;
  pineconeApiKey: string;
  pineconeEnvironment: string;
  pineconeIndex: string;
  googleCalendarClientId?: string;
  googleCalendarClientSecret?: string;
}

/**
 * Validate and retrieve environment variables
 * Reads from process.env (which loads from .env file in local development)
 * 
 * NOTE: This is for OLD utilities only. New code should use secrets.ts!
 */
export function validateEnvVars(): EnvConfig {
  // Read from environment variables (.env file)
  const openaiApiKey = process.env.OPENAI_API_KEY || '';
  const pineconeApiKey = process.env.PINECONE_API_KEY || '';
  const pineconeEnvironment = process.env.PINECONE_ENVIRONMENT || 'us-east-1-aws';
  const pineconeIndex = process.env.PINECONE_INDEX || 'messageai-embeddings';
  const googleCalendarClientId = process.env.GOOGLE_CALENDAR_CLIENT_ID || '';
  const googleCalendarClientSecret = process.env.GOOGLE_CALENDAR_CLIENT_SECRET || '';

  // Validate required variables
  const missing: string[] = [];
  if (!openaiApiKey) missing.push('OPENAI_API_KEY');
  if (!pineconeApiKey) missing.push('PINECONE_API_KEY');

  if (missing.length > 0) {
    const errorMsg = `Missing required environment variables: ${missing.join(', ')}`;
    logger.error(errorMsg);
    throw new Error(errorMsg);
  }

  logger.info('Environment variables validated successfully');

  return {
    openaiApiKey,
    pineconeApiKey,
    pineconeEnvironment,
    pineconeIndex,
    googleCalendarClientId,
    googleCalendarClientSecret,
  };
}

