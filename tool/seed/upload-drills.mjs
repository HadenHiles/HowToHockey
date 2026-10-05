import { readFile, stat } from 'node:fs/promises';
import { createRequire } from 'node:module';
import { basename, dirname, extname, isAbsolute, relative, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const require = createRequire(new URL('../../functions/package.json', import.meta.url));
const { initializeApp } = require('firebase-admin/app');
const { FieldValue, getFirestore } = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

const defaultDataPath = fileURLToPath(new URL('./drills.json', import.meta.url));
const trackingTypes = ['volume', 'duration', 'density', 'accuracy', 'streak', 'binary'];
const locations = ['ice', 'roller', 'drivewayGarage', 'basement', 'syntheticIce'];
const puckInventories = ['low', 'medium', 'high'];
const pillars = ['shooting', 'stickhandling', 'skating', 'passing', 'iqConditioning'];
const accessTiers = ['free', 'pro'];
const ballTypes = ['golfBall', 'trainingBall', 'greenBiscuit'];
const passerTypes = ['rebounder', 'partner'];

function assertObject(value, label) {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new TypeError(`${label} must be an object.`);
  }
  return value;
}

function assertOnlyKeys(value, allowedKeys, label) {
  const unexpected = Object.keys(value).find((key) => !allowedKeys.includes(key));
  if (unexpected) {
    throw new TypeError(`${label} contains unsupported property "${unexpected}".`);
  }
}

function assertString(value, label, { minLength = 1 } = {}) {
  if (typeof value !== 'string' || value.trim().length < minLength) {
    throw new TypeError(`${label} must be a non-empty string.`);
  }
}

function assertInteger(value, label, { min, max = Number.MAX_SAFE_INTEGER } = {}) {
  if (!Number.isSafeInteger(value) || value < min || value > max) {
    throw new TypeError(`${label} must be an integer between ${min} and ${max}.`);
  }
}

function assertEnum(value, allowedValues, label) {
  if (!allowedValues.includes(value)) {
    throw new TypeError(`${label} must be one of: ${allowedValues.join(', ')}.`);
  }
}

function assertStringArray(
  value,
  label,
  { minItems = 0, maxItems = Infinity, uniqueItems = false } = {},
) {
  if (!Array.isArray(value) || value.length < minItems || value.length > maxItems) {
    throw new TypeError(`${label} must be an array with ${minItems} to ${maxItems} items.`);
  }
  if (uniqueItems && new Set(value).size !== value.length) {
    throw new TypeError(`${label} must not contain duplicates.`);
  }
  value.forEach((item, index) => assertString(item, `${label}[${index}]`));
}

function assertEnumArray(value, allowedValues, label, { minItems = 0 } = {}) {
  if (!Array.isArray(value) || value.length < minItems) {
    throw new TypeError(`${label} must be an array with at least ${minItems} items.`);
  }
  if (new Set(value).size !== value.length) {
    throw new TypeError(`${label} must not contain duplicates.`);
  }
  value.forEach((item, index) => assertEnum(item, allowedValues, `${label}[${index}]`));
}

function assertPrescription(value, label) {
  const prescription = assertObject(value, label);
  assertOnlyKeys(prescription, ['sets', 'reps', 'seconds', 'restSeconds', 'targetLabel'], label);
  assertInteger(prescription.sets, `${label}.sets`, { min: 1 });
  assertInteger(prescription.restSeconds, `${label}.restSeconds`, { min: 0 });
  if (prescription.reps !== undefined) {
    assertInteger(prescription.reps, `${label}.reps`, { min: 1 });
  }
  if (prescription.seconds !== undefined) {
    assertInteger(prescription.seconds, `${label}.seconds`, { min: 1 });
  }
  if (prescription.targetLabel !== undefined) {
    assertString(prescription.targetLabel, `${label}.targetLabel`);
  }
}

