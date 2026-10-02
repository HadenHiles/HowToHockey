import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, describe, it } from 'node:test';

import {
  assertFails,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
} from 'firebase/firestore';
import {
  deleteObject,
  getBytes,
  getMetadata,
  listAll,
  ref,
  updateMetadata,
  uploadBytes,
} from 'firebase/storage';

const projectId = 'demo-how-to-hockey';
const bucket = `gs://${projectId}.appspot.com`;
const documentPaths = ['profiles/player', 'teams/team/private/details'];
const objectPaths = ['media/drill.bin', 'profiles/player/private/image.bin'];
const identities = [
  { name: 'unauthenticated' },
  { name: 'anonymous', uid: 'player', claims: { firebase: { sign_in_provider: 'anonymous' } } },
  { name: 'owner', uid: 'player' },
  { name: 'another player', uid: 'other-player' },
  { name: 'coach', uid: 'coach', claims: { role: 'coach' } },
  { name: 'admin claimant', uid: 'admin', claims: { admin: true } },
];

function emulatorAddress(variable) {
  const address = process.env[variable];
  assert.ok(address, `${variable} must be set by firebase emulators:exec.`);
  const url = new URL(`http://${address}`);
  assert.ok(
    ['127.0.0.1', 'localhost', '[::1]'].includes(url.hostname),
    `${variable} must point to a local emulator, not a live backend.`,
  );
  assert.ok(url.port, `${variable} must include a port.`);
  return { host: url.hostname, port: Number(url.port) };
}

describe('deny-by-default Firebase rules', () => {
  let environment;

  before(async () => {
    environment = await initializeTestEnvironment({
      projectId,
      firestore: {
        ...emulatorAddress('FIRESTORE_EMULATOR_HOST'),
        rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8'),
      },
      storage: {
        ...emulatorAddress('FIREBASE_STORAGE_EMULATOR_HOST'),
        rules: await readFile(new URL('../storage.rules', import.meta.url), 'utf8'),
      },
    });
    await environment.withSecurityRulesDisabled(async (context) => {
      for (const path of documentPaths) {
        await setDoc(doc(context.firestore(), path), { ownerId: 'player', value: 1 });
      }
      for (const path of objectPaths) {
        await uploadBytes(ref(context.storage(bucket), path), new Uint8Array([1, 2, 3]));
      }
    });
  });

  after(async () => {
    if (environment) {
      await environment.cleanup();
    }
  });

  it('seeds existing resources so denials are not missing-data checks', async () => {
    await environment.withSecurityRulesDisabled(async (context) => {
      for (const path of documentPaths) {
        assert.equal((await getDoc(doc(context.firestore(), path))).exists(), true);
      }
      for (const path of objectPaths) {
        assert.equal((await getMetadata(ref(context.storage(bucket), path))).size, 3);
      }
    });
  });

  for (const identity of identities) {
    it(`denies Firestore reads, queries, creates, updates, and deletes for ${identity.name}`, async () => {
      const context = identity.uid
        ? environment.authenticatedContext(identity.uid, identity.claims)
        : environment.unauthenticatedContext();
      for (const path of documentPaths) {
        const document = doc(context.firestore(), path);
        await assertFails(getDoc(document));
        await assertFails(getDocs(collection(context.firestore(), path.substring(0, path.lastIndexOf('/')))));
        await assertFails(setDoc(doc(context.firestore(), `${path}-new`), { ownerId: identity.uid ?? null }));
        await assertFails(updateDoc(document, { value: 2 }));
        await assertFails(deleteDoc(document));
      }
    });

    it(`denies Storage downloads, metadata reads, lists, creates, overwrites, updates, and deletes for ${identity.name}`, async () => {
      const context = identity.uid
        ? environment.authenticatedContext(identity.uid, identity.claims)
        : environment.unauthenticatedContext();
      for (const path of objectPaths) {
        const object = ref(context.storage(bucket), path);
        await assertFails(getBytes(object));
        await assertFails(getMetadata(object));
        await assertFails(listAll(ref(context.storage(bucket), path.substring(0, path.lastIndexOf('/')))));
        await assertFails(uploadBytes(ref(context.storage(bucket), `${path}-new`), new Uint8Array([4])));
        await assertFails(uploadBytes(object, new Uint8Array([4])));
        await assertFails(updateMetadata(object, { contentType: 'text/plain' }));
        await assertFails(deleteObject(object));
      }
    });
  }
});
