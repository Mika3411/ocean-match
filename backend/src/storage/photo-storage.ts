import crypto from 'node:crypto';

import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

import { env } from '../config/env.js';

export type UploadUrlRequest = {
  userId: string;
  contentType: 'image/jpeg' | 'image/png' | 'image/webp';
};

export type UploadUrlResult = {
  storageBucket: string;
  storageKey: string;
  uploadUrl: string;
  expiresAt: string;
  headers: Record<string, string>;
};

export interface PhotoStorage {
  createUploadUrl(request: UploadUrlRequest): Promise<UploadUrlResult>;
  publicUrlFor(storageKey: string): string;
}

function extensionFor(contentType: UploadUrlRequest['contentType']) {
  if (contentType === 'image/png') return 'png';
  if (contentType === 'image/webp') return 'webp';
  return 'jpg';
}

function createStorageKey(request: UploadUrlRequest) {
  const date = new Date().toISOString().slice(0, 10);
  const random = crypto.randomUUID();
  return `users/${request.userId}/${date}/${random}.${extensionFor(request.contentType)}`;
}

class MockPhotoStorage implements PhotoStorage {
  async createUploadUrl(request: UploadUrlRequest): Promise<UploadUrlResult> {
    const storageKey = createStorageKey(request);
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000).toISOString();
    return {
      storageBucket: env.PHOTO_BUCKET,
      storageKey,
      uploadUrl: `${env.API_PUBLIC_BASE_URL}/mock-photo-upload/${encodeURIComponent(storageKey)}`,
      expiresAt,
      headers: { 'content-type': request.contentType },
    };
  }

  publicUrlFor(storageKey: string): string {
    return `${env.PHOTO_PUBLIC_BASE_URL.replace(/\/$/, '')}/${storageKey}`;
  }
}

class S3PhotoStorage implements PhotoStorage {
  private readonly client = new S3Client({
    region: env.S3_REGION,
    endpoint: env.S3_ENDPOINT || undefined,
    forcePathStyle: Boolean(env.S3_ENDPOINT),
    credentials:
      env.S3_ACCESS_KEY_ID && env.S3_SECRET_ACCESS_KEY
        ? {
            accessKeyId: env.S3_ACCESS_KEY_ID,
            secretAccessKey: env.S3_SECRET_ACCESS_KEY,
          }
        : undefined,
  });

  async createUploadUrl(request: UploadUrlRequest): Promise<UploadUrlResult> {
    const storageKey = createStorageKey(request);
    const command = new PutObjectCommand({
      Bucket: env.PHOTO_BUCKET,
      Key: storageKey,
      ContentType: request.contentType,
    });
    const uploadUrl = await getSignedUrl(this.client, command, { expiresIn: 15 * 60 });
    return {
      storageBucket: env.PHOTO_BUCKET,
      storageKey,
      uploadUrl,
      expiresAt: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
      headers: { 'content-type': request.contentType },
    };
  }

  publicUrlFor(storageKey: string): string {
    return `${env.PHOTO_PUBLIC_BASE_URL.replace(/\/$/, '')}/${storageKey}`;
  }
}

export const photoStorage: PhotoStorage =
  env.PHOTO_STORAGE_DRIVER === 's3' ? new S3PhotoStorage() : new MockPhotoStorage();
