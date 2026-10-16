import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { createChildProfile, createOwnProfile, MAX_CHILD_PROFILES } from '../src/profiles';

const now = new Date('2026-10-16T12:00:00Z');
const parent = { uid: 'parent-1', isAnonymous: false, email: 'parent@example.com' };

let app: App;
let db: Firestore;

beforeAll(() => {
  if (!process.env.FIRESTORE_EMULATOR_HOST || !/^(127\.0\.0\.1|localhost|\[::1\])/.test(process.env.FIRESTORE_EMULATOR_HOST)) {
    throw new Error('These tests must run against the local Firestore emulator.');
  }
  app = initializeApp({ projectId: 'demo-how-to-hockey' }, 'profiles-tests');
  db = getFirestore(app);
});

afterAll(() => deleteApp(app));

beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-how-to-hockey/databases/(default)/documents`, { method: 'DELETE' });
});

const child = { displayName: 'Avery H.', birthYear: 2015 };

describe('createChildProfile', () => {
  it('creates a child profile owned by the parent and gives them the parent role', async () => {
    const result = await createChildProfile(db, parent, child, now);
    const profile = (await db.collection('profiles').doc(result.profileId).get()).data();
    expect(profile).toMatchObject({ ownerUid: 'parent-1', displayName: 'Avery H.', birthYear: 2015, isChild: true, teamIds: [] });
    expect((await db.collection('users').doc('parent-1').get()).data()?.roles).toEqual(['parent']);
  });

  it('tidies the display name on the server', async () => {
    const result = await createChildProfile(db, parent, { displayName: '  avery   h ', birthYear: 2015 }, now);
    expect(result.displayName).toBe('Avery H.');
  });

  it(`allows ${MAX_CHILD_PROFILES} children and refuses the next`, async () => {
    for (let i = 0; i < MAX_CHILD_PROFILES; i++) {
      await createChildProfile(db, parent, child, now);
    }
    await expect(createChildProfile(db, parent, child, now)).rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await db.collection('profiles').where('ownerUid', '==', 'parent-1').get()).size).toBe(MAX_CHILD_PROFILES);
  });

  it('counts children per parent, not across parents', async () => {
    for (let i = 0; i < MAX_CHILD_PROFILES; i++) {
      await createChildProfile(db, parent, child, now);
    }
    await expect(createChildProfile(db, { ...parent, uid: 'parent-2' }, child, now)).resolves.toBeTruthy();
  });

  it('never exceeds the cap when requests arrive at the same moment', async () => {
    await createChildProfile(db, parent, child, now);
    await createChildProfile(db, parent, child, now);
    const results = await Promise.allSettled([createChildProfile(db, parent, child, now), createChildProfile(db, parent, child, now), createChildProfile(db, parent, child, now)]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
    expect((await db.collection('profiles').where('isChild', '==', true).get()).size).toBe(MAX_CHILD_PROFILES);
  });

  it('does not count the parent\'s own profile toward the cap', async () => {
    await createOwnProfile(db, parent, { displayName: 'Pat H.', birthYear: 1985 }, now);
    for (let i = 0; i < MAX_CHILD_PROFILES; i++) {
      await createChildProfile(db, parent, child, now);
    }
    expect((await db.collection('users').doc('parent-1').get()).data()?.roles).toEqual(expect.arrayContaining(['player', 'parent']));
  });

  it('needs a signed-in, non-anonymous account', async () => {
    await expect(createChildProfile(db, undefined, child, now)).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(createChildProfile(db, { uid: 'anon', isAnonymous: true }, child, now)).rejects.toMatchObject({ code: 'failed-precondition' });
    expect((await db.collection('profiles').get()).size).toBe(0);
  });

  it('rejects bad names and birth years without writing anything', async () => {
    for (const bad of [{ displayName: 'Avery', birthYear: 2015 }, { displayName: 'Avery H.', birthYear: 2027 }, { displayName: 'Avery H.', birthYear: '2015' }, { displayName: 'Avery H.' }, {}]) {
      await expect(createChildProfile(db, parent, bad as never, now)).rejects.toMatchObject({ code: 'invalid-argument' });
    }
    expect((await db.collection('profiles').get()).size).toBe(0);
  });

  it('only accepts players who are certainly minors', async () => {
    await expect(createChildProfile(db, parent, { displayName: 'Sam T.', birthYear: 2008 }, now)).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(createChildProfile(db, parent, { displayName: 'Sam T.', birthYear: 2009 }, now)).resolves.toBeTruthy();
  });
});

describe('createOwnProfile', () => {
  it('creates the signed-in adult\'s profile and records their email and role', async () => {
    const result = await createOwnProfile(db, parent, { displayName: 'Pat H.', birthYear: 1985 }, now);
    expect(result.profileId).toBe('parent-1');
    expect((await db.collection('profiles').doc('parent-1').get()).data()).toMatchObject({ ownerUid: 'parent-1', isChild: false, birthYear: 1985 });
    expect((await db.collection('users').doc('parent-1').get()).data()).toMatchObject({ roles: ['player'], email: 'parent@example.com' });
  });

  it('only creates one own profile', async () => {
    await createOwnProfile(db, parent, { displayName: 'Pat H.', birthYear: 1985 }, now);
    await expect(createOwnProfile(db, parent, { displayName: 'Pat H.', birthYear: 1985 }, now)).rejects.toMatchObject({ code: 'already-exists' });
  });

  it('keeps existing roles when adding the player role', async () => {
    await createChildProfile(db, parent, child, now);
    await createOwnProfile(db, parent, { displayName: 'Pat H.', birthYear: 1985 }, now);
    expect((await db.collection('users').doc('parent-1').get()).data()?.roles).toEqual(['parent', 'player']);
  });

  it('refuses anyone who could be under 13 and allows the first safe birth year', async () => {
    await expect(createOwnProfile(db, parent, { displayName: 'Kid K.', birthYear: 2013 }, now)).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(createOwnProfile(db, parent, { displayName: 'Kid K.', birthYear: 2012 }, now)).resolves.toBeTruthy();
  });

  it('needs a signed-in, non-anonymous account', async () => {
    await expect(createOwnProfile(db, undefined, { displayName: 'Pat H.', birthYear: 1985 }, now)).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(createOwnProfile(db, { uid: 'anon', isAnonymous: true }, { displayName: 'Pat H.', birthYear: 1985 }, now)).rejects.toMatchObject({ code: 'failed-precondition' });
  });
});