async function validateDrill(drill, index, mediaRoot) {
  const label = `drills[${index}]`;
  const fields = [
    'id',
    'title',
    'mediaAssetPath',
    'formCues',
    'trackingType',
    'allowedLocations',
    'minPuckInventory',
    'requiresPasser',
    'skillWeights',
    'tier',
    'supportedBalls',
    'passerTypes',
    'defaultPrescription',
    'estimatedSecondsPerSet',
    'difficulty',
    'tags',
    'swapGroup',
  ];
  const entry = assertObject(drill, label);
  assertOnlyKeys(entry, fields, label);

  assertString(entry.id, `${label}.id`);
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(entry.id)) {
    throw new TypeError(`${label}.id must be a lowercase kebab-case slug.`);
  }
  assertString(entry.title, `${label}.title`);
  assertString(entry.mediaAssetPath, `${label}.mediaAssetPath`);
  if (!entry.mediaAssetPath.startsWith('drills/') || extname(entry.mediaAssetPath) !== '.mp4') {
    throw new TypeError(`${label}.mediaAssetPath must be an MP4 path inside drills/.`);
  }

  const mediaPath = resolve(mediaRoot, entry.mediaAssetPath);
  const mediaRelativePath = relative(mediaRoot, mediaPath);
  if (
    isAbsolute(mediaRelativePath) ||
    mediaRelativePath === '..' ||
    mediaRelativePath.startsWith(`..${sep}`)
  ) {
    throw new TypeError(`${label}.mediaAssetPath must stay inside the media directory.`);
  }
  const mediaInfo = await stat(mediaPath).catch((error) => {
    if (error.code === 'ENOENT') {
      throw new Error(`${label}.mediaAssetPath file does not exist: ${mediaPath}`);
    }
    throw error;
  });
  if (!mediaInfo.isFile()) {
    throw new TypeError(`${label}.mediaAssetPath must refer to a file.`);
  }

  assertStringArray(entry.formCues, `${label}.formCues`, { minItems: 1, maxItems: 3 });
  assertEnum(entry.trackingType, trackingTypes, `${label}.trackingType`);
  assertEnumArray(entry.allowedLocations, locations, `${label}.allowedLocations`, { minItems: 1 });
  assertEnum(entry.minPuckInventory, puckInventories, `${label}.minPuckInventory`);
  if (typeof entry.requiresPasser !== 'boolean') {
    throw new TypeError(`${label}.requiresPasser must be a boolean.`);
  }

  const weights = assertObject(entry.skillWeights, `${label}.skillWeights`);
  const weightedPillars = Object.keys(weights);
  if (weightedPillars.length === 0) {
    throw new TypeError(`${label}.skillWeights must contain at least one pillar.`);
  }
  let totalWeight = 0;
  for (const [pillar, weight] of Object.entries(weights)) {
    assertEnum(pillar, pillars, `${label}.skillWeights key`);
    if (typeof weight !== 'number' || !Number.isFinite(weight) || weight < 0 || weight > 1) {
      throw new TypeError(`${label}.skillWeights.${pillar} must be a number from 0 to 1.`);
    }
    totalWeight += weight;
  }
  if (Math.abs(totalWeight - 1) > 1e-6) {
    throw new TypeError(`${label}.skillWeights must sum to 1.0 (received ${totalWeight}).`);
  }

  assertEnum(entry.tier, accessTiers, `${label}.tier`);
  assertEnumArray(entry.supportedBalls, ballTypes, `${label}.supportedBalls`);
  assertEnumArray(entry.passerTypes, passerTypes, `${label}.passerTypes`);
  if (entry.requiresPasser && entry.passerTypes.length === 0) {
    throw new TypeError(`${label}.passerTypes must not be empty when requiresPasser is true.`);
  }
  assertPrescription(entry.defaultPrescription, `${label}.defaultPrescription`);
  assertInteger(entry.estimatedSecondsPerSet, `${label}.estimatedSecondsPerSet`, { min: 1 });
  assertInteger(entry.difficulty, `${label}.difficulty`, { min: 1, max: 5 });
  assertStringArray(entry.tags, `${label}.tags`, { uniqueItems: true });
  if (entry.swapGroup !== undefined && entry.swapGroup !== null) {
    assertString(entry.swapGroup, `${label}.swapGroup`);
  }
}

export async function validateCatalog(catalog, mediaRoot) {
  const root = assertObject(catalog, 'Catalog');
  assertOnlyKeys(root, ['schemaVersion', 'drills'], 'Catalog');
  if (root.schemaVersion !== 1) {
    throw new TypeError('Catalog.schemaVersion must be 1.');
  }
  if (!Array.isArray(root.drills)) {
    throw new TypeError('Catalog.drills must be an array.');
  }

  const ids = new Set();
  for (const [index, drill] of root.drills.entries()) {
    await validateDrill(drill, index, mediaRoot);
    if (ids.has(drill.id)) {
      throw new TypeError(`Duplicate drill id "${drill.id}".`);
    }
    ids.add(drill.id);
  }
  return root.drills;
}

