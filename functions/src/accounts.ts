import { HttpsError } from 'firebase-functions/v2/https';
import type { Firestore } from 'firebase-admin/firestore';

import { requireAccount, type CallerAuth } from './profiles';

export interface UserEraser {
  deleteUsers(uids: string[]): Promise<unknown>;
}

/**
 * Deletes an account and everything it owns: its own profile, every child profile (with their
 * sessions and stats), pairing codes, paired kid-device sign-ins and the account document.
 * The sign-in itself goes last, so a failure part-way can simply be retried.
 */
export async function deleteAccount(db: Firestore, eraser: UserEraser, caller: CallerAuth | undefined, data: { confirm?: unknown }) {
  const account = requireAccount(caller);
  if (data.confirm !== true) throw new HttpsError('invalid-argument', 'Confirm that you want to delete this account.');

  const owned = await db.collection('profiles').where('ownerUid', '==', account.uid).get();
  const kidUids: string[] = [];
  for (const profile of owned.docs) {
    for (const code of (await db.collection('pairingCodes').where('profileId', '==', profile.id).get()).docs) await code.ref.delete();
    await db.recursiveDelete(profile.ref);
    if (profile.data().isChild === true) kidUids.push(`kid-${profile.id}`);
  }
  await db.recursiveDelete(db.collection('users').doc(account.uid));
  // Missing users are reported, not thrown, so this is safe for kids who never paired a device.
  await eraser.deleteUsers([...kidUids, account.uid]);
  return { deleted: true, profiles: owned.size };
}
