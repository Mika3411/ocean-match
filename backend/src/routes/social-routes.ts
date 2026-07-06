import { Router } from 'express';

import { asyncHandler } from '../http/async-handler.js';
import { validateBody, validateParams } from '../http/validate.js';
import { currentUserId } from '../middleware/auth.js';
import { SocialService } from '../services/social-service.js';
import {
  blockCreateSchema,
  paramsIdSchema,
  reportCreateSchema,
  targetUserSchema,
} from '../validation/schemas.js';

const socialService = new SocialService();

export function socialRouter() {
  const router = Router();

  router.post(
    '/likes',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, targetUserSchema);
      response.status(201).json(await socialService.like(currentUserId(request), input.targetUserId));
    }),
  );

  router.post(
    '/passes',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, targetUserSchema);
      await socialService.pass(currentUserId(request), input.targetUserId);
      response.status(204).send();
    }),
  );

  router.get(
    '/blocks',
    asyncHandler(async (request, response) => {
      response.json({ blocks: await socialService.listBlocks(currentUserId(request)) });
    }),
  );

  router.post(
    '/blocks',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, blockCreateSchema);
      response.status(201).json(await socialService.block(currentUserId(request), input.blockedUserId));
    }),
  );

  router.delete(
    '/blocks/:id',
    asyncHandler(async (request, response) => {
      const params = validateParams(request, paramsIdSchema);
      await socialService.unblock(currentUserId(request), params.id);
      response.status(204).send();
    }),
  );

  router.post(
    '/reports',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, reportCreateSchema);
      response.status(201).json(await socialService.report(currentUserId(request), input));
    }),
  );

  return router;
}
