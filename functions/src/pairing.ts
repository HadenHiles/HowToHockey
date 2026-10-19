import { createHash, randomInt } from 'node:crypto';

import { HttpsError } from 'firebase-functions/v2/https';
import type { Firestore } from 'firebase-admin/firestore';

import type { CallerAuth } from './profiles';

export const PAIRING_CODE_MINUTES = 10;
const CODE_PATTERN = /^\d{8}$/;

export interface TokenMinter {
  createCustomToken(uid: string, claims: Record<string, unknown>): Promise<string>;
}

/** Codes are stored hashed, so reading the database never reveals a usable code. */
export function hashCode(code: string): string {
  return createHash('sha256').update(code).digest('hex');
}

export function newPairingCode(): string {
  return randomInt(0, 100_000_000).toString().padStart(8, '0');
}

/**
 * A parent asks for a short-lived, single-use code for one of their child profiles. Asking again
 * replaces any earlier code for that child.
 */
export async function createPairingCode(db: Firestore, caller: CallerAuth | undefined, data: { profileId?: unknown }, now: Date = new Date(), makeCode: () => string = newPairingCode) {
  if (!caller) throw new HttpsError('unauthenticated', 'Sign in to continue.');
  if (caller.isAnonymous) throw new HttpsError('failed-precondition', 'Create an account first.');
  if (typeof data.profileId !== 'string' || data.profileId.length === 0) throw new HttpsError('invalid-argument', 'Choose a child first.');

  const profile = await db.collection('profiles').doc(data.profileId).get();
  if (!profile.exists || profile.data()?.ownerUid !== caller.uid || profile.data()?.isChild !== true) {
    throw new HttpsError('permission-denied', 'You can only pair devices for your own child profiles.');
  }

  const codes = db.collection('pairingCodes');
  const expiresAt = new Date(now.getTime() + PAIRING_CODE_MINUTES * 60_000);
  for (const old of (await codes.where('profileId', '==', data.profileId).get()).docs) await old.ref.delete();
  for (let attempt = 0; attempt < 5; attempt++) {
    const code = makeCode();
    try {
      await codes.doc(hashCode(code)).create({ profileId: data.profileId, ownerUid: caller.uid, expiresAt });
      return { code, expiresAtMillis: expiresAt.getTime() };
    } catch (error) {
      if ((error as { code?: number }).code !== 6) throw error; // 6 = ALREADY_EXISTS: another child's live code collided, pick again.
    }
  }
  throw new HttpsError('internal', 'Something went wrong. Try again.');
}

/**
 * The kid's device trades a valid code for a sign-in token locked to that one profile.
 * A code works once, and only until it expires.
 */
export async function redeemPairingCode(db: Firestore, minter: TokenMinter, data: { code?: unknown }, now: Date = new Date()) {
  const refused = new HttpsError('not-found', 'That code didn\'t work. Ask your parent for a new one.');
  if (typeof data.code !== 'string' || !CODE_PATTERN.test(data.code.trim())) throw refused;

  const codeRef = db.collection('pairingCodes').doc(hashCode(data.code.trim()));
  const profileId = await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(codeRef);
    if (!snapshot.exists) throw refused;
    transaction.delete(codeRef); // Expired codes are used up too; throwing here would roll the delete back.
    return snapshot.data()!.expiresAt.toDate() <= now ? undefined : (snapshot.data()!.profileId as string);
  });
  if (!profileId) throw refused;

  const profile = await db.collection('profiles').doc(profileId).get();
  if (!profile.exists) throw refused;
  const token = await minter.createCustomToken(`kid-${profileId}`, { profileId });
  return { token, profileId, displayName: profile.data()!.displayName as string };
}
