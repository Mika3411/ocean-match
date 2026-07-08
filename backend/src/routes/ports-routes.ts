import { Router } from 'express';

import { asyncHandler } from '../http/async-handler.js';
import { currentUserId } from '../middleware/auth.js';
import { PortService } from '../services/port-service.js';

const portService = new PortService();

export function portsRouter() {
  const router = Router();

  router.get(
    '/ports',
    asyncHandler(async (request, response) => {
      response.json({ ports: await portService.list(currentUserId(request)) });
    }),
  );

  return router;
}
