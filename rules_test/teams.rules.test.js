import { readFile } from 'node:fs/promises';
import { after, before, beforeEach, describe, it } from 'node:test';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, query, setDoc, where } from 'firebase/firestore';

describe('team membership rules', () => {
  let env;
  const dbFor = (uid, claims = {}) => env.authenticatedContext(uid, claims).firestore();
  before(async () => {
    const host = process.env.FIRESTORE_EMULATOR_HOST;
    if (!host || !/^(127\.0\.0\.1|localhost|\[::1\]):/.test(host)) throw new Error('Local Firestore emulator required.');
    const url = new URL(`http://${host}`);
    env = await initializeTestEnvironment({
      projectId: 'demo-how-to-hockey',
      firestore: { host: url.hostname, port: Number(url.port), rules: await readFile(new URL('../firestore.rules', import.meta.url), 'utf8') },
    });
  });
  after(async () => env?.cleanup());
  beforeEach(async () => {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'teams/t1'), { name: 'Stars', visibility: 'public', coachUids: ['coach'], memberOwnerUids: ['parent'], memberProfileIds: ['kid'] });
      await setDoc(doc(db, 'teams/t1/members/kid'), { ownerUid: 'parent', displayName: 'Kid H.' });
      await setDoc(doc(db, 'teams/t1/joinRequests/other'), { ownerUid: 'other', status: 'coachPending' });
      await setDoc(doc(db, 'teamDirectory/t1'), { name: 'Stars', memberCount: 1 });
      await setDoc(doc(db, 'users/parent/teamRequests/request'), { status: 'parentPending' });
      await setDoc(doc(db, 'teamCodes/secret'), { teamId: 't1', kind: 'coach' });
    });
  });

  it('allows owner/member queries and coach queries, not arbitrary team listing', async () => {
    await assertSucceeds(getDocs(query(collection(dbFor('parent'), 'teams'), where('memberOwnerUids', 'array-contains', 'parent'))));
    await assertSucceeds(getDocs(query(collection(dbFor('coach'), 'teams'), where('coachUids', 'array-contains', 'coach'))));
    await assertSucceeds(getDocs(query(collection(dbFor('kid-kid', { profileId: 'kid' }), 'teams'), where('memberProfileIds', 'array-contains', 'kid'))));
    await assertFails(getDocs(collection(dbFor('stranger'), 'teams')));
    await assertFails(getDoc(doc(dbFor('stranger'), 'teams/t1')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'teams/t1')));
  });
  it('members, parents and coaches can read a roster, but no private player profile', async () => {
    for (const db of [dbFor('parent'), dbFor('coach'), dbFor('kid-kid', { profileId: 'kid' })]) {
      await assertSucceeds(getDocs(collection(db, 'teams/t1/members')));
    }
    await assertFails(getDocs(collection(dbFor('stranger'), 'teams/t1/members')));
    await assertFails(getDoc(doc(dbFor('coach'), 'profiles/kid')));
    await assertFails(getDoc(doc(dbFor('kid-sibling', { profileId: 'sibling' }), 'teams/t1')));
  });
  it('only coaches can list team join requests and only parents can read their approval inbox', async () => {
    await assertSucceeds(getDocs(collection(dbFor('coach'), 'teams/t1/joinRequests')));
    await assertFails(getDocs(collection(dbFor('parent'), 'teams/t1/joinRequests')));
    await assertSucceeds(getDocs(collection(dbFor('parent'), 'users/parent/teamRequests')));
    await assertFails(getDocs(collection(dbFor('coach'), 'users/parent/teamRequests')));
    await assertFails(getDocs(collection(dbFor('kid-kid', { profileId: 'kid' }), 'users/parent/teamRequests')));
  });
  it('directory is discoverable without exposing teams, codes, or private activity', async () => {
    await assertSucceeds(getDocs(collection(dbFor('stranger'), 'teamDirectory')));
    await assertFails(getDocs(collection(env.unauthenticatedContext().firestore(), 'teamDirectory')));
    await assertFails(getDoc(doc(dbFor('coach'), 'teamCodes/secret')));
    await assertFails(getDoc(doc(dbFor('stranger'), 'teams/t1/feed/post')));
  });
  it('never allows client writes to teams, rosters, requests, directory, or invite codes', async () => {
    for (const path of ['teams/t1', 'teams/t1/members/kid', 'teams/t1/joinRequests/other', 'teamDirectory/t1', 'teamCodes/secret', 'users/parent/teamRequests/request']) {
      await assertFails(setDoc(doc(dbFor('coach'), path), { approved: true }, { merge: true }));
      await assertFails(setDoc(doc(dbFor('parent'), path), { approved: true }, { merge: true }));
    }
  });
});
