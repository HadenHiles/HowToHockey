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
          skillWeights: { shooting: 0.75, iqConditioning: 0.25 },
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
  catalog.drills[0].skillWeights = { shooting: 0.7, iqConditioning: 0.2 };

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
