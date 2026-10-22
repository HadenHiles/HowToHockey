import type { Firestore, Timestamp } from 'firebase-admin/firestore';

import { addWorkout, DEFAULT_TUNING, emptyStats, PILLARS, type Best, type DrillSpec, type Pillar, type SetLog, type Stats, type Tracking, type Tuning, type WorkoutInput } from './progress';
import { programContent } from './programs';

const TRACKING: Tracking[] = ['volume', 'duration', 'density', 'accuracy', 'streak', 'binary'];
const MAX_SETS = 300;
const MAX_AGE_DAYS = 400;
/** Session IDs kept on the stats document so a phone can tell which of its workouts are already counted. */
const RECENT_IDS = 30;

export type Outcome = { status: 'skipped' } | { status: 'rejected'; reason: string } | { status: 'processed'; newBestKeys: string[] };

const num = (value: unknown): number | null => (typeof value === 'number' && Number.isFinite(value) ? value : null);
const millis = (value: unknown): number | null => (value && typeof (value as Timestamp).toMillis === 'function' ? (value as Timestamp).toMillis() : num(value));

function cleanLog(raw: Record<string, unknown>): SetLog | null {
  const loggedAtMs = millis(raw.loggedAt);
  if (loggedAtMs == null) return null;
  const optional = (v: unknown) => (v == null ? null : num(v));
  const log: SetLog = { reps: optional(raw.reps), hits: optional(raw.hits), seconds: optional(raw.seconds), streak: optional(raw.streak), completed: typeof raw.completed === 'boolean' ? raw.completed : null, loggedAtMs };
  return log;
}

/** Weights from a session snapshot, kept only when they look sane. */
function cleanWeights(raw: unknown): Partial<Record<Pillar, number>> {
  const out: Partial<Record<Pillar, number>> = {};
  let total = 0;
  if (raw && typeof raw === 'object') {
    for (const pillar of PILLARS) {
      const weight = num((raw as Record<string, unknown>)[pillar]);
      if (weight != null && weight > 0 && weight <= 1) {
        out[pillar] = weight;
        total += weight;
      }
    }
  }
  if (total > 1.0001) return {};
  return out;
}

type Built = { workout: WorkoutInput } | { reject: string };

/** Turns a stored session (its drills, plus the catalog's numbers for known drills) into what the credit maths needs. */
function buildWorkout(sessionId: string, data: Record<string, unknown>, drills: { id: string; data: Record<string, unknown> }[], catalog: Map<string, Record<string, unknown>>, now: Date): Built {
  const startedAtMs = millis(data.startedAt);
  if (data.status !== 'completed' || startedAtMs == null) return { reject: 'not a finished session' };
  if (startedAtMs > now.getTime() + 86_400_000 || startedAtMs < now.getTime() - MAX_AGE_DAYS * 86_400_000) return { reject: 'date out of range' };
  const tz = num(data.tzOffsetMinutes) ?? 0;
  const tzOffsetMinutes = Math.max(-840, Math.min(840, Math.round(tz)));

  const sets: WorkoutInput['sets'] = [];
  for (const doc of [...drills].sort((a, b) => Number(a.id) - Number(b.id))) {
    const d = doc.data;
    const drillId = typeof d.drillId === 'string' ? d.drillId : '';
    const known = catalog.get(drillId);
    const tracking = (known?.trackingType ?? d.trackingType) as Tracking;
    if (!drillId || !TRACKING.includes(tracking)) continue;
    const weights = known ? cleanWeights(known.skillWeights) : cleanWeights(d.skillWeights);
    const estimated = num(known?.estimatedSecondsPerSet ?? d.estimatedSecondsPerSet);
    if (Object.keys(weights).length === 0 || estimated == null || estimated < 1 || estimated > 600) continue;
    const spec: DrillSpec = { id: drillId, title: String(known?.title ?? d.title ?? drillId).slice(0, 80), tracking, weights, estimatedSecondsPerSet: Math.round(estimated) };
    for (const raw of Array.isArray(d.sets) ? d.sets : []) {
      const log = raw && typeof raw === 'object' ? cleanLog(raw as Record<string, unknown>) : null;
      if (log) sets.push({ drill: spec, log });
    }
  }
  if (sets.length === 0) return { reject: 'no usable sets' };
  if (sets.length > MAX_SETS) return { reject: 'too many sets' };
  const corrected = num(data.correctedSeconds);
  return { workout: { id: sessionId, startedAtMs, tzOffsetMinutes, sets, ...(corrected != null ? { secondsOverride: corrected } : {}) } };
}

