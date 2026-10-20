import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { handleRevenueCatWebhook } from '../src/entitlements';
import { createChildProfile } from '../src/profiles';

const secret = 'Bearer shhh';
const now = new Date('2026-10-20T12:00:00Z');
const active = { subscriber: { entitlements: { player_pro: { expires_date: '2027-01-01T00:00:00Z' } } } };
const none = { subscriber: { entitlements: {} } };

let app: App;
let db: Firestore;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !/^(127\.0\.0\.1|localhost|\[::1\])/.test(process.env.FIRESTORE_EMULATOR_HOST)) {
    throw new Error('These tests must run against the local Firestore emulator.');
  }
  app = initializeApp({ projectId: 'demo-how-to-hockey' }, 'entitlements-tests');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-how-to-hockey/databases/(default)/documents`, { method: 'DELETE' });
  await db.collection('users').doc('parent-1').set({ roles: ['player', 'parent'] });
  await db.collection('profiles').doc('parent-1').set({ ownerUid: 'parent-1', isChild: false, pro: false });
  await db.collection('profiles').doc('kid-a').set({ ownerUid: 'parent-1', isChild: true, pro: false });
  await db.collection('profiles').doc('other').set({ ownerUid: 'other', isChild: false, pro: false });
  await db.collection('users').doc('other').set({ roles: ['player'] });
});

function deliver(body: unknown, plans: Record<string, unknown>, authorization: string | null = secret) {
  return handleRevenueCatWebhook({ authorization: authorization ?? undefined, body }, { db, expectedAuthorization: secret, fetchSubscriber: async (uid) => plans[uid] ?? none, now });
}

const purchase = { event: { type: 'INITIAL_PURCHASE', app_user_id: 'parent-1' } };

describe('revenueCatWebhook', () => {
  it('turns Pro on for the account and every profile it owns, and nobody else', async () => {
    expect(await deliver(purchase, { 'parent-1': active })).toEqual({ status: 200, message: 'Updated 1.' });
    expect((await db.collection('users').doc('parent-1').get()).data()?.entitlements).toMatchObject({ playerPro: true, coachPro: false });
    expect((await db.collection('profiles').doc('parent-1').get()).data()?.pro).toBe(true);
    expect((await db.collection('profiles').doc('kid-a').get()).data()?.pro).toBe(true);
    expect((await db.collection('profiles').doc('other').get()).data()?.pro).toBe(false);
    expect((await db.collection('users').doc('parent-1').get()).data()?.roles).toEqual(['player', 'parent']);
  });

  it('turns Pro off again when the plan has ended', async () => {
    await deliver(purchase, { 'parent-1': active });
    await deliver({ event: { type: 'EXPIRATION', app_user_id: 'parent-1' } }, { 'parent-1': none });
    expect((await db.collection('profiles').doc('kid-a').get()).data()?.pro).toBe(false);
    expect((await db.collection('users').doc('parent-1').get()).data()?.entitlements).toMatchObject({ playerPro: false });
  });

  it('is safe to repeat and re-reads the truth, so a stale event cannot undo a newer purchase', async () => {
    await deliver(purchase, { 'parent-1': active });
    await deliver({ event: { type: 'CANCELLATION', app_user_id: 'parent-1' } }, { 'parent-1': active });
    expect((await db.collection('profiles').doc('parent-1').get()).data()?.pro).toBe(true);
  });

  it('refreshes both accounts when a purchase is transferred', async () => {
    await deliver(purchase, { 'parent-1': active });
    await deliver({ event: { type: 'TRANSFER', transferred_from: ['parent-1'], transferred_to: ['other'] } }, { 'parent-1': none, other: active });
    expect((await db.collection('profiles').doc('parent-1').get()).data()?.pro).toBe(false);
    expect((await db.collection('profiles').doc('other').get()).data()?.pro).toBe(true);
  });

  it('ignores accounts that no longer exist instead of recreating them', async () => {
    expect(await deliver({ event: { type: 'RENEWAL', app_user_id: 'deleted-user' } }, { 'deleted-user': active })).toEqual({ status: 200, message: 'Updated 0.' });
    expect((await db.collection('users').doc('deleted-user').get()).exists).toBe(false);
  });

  it('refuses a wrong or missing secret without reading or writing anything', async () => {
    expect((await deliver(purchase, { 'parent-1': active }, 'Bearer nope')).status).toBe(401);
    expect((await deliver(purchase, { 'parent-1': active }, null)).status).toBe(401);
    expect((await db.collection('profiles').doc('parent-1').get()).data()?.pro).toBe(false);
  });

  it('rejects a body without an event', async () => {
    expect((await deliver({}, {})).status).toBe(400);
    expect((await deliver(null, {})).status).toBe(400);
  });

  it('gives a child profile created later the plan the account already has', async () => {
    await deliver(purchase, { 'parent-1': active });
    const { profileId } = await createChildProfile(db, { uid: 'parent-1', isAnonymous: false }, { displayName: 'Avery H.', birthYear: 2015 }, now);
    expect((await db.collection('profiles').doc(profileId).get()).data()?.pro).toBe(true);
  });
});
