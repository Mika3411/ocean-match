import { Router } from 'express';

import { asyncHandler } from '../http/async-handler.js';
import { currentUserId } from '../middleware/auth.js';
import { DiscoveryService } from '../services/discovery-service.js';

const discoveryService = new DiscoveryService();

export function discoveryRouter() {
  const router = Router();

  router.get(
    '/discovery',
    asyncHandler(async (request, response) => {
      response.json({ profiles: await discoveryService.list(currentUserId(request)) });
    }),
  );

  return router;
}