const knownDrills = async (db: Firestore, drillDocs: { data: Record<string, unknown> }[], read: (ref: FirebaseFirestore.DocumentReference) => Promise<FirebaseFirestore.DocumentSnapshot>) => {
  const ids = [...new Set(drillDocs.map((d) => d.data.drillId).filter((id): id is string => typeof id === 'string' && id.length > 0 && id.length < 100 && !id.includes('/')))];
  const docs = await Promise.all(ids.map((id) => read(db.collection('drills').doc(id))));
  return new Map(docs.filter((d) => d.exists).map((d) => [d.id, d.data()!]));
};

/**
 * Credits a finished session to its profile, once. Drills in the catalog use the catalog's numbers, so
 * a doctored phone can't change what a drill is worth; custom and manual drills use their own, within sane limits.
 */
export async function processSession(db: Firestore, profileId: string, sessionId: string, now: Date = new Date(), tuning: Tuning = DEFAULT_TUNING): Promise<Outcome> {
  const profileRef = db.collection('profiles').doc(profileId);
  const sessionRef = profileRef.collection('sessions').doc(sessionId);
  const statsRef = profileRef.collection('stats').doc('lifetime');

  return db.runTransaction(async (tx): Promise<Outcome> => {
    const session = await tx.get(sessionRef);
    if (!session.exists || session.data()?.processedAt) return { status: 'skipped' };
    const data = session.data()!;
    // A child's workout waits for a parent to confirm it; nothing is credited until then.
    if (data.status === 'pending') return { status: 'skipped' };
    const drillDocs = (await tx.get(sessionRef.collection('drills'))).docs.map((d) => ({ id: d.id, data: d.data() }));
    const catalog = await knownDrills(db, drillDocs, (ref) => tx.get(ref));
    const statsSnap = await tx.get(statsRef);
    let programRunRef: FirebaseFirestore.DocumentReference | undefined;
    let programRun: FirebaseFirestore.DocumentData | undefined;
    let programProgressRef: FirebaseFirestore.DocumentReference | undefined;
    let programProgress: FirebaseFirestore.DocumentData | undefined;
    if (typeof data.programRunId === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(data.programRunId)) {
      programRunRef = profileRef.collection('programRuns').doc(data.programRunId);
      const runSnap = await tx.get(programRunRef);
      if (runSnap.exists && runSnap.data()?.status === 'started') {
        programRun = runSnap.data();
        if (typeof programRun?.programId === 'string' && typeof programRun.day === 'number') {
          programProgressRef = profileRef.collection('programs').doc(programRun.programId);
          programProgress = (await tx.get(programProgressRef)).data();
          const expected = programContent(programRun.programId, programRun.day);
          const orderedDrills = [...drillDocs].sort((a, b) => Number(a.id) - Number(b.id));
          if (
            !expected ||
            orderedDrills.length !== expected.drillIds.length ||
            orderedDrills.some((drill, index) => drill.data.drillId !== expected.drillIds[index] || !Array.isArray(drill.data.sets) || drill.data.sets.length < expected.sets[index])
          ) {
            programRun = undefined;
            programRunRef = undefined;
            programProgressRef = undefined;
            programProgress = undefined;
          }
        } else {
          programRun = undefined;
        }
      }
    }

    const built = buildWorkout(sessionId, data, drillDocs, catalog, now);
    if ('reject' in built) {
      tx.update(sessionRef, { processedAt: now, rejected: built.reject });
      return { status: 'rejected', reason: built.reject };
    }

    const before = statsSnap.exists ? readStats(statsSnap.data()!) : emptyStats();
    const { stats, newBests } = addWorkout(before, built.workout, tuning);
    const recent = [...(Array.isArray(statsSnap.data()?.recent) ? (statsSnap.data()!.recent as string[]) : []), sessionId].slice(-RECENT_IDS);
    tx.set(statsRef, { ...writeStats(stats), recent });
    for (const best of newBests) tx.set(profileRef.collection('prs').doc(best.key), bestDoc(best));
    const sessionUpdate: Record<string, unknown> = { processedAt: now, credit: { seconds: Math.round(stats.seconds - before.seconds), shots: stats.shots - before.shots, newBestKeys: newBests.map((b) => b.key) } };
    if (programRunRef && programRun && programProgressRef) {
      const completed = Array.isArray(programProgress?.completedDays)
        ? [...new Set((programProgress.completedDays as unknown[]).filter((value): value is number => typeof value === 'number' && Number.isInteger(value) && value > 0))].sort((a, b) => a - b)
        : [];
      const day = programRun.day as number;
      if (day === completed.length + 1) completed.push(day);
      const challengeDays = Array.isArray(programProgress?.completedChallenges)
        ? [...new Set((programProgress.completedChallenges as unknown[]).filter((value): value is number => typeof value === 'number' && Number.isInteger(value) && value > 0))]
        : [];
      if (!challengeDays.includes(day)) challengeDays.push(day);
      tx.set(programProgressRef, { completedDays: completed, completedChallenges: challengeDays.sort((a, b) => a - b), updatedAt: now }, { merge: true });
      tx.update(programRunRef, { status: 'completed', completedAt: now, sessionId });
      sessionUpdate.programCompletedDay = day;
      sessionUpdate.programId = programRun.programId;
    }
    tx.update(sessionRef, sessionUpdate);
    return { status: 'processed', newBestKeys: newBests.map((b) => b.key) };
  });
}

