import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, describe, it } from 'node:test';

import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { Timestamp, collection, deleteDoc, doc, getDoc, getDocs, query, serverTimestamp, setDoc, updateDoc, where } from 'firebase/firestore';

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

  const finishedSession = (extra = {}) => ({ status: 'completed', startedAt: Timestamp.now(), endedAt: Timestamp.now(), tzOffsetMinutes: -240, ...extra });
  const sessionDrill = (extra = {}) => ({ drillId: 'pick-your-corner', sets: [{ reps: 10, hits: 6, loggedAt: Timestamp.now() }], ...extra });

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

    it('keeps pairing codes server-only', async () => {
      await assertFails(getDocs(collection(parent(), 'pairingCodes')));
      await assertFails(getDoc(doc(parent(), 'pairingCodes/anything')));
      await assertFails(setDoc(doc(parent(), 'pairingCodes/anything'), { profileId: 'kid-a', ownerUid: 'parent' }));
      await assertFails(getDoc(doc(kidDevice('kid-a'), 'pairingCodes/anything')));
    });

    it('lets an account watch its own profile before it exists, but nobody else\'s', async () => {
      await assertSucceeds(getDoc(doc(parent(), 'profiles/parent')));
      await assertSucceeds(getDoc(doc(stranger(), 'profiles/stranger')));
      await assertFails(getDoc(doc(parent(), 'profiles/someone-new')));
      await assertFails(getDoc(doc(stranger(), 'profiles/parent')));
      await assertFails(getDoc(doc(kidDevice('kid-a'), 'profiles/parent')));
      await assertFails(getDoc(doc(anonymous(), 'profiles/stranger')));
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
      program: `profiles/${profile}/programs/shooting-30`,
    });

    it('lets the owner read everything on their children', async () => {
      for (const path of Object.values(paths('kid-a'))) {
        await assertSucceeds(getDoc(doc(parent(), path)));
      }
    });

    it('lets the owner save a finished workout and presets, but not the totals Functions compute', async () => {
      const p = paths('kid-a');
      await assertSucceeds(setDoc(doc(parent(), 'profiles/kid-a/sessions/s2'), finishedSession({ routineName: 'Garage', drillCount: 1, activeSeconds: 600, programRunId: 'serverRun123' })));
      await assertSucceeds(setDoc(doc(parent(), 'profiles/kid-a/sessions/s2/drills/0'), sessionDrill({ title: 'Pick your corner', estimatedSecondsPerSet: 60, trackingType: 'accuracy', skillWeights: { shotAccuracy: 1 } })));
      await assertSucceeds(setDoc(doc(parent(), 'profiles/kid-a/focusPresets/p2'), { name: 'Rink' }));
      await assertFails(setDoc(doc(parent(), p.stats), { totalShots: 999999 }));
      await assertFails(updateDoc(doc(parent(), p.pr), { value: 100 }));
      await assertFails(setDoc(doc(parent(), p.program), { completedDays: [1, 2] }));
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/programRuns/run1'), { status: 'started' }));
      await assertFails(deleteDoc(doc(parent(), p.session)));
    });

    it('keeps workouts write-once: no edits, no deleting, no awarding yourself credit', async () => {
      await assertSucceeds(setDoc(doc(parent(), 'profiles/kid-a/sessions/s2'), finishedSession()));
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/sessions/s2'), finishedSession({ activeSeconds: 5 })));
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a/sessions/s2'), { activeSeconds: 5 }));
      await assertFails(deleteDoc(doc(parent(), 'profiles/kid-a/sessions/s2')));
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/sessions/s3'), finishedSession({ processedAt: Timestamp.now() })));
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/sessions/s3'), finishedSession({ credit: { seconds: 99999, shots: 99999 } })));
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/sessions/s3'), finishedSession({ rejected: 'no' })));
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a/sessions/s1/drills/0'), { drillId: 'y' }));
    });

    it('checks the shape of a workout before it is stored', async () => {
      const bad = [
        finishedSession({ status: 'active' }),
        finishedSession({ startedAt: 'yesterday' }),
        finishedSession({ tzOffsetMinutes: 5000 }),
        finishedSession({ tzOffsetMinutes: '300' }),
        finishedSession({ drillCount: 500 }),
        finishedSession({ routineName: 'x'.repeat(200) }),
        finishedSession({ surprise: true }),
      ];
      for (const [i, data] of bad.entries()) await assertFails(setDoc(doc(parent(), `profiles/kid-a/sessions/bad${i}`), data));
      const { status, ...missing } = finishedSession();
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/sessions/bad-missing'), missing));

      const badDrills = [
        sessionDrill({ sets: 'many' }),
        sessionDrill({ drillId: '' }),
        sessionDrill({ sets: Array.from({ length: 101 }, () => ({ reps: 1 })) }),
        sessionDrill({ estimatedSecondsPerSet: 99999 }),
        sessionDrill({ extra: 1 }),
      ];
      for (const [i, data] of badDrills.entries()) await assertFails(setDoc(doc(parent(), `profiles/kid-a/sessions/s1/drills/${i + 1}`), data));
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/sessions/s1/drills/abc'), sessionDrill()));
    });

    it('blocks everyone else from another profile\'s data', async () => {
      for (const path of Object.values(paths('kid-a'))) {
        await assertFails(getDoc(doc(stranger(), path)));
        await assertFails(getDoc(doc(signedOut(), path)));
        await assertFails(getDoc(doc(anonymous(), path)));
      }
      await assertFails(setDoc(doc(stranger(), 'profiles/kid-a/sessions/evil'), finishedSession()));
    });

    it('locks a kid device to its own profile\'s data, including siblings', async () => {
      const kid = kidDevice('kid-a');
      for (const path of Object.values(paths('kid-a'))) {
        await assertSucceeds(getDoc(doc(kid, path)));
      }
      await assertSucceeds(setDoc(doc(kid, 'profiles/kid-a/sessions/s2'), finishedSession({ status: 'pending' })));
      for (const path of Object.values(paths('kid-b'))) {
        await assertFails(getDoc(doc(kid, path)));
      }
      await assertFails(setDoc(doc(kid, 'profiles/kid-b/sessions/evil'), finishedSession()));
      await assertFails(setDoc(doc(kid, 'profiles/kid-a/stats/lifetime'), { totalShots: 999999 }));
    });

    it('lets the owner list their own profile\'s sessions but nobody else', async () => {
      await assertSucceeds(getDocs(collection(parent(), 'profiles/kid-a/sessions')));
      await assertFails(getDocs(collection(stranger(), 'profiles/kid-a/sessions')));
      await assertFails(getDocs(collection(kidDevice('kid-b'), 'profiles/kid-a/sessions')));
    });

    it('keeps a child device\'s workout pending until a parent confirms it', async () => {
      const kid = kidDevice('kid-a');
      await assertFails(setDoc(doc(kid, 'profiles/kid-a/sessions/c1'), finishedSession()));
      await assertSucceeds(setDoc(doc(kid, 'profiles/kid-a/sessions/p1'), finishedSession({ status: 'pending' })));
      await assertSucceeds(setDoc(doc(kid, 'profiles/kid-a/sessions/p1/drills/0'), sessionDrill()));
      await assertFails(setDoc(doc(kid, 'profiles/kid-a/sessions/p2'), finishedSession({ status: 'pending', processedAt: Timestamp.now() })));
      await assertFails(setDoc(doc(kid, 'profiles/kid-a/sessions/p3'), finishedSession({ status: 'done' })));

      // The kid cannot confirm or discard their own workout.
      await assertFails(updateDoc(doc(kid, 'profiles/kid-a/sessions/p1'), { status: 'completed', confirmedAt: Timestamp.now() }));
      await assertFails(deleteDoc(doc(kid, 'profiles/kid-a/sessions/p1')));
      await assertFails(updateDoc(doc(kid, 'profiles/kid-b/sessions/p1'), { status: 'completed' }));
      // Neither can a stranger or another parent.
      await assertFails(updateDoc(doc(stranger(), 'profiles/kid-a/sessions/p1'), { status: 'completed', confirmedAt: serverTimestamp() }));
      await assertFails(deleteDoc(doc(stranger(), 'profiles/kid-a/sessions/p1')));

      // The parent can confirm only by flipping the status, and only while it is pending.
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a/sessions/p1'), { status: 'completed', confirmedAt: serverTimestamp(), activeSeconds: 99 }));
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a/sessions/p1'), { status: 'completed' }));
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a/sessions/p1'), { status: 'completed', confirmedAt: Timestamp.fromMillis(1) }));
      await assertSucceeds(updateDoc(doc(parent(), 'profiles/kid-a/sessions/p1'), { status: 'completed', confirmedAt: serverTimestamp() }));
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a/sessions/p1'), { status: 'pending' }));
      await assertFails(deleteDoc(doc(parent(), 'profiles/kid-a/sessions/p1')));
      await assertFails(deleteDoc(doc(parent(), 'profiles/kid-a/sessions/p1/drills/0')));
    });

    it('lets a parent discard a pending workout and its drills', async () => {
      await assertSucceeds(setDoc(doc(kidDevice('kid-a'), 'profiles/kid-a/sessions/p9'), finishedSession({ status: 'pending' })));
      await assertSucceeds(setDoc(doc(kidDevice('kid-a'), 'profiles/kid-a/sessions/p9/drills/0'), sessionDrill()));
      await assertSucceeds(deleteDoc(doc(parent(), 'profiles/kid-a/sessions/p9/drills/0')));
      await assertSucceeds(deleteDoc(doc(parent(), 'profiles/kid-a/sessions/p9')));
    });

    it('lets a parent list their child\'s pending workouts', async () => {
      const pending = (db) => query(collection(db, 'profiles/kid-a/sessions'), where('status', '==', 'pending'));
      await assertSucceeds(getDocs(pending(parent())));
      await assertSucceeds(getDocs(pending(kidDevice('kid-a'))));
      await assertFails(getDocs(pending(stranger())));
    });

    it('keeps the audit trail readable by the parent only, and writable by nobody', async () => {
      await environment.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'profiles/kid-a/sessions/s1/audits/a1'), { by: 'parent', action: 'timeCorrected' });
      });
      await assertSucceeds(getDoc(doc(parent(), 'profiles/kid-a/sessions/s1/audits/a1')));
      await assertFails(getDoc(doc(kidDevice('kid-a'), 'profiles/kid-a/sessions/s1/audits/a1')));
      await assertFails(getDoc(doc(stranger(), 'profiles/kid-a/sessions/s1/audits/a1')));
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/sessions/s1/audits/a2'), { by: 'parent' }));
      await assertFails(deleteDoc(doc(parent(), 'profiles/kid-a/sessions/s1/audits/a1')));
      await assertFails(updateDoc(doc(parent(), 'profiles/kid-a/sessions/s1'), { correctedSeconds: 1 }));
    });

    it('lets a parent and the child\'s device read the child\'s routines, but only Functions write them', async () => {
      await environment.withSecurityRulesDisabled(async (context) => {
        await setDoc(doc(context.firestore(), 'profiles/kid-a/routines/r1'), { name: 'Hands', drills: [] });
      });
      await assertSucceeds(getDoc(doc(parent(), 'profiles/kid-a/routines/r1')));
      await assertSucceeds(getDoc(doc(kidDevice('kid-a'), 'profiles/kid-a/routines/r1')));
      await assertFails(getDoc(doc(kidDevice('kid-b'), 'profiles/kid-a/routines/r1')));
      await assertFails(getDoc(doc(stranger(), 'profiles/kid-a/routines/r1')));
      await assertFails(setDoc(doc(parent(), 'profiles/kid-a/routines/r2'), { name: 'x' }));
      await assertFails(setDoc(doc(kidDevice('kid-a'), 'profiles/kid-a/routines/r2'), { name: 'x' }));
      await assertFails(deleteDoc(doc(parent(), 'profiles/kid-a/routines/r1')));
    });
  });
});
