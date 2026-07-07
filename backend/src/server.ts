import { env } from './config/env.js';
import { pool } from './db/pool.js';
import { createApp } from './app.js';

const app = createApp();
const server = app.listen(env.PORT, () => {
  console.log(`BlueWater Match API listening on ${env.API_PUBLIC_BASE_URL}`);
});

async function shutdown(signal: string) {
  console.log(`${signal} received, shutting down BlueWater Match API.`);
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