const REBUILD_LIMIT = 500;

/**
 * Works a profile's stats and personal bests out again from its counted sessions, oldest first, honouring parent
 * corrections and removals. Used after a correction, because totals and bests can't be "un-added".
 */
export async function rebuildStats(db: Firestore, profileId: string, now: Date = new Date(), tuning: Tuning = DEFAULT_TUNING): Promise<Stats> {
  const profileRef = db.collection('profiles').doc(profileId);
  const sessions = await profileRef.collection('sessions').orderBy('startedAt', 'desc').limit(REBUILD_LIMIT).get();
  const counted = sessions.docs.filter((d) => d.data().status === 'completed' && d.data().processedAt && !d.data().rejected && !d.data().removed).reverse();
  let stats = emptyStats();
  const ids: string[] = [];
  for (const doc of counted) {
    const drillDocs = (await doc.ref.collection('drills').get()).docs.map((d) => ({ id: d.id, data: d.data() }));
    const catalog = await knownDrills(db, drillDocs, (ref) => ref.get());
    const built = buildWorkout(doc.id, doc.data(), drillDocs, catalog, now);
    if ('reject' in built) continue;
    stats = addWorkout(stats, built.workout, tuning).stats;
    ids.push(doc.id);
  }
  const prs = await profileRef.collection('prs').get();
  const batch = db.batch();
  for (const pr of prs.docs) batch.delete(pr.ref);
  for (const best of Object.values(stats.bests)) batch.set(profileRef.collection('prs').doc(best.key), bestDoc(best));
  batch.set(profileRef.collection('stats').doc('lifetime'), { ...writeStats(stats), recent: ids.slice(-RECENT_IDS) });
  await batch.commit();
  return stats;
}

function bestDoc(best: Best) {
  return { ...best, achievedAt: new Date(best.achievedAtMs) };
}

export function writeStats(stats: Stats) {
  return {
    workouts: stats.workouts,
    seconds: stats.seconds,
    shots: stats.shots,
    pillarSeconds: stats.pillarSeconds,
    bests: Object.values(stats.bests).map((b) => ({ key: b.key, drillId: b.drillId, title: b.title, kind: b.kind, value: b.value, achievedAt: new Date(b.achievedAtMs).toISOString(), workoutId: b.workoutId })),
    days: stats.days,
  };
}

export function readStats(data: Record<string, unknown>): Stats {
  const bests: Record<string, Best> = {};
  for (const raw of Array.isArray(data.bests) ? data.bests : []) {
    const b = raw as Record<string, unknown>;
    bests[String(b.key)] = { key: String(b.key), drillId: String(b.drillId), title: String(b.title), kind: b.kind as Best['kind'], value: Number(b.value), achievedAtMs: Date.parse(String(b.achievedAt)), workoutId: String(b.workoutId) };
  }
  return {
    workouts: Number(data.workouts) || 0,
    seconds: Number(data.seconds) || 0,
    shots: Number(data.shots) || 0,
    pillarSeconds: (data.pillarSeconds as Stats['pillarSeconds']) ?? {},
    bests,
    days: (data.days as Stats['days']) ?? {},
  };
}
