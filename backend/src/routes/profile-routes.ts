import { Router } from 'express';

import { asyncHandler } from '../http/async-handler.js';
import { validateBody, validateParams } from '../http/validate.js';
import { currentUserId } from '../middleware/auth.js';
import { AuthService } from '../services/auth-service.js';
import { ProfileService } from '../services/profile-service.js';
import {
  currentZoneSchema,
  futureRouteSchema,
  lifeAboardSchema,
  paramsIdSchema,
  photoCreateSchema,
  photoPatchSchema,
  photoUploadUrlSchema,
  preferencesSchema,
  profileSchema,
} from '../validation/schemas.js';

const authService = new AuthService();
const profileService = new ProfileService();

export function profileRouter() {
  const router = Router();

  router.get(
    '/me',
    asyncHandler(async (request, response) => {
      response.json(await profileService.getMe(currentUserId(request)));
    }),
  );

  router.delete(
    '/account',
    asyncHandler(async (request, response) => {
      await authService.deleteAccount(currentUserId(request));
      response.status(204).send();
    }),
  );

  router.put(
    '/profile',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, profileSchema);
      response.json(await profileService.putProfile(currentUserId(request), input));
    }),
  );

  router.put(
    '/life-aboard',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, lifeAboardSchema);
      response.json(await profileService.putLifeAboard(currentUserId(request), input));
    }),
  );

  router.put(
    '/current-zone',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, currentZoneSchema);
      response.json(await profileService.putCurrentZone(currentUserId(request), input));
    }),
  );

  router.put(
    '/future-route',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, futureRouteSchema);
      response.json(await profileService.putFutureRoute(currentUserId(request), input));
    }),
  );

  router.put(
    '/preferences',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, preferencesSchema);
      response.json(await profileService.putPreferences(currentUserId(request), input));
    }),
  );

  router.post(
    '/photos/upload-url',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, photoUploadUrlSchema);
      response.status(201).json(await profileService.createPhotoUploadUrl(currentUserId(request), input));
    }),
  );

  router.post(
    '/photos',
    asyncHandler(async (request, response) => {
      const input = validateBody(request, photoCreateSchema);
      response.status(201).json(await profileService.createPhoto(currentUserId(request), input));
    }),
  );

  router.patch(
    '/photos/:id',
    asyncHandler(async (request, response) => {
      const params = validateParams(request, paramsIdSchema);
      const input = validateBody(request, photoPatchSchema);
      response.json(await profileService.updatePhoto(currentUserId(request), params.id, input));
    }),
  );

  router.delete(
    '/photos/:id',
    asyncHandler(async (request, response) => {
      const params = validateParams(request, paramsIdSchema);
      await profileService.deletePhoto(currentUserId(request), params.id);
      response.status(204).send();
    }),
  );

  return router;
}
