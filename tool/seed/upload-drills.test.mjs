import assert from 'node:assert/strict';
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';

import { validateCatalog } from './upload-drills.mjs';

async function makeFixture(t) {
  const mediaRoot = await mkdtemp(path.join(os.tmpdir(), 'hth-drill-seed-'));
  t.after(() => rm(mediaRoot, { recursive: true, force: true }));
  await mkdir(path.join(mediaRoot, 'drills'));
  await writeFile(path.join(mediaRoot, 'drills', 'quick-release.mp4'), 'video fixture');
  await writeFile(path.join(mediaRoot, 'drills', 'quick-release.jpg'), 'poster fixture');

  return {
    mediaRoot,
    catalog: {
      schemaVersion: 1,
      drills: [
        {
          id: 'quick-release',
          title: 'Quick Release',
          mediaAssetPath: 'drills/quick-release.mp4',
          formCues: ['Keep the puck close'],
          trackingType: 'accuracy',
          allowedLocations: ['drivewayGarage'],
          minPuckInventory: 'medium',
          requiresPasser: true,
          skillWeights: { shotPower: 0.75, endurance: 0.25 },
          tier: 'free',
          supportedBalls: ['greenBiscuit'],
          passerTypes: ['partner'],
          defaultPrescription: {
            sets: 3,
            reps: 10,
            restSeconds: 45,
            targetLabel: 'Top-right pipe',
          },
          estimatedSecondsPerSet: 90,
          difficulty: 2,
          tags: ['quick-release'],
        },
      ],
    },
  };
}

test('validates the model shape and matching media file', async (t) => {
  const { catalog, mediaRoot } = await makeFixture(t);

  assert.deepEqual(await validateCatalog(catalog, mediaRoot), catalog.drills);
});

test('rejects skill weights that do not sum to one', async (t) => {
  const { catalog, mediaRoot } = await makeFixture(t);
  catalog.drills[0].skillWeights = { shotPower: 0.7, endurance: 0.2 };

  await assert.rejects(
    validateCatalog(catalog, mediaRoot),
    /skillWeights must sum to 1\.0/,
  );
});

test('rejects media paths that escape the media directory', async (t) => {
  const { catalog, mediaRoot } = await makeFixture(t);
  catalog.drills[0].mediaAssetPath = 'drills/../../outside.mp4';

  await assert.rejects(
    validateCatalog(catalog, mediaRoot),
    /must stay inside the media directory/,
  );
});

test('rejects duplicate drill ids before any writes', async (t) => {
  const { catalog, mediaRoot } = await makeFixture(t);
  catalog.drills.push({ ...catalog.drills[0] });

  await assert.rejects(validateCatalog(catalog, mediaRoot), /Duplicate drill id/);
});

test('rejects duplicate drill tags', async (t) => {
  const { catalog, mediaRoot } = await makeFixture(t);
  catalog.drills[0].tags.push('quick-release');

  await assert.rejects(validateCatalog(catalog, mediaRoot), /tags must not contain duplicates/);
});

test('rejects legacy skill pillar names', async (t) => {
  const { catalog, mediaRoot } = await makeFixture(t);
  catalog.drills[0].skillWeights = { shooting: 1 };

  await assert.rejects(validateCatalog(catalog, mediaRoot), /skillWeights key must be one of/);
});

test('rejects videos over the size limit and missing posters', async (t) => {
  const { catalog, mediaRoot } = await makeFixture(t);
  await writeFile(path.join(mediaRoot, 'drills', 'quick-release.mp4'), Buffer.alloc(1_500_001));
  await assert.rejects(validateCatalog(catalog, mediaRoot), /at most 1500000 bytes/);

  await writeFile(path.join(mediaRoot, 'drills', 'quick-release.mp4'), 'video fixture');
  await rm(path.join(mediaRoot, 'drills', 'quick-release.jpg'));
  await assert.rejects(validateCatalog(catalog, mediaRoot), /poster file does not exist/);
});

test('can validate metadata before media exists', async (t) => {
  const { catalog, mediaRoot } = await makeFixture(t);
  await rm(path.join(mediaRoot, 'drills'), { recursive: true });

  assert.deepEqual(await validateCatalog(catalog, mediaRoot, { checkMedia: false }), catalog.drills);
});

test('committed starter catalog is valid, free, and covers every pillar and tracking type', async () => {
  const { readFile } = await import('node:fs/promises');
  const catalog = JSON.parse(await readFile(new URL('./drills.json', import.meta.url), 'utf8'));
  const drills = await validateCatalog(catalog, '/unused', { checkMedia: false });

  assert.equal(drills.length, 20);
  assert.ok(drills.every((drill) => drill.tier === 'free'));
  const pillars = new Set(drills.flatMap((drill) => Object.keys(drill.skillWeights)));
  assert.deepEqual([...pillars].sort(), ['endurance', 'hands', 'passing', 'shotAccuracy', 'shotPower', 'speedStrength']);
  const tracking = new Set(drills.map((drill) => drill.trackingType));
  assert.deepEqual([...tracking].sort(), ['accuracy', 'binary', 'density', 'duration', 'streak', 'volume']);
});
