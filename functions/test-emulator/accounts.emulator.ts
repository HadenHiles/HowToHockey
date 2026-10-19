import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { deleteAccount, type UserEraser } from '../src/accounts';
import { hashCode } from '../src/pairing';

const parent = { uid: 'parent-1', isAnonymous: false };
let app: App;
let db: Firestore;
let erased: string[];
const eraser: UserEraser = { deleteUsers: async (uids) => void erased.push(...uids) };

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !/^(127\.0\.0\.1|localhost|\[::1\])/.test(process.env.FIRESTORE_EMULATOR_HOST)) {
    throw new Error('These tests must run against the local Firestore emulator.');
  }
  app = initializeApp({ projectId: 'demo-how-to-hockey' }, 'accounts-tests');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  erased = [];
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-how-to-hockey/databases/(default)/documents`, { method: 'DELETE' });
  await db.collection('users').doc('parent-1').set({ roles: ['player', 'parent'] });
  await db.collection('users').doc('other').set({ roles: ['player'] });
  await db.collection('profiles').doc('parent-1').set({ ownerUid: 'parent-1', isChild: false });
  await db.collection('profiles').doc('kid-a').set({ ownerUid: 'parent-1', isChild: true });
  await db.collection('profiles').doc('kid-a').collection('sessions').doc('s1').set({ minutes: 20 });
  await db.collection('profiles').doc('other').set({ ownerUid: 'other', isChild: false });
  await db.collection('pairingCodes').doc(hashCode('12345678')).set({ profileId: 'kid-a', ownerUid: 'parent-1', expiresAt: new Date() });
  await db.collection('pairingCodes').doc(hashCode('87654321')).set({ profileId: 'other', ownerUid: 'other', expiresAt: new Date() });
});

describe('deleteAccount', () => {
  it('removes the account, its profiles with their sessions, codes and kid sign-ins, and nothing else', async () => {
    const result = await deleteAccount(db, eraser, parent, { confirm: true });
    expect(result).toEqual({ deleted: true, profiles: 2 });
    expect((await db.collection('profiles').doc('parent-1').get()).exists).toBe(false);
    expect((await db.collection('profiles').doc('kid-a').get()).exists).toBe(false);
    expect((await db.collection('profiles').doc('kid-a').collection('sessions').get()).size).toBe(0);
    expect((await db.collection('users').doc('parent-1').get()).exists).toBe(false);
    expect((await db.collection('pairingCodes').get()).docs.map((d) => d.id)).toEqual([hashCode('87654321')]);
    expect(erased).toEqual(['kid-kid-a', 'parent-1']);
    expect((await db.collection('profiles').doc('other').get()).exists).toBe(true);
    expect((await db.collection('users').doc('other').get()).exists).toBe(true);
  });

  it('can be run again after finishing', async () => {
    await deleteAccount(db, eraser, parent, { confirm: true });
    await expect(deleteAccount(db, eraser, parent, { confirm: true })).resolves.toMatchObject({ deleted: true, profiles: 0 });
  });

  it('needs explicit confirmation, a real account, and not a kid device', async () => {
    await expect(deleteAccount(db, eraser, parent, {})).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(deleteAccount(db, eraser, parent, { confirm: 'yes' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(deleteAccount(db, eraser, undefined, { confirm: true })).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(deleteAccount(db, eraser, { uid: 'kid-kid-a', isAnonymous: false, isKidDevice: true }, { confirm: true })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(deleteAccount(db, eraser, { uid: 'g', isAnonymous: true }, { confirm: true })).rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await db.collection('profiles').doc('kid-a').get()).exists).toBe(true);
    expect(erased).toEqual([]);
  });
});
