import { z } from 'zod';

const exactPositionPattern =
  /([-+]?\d{1,2}([.,]\d+)?\s*[,;/]\s*[-+]?\d{1,3}([.,]\d+)?)|\b(gps|latitude|longitude|lat\.?|lon\.?|coordinates|coordonnees|marina|quai|ponton|anneau|mouillage)\b|\bport\s+(de|du|des|d')\b/i;

export function rejectExactPosition(value: string) {
  return !exactPositionPattern.test(value);
}

const publicText = (min: number, max: number) =>
  z
    .string()
    .trim()
    .min(min)
    .max(max)
    .refine(rejectExactPosition, {
      message: 'Gardez uniquement des zones larges, sans GPS, marina, quai ou ponton.',
    });

const uuid = z.string().uuid();

export const paramsIdSchema = z.object({ id: uuid });
export const conversationParamsSchema = z.object({ id: uuid });

export const signupSchema = z.object({
  email: z.string().trim().email().max(320).transform((email) => email.toLowerCase()),
  password: z.string().min(8).max(160),
});

export const loginSchema = signupSchema;

export const refreshSchema = z.object({
  refreshToken: z.string().min(40),
});

export const logoutSchema = z.object({
  refreshToken: z.string().min(40).optional(),
});

export const verifyEmailSchema = z.object({
  token: z.string().min(40),
});

export const passwordResetRequestSchema = z.object({
  email: z.string().trim().email().max(320).transform((email) => email.toLowerCase()),
});

export const passwordResetConfirmSchema = z.object({
  token: z.string().min(40),
  password: z.string().min(8).max(160),
});

export const genderSchema = z.enum(['woman', 'man', 'non_binary', 'other']);
export const searchGenderSchema = z.enum(['women', 'men', 'everyone']);
export const boardStatusSchema = z.enum([
  'liveaboard',
  'long_distance_sailor',
  'owner',
  'crew',
  'future_liveaboard',
]);
export const sailingExperienceSchema = z.enum(['beginner', 'intermediate', 'confirmed', 'expert']);
export const routeFlexibilitySchema = z.enum(['fixed', 'flexible', 'very_flexible']);
export const intentionSchema = z.enum([
  'serious_relationship',
  'casual_dating',
  'friendship',
  'crew',
  'sailing_project',
  'liveaboard_project',
]);
export const reportReasonSchema = z.enum([
  'fake_profile',
  'harassment',
  'inappropriate_content',
  'suspicious_behavior',
  'other',
]);

export const profileSchema = z.object({
  firstName: z.string().trim().min(1).max(80),
  birthDate: z.string().date(),
  gender: genderSchema,
  searchGender: searchGenderSchema.default('everyone'),
  languages: z.array(z.string().trim().min(1).max(40)).min(1).max(8),
  bio: publicText(1, 1000),
});

export const lifeAboardSchema = z.object({
  status: boardStatusSchema,
  boatOrProject: publicText(1, 160),
  sailingType: z.string().trim().min(1).max(120),
  experience: sailingExperienceSchema,
  lifestyleTags: z.array(z.string().trim().min(1).max(40)).max(12).default([]),
});

export const currentZoneSchema = z.object({
  zone: publicText(2, 120),
  country: z.string().trim().min(2).max(80).optional(),
});

export const futureRouteSchema = z.object({
  destinationZone: publicText(2, 120),
  destinationCountry: z.string().trim().min(2).max(80).optional(),
  startPeriod: z.string().trim().min(1).max(80),
  endPeriod: z.string().trim().min(1).max(80),
  flexibility: routeFlexibilitySchema,
  comment: z
    .string()
    .trim()
    .max(500)
    .refine(rejectExactPosition, {
      message: 'Gardez uniquement des zones larges, sans position exacte.',
    })
    .default(''),
});

export const preferencesSchema = z
  .object({
    ageMin: z.number().int().min(18).max(99),
    ageMax: z.number().int().min(18).max(99),
    genderTargets: searchGenderSchema.default('everyone'),
    zones: z.array(publicText(2, 120)).min(1).max(20),
    intentions: z.array(intentionSchema).min(1).max(6),
  })
  .refine((value) => value.ageMin <= value.ageMax, {
    message: 'ageMin doit etre inferieur ou egal a ageMax.',
    path: ['ageMin'],
  });

export const photoUploadUrlSchema = z.object({
  contentType: z.enum(['image/jpeg', 'image/png', 'image/webp']),
  fileSizeBytes: z.number().int().min(1).max(10 * 1024 * 1024),
});

export const photoCreateSchema = z.object({
  storageBucket: z.string().min(1).max(120).optional(),
  storageKey: z.string().min(8).max(500),
  publicUrl: z.string().url().optional(),
  contentType: z.enum(['image/jpeg', 'image/png', 'image/webp']),
  sizeBytes: z.number().int().min(1).max(10 * 1024 * 1024).optional(),
  isPrimary: z.boolean().default(false),
  order: z.number().int().min(0).default(0),
});

export const photoPatchSchema = z.object({
  isPrimary: z.boolean().optional(),
  order: z.number().int().min(0).optional(),
});

export const targetUserSchema = z.object({
  targetUserId: uuid,
});

export const messageCreateSchema = z.object({
  content: z.string().trim().min(1).max(1000),
});

export const blockCreateSchema = z.object({
  blockedUserId: uuid,
});

export const reportCreateSchema = z.object({
  reportedUserId: uuid,
  reason: reportReasonSchema,
  conversationId: uuid.optional(),
  messageId: uuid.optional(),
  comment: z.string().trim().max(2000).optional(),
});
