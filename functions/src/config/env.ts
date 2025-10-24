/**
 * Environment configuration and validation
 */

import * as functions from 'firebase-functions/v1';
import { logger } from '../utils/logger';

interface EnvConfig {
  openaiApiKey: string;
  pineconeApiKey: string;
  pineconeEnvironment: string;
  pineconeIndex: string;
}

/**
 * Validate and retrieve environment variables
 * For local development: reads from process.env
 * For deployed functions: reads from Firebase Functions config
 */
export function validateEnvVars(): EnvConfig {
  const config = functions.config();
  
  // Try Firebase Functions config first, fall back to process.env
  const openaiApiKey = config.openai?.api_key || process.env.OPENAI_API_KEY || '';
  const pineconeApiKey = config.pinecone?.api_key || process.env.PINECONE_API_KEY || '';
  const pineconeEnvironment = config.pinecone?.environment || process.env.PINECONE_ENVIRONMENT || '';
  const pineconeIndex = config.pinecone?.index || process.env.PINECONE_INDEX || '';

  // Validate required variables
  const missing: string[] = [];
  if (!openaiApiKey) missing.push('openai.api_key');
  if (!pineconeApiKey) missing.push('pinecone.api_key');
  if (!pineconeEnvironment) missing.push('pinecone.environment');
  if (!pineconeIndex) missing.push('pinecone.index');

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
  };
}

