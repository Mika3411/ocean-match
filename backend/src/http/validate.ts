import type { Request } from 'express';
import type { z } from 'zod';

export function validateBody<TSchema extends z.ZodTypeAny>(
  request: Request,
  schema: TSchema,
): z.infer<TSchema> {
  return schema.parse(request.body);
}

export function validateParams<TSchema extends z.ZodTypeAny>(
  request: Request,
  schema: TSchema,
): z.infer<TSchema> {
  return schema.parse(request.params);
}

export function validateQuery<TSchema extends z.ZodTypeAny>(
  request: Request,
  schema: TSchema,
): z.infer<TSchema> {
  return schema.parse(request.query);
}
