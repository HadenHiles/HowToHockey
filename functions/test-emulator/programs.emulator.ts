import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { getProgramDashboard, startProgramDay } from '../src/programs';
import { processSession } from '../src/sessions';

const parent = { uid: 'parent', isAnonymous: false };
const kidDevice = { uid: 'kid-kid-a', isAnonymous: false, isKidDevice: true };
const now = new Date('2026-10-22T15:00:00Z');
let app: App;
let db: Firestore;

beforeAll(() => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(127\.0\.0\.1|localhost|\[::1\]):/.test(host)) throw new Error('Local Firestore emulator required.');
  app = initializeApp({ projectId: 'demo-how-to-hockey' }, 'program-tests');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-how-to-hockey/databases/(default)/documents`, { method: 'DELETE' });
  await db.doc('users/parent').set({ entitlements: { programs: [] } });
  await db.doc('profiles/kid-a').set({ ownerUid: 'parent', isChild: true });
  await db.doc('drills/quick-release-wrist-shots').set({ title: 'Quick-release wrist shots', trackingType: 'volume', skillWeights: { shotPower: 1 }, estimatedSecondsPerSet: 45 });
  await db.doc('drills/shot-burst-30').set({ title: '30-second shot burst', trackingType: 'density', skillWeights: { endurance: 1 }, estimatedSecondsPerSet: 30 });
  await db.doc('drills/pick-your-corner').set({ title: 'Pick your corner', trackingType: 'accuracy', skillWeights: { shotAccuracy: 1 }, estimatedSecondsPerSet: 45 });
});

async function writeRunSession(sessionId: string, runId: string, status: 'completed' | 'pending') {
  const ref = db.doc(`profiles/kid-a/sessions/${sessionId}`);
  const batch = db.batch();
  batch.set(ref, {
    status,
    startedAt: Timestamp.fromDate(new Date(now.getTime() - 60_000)),
    endedAt: Timestamp.fromDate(now),
    tzOffsetMinutes: 0,
    programRunId: runId,
  });
  for (const [index, entry] of [
    ['quick-release-wrist-shots', 3],
    ['shot-burst-30', 2],
  ].entries()) {
    batch.set(ref.collection('drills').doc(String(index)), {
      drillId: entry[0],
      sets: Array.from({ length: entry[1] }, () => ({ reps: 10, seconds: 30, loggedAt: Timestamp.fromDate(now) })),
    });
  }
  await batch.commit();
}

describe('program access and progress', () => {
  it('returns server-owned catalog content and checks ownership for dashboard reads', async () => {
    const dashboard = await getProgramDashboard(db, parent, { profileId: 'kid-a' });
    expect(dashboard.ownedProgramIds).toEqual([]);
    await expect(getProgramDashboard(db, { uid: 'stranger', isAnonymous: false }, { profileId: 'kid-a' })).rejects.toMatchObject({ code: 'permission-denied' });
    expect((await getProgramDashboard(db, kidDevice, { profileId: 'kid-a' })).ownedProgramIds).toEqual([]);
    await expect(getProgramDashboard(db, kidDevice, { profileId: 'another-kid' })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('starts free Day 1, waits for parent confirmation, then unlocks sequential progress', async () => {
    const { runId } = await startProgramDay(db, parent, { profileId: 'kid-a', programId: 'shooting-30', day: 1 }, now);
    await writeRunSession('session-1', runId, 'pending');
    expect(await processSession(db, 'kid-a', 'session-1', now)).toEqual({ status: 'skipped' });
    expect((await db.doc('profiles/kid-a/programs/shooting-30').get()).exists).toBe(false);

    await db.doc('profiles/kid-a/sessions/session-1').update({ status: 'completed' });
    expect((await processSession(db, 'kid-a', 'session-1', now)).status).toBe('processed');
    expect((await db.doc('profiles/kid-a/programs/shooting-30').get()).data()).toMatchObject({ completedDays: [1], completedChallenges: [1] });
    expect((await db.doc(`profiles/kid-a/programRuns/${runId}`).get()).data()).toMatchObject({ status: 'completed', sessionId: 'session-1' });

    await expect(startProgramDay(db, parent, { profileId: 'kid-a', programId: 'shooting-30', day: 2 }, now)).rejects.toMatchObject({ code: 'permission-denied' });
    await db.doc('users/parent').update({ 'entitlements.programs': ['program_shooting-30'] });
    await expect(startProgramDay(db, parent, { profileId: 'kid-a', programId: 'shooting-30', day: 3 }, now)).rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await startProgramDay(db, parent, { profileId: 'kid-a', programId: 'shooting-30', day: 2 }, now)).runId).toBeTruthy();
  });

  it('allows the paired player to start a free day but not another profile or an invalid day', async () => {
    expect((await startProgramDay(db, kidDevice, { profileId: 'kid-a', programId: 'hands-21', day: 1 }, now)).runId).toBeTruthy();
    await expect(startProgramDay(db, kidDevice, { profileId: 'other', programId: 'hands-21', day: 1 }, now)).rejects.toMatchObject({ code: 'not-found' });
    await expect(startProgramDay(db, parent, { profileId: 'kid-a', programId: 'hands-21', day: 22 }, now)).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('does not count a run when the workout does not match its server-authored routine', async () => {
    const { runId } = await startProgramDay(db, parent, { profileId: 'kid-a', programId: 'shooting-30', day: 1 }, now);
    const ref = db.doc('profiles/kid-a/sessions/s1');
    await ref.set({ status: 'completed', startedAt: Timestamp.fromDate(new Date(now.getTime() - 60_000)), endedAt: Timestamp.fromDate(now), tzOffsetMinutes: 0, programRunId: runId });
    await ref.collection('drills').doc('0').set({ drillId: 'pick-your-corner', sets: [{ reps: 10, hits: 8, loggedAt: Timestamp.fromDate(now) }] });
    expect((await processSession(db, 'kid-a', 's1', now)).status).toBe('processed');
    expect((await db.doc('profiles/kid-a/programs/shooting-30').get()).exists).toBe(false);
    expect((await db.doc(`profiles/kid-a/programRuns/${runId}`).get()).data()?.status).toBe('started');
  });
});
