import { HttpsError } from 'firebase-functions/v2/https';
import type { Firestore } from 'firebase-admin/firestore';

export const MAX_CHILD_PROFILES = 3;
export const ACCOUNT_MIN_YEARS = 14;
export const CHILD_MAX_YEARS = 17;

/** Display names are a first name and a last initial, such as "Jamie H." */
const NAME_PATTERN = /^(\p{L}[\p{L}'’-]{0,23}) (\p{L})\.?$/u;

export function normalizeDisplayName(input: unknown): string {
  if (typeof input !== 'string') {
    throw new HttpsError('invalid-argument', 'Enter a first name and last initial.');
  }
  const match = NAME_PATTERN.exec(input.normalize('NFC').trim().replace(/\s+/g, ' '));
  if (!match) {
    throw new HttpsError('invalid-argument', 'Use a first name and last initial, like "Jamie H."');
  }
  const [, first, initial] = match;
  const capitalized = first.charAt(0).toLocaleUpperCase() + first.slice(1);
  return `${capitalized} ${initial.toLocaleUpperCase()}.`;
}

export function validateBirthYear(input: unknown, now: Date): number {
  if (typeof input !== 'number' || !Number.isInteger(input)) {
    throw new HttpsError('invalid-argument', 'Enter a birth year.');
  }
  const thisYear = now.getUTCFullYear();
  if (input < thisYear - 100 || input > thisYear) {
    throw new HttpsError('invalid-argument', 'That birth year doesn\'t look right.');
  }
  return input;
}

/**
 * Only the birth year is collected, so ages are read cautiously from the year difference:
 * an account holder needs 14 or more years since birth (so they are certainly 13+), and a child
 * profile needs 17 or fewer (so they are certainly a minor).
 */
export function yearsSinceBirthYear(birthYear: number, now: Date): number {
  return now.getUTCFullYear() - birthYear;
}

/** Whether the account that owns a new profile already holds Player Pro or Coach Pro. */
function planOf(user: FirebaseFirestore.DocumentData | undefined): boolean {
  return (user?.entitlements as { playerPro?: boolean } | undefined)?.playerPro === true;
}

export interface CallerAuth {
  uid: string;
  isAnonymous: boolean;
  /** Signed in with a pairing code: it can act as one child and nothing else. */
  isKidDevice?: boolean;
  email?: string;
}

export function requireAccount(auth: CallerAuth | undefined): CallerAuth {
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Sign in to continue.');
  }
  if (auth.isKidDevice) {
    throw new HttpsError('permission-denied', 'Ask a parent to do this from their own account.');
  }
  if (auth.isAnonymous) {
    throw new HttpsError('failed-precondition', 'Create an account first so profiles are not lost.');
  }
  return auth;
}

/**
 * Creates a child profile for the signed-in parent. Anyone with an account can, on any plan,
 * up to MAX_CHILD_PROFILES. Children never get their own account.
 */
export async function createChildProfile(db: Firestore, caller: CallerAuth | undefined, data: { displayName?: unknown; birthYear?: unknown }, now: Date = new Date()) {
  const auth = requireAccount(caller);
  const displayName = normalizeDisplayName(data.displayName);
  const birthYear = validateBirthYear(data.birthYear, now);
  if (yearsSinceBirthYear(birthYear, now) > CHILD_MAX_YEARS) {
    throw new HttpsError('invalid-argument', 'Child profiles are for players 17 and under.');
  }

  const profiles = db.collection('profiles');
  const userRef = db.collection('users').doc(auth.uid);
  const profileRef = profiles.doc();
  await db.runTransaction(async (transaction) => {
    // Firestore requires every read in a transaction to happen before any write.
    const existing = await transaction.get(profiles.where('ownerUid', '==', auth.uid).where('isChild', '==', true));
    const user = await transaction.get(userRef);
    if (existing.size >= MAX_CHILD_PROFILES) {
      throw new HttpsError('failed-precondition', `You can add up to ${MAX_CHILD_PROFILES} child profiles.`);
    }
    const roles: string[] = (user.data()?.roles as string[] | undefined) ?? [];
    transaction.set(profileRef, { ownerUid: auth.uid, displayName, birthYear, isChild: true, teamIds: [], pro: planOf(user.data()), createdAt: now });
    transaction.set(userRef, { roles: roles.includes('parent') ? roles : [...roles, 'parent'], createdAt: user.data()?.createdAt ?? now }, { merge: true });
  });
  return { profileId: profileRef.id, displayName };
}

/**
 * Creates the signed-in adult's own player profile, once. Under-13s cannot have an account at all,
 * so this refuses anyone who could be younger than 13.
 */
export async function createOwnProfile(db: Firestore, caller: CallerAuth | undefined, data: { displayName?: unknown; birthYear?: unknown }, now: Date = new Date()) {
  const auth = requireAccount(caller);
  const displayName = normalizeDisplayName(data.displayName);
  const birthYear = validateBirthYear(data.birthYear, now);
  if (yearsSinceBirthYear(birthYear, now) < ACCOUNT_MIN_YEARS) {
    throw new HttpsError('failed-precondition', 'Players under 13 can\'t have their own account. A parent can set up a child profile.');
  }

  const profileRef = db.collection('profiles').doc(auth.uid);
  const userRef = db.collection('users').doc(auth.uid);
  await db.runTransaction(async (transaction) => {
    if ((await transaction.get(profileRef)).exists) {
      throw new HttpsError('already-exists', 'You already have a player profile.');
    }
    const user = await transaction.get(userRef);
    const roles: string[] = user.exists ? ((user.data()?.roles as string[] | undefined) ?? []) : [];
    transaction.set(profileRef, { ownerUid: auth.uid, displayName, birthYear, isChild: false, teamIds: [], pro: planOf(user.data()), createdAt: now });
    transaction.set(userRef, { roles: roles.includes('player') ? roles : [...roles, 'player'], createdAt: user.exists ? (user.data()?.createdAt ?? now) : now, ...(auth.email ? { email: auth.email } : {}) }, { merge: true });
  });
  return { profileId: profileRef.id, displayName };
}
