/**
 * Structured logging utility for Cloud Functions
 */

export const logger = {
  info: (msg: string, data?: any) => {
    console.log(JSON.stringify({
      level: 'info',
      msg,
      timestamp: new Date().toISOString(),
      ...data
    }));
  },
  
  warn: (msg: string, data?: any) => {
    console.warn(JSON.stringify({
      level: 'warn',
      msg,
      timestamp: new Date().toISOString(),
      ...data
    }));
  },
  
  error: (msg: string, err?: any) => {
    console.error(JSON.stringify({
      level: 'error',
      msg,
      timestamp: new Date().toISOString(),
      err: err ? {
        message: err.message,
        stack: err.stack,
        ...err
      } : undefined
    }));
  }
};
