import type { NextFunction, Request, Response } from 'express';

import { UnauthorizedError } from '../errors.js';
import { verifyAccessToken } from '../security/tokens.js';

export function requireAuth(request: Request, _response: Response, next: NextFunction) {
  const header = request.header('authorization');
  if (!header?.startsWith('Bearer ')) {
    throw new UnauthorizedError();
  }

  const token = header.slice('Bearer '.length).trim();
  request.auth = verifyAccessToken(token);
  next();
}

export function currentUserId(request: Request): string {
  if (!request.auth?.sub) {
    throw new UnauthorizedError();
  }
  return request.auth.sub;
}
