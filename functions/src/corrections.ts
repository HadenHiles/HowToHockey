import type { Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { requireAccount, type CallerAuth } from './profiles';
import { DEFAULT_TUNING, type Tuning } from './progress';
import { rebuildStats } from './sessions';

type Input = { profileId?: unknown; sessionId?: unknown; activeMinutes?: unknown; remove?: unknown };

const MIN_MINUTES = 1;
const MAX_MINUTES = 180;

const id = (value: unknown, what: string) => {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new HttpsError('invalid-argument', `Choose a valid ${what}.`);
  return value;
};

/**
 * A parent fixes or removes one of their child's counted workouts: either the training time, or the whole workout.
 * Every change is written to an audit trail (who, when, before, after) and the child's stats are worked out again.
 * Nothing is excluded automatically from leaderboards: parents and coaches decide what is fair.
 */
export async function correctSession(db: Firestore, caller: CallerAuth | undefined, data: Input, now: Date = new Date(), tuning: Tuning = DEFAULT_TUNING) {
  const auth = requireAccount(caller);
  const profileId = id(data.profileId, 'player');
  const sessionId = id(data.sessionId, 'workout');
  const remove = data.remove === true;
  let minutes: number | null = null;
  if (!remove) {
    if (typeof data.activeMinutes !== 'number' || !Number.isInteger(data.activeMinutes) || data.activeMinutes < MIN_MINUTES || data.activeMinutes > MAX_MINUTES) {
      throw new HttpsError('invalid-argument', `Training time is between ${MIN_MINUTES} and ${MAX_MINUTES} minutes.`);
    }
    minutes = data.activeMinutes;
  }

  const profileRef = db.doc(`profiles/${profileId}`);
  const sessionRef = profileRef.collection('sessions').doc(sessionId);
  await db.runTransaction(async (tx) => {
    const [profile, session] = await Promise.all([tx.get(profileRef), tx.get(sessionRef)]);
    if (!profile.exists || profile.data()!.ownerUid !== auth.uid || profile.data()!.isChild !== true) throw new HttpsError('permission-denied', 'Only a parent can change their child\'s workouts.');
    if (!session.exists || session.data()!.status !== 'completed' || session.data()!.removed) throw new HttpsError('not-found', 'That workout isn\'t there anymore.');
    if (!session.data()!.processedAt) throw new HttpsError('failed-precondition', 'That workout is still being counted. Try again in a moment.');
    const before = session.data()!;
    const beforeSeconds = typeof before.correctedSeconds === 'number' ? before.correctedSeconds : null;
    if (remove) {
      tx.update(sessionRef, { removed: true, removedAt: now });
    } else {
      tx.update(sessionRef, { correctedSeconds: minutes! * 60, correctedAt: now });
    }
    tx.create(sessionRef.collection('audits').doc(), {
      by: auth.uid,
      at: now,
      action: remove ? 'removed' : 'timeCorrected',
      beforeSeconds,
      afterSeconds: remove ? null : minutes! * 60,
      creditedSecondsBefore: typeof before.credit?.seconds === 'number' ? before.credit.seconds : null,
    });
  });
  const stats = await rebuildStats(db, profileId, now, tuning);
  return { updated: true, workouts: stats.workouts };
}
