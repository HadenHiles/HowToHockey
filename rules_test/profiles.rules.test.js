import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, describe, it } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, query, setDoc, updateDoc, where } from 'firebase/firestore';

const projectId = 'demo-how-to-hockey';

function emulatorAddress() {
  const address = process.env.FIRESTORE_EMULATOR_HOST;
  assert.ok(address, 'FIRESTORE_EMULATOR_HOST must be set by firebase emulators:exec.');
  const url = new URL(`http://${address}`);
  assert.ok(['127.0.0.1', 'localhost', '[::1]'].includes(url.hostname), 'Rules tests must run against a local emulator, not a live backend.');
  return { host: url.hostname, port: Number(url.port) };
}

describe('account and profile rules', () => {
  let environment;

  before(async () => {
    environment = await initializeTestEnvironment({
      projectId,
      firestore: { ...emulatorAddress(), rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8') },
    });
  });

  after(async () => environment?.cleanup());

  beforeEach(async () => {
    await environment.clearFirestore();
    await environment.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users/parent'), { roles: ['parent'], email: 'parent@example.com' });
      await setDoc(doc(db, 'users/stranger'), { roles: ['player'] });
      await setDoc(doc(db, 'profiles/kid-a'), { ownerUid: 'parent', displayName: 'Avery H.', isChild: true });
      await setDoc(doc(db, 'profiles/kid-b'), { ownerUid: 'parent', displayName: 'Riley H.', isChild: true });
      await setDoc(doc(db, 'profiles/stranger'), { ownerUid: 'stranger', displayName: 'Sam T.', isChild: false });
      for (const profile of ['kid-a', 'kid-b', 'stranger']) {
        await setDoc(doc(db, `profiles/${profile}/sessions/s1`), { status: 'finished' });
        await setDoc(doc(db, `profiles/${profile}/sessions/s1/drills/0`), { drillId: 'x' });
        await setDoc(doc(db, `profiles/${profile}/stats/lifetime`), { totalShots: 10 });
        await setDoc(doc(db, `profiles/${profile}/prs/accuracy`), { value: 80 });
        await setDoc(doc(db, `profiles/${profile}/focusPresets/p1`), { name: 'Garage' });
      }
    });
  });

  const parent = () => environment.authenticatedContext('parent', { firebase: { sign_in_provider: 'password' } }).firestore();
  const stranger = () => environment.authenticatedContext('stranger', { firebase: { sign_in_provider: 'password' } }).firestore();
  const anonymous = () => environment.authenticatedContext('anon', { firebase: { sign_in_provider: 'anonymous' } }).firestore();
  const signedOut = () => environment.unauthenticatedContext().firestore();
  // A kid device: its own uid, locked to one profile by the custom-token claim.
  const kidDevice = (profileId) => environment.authenticatedContext(`kid_${profileId}`, { profileId }).firestore();

  describe('users', () => {
    it('lets people read only their own account document', async () => {
      await assertSucceeds(getDoc(doc(parent(), 'users/parent')));
      await assertFails(getDoc(doc(stranger(), 'users/parent')));
      await assertFails(getDoc(doc(signedOut(), 'users/parent')));
      await assertFails(getDoc(doc(anonymous(), 'users/parent')));
    });

    it('never lets a client write roles or any account field', async () => {
      await assertFails(updateDoc(doc(parent(), 'users/parent'), { roles: ['parent', 'coach'] }));
      await assertFails(setDoc(doc(parent(), 'users/parent'), { roles: ['coach'] }));
      await assertFails(setDoc(doc(stranger(), 'users/newcomer'), { roles: ['player'] }));
      await assertFails(deleteDoc(doc(parent(), 'users/parent')));
    });

    it('hides the parent account from a kid device', async () => {
      await assertFails(getDoc(doc(kidDevice('kid-a'), 'users/parent')));
    });

    it('cannot be listed', async () => {
      await assertFails(getDocs(collection(parent(), 'users')));
    });
  });

  describe('profiles', () => {
    it('lets a parent read every profile they own', async () => {
      await assertSucceeds(getDoc(doc(parent(), 'profiles/kid-a')));
      await assertSucceeds(getDoc(doc(parent(), 'profiles/kid-b')));
    });

    it('keeps other people\'s profiles private', async () => {
      await assertFails(getDoc(doc(stranger(), 'profiles/kid-a')));
      await assertFails(getDoc(doc(parent(), 'profiles/stranger')));
      await assertFails(getDoc(doc(signedOut(), 'profiles/kid-a')));
      await assertFails(getDoc(doc(anonymous(), 'profiles/kid-a')));
    });

    it('lets a kid device read only the profile it is locked to', async () => {
      await assertSucceeds(getDoc(doc(kidDevice('kid-a'), 'profiles/kid-a')));
      await assertFails(getDoc(doc(kidDevice('kid-a'), 'profiles/kid-b')));
      await assertFails(getDoc(doc(kidDevice('kid-a'), 'profiles/stranger')));
    });

    it('never lets a client create, edit, or delete a profile (names and caps are enforced by Functions)', async () => {
      await assertFails(setDoc(doc(parent(), 'profiles/new-kid'), { ownerUid: 'parent', displayName: 'Anything Goes', isChild: true }));
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a'), { displayName: 'Hacked' }));
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a'), { ownerUid: 'stranger' }));
      await assertFails(deleteDoc(doc(parent(), 'profiles/kid-a')));
      await assertFails(updateDoc(doc(kidDevice('kid-a'), 'profiles/kid-a'), { displayName: 'Hacked' }));
    });

    it('cannot be listed or queried broadly', async () => {
      await assertFails(getDocs(collection(parent(), 'profiles')));
      await assertFails(getDocs(collection(signedOut(), 'profiles')));
    });

    it('lets a parent list their own children, and nobody else\'s', async () => {
      const own = (db, uid) => query(collection(db, 'profiles'), where('ownerUid', '==', uid), where('isChild', '==', true));
      await assertSucceeds(getDocs(own(parent(), 'parent')));
      await assertFails(getDocs(own(stranger(), 'parent')));
      await assertFails(getDocs(own(kidDevice('kid-a'), 'parent')));
    });
  });

  describe('private profile data', () => {
    const paths = (profile) => ({
      session: `profiles/${profile}/sessions/s1`,
      drill: `profiles/${profile}/sessions/s1/drills/0`,
      stats: `profiles/${profile}/stats/lifetime`,
      pr: `profiles/${profile}/prs/accuracy`,
      preset: `profiles/${profile}/focusPresets/p1`,
    });

    it('lets the owner read everything on their children', async () => {
      for (const path of Object.values(paths('kid-a'))) {
        await assertSucceeds(getDoc(doc(parent(), path)));
      }
    });

    it('lets the owner save sessions and presets, but not the totals Functions compute', async () => {
      const p = paths('kid-a');
      await assertSucceeds(setDoc(doc(parent(), 'profiles/kid-a/sessions/s2'), { status: 'finished' }));
      await assertSucceeds(updateDoc(doc(parent(), p.session), { status: 'finished', activeSeconds: 100 }));
      await assertSucceeds(setDoc(doc(parent(), 'profiles/kid-a/sessions/s2/drills/0'), { drillId: 'x' }));
      await assertSucceeds(setDoc(doc(parent(), 'profiles/kid-a/focusPresets/p2'), { name: 'Rink' }));
      await assertFails(setDoc(doc(parent(), p.stats), { totalShots: 999999 }));
      await assertFails(updateDoc(doc(parent(), p.pr), { value: 100 }));
      await assertFails(deleteDoc(doc(parent(), p.session)));
    });

    it('blocks everyone else from another profile\'s data', async () => {
      for (const path of Object.values(paths('kid-a'))) {
        await assertFails(getDoc(doc(stranger(), path)));
        await assertFails(getDoc(doc(signedOut(), path)));
        await assertFails(getDoc(doc(anonymous(), path)));
      }
      await assertFails(setDoc(doc(stranger(), 'profiles/kid-a/sessions/evil'), { status: 'finished' }));
    });

    it('locks a kid device to its own profile\'s data, including siblings', async () => {
      const kid = kidDevice('kid-a');
      for (const path of Object.values(paths('kid-a'))) {
        await assertSucceeds(getDoc(doc(kid, path)));
      }
      await assertSucceeds(setDoc(doc(kid, 'profiles/kid-a/sessions/s2'), { status: 'finished' }));
      for (const path of Object.values(paths('kid-b'))) {
        await assertFails(getDoc(doc(kid, path)));
      }
      await assertFails(setDoc(doc(kid, 'profiles/kid-b/sessions/evil'), { status: 'finished' }));
      await assertFails(setDoc(doc(kid, 'profiles/kid-a/stats/lifetime'), { totalShots: 999999 }));
    });

    it('lets the owner list their own profile\'s sessions but nobody else', async () => {
      await assertSucceeds(getDocs(collection(parent(), 'profiles/kid-a/sessions')));
      await assertFails(getDocs(collection(stranger(), 'profiles/kid-a/sessions')));
      await assertFails(getDocs(collection(kidDevice('kid-b'), 'profiles/kid-a/sessions')));
    });
  });
});
