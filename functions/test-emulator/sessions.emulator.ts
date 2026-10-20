import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, Timestamp, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { processSession } from '../src/sessions';

const now = new Date('2026-10-20T15:00:00Z');
const startedAt = new Date('2026-10-20T13:00:00Z');
let app: App;
let db: Firestore;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !/^(127\.0\.0\.1|localhost|\[::1\])/.test(process.env.FIRESTORE_EMULATOR_HOST)) {
    throw new Error('These tests must run against the local Firestore emulator.');
  }
  app = initializeApp({ projectId: 'demo-how-to-hockey' }, 'sessions-tests');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-how-to-hockey/databases/(default)/documents`, { method: 'DELETE' });
  await db.collection('drills').doc('pick-your-corner').set({ title: 'Pick your corner', trackingType: 'accuracy', skillWeights: { shotAccuracy: 0.8, shotPower: 0.2 }, estimatedSecondsPerSet: 60 });
  await db.collection('drills').doc('ball-bounce-streak').set({ title: 'Bounce and catch streak', trackingType: 'streak', skillWeights: { hands: 1 }, estimatedSecondsPerSet: 45 });
});

const set = (fields: Record<string, unknown>, at = startedAt) => ({ loggedAt: Timestamp.fromDate(at), ...fields });

async function writeSession(id: string, drills: Record<string, unknown>[], overrides: Record<string, unknown> = {}, profile = 'kid-a') {
  const ref = db.collection('profiles').doc(profile).collection('sessions').doc(id);
  const batch = db.batch();
  batch.set(ref, { status: 'completed', startedAt: Timestamp.fromDate(startedAt), endedAt: Timestamp.fromDate(now), tzOffsetMinutes: 0, ...overrides });
  drills.forEach((d, i) => batch.set(ref.collection('drills').doc(String(i)), d));
  await batch.commit();
}

const corner = (hits: number, reps = 10, extra: Record<string, unknown> = {}) => ({ drillId: 'pick-your-corner', title: 'Pick your corner', trackingType: 'accuracy', skillWeights: { shotAccuracy: 0.8, shotPower: 0.2 }, estimatedSecondsPerSet: 60, sets: [set({ reps, hits })], ...extra });

describe('processSession', () => {
  it('credits stats and personal bests, and marks the session', async () => {
    await writeSession('s1', [corner(7), { drillId: 'ball-bounce-streak', sets: [set({ streak: 18 })] }]);
    const outcome = await processSession(db, 'kid-a', 's1', now);
    expect(outcome).toEqual({ status: 'processed', newBestKeys: ['accuracy:pick-your-corner', 'streak:ball-bounce-streak'] });

    const stats = (await db.doc('profiles/kid-a/stats/lifetime').get()).data()!;
    expect(stats).toMatchObject({ workouts: 1, shots: 10, seconds: 105 });
    expect(stats.pillarSeconds.shotAccuracy).toBeCloseTo(48);
    expect(stats.pillarSeconds.hands).toBeCloseTo(45);
    expect(stats.days['2026-10-20']).toEqual([105, 10]);
    expect(stats.recent).toEqual(['s1']);
    expect((stats.bests as { key: string; value: number }[]).map((b) => [b.key, b.value]).sort()).toEqual([
      ['accuracy:pick-your-corner', 70],
      ['streak:ball-bounce-streak', 18],
    ]);
    expect((await db.doc('profiles/kid-a/prs/accuracy:pick-your-corner').get()).data()).toMatchObject({ value: 70, workoutId: 's1', title: 'Pick your corner' });
    const session = (await db.doc('profiles/kid-a/sessions/s1').get()).data()!;
    expect(session.processedAt).toBeTruthy();
    expect(session.credit).toMatchObject({ seconds: 105, shots: 10 });
  });

  it('counts a session only once', async () => {
    await writeSession('s1', [corner(7)]);
    await processSession(db, 'kid-a', 's1', now);
    expect(await processSession(db, 'kid-a', 's1', now)).toEqual({ status: 'skipped' });
    const results = await Promise.all([processSession(db, 'kid-a', 's1', now), processSession(db, 'kid-a', 's1', now)]);
    expect(results.every((r) => r.status === 'skipped')).toBe(true);
    expect((await db.doc('profiles/kid-a/stats/lifetime').get()).data()!.workouts).toBe(1);
    expect(await processSession(db, 'kid-a', 'missing', now)).toEqual({ status: 'skipped' });
  });

  it('simultaneous new sessions both count', async () => {
    await writeSession('s1', [corner(7)]);
    await writeSession('s2', [corner(8)], { startedAt: Timestamp.fromDate(new Date('2026-10-20T14:00:00Z')) });
    await Promise.all([processSession(db, 'kid-a', 's1', now), processSession(db, 'kid-a', 's2', now)]);
    const stats = (await db.doc('profiles/kid-a/stats/lifetime').get()).data()!;
    expect(stats.workouts).toBe(2);
    expect(stats.shots).toBe(20);
  });

  it('adds up across sessions and keeps the better best', async () => {
    await writeSession('s1', [corner(9)]);
    await processSession(db, 'kid-a', 's1', now);
    await writeSession('s2', [corner(5)], { startedAt: Timestamp.fromDate(new Date('2026-10-21T01:00:00Z')) }, 'kid-a');
    const outcome = await processSession(db, 'kid-a', 's2', new Date('2026-10-21T03:00:00Z'));
    expect(outcome).toEqual({ status: 'processed', newBestKeys: [] });
    const stats = (await db.doc('profiles/kid-a/stats/lifetime').get()).data()!;
    expect(stats.workouts).toBe(2);
    expect(stats.recent).toEqual(['s1', 's2']);
    expect((stats.bests as { value: number }[])[0].value).toBe(90);
    expect(Object.keys(stats.days).sort()).toEqual(['2026-10-20', '2026-10-21']);
  });

  it("uses the player's own time zone for the day", async () => {
    await writeSession('s1', [corner(7)], { startedAt: Timestamp.fromDate(new Date('2026-10-21T02:00:00Z')), tzOffsetMinutes: -300 });
    await processSession(db, 'kid-a', 's1', new Date('2026-10-21T03:00:00Z'));
    expect(Object.keys((await db.doc('profiles/kid-a/stats/lifetime').get()).data()!.days)).toEqual(['2026-10-20']);
  });

  it('uses the catalog for known drills, so inflated numbers from a phone change nothing', async () => {
    await writeSession('s1', [corner(7, 10, { skillWeights: { hands: 1 }, trackingType: 'volume', estimatedSecondsPerSet: 600 })]);
    await processSession(db, 'kid-a', 's1', now);
    const stats = (await db.doc('profiles/kid-a/stats/lifetime').get()).data()!;
    expect(stats.seconds).toBe(60);
    expect(stats.pillarSeconds.hands).toBeUndefined();
    expect(stats.pillarSeconds.shotAccuracy).toBeCloseTo(48);
  });

  it('accepts custom drills within sane limits and ignores the rest', async () => {
    const custom = (extra: Record<string, unknown>) => ({ drillId: 'custom-hands-1', title: 'Custom puck control', trackingType: 'volume', skillWeights: { hands: 1 }, estimatedSecondsPerSet: 50, sets: [set({ reps: 10 })], ...extra });
    await writeSession('s1', [custom({}), custom({ drillId: 'custom-x', skillWeights: { hands: 1, passing: 1 } }), custom({ drillId: 'custom-y', estimatedSecondsPerSet: 99999 }), custom({ drillId: 'custom-z', trackingType: 'nonsense' })]);
    await processSession(db, 'kid-a', 's1', now);
    const stats = (await db.doc('profiles/kid-a/stats/lifetime').get()).data()!;
    expect(stats.seconds).toBe(50);
    expect(stats.pillarSeconds).toEqual({ hands: 50 });
  });

  it('rejects sessions that are unfinished, from the future, too old, or empty, without crediting them', async () => {
    await writeSession('open', [corner(7)], { status: 'active' });
    await writeSession('future', [corner(7)], { startedAt: Timestamp.fromDate(new Date('2026-12-25T00:00:00Z')) });
    await writeSession('old', [corner(7)], { startedAt: Timestamp.fromDate(new Date('2024-01-01T00:00:00Z')) });
    await writeSession('empty', []);
    await writeSession('junk', [{ drillId: 'pick-your-corner', sets: [{ reps: 'lots' }] }]);
    for (const id of ['open', 'future', 'old', 'empty', 'junk']) {
      const outcome = await processSession(db, 'kid-a', id, now);
      expect(outcome.status, id).toBe('rejected');
      expect((await db.doc(`profiles/kid-a/sessions/${id}`).get()).data()!.rejected, id).toBeTruthy();
    }
    expect((await db.doc('profiles/kid-a/stats/lifetime').get()).exists).toBe(false);
  });

  it('keeps each profile separate', async () => {
    await writeSession('s1', [corner(7)], {}, 'kid-a');
    await writeSession('s1', [corner(9)], {}, 'kid-b');
    await processSession(db, 'kid-a', 's1', now);
    await processSession(db, 'kid-b', 's1', now);
    expect((await db.doc('profiles/kid-a/stats/lifetime').get()).data()!.bests[0].value).toBe(70);
    expect((await db.doc('profiles/kid-b/stats/lifetime').get()).data()!.bests[0].value).toBe(90);
  });
});
