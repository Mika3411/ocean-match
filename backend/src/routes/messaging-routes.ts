import { Router } from 'express';

import { asyncHandler } from '../http/async-handler.js';
import { validateBody, validateParams } from '../http/validate.js';
import { currentUserId } from '../middleware/auth.js';
import { MessagingService } from '../services/messaging-service.js';
import { conversationParamsSchema, messageCreateSchema } from '../validation/schemas.js';

const messagingService = new MessagingService();

export function messagingRouter() {
  const router = Router();

  router.get(
    '/matches',
    asyncHandler(async (request, response) => {
      response.json({ matches: await messagingService.listMatches(currentUserId(request)) });
    }),
  );

  router.get(
    '/conversations',
    asyncHandler(async (request, response) => {
      response.json({
        conversations: await messagingService.listConversations(currentUserId(request)),
      });
    }),
  );

  router.get(
    '/conversations/:id/messages',
    asyncHandler(async (request, response) => {
      const params = validateParams(request, conversationParamsSchema);
      response.json({
        messages: await messagingService.listMessages(currentUserId(request), params.id),
      });
    }),
  );

  router.post(
    '/conversations/:id/messages',
    asyncHandler(async (request, response) => {
      const params = validateParams(request, conversationParamsSchema);
      const input = validateBody(request, messageCreateSchema);
      response.status(201).json(
        await messagingService.sendMessage(currentUserId(request), params.id, input.content),
      );
    }),
  );

  return router;
}
