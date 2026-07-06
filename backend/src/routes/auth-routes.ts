import { Router } from 'express';

import { asyncHandler } from '../http/async-handler.js';
import { validateBody } from '../http/validate.js';
import { currentUserId, requireAuth } from '../middleware/auth.js';
import { authRateLimiter } from '../middleware/security.js';
import { AuthService, requestMetaFrom } from '../services/auth-service.js';
import {
  loginSchema,
  logoutSchema,
  passwordResetConfirmSchema,
  passwordResetRequestSchema,
  refreshSchema,
  signupSchema,
  verifyEmailSchema,
} from '../validation/schemas.js';

const authService = new AuthService();

export function authRouter() {
  const router = Router();

  router.post(
    '/signup',
    authRateLimiter,
    asyncHandler(async (request, response) => {
      const input = validateBody(request, signupSchema);
      const result = await authService.signup(
        input,
        requestMetaFrom(request.ip, request.header('user-agent')),
      );
      response.status(201).json(result);
    }),
  );

  router.post(
    '/login',
    authRateLimiter,
    asyncHandler(async (request, response) => {
      const input = validateBody(request, loginSchema);
      const result = await authService.login(
        input,
        requestMetaFrom(request.ip, request.header('user-agent')),
      );
      response.json(result);
    }),
  );

  router.post(
    '/refresh',
    authRateLimiter,
    asyncHandler(async (request, response) => {
      const input = validateBody(request, refreshSchema);
      const result = await authService.refresh(
        input.refreshToken,
        requestMetaFrom(request.ip, request.header('user-agent')),
      );
      response.json(result);
    }),
  );

  router.post(
    '/logout',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, logoutSchema);
      await authService.logout(input.refreshToken);
      response.status(204).send();
    }),
  );

  router.post(
    '/verify-email',
    authRateLimiter,
    asyncHandler(async (request, response) => {
      const input = validateBody(request, verifyEmailSchema);
      response.json(await authService.verifyEmail(input.token));
    }),
  );

  router.post(
    '/resend-verification',
    requireAuth,
    authRateLimiter,
    asyncHandler(async (request, response) => {
      response.status(202).json(await authService.resendVerification(currentUserId(request)));
    }),
  );

  router.post(
    '/password-reset',
    authRateLimiter,
    asyncHandler(async (request, response) => {
      const input = validateBody(request, passwordResetRequestSchema);
      response.status(202).json(await authService.requestPasswordReset(input.email));
    }),
  );

  router.post(
    '/password-reset/confirm',
    authRateLimiter,
    asyncHandler(async (request, response) => {
      const input = validateBody(request, passwordResetConfirmSchema);
      await authService.confirmPasswordReset(input.token, input.password);
      response.status(204).send();
    }),
  );

  return router;
}
