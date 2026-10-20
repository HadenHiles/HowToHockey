import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import * as teams from '../src/teams';
import { deleteAccount } from '../src/accounts';
import { createChildProfile, createOwnProfile } from '../src/profiles';

const coach = { uid: 'coach', isAnonymous: false };
const parent = { uid: 'parent', isAnonymous: false };
const stranger = { uid: 'stranger', isAnonymous: false };
const kid = { uid: 'kid-child', isAnonymous: false, isKidDevice: true };
let app: App;
let db: Firestore;
let teamId: string;
let code: string;

beforeAll(() => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(127\.0\.0\.1|localhost|\[::1\]):/.test(host)) throw new Error('Local Firestore emulator required.');
  app = initializeApp({ projectId: 'demo-how-to-hockey' }, 'team-tests');
  db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-how-to-hockey/databases/(default)/documents`, { method: 'DELETE' });
  for (const uid of ['coach', 'parent', 'stranger']) {
    await db.doc(`users/${uid}`).set({ roles: ['player'] });
    await db.doc(`profiles/${uid}`).set({ ownerUid: uid, displayName: `${uid} H.`, birthYear: 1990, isChild: false, teamIds: [] });
  }
  for (const profileId of ['child', 'sibling']) await db.doc(`profiles/${profileId}`).set({ ownerUid: 'parent', displayName: 'Kid H.', birthYear: 2017, isChild: true, teamIds: [] });
  teamId = (await teams.createTeam(db, coach, { name: 'North Stars' })).teamId;
  code = (await db.doc(`teams/${teamId}`).get()).data()!.joinCode as string;
});

describe('core teams', () => {
  it('creates a private team and gives only coaches permission to change visibility', async () => {
    expect((await db.doc(`teams/${teamId}`).get()).data()).toMatchObject({ visibility: 'private', memberCount: 0, coachUids: ['coach'] });
    expect((await db.doc(`teamDirectory/${teamId}`).get()).exists).toBe(false);
    await expect(teams.updateTeam(db, stranger, { teamId, visibility: 'public' })).rejects.toMatchObject({ code: 'permission-denied' });
    await teams.updateTeam(db, coach, { teamId, visibility: 'public' });
    const listing = (await db.doc(`teamDirectory/${teamId}`).get()).data()!;
    expect(Object.keys(listing).sort()).toEqual(['coachName', 'memberCount', 'name', 'searchName']);
    await teams.updateTeam(db, coach, { teamId, visibility: 'private' });
    expect((await db.doc(`teamDirectory/${teamId}`).get()).exists).toBe(false);
  });

  it('joins each selected profile independently, with idempotent concurrent retries', async () => {
    await teams.updateTeam(db, coach, { teamId, visibility: 'public' });
    await Promise.all(Array.from({ length: 4 }, () => teams.joinTeam(db, parent, { profileId: 'child', code })));
    expect((await db.doc(`teams/${teamId}`).get()).data()!.memberCount).toBe(1);
    expect((await db.doc('profiles/parent').get()).data()!.teamIds).toEqual([]);
    expect((await db.doc('profiles/sibling').get()).data()!.teamIds).toEqual([]);
    expect((await db.doc('profiles/child').get()).data()!.teamIds).toEqual([teamId]);
    expect((await db.doc(`teamDirectory/${teamId}`).get()).data()!.memberCount).toBe(1);
    const second = await teams.createTeam(db, coach, { name: 'Second Team' });
    const secondCode = (await db.doc(`teams/${second.teamId}`).get()).data()!.joinCode;
    await teams.joinTeam(db, parent, { profileId: 'child', code: secondCode });
    expect((await db.doc('profiles/child').get()).data()!.teamIds).toHaveLength(2);
  });

  it('requires parent approval for kid code requests and refuses another child or a coach bypass', async () => {
    expect(await teams.joinTeam(db, kid, { profileId: 'child', code })).toEqual({ status: 'parentPending' });
    expect((await db.doc(`teams/${teamId}`).get()).data()!.memberCount).toBe(0);
    const request = { teamId, profileId: 'child', approve: true };
    await expect(teams.reviewTeamRequest(db, coach, request)).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(teams.joinTeam(db, kid, { profileId: 'sibling', code })).rejects.toMatchObject({ code: 'permission-denied' });
    await teams.reviewTeamRequest(db, parent, request);
    expect((await db.doc(`teams/${teamId}`).get()).data()!.memberCount).toBe(1);
    expect((await db.collection('users/parent/teamRequests').get()).empty).toBe(true);
    expect((await db.collection(`teams/${teamId}/joinRequests`).get()).empty).toBe(true);
  });

  it('public discovery requires parent then coach approval and kid retries do not undo approval', async () => {
    await teams.updateTeam(db, coach, { teamId, visibility: 'public' });
    expect(await teams.joinTeam(db, kid, { profileId: 'child', teamId })).toEqual({ status: 'parentPending' });
    expect(await teams.reviewTeamRequest(db, parent, { teamId, profileId: 'child', approve: true })).toEqual({ status: 'coachPending' });
    expect(await teams.joinTeam(db, kid, { profileId: 'child', teamId })).toEqual({ status: 'coachPending' });
    await expect(teams.reviewTeamRequest(db, parent, { teamId, profileId: 'child', approve: true })).rejects.toMatchObject({ code: 'permission-denied' });
    await teams.reviewTeamRequest(db, coach, { teamId, profileId: 'child', approve: true });
    expect((await db.doc(`teams/${teamId}/members/child`).get()).exists).toBe(true);
    await teams.joinTeam(db, parent, { profileId: 'sibling', teamId });
    await teams.reviewTeamRequest(db, coach, { teamId, profileId: 'sibling', approve: false });
    expect((await db.doc(`teams/${teamId}/members/sibling`).get()).exists).toBe(false);
  });

  it('rotates player codes without removing players', async () => {
    await teams.joinTeam(db, parent, { profileId: 'child', code });
    const rotated = await teams.createTeamInvite(db, coach, { teamId, kind: 'player' });
    await expect(teams.previewTeamInvite(db, parent, { code })).rejects.toMatchObject({ code: 'not-found' });
    await expect(teams.previewTeamInvite(db, parent, { code: rotated.code })).resolves.toMatchObject({ teamId, kind: 'player' });
    expect((await db.doc(`teams/${teamId}`).get()).data()!.memberCount).toBe(1);
  });

  it('coach invites are separate, expiring, single use, and cannot be accepted by kids or teens', async () => {
    const invite = await teams.createTeamInvite(db, coach, { teamId, kind: 'coach' });
    await expect(teams.joinTeam(db, parent, { profileId: 'child', code: invite.code })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(teams.acceptCoachInvite(db, kid, { code: invite.code })).rejects.toMatchObject({ code: 'permission-denied' });
    await db.doc('profiles/stranger').update({ birthYear: new Date().getUTCFullYear() - 16 });
    await expect(teams.acceptCoachInvite(db, stranger, { code: invite.code })).rejects.toMatchObject({ code: 'failed-precondition' });
    await db.doc('profiles/stranger').update({ birthYear: 1990 });
    await Promise.allSettled([teams.acceptCoachInvite(db, stranger, { code: invite.code }), teams.acceptCoachInvite(db, parent, { code: invite.code })]);
    expect((await db.doc(`teams/${teamId}`).get()).data()!.coachUids).toHaveLength(2);
    await expect(teams.acceptCoachInvite(db, parent, { code: invite.code })).rejects.toMatchObject({ code: 'not-found' });
    const expired = await teams.createTeamInvite(db, coach, { teamId, kind: 'coach' });
    const codes = await db.collection('teamCodes').where('kind', '==', 'coach').get();
    await codes.docs[0].ref.update({ expiresAt: new Date(0) });
    await expect(teams.acceptCoachInvite(db, parent, { code: expired.code })).rejects.toMatchObject({ code: 'not-found' });
  });

  it('removal preserves player history and keeps parent access until their last child leaves', async () => {
    await teams.joinTeam(db, parent, { profileId: 'child', code });
    await teams.joinTeam(db, parent, { profileId: 'sibling', code });
    await db.doc('profiles/child/sessions/s1').set({ status: 'completed' });
    await expect(teams.removeTeamMember(db, stranger, { teamId, profileId: 'child' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(teams.removeTeamMember(db, kid, { teamId, profileId: 'child' })).rejects.toMatchObject({ code: 'permission-denied' });
    await teams.removeTeamMember(db, coach, { teamId, profileId: 'child' });
    expect((await db.doc(`teams/${teamId}`).get()).data()!.memberOwnerUids).toEqual(['parent']);
    await teams.removeTeamMember(db, parent, { teamId, profileId: 'sibling' });
    expect((await db.doc(`teams/${teamId}`).get()).data()).toMatchObject({ memberOwnerUids: [], memberCount: 0 });
    expect((await db.doc('profiles/child/sessions/s1').get()).exists).toBe(true);
  });

  it('account deletion removes memberships, outstanding requests, codes and orphan teams', async () => {
    await teams.joinTeam(db, parent, { profileId: 'child', code });
    await teams.joinTeam(db, { ...kid, uid: 'kid-sibling' }, { profileId: 'sibling', code });
    const eraser = { deleteUsers: async () => {} };
    await deleteAccount(db, eraser, parent, { confirm: true });
    expect((await db.doc(`teams/${teamId}`).get()).data()!.memberCount).toBe(0);
    expect((await db.collection(`teams/${teamId}/joinRequests`).get()).empty).toBe(true);
    await teams.joinTeam(db, stranger, { profileId: 'stranger', code });
    await deleteAccount(db, eraser, coach, { confirm: true });
    expect((await db.doc(`teams/${teamId}`).get()).exists).toBe(false);
    expect((await db.doc('profiles/stranger').get()).data()!.teamIds).toEqual([]);
    expect((await db.collection('teamCodes').get()).empty).toBe(true);
  });

  it('validates accounts, identifiers, input, and private-team discovery', async () => {
    await expect(teams.createTeam(db, undefined, { name: 'Team' })).rejects.toMatchObject({ code: 'unauthenticated' });
    await expect(teams.createTeam(db, { uid: 'g', isAnonymous: true }, { name: 'Team' })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(teams.createTeam(db, kid, { name: 'Team' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(teams.createTeam(db, coach, { name: '<script>' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(teams.joinTeam(db, parent, { teamId, profileId: 'child' })).rejects.toMatchObject({ code: 'not-found' });
    await expect(teams.joinTeam(db, stranger, { code, profileId: 'child' })).rejects.toMatchObject({ code: 'permission-denied' });
    await expect(teams.joinTeam(db, parent, { code, profileId: '../child' })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(teams.previewTeamInvite(db, parent, { code: 'bad' })).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('does not add profiles or memberships while an account or team is being deleted', async () => {
    await db.doc('users/parent').update({ deletingAt: new Date() });
    await expect(teams.joinTeam(db, parent, { profileId: 'child', code })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(teams.joinTeam(db, kid, { profileId: 'child', code })).rejects.toMatchObject({ code: 'failed-precondition' });
    await expect(createChildProfile(db, parent, { displayName: 'New H.', birthYear: 2017 })).rejects.toMatchObject({ code: 'failed-precondition' });
    await db.doc('profiles/parent').delete();
    await expect(createOwnProfile(db, parent, { displayName: 'Pat H.', birthYear: 1990 })).rejects.toMatchObject({ code: 'failed-precondition' });
    await db.doc(`teams/${teamId}`).update({ deletingAt: new Date() });
    await expect(teams.joinTeam(db, stranger, { profileId: 'stranger', code })).rejects.toMatchObject({ code: 'not-found' });
    await expect(teams.createTeamInvite(db, coach, { teamId, kind: 'coach' })).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('keeps teams with another coach and replaces the deleted coach name in public listings', async () => {
    const invitation = await teams.createTeamInvite(db, coach, { teamId, kind: 'coach' });
    await teams.acceptCoachInvite(db, stranger, { code: invitation.code });
    await teams.updateTeam(db, coach, { teamId, visibility: 'public' });
    await deleteAccount(db, { deleteUsers: async () => {} }, coach, { confirm: true });
    expect((await db.doc(`teams/${teamId}`).get()).data()!.coachUids).toEqual(['stranger']);
    expect((await db.doc(`teamDirectory/${teamId}`).get()).data()!.coachName).toBe('stranger H.');
    await expect(teams.createTeamInvite(db, stranger, { teamId, kind: 'player' })).resolves.toHaveProperty('code');
  });
});
