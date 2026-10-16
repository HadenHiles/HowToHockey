import { defineConfig } from 'vitest/config';

// Runs only the tests that need the Firestore emulator; see `npm run test:emulator`.
export default defineConfig({ test: { include: ['test-emulator/**/*.emulator.ts'] } });
