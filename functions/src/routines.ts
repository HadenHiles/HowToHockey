import type { Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { requireAccount, type CallerAuth } from './profiles';
import { cleanRoutine } from './teams';

type Input = { profileId?: unknown; routineId?: unknown; routine?: unknown };

/** Everyone without a subscription keeps up to this many saved routines per player. */
export const FREE_ROUTINE_LIMIT = 3;

const id = (value: unknown, what: string) => {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new HttpsError('invalid-argument', `Choose a valid ${what}.`);
  return value;
};

/** A parent saves (or replaces) one of their child's routines: library drills and set counts, nothing else. */
export async function saveProfileRoutine(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  const profileId = id(data.profileId, 'player');
  const routine = cleanRoutine(data.routine);
  const profileRef = db.doc(`profiles/${profileId}`);
  const routines = profileRef.collection('routines');
  const ref = data.routineId == null ? routines.doc() : routines.doc(id(data.routineId, 'routine'));
  await db.runTransaction(async (tx) => {
    const profile = await tx.get(profileRef);
    if (!profile.exists || profile.data()!.ownerUid !== auth.uid) throw new HttpsError('permission-denied', 'Only the parent can change these routines.');
    const [existing, all] = await Promise.all([tx.get(ref), tx.get(routines)]);
    if (!existing.exists && !profile.data()!.pro && all.size >= FREE_ROUTINE_LIMIT) {
      throw new HttpsError('resource-exhausted', `You can keep up to ${FREE_ROUTINE_LIMIT} saved routines. Delete one to save another, or go Pro for unlimited.`);
    }
    tx.set(ref, { ...routine, updatedAt: new Date(), updatedBy: auth.uid, ...(existing.exists ? { createdAt: existing.data()!.createdAt } : { createdAt: new Date() }) });
  });
  return { routineId: ref.id };
}

export async function deleteProfileRoutine(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  const profileId = id(data.profileId, 'player');
  const profileRef = db.doc(`profiles/${profileId}`);
  const ref = profileRef.collection('routines').doc(id(data.routineId, 'routine'));
  await db.runTransaction(async (tx) => {
    const profile = await tx.get(profileRef);
    if (!profile.exists || profile.data()!.ownerUid !== auth.uid) throw new HttpsError('permission-denied', 'Only the parent can change these routines.');
    tx.delete(ref);
  });
  return { deleted: true };
}