function parseArguments(args) {
  const options = { dataPath: defaultDataPath, mode: null, validateOnly: false };
  for (let index = 0; index < args.length; index += 1) {
    const argument = args[index];
    if (argument === '--data') {
      const value = args[index + 1];
      if (value === undefined || value.startsWith('--')) {
        throw new TypeError('--data requires a path.');
      }
      options.dataPath = resolve(value);
      index += 1;
    } else if (argument === '--project') {
      const value = args[index + 1];
      if (value === undefined || value.startsWith('--')) {
        throw new TypeError('--project requires a project id.');
      }
      options.projectId = value;
      index += 1;
    } else if (argument === '--bucket') {
      const value = args[index + 1];
      if (value === undefined || value.startsWith('--')) {
        throw new TypeError('--bucket requires a bucket name.');
      }
      options.bucketName = value;
      index += 1;
    } else if (argument === '--emulator' || argument === '--live') {
      if (options.mode !== null) {
        throw new TypeError('Choose only one of --emulator or --live.');
      }
      options.mode = argument.slice(2);
    } else if (argument === '--validate-only') {
      options.validateOnly = true;
    } else if (argument === '--help') {
      options.help = true;
    } else {
      throw new TypeError(`Unknown argument "${argument}".`);
    }
  }

  if (!options.validateOnly && options.mode === null) {
    throw new TypeError('Choose --emulator or explicitly opt in to production with --live.');
  }
  if (options.projectId === undefined) {
    options.projectId = process.env.GCLOUD_PROJECT ?? 'how-to-hockey';
  }
  if (options.bucketName === undefined) {
    options.bucketName = `${options.projectId}.firebasestorage.app`;
  }
  return options;
}

function printHelp() {
  console.log(`Usage: npm --prefix functions run seed:drills -- [options]

Options:
  --data <path>   Catalog JSON file (default: tool/seed/drills.json)
  --emulator      Upload to local Firestore and Storage emulators
  --live          Explicitly upload to the configured live Firebase project
  --project <id>  Firebase project id (default: how-to-hockey)
  --bucket <name> Storage bucket (default: <project>.firebasestorage.app)
  --validate-only Validate files without connecting to Firebase
  --help          Show this help`);
}

async function main(args = process.argv.slice(2)) {
  const options = parseArguments(args);
  if (options.help) {
    printHelp();
    return;
  }

  const dataPath = resolve(options.dataPath);
  const mediaRoot = resolve(dirname(dataPath), 'media');
  const catalog = JSON.parse(await readFile(dataPath, 'utf8'));
  const drills = await validateCatalog(catalog, mediaRoot);

  if (options.validateOnly) {
    console.log(`Validated ${drills.length} drill(s) and their media files.`);
    return;
  }
  if (drills.length === 0) {
    throw new Error('Catalog is empty; add drills before uploading.');
  }

  if (options.mode === 'emulator') {
    process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
    process.env.FIREBASE_STORAGE_EMULATOR_HOST ??= '127.0.0.1:9199';
  } else if (
    process.env.FIRESTORE_EMULATOR_HOST !== undefined ||
    process.env.FIREBASE_STORAGE_EMULATOR_HOST !== undefined
  ) {
    throw new Error('--live cannot be used while Firebase emulator host variables are set.');
  }

  const app = initializeApp(
    { projectId: options.projectId, storageBucket: options.bucketName },
    'drill-seed',
  );
  const db = getFirestore(app);
  const bucket = getStorage(app).bucket(options.bucketName);

  try {
    for (const drill of drills) {
      const mediaPath = resolve(mediaRoot, drill.mediaAssetPath);
      await bucket.upload(mediaPath, {
        destination: drill.mediaAssetPath,
        metadata: { contentType: 'video/mp4' },
      });
      await db.collection('drills').doc(drill.id).set({
        ...drill,
        updatedAt: FieldValue.serverTimestamp(),
      });
      console.log(`Uploaded ${drill.id}`);
    }
    console.log(`Uploaded ${drills.length} drill(s) to ${options.projectId}.`);
  } finally {
    await app.delete();
  }
}

if (process.argv[1] !== undefined && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
}
