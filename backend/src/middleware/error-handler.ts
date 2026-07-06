import type { ErrorRequestHandler } from 'express';
import { ZodError } from 'zod';

import { env } from '../config/env.js';
import { AppError, ConflictError, ValidationError } from '../errors.js';

type PgError = Error & { code?: string; constraint?: string; detail?: string };

function normalizeError(error: unknown): AppError {
  if (error instanceof AppError) {
    return error;
  }

  if (error instanceof ZodError) {
    return new ValidationError('Validation serveur echouee.', error.flatten());
  }

  const pgError = error as PgError;
  if (pgError.code === '23505') {
    return new ConflictError('Ressource deja existante.', {
      constraint: pgError.constraint,
    });
  }

  if (pgError.code === '23503' || pgError.code === '23514') {
    return new ValidationError('Donnees refusees par les regles de securite.', {
      constraint: pgError.constraint,
      detail: pgError.detail,
    });
  }

  return new AppError(500, 'internal_error', 'Erreur interne.');
}

export const errorHandler: ErrorRequestHandler = (error, _request, response, _next) => {
  const normalized = normalizeError(error);
  response.status(normalized.statusCode).json({
    error: {
      code: normalized.code,
      message: normalized.message,
      details: normalized.details,
      ...(env.isProduction ? {} : { stack: error instanceof Error ? error.stack : undefined }),
    },
  });
};
