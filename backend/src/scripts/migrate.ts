import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { pool } from '../db/pool.js';

const currentFile = fileURLToPath(import.meta.url);
const backendRoot = path.resolve(path.dirname(currentFile), '..', '..');
const migrationsDir = path.join(backendRoot, 'migrations');

async function run() {
  const files = (await readdir(migrationsDir))
    .filter((file) => file.endsWith('.sql'))
    .sort((a, b) => a.localeCompare(b));

  for (const file of files) {
    const fullPath = path.join(migrationsDir, file);
    const sql = await readFile(fullPath, 'utf8');
    console.log(`Applying ${file}`);
    await pool.query(sql);
  }

  await pool.end();
  console.log('Migrations applied.');
}

run().catch(async (error) => {
  await pool.end();
  console.error(error);
  process.exit(1);
});
