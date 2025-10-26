/**
 * Authentication utilities for Cloud Functions
 */

import { Request } from 'firebase-functions/v2/https';
import { getAuth } from 'firebase-admin/auth';

/**
 * Verify authentication from request headers
 * @param req - HTTP request
 * @returns User ID if authenticated, null otherwise
 */
export async function verifyAuth(req: Request): Promise<string | null> {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return null;
    }

    const token = authHeader.split('Bearer ')[1];
    const decodedToken = await getAuth().verifyIdToken(token);
    return decodedToken.uid;
  } catch (error) {
    console.error('Auth verification failed:', error);
    return null;
  }
}
