import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { createPairingCode, hashCode, PAIRING_CODE_MINUTES, redeemPairingCode, type TokenMinter } from '../src/pairing';

const now = new Date('2026-10-19T12:00:00Z');
const parent = { uid: 'parent-1', isAnonymous: false };
const minter: TokenMinter = { createCustomToken: async (uid, claims) => `token:${uid}:${JSON.stringify(claims)}` };

let app: App;
let db: Firestore;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !/^(127\.0\.0\.1|localhost|\[::1\])/.test(process.env.FIRESTORE_EMULATOR_HOST)) {
    throw new Error('These tests must run against the local Firestore emulator.');
  }
  app = initializeApp({ projectId: 'demo-how-to-hockey' }, 'pairing-tests');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-how-to-hockey/databases/(default)/documents`, { method: 'DELETE' });
  await db.collection('profiles').doc('kid-a').set({ ownerUid: 'parent-1', displayName: 'Avery H.', isChild: true });
  await db.collection('profiles').doc('kid-b').set({ ownerUid: 'other', displayName: 'Riley H.', isChild: true });
  await db.collection('profiles').doc('parent-1').set({ ownerUid: 'parent-1', displayName: 'Pat H.', isChild: false });
});

describe('createPairingCode', () => {
  it('stores only a hash and expires after the pairing window', async () => {
    const result = await createPairingCode(db, parent, { profileId: 'kid-a' }, now, () => '12345678');
    expect(result).toEqual({ code: '12345678', expiresAtMillis: now.getTime() + PAIRING_CODE_MINUTES * 60_000 });
    const docs = (await db.collection('pairingCodes').get()).docs;
    expect(docs.map((d) => d.id)).toEqual([hashCode('12345678')]);
    expect(JSON.stringify(docs[0].data())).not.toContain('12345678');
  });

  it('replaces the earlier code for the same child', async () => {
    await createPairingCode(db, parent, { profileId: 'kid-a' }, now, () => '11111111');
    await createPairingCode(db, parent, { profileId: 'kid-a' }, now, () => '22222222');
    expect((await db.collection('pairingCodes').get()).docs.map((d) => d.id)).toEqual([hashCode('22222222')]);
  });

  it('refuses other people\'s children, the parent\'s own profile, guests and signed-out callers', async () => {
    await expect(createPairingCode(db, parent, { profileId: 'kid-b' }, now)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(createPairingCode(db, parent, { profileId: 'parent-1' }, now)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(createPairingCode(db, parent, { profileId: 'missing' }, now)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(createPairingCode(db, { uid: 'g', isAnonymous: true }, { profileId: 'kid-a' }, now)).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(createPairingCode(db, { uid: 'kid-kid-a', isAnonymous: false, isKidDevice: true }, { profileId: 'kid-a' }, now)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(createPairingCode(db, undefined, { profileId: 'kid-a' }, now)).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('picks another code when one is already live for a different child', async () => {
    await db.collection('pairingCodes').doc(hashCode('11111111')).set({ profileId: 'kid-x', ownerUid: 'z', expiresAt: now });
    const codes = ['11111111', '33333333'];
    const result = await createPairingCode(db, parent, { profileId: 'kid-a' }, now, () => codes.shift()!);
    expect(result.code).toBe('33333333');
  });
});

describe('redeemPairingCode', () => {
  it('gives a token locked to the child, once', async () => {
    await createPairingCode(db, parent, { profileId: 'kid-a' }, now, () => '12345678');
    const result = await redeemPairingCode(db, minter, { code: ' 12345678 ' }, new Date(now.getTime() + 60_000));
    expect(result).toEqual({ token: 'token:kid-kid-a:{"profileId":"kid-a"}', profileId: 'kid-a', displayName: 'Avery H.' });
    await expect(redeemPairingCode(db, minter, { code: '12345678' }, now)).rejects.toMatchObject({ code: 'not-found' });
  });

  it('refuses expired codes and uses them up', async () => {
    await createPairingCode(db, parent, { profileId: 'kid-a' }, now, () => '12345678');
    const late = new Date(now.getTime() + (PAIRING_CODE_MINUTES + 1) * 60_000);
    await expect(redeemPairingCode(db, minter, { code: '12345678' }, late)).rejects.toMatchObject({ code: 'not-found' });
    expect((await db.collection('pairingCodes').get()).size).toBe(0);
  });

  it('refuses malformed and unknown codes with the same answer', async () => {
    for (const code of [undefined, 12345678, '1234', 'abcdefgh', '99999999']) {
      await expect(redeemPairingCode(db, minter, { code }, now)).rejects.toMatchObject({ code: 'not-found', message: 'That code didn\'t work. Ask your parent for a new one.' });
    }
  });

  it('lets only one of two simultaneous redemptions win', async () => {
    await createPairingCode(db, parent, { profileId: 'kid-a' }, now, () => '12345678');
    const results = await Promise.allSettled([redeemPairingCode(db, minter, { code: '12345678' }, now), redeemPairingCode(db, minter, { code: '12345678' }, now)]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
  });
});
