import express from 'express';

import { pool } from './db/pool.js';
import { errorHandler } from './middleware/error-handler.js';
import { requireAuth } from './middleware/auth.js';
import { installSecurityMiddleware } from './middleware/security.js';
import { authRouter } from './routes/auth-routes.js';
import { discoveryRouter } from './routes/discovery-routes.js';
import { messagingRouter } from './routes/messaging-routes.js';
import { portsRouter } from './routes/ports-routes.js';
import { profileRouter } from './routes/profile-routes.js';
import { socialRouter } from './routes/social-routes.js';

export function createApp() {
  const app = express();

  installSecurityMiddleware(app);

  app.put(
    '/mock-photo-upload/:key',
    express.raw({ type: ['image/jpeg', 'image/png', 'image/webp'], limit: '10mb' }),
    (_request, response) => {
      response.status(204).send();
    },
  );

  app.use(express.json({ limit: '512kb' }));

  app.get('/health', async (_request, response) => {
    await pool.query('SELECT 1');
    response.json({ ok: true });
  });

  app.use('/v1/auth', authRouter());
  app.use('/v1', requireAuth, profileRouter());
  app.use('/v1', requireAuth, portsRouter());
  app.use('/v1', requireAuth, discoveryRouter());
  app.use('/v1', requireAuth, socialRouter());
  app.use('/v1', requireAuth, messagingRouter());

  app.use(errorHandler);

  return app;
}
