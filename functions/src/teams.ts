import { createHash, randomBytes } from 'node:crypto';
import { FieldValue, type Firestore, type Transaction, type DocumentSnapshot } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import { requireAccount, type CallerAuth } from './profiles';

type Input = { routine?: unknown; teamId?: unknown; profileId?: unknown; code?: unknown; name?: unknown; visibility?: unknown; approve?: unknown };
const codeKey = (code: string) => createHash('sha256').update(code).digest('hex');
const newCode = () => randomBytes(8).toString('hex').toUpperCase();

function id(value: unknown): string {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new HttpsError('invalid-argument', 'Choose a valid team and player.');
  return value;
}

function normalizedCode(value: unknown): string {
  if (typeof value !== 'string') throw new HttpsError('invalid-argument', 'Enter the invitation code.');
  const code = value.replace(/\s/g, '').toUpperCase();
  if (!/^[A-F0-9]{16}$/.test(code)) throw new HttpsError('invalid-argument', 'Enter the 16-character invitation code.');
  return code;
}

function coach(team: DocumentSnapshot, uid: string) {
  if (!team.exists) throw new HttpsError('not-found', 'This team no longer exists.');
  if (team.data()?.deletingAt) throw new HttpsError('failed-precondition', 'This team is being deleted.');
  if (!(team.data()?.coachUids as string[]).includes(uid)) throw new HttpsError('permission-denied', 'Only a team coach can do this.');
}

async function requireActiveAccount(db: Firestore, tx: Transaction, uid: string) {
  const user = await tx.get(db.doc(`users/${uid}`));
  if (user.data()?.deletingAt) throw new HttpsError('failed-precondition', 'This account is being deleted.');
  return user;
}

function directory(team: FirebaseFirestore.DocumentData) {
  return { name: team.name, searchName: team.searchName, coachName: team.coachName, memberCount: team.memberCount };
}

export async function createTeam(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  if (typeof data.name !== 'string' || data.name.trim().length < 2 || data.name.trim().length > 60 || /[\p{C}<>]/u.test(data.name)) {
    throw new HttpsError('invalid-argument', 'Use a team name between 2 and 60 characters, without special markup.');
  }
  const name = data.name.trim().replace(/\s+/g, ' ');
  const teamRef = db.collection('teams').doc();
  const joinCode = newCode();
  await db.runTransaction(async (tx) => {
    const own = await tx.get(db.doc(`profiles/${auth.uid}`));
    const user = await requireActiveAccount(db, tx, auth.uid);
    if (!own.exists || new Date().getUTCFullYear() - own.data()!.birthYear < 19) throw new HttpsError('failed-precondition', 'Finish your player profile first. Only adults can create teams; we check conservatively using birth year.');
    const team = { name, searchName: name.toLowerCase(), visibility: 'private', coachUids: [auth.uid], coachName: own.data()!.displayName, joinCode, memberCount: 0, memberOwnerUids: [], memberProfileIds: [], createdAt: new Date() };
    tx.create(teamRef, team);
    tx.create(db.doc(`teamCodes/${codeKey(joinCode)}`), { teamId: teamRef.id, kind: 'player' });
    tx.set(user.ref, { roles: FieldValue.arrayUnion('coach'), createdAt: user.data()?.createdAt ?? new Date() }, { merge: true });
  });
  return { teamId: teamRef.id };
}

export async function updateTeam(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  const ref = db.doc(`teams/${id(data.teamId)}`);
  if (data.visibility !== 'public' && data.visibility !== 'private') throw new HttpsError('invalid-argument', 'Choose public or private.');
  await db.runTransaction(async (tx) => {
    const team = await tx.get(ref);
    await requireActiveAccount(db, tx, auth.uid);
    coach(team, auth.uid);
    const updated = { ...team.data()!, visibility: data.visibility };
    tx.update(ref, { visibility: data.visibility });
    const listing = db.doc(`teamDirectory/${ref.id}`);
    if (data.visibility === 'public') tx.set(listing, directory(updated));
    else tx.delete(listing);
  });
  return { updated: true };
}

export async function createTeamInvite(db: Firestore, caller: CallerAuth | undefined, data: Input & { kind?: unknown }) {
  const auth = requireAccount(caller);
  if (data.kind !== 'coach' && data.kind !== 'player') throw new HttpsError('invalid-argument', 'Choose a coach or player invitation.');
  const ref = db.doc(`teams/${id(data.teamId)}`);
  const code = newCode();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
  await db.runTransaction(async (tx) => {
    const team = await tx.get(ref);
    await requireActiveAccount(db, tx, auth.uid);
    coach(team, auth.uid);
    if (data.kind === 'player') {
      tx.delete(db.doc(`teamCodes/${codeKey(team.data()!.joinCode as string)}`));
      tx.update(ref, { joinCode: code });
    }
    tx.create(db.doc(`teamCodes/${codeKey(code)}`), { teamId: ref.id, kind: data.kind, ...(data.kind === 'coach' ? { expiresAt } : {}) });
  });
  return { code, expiresAtMillis: data.kind === 'coach' ? expiresAt.getTime() : null };
}

async function invitation(db: Firestore, tx: Transaction, code: string) {
  const invite = await tx.get(db.doc(`teamCodes/${codeKey(code)}`));
  if (!invite.exists || (invite.data()?.expiresAt && invite.data()!.expiresAt.toMillis() <= Date.now())) throw new HttpsError('not-found', 'This invitation is invalid or expired. Ask your coach for a new one.');
  const team = await tx.get(db.doc(`teams/${id(invite.data()!.teamId)}`));
  if (!team.exists || team.data()?.deletingAt) throw new HttpsError('not-found', 'This team no longer exists.');
  return { invite, team };
}

export async function previewTeamInvite(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  if (!caller) throw new HttpsError('unauthenticated', 'Sign in to continue.');
  return db.runTransaction(async (tx) => {
    const { invite, team } = await invitation(db, tx, normalizedCode(data.code));
    return { teamId: team.id, name: team.data()!.name, kind: invite.data()!.kind };
  });
}

function addMember(db: Firestore, tx: Transaction, team: DocumentSnapshot, profile: DocumentSnapshot, addedByUid: string) {
  const t = team.data()!;
  const p = profile.data()!;
  if ((t.memberProfileIds as string[]).includes(profile.id)) return;
  tx.create(team.ref.collection('members').doc(profile.id), { ownerUid: p.ownerUid, displayName: p.displayName, joinedAt: new Date(), addedByUid });
  tx.update(team.ref, { memberCount: FieldValue.increment(1), memberProfileIds: FieldValue.arrayUnion(profile.id), memberOwnerUids: FieldValue.arrayUnion(p.ownerUid) });
  tx.update(profile.ref, { teamIds: FieldValue.arrayUnion(team.id) });
  if (t.visibility === 'public') tx.set(db.doc(`teamDirectory/${team.id}`), { ...directory(t), memberCount: t.memberCount + 1 });
}

export async function joinTeam(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  if (!caller || caller.isAnonymous) throw new HttpsError('unauthenticated', 'Create an account or pair a kid device to join a team.');
  const profileId = id(data.profileId);
  return db.runTransaction(async (tx) => {
    const profile = await tx.get(db.doc(`profiles/${profileId}`));
    if (!profile.exists || (caller.isKidDevice ? caller.uid !== `kid-${profileId}` : profile.data()!.ownerUid !== caller.uid)) throw new HttpsError('permission-denied', 'Choose one of your own player profiles.');
    await requireActiveAccount(db, tx, profile.data()!.ownerUid as string);
    let team: DocumentSnapshot;
    let source: string;
    if (data.code != null) {
      const found = await invitation(db, tx, normalizedCode(data.code));
      if (found.invite.data()!.kind !== 'player') throw new HttpsError('invalid-argument', 'This code is for a coach, not a player.');
      team = found.team;
      source = 'code';
    } else {
      team = await tx.get(db.doc(`teams/${id(data.teamId)}`));
      if (!team.exists || team.data()!.deletingAt || team.data()!.visibility !== 'public') throw new HttpsError('not-found', 'Choose a public team or enter a team code.');
      source = 'public';
    }
    if ((team.data()!.memberProfileIds as string[]).includes(profileId)) return { status: 'joined' };
    if (!caller.isKidDevice && source === 'code') {
      addMember(db, tx, team, profile, caller.uid);
      tx.delete(team.ref.collection('joinRequests').doc(profileId));
      tx.delete(db.doc(`users/${profile.data()!.ownerUid}/teamRequests/${team.id}_${profileId}`));
      return { status: 'joined' };
    }
    const requestRef = team.ref.collection('joinRequests').doc(profileId);
    const existing = await tx.get(requestRef);
    // A repeated kid request must not reset a parent's approval.
    if (existing.exists) return { status: existing.data()!.status };
    const status = caller.isKidDevice ? 'parentPending' : 'coachPending';
    const request = { teamId: team.id, teamName: team.data()!.name, profileId, displayName: profile.data()!.displayName, ownerUid: profile.data()!.ownerUid, source, status, createdAt: new Date() };
    tx.set(requestRef, request);
    tx.set(db.doc(`users/${request.ownerUid}/teamRequests/${team.id}_${profileId}`), request);
    return { status };
  });
}

export async function acceptCoachInvite(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  return db.runTransaction(async (tx) => {
    const { invite, team } = await invitation(db, tx, normalizedCode(data.code));
    const own = await tx.get(db.doc(`profiles/${auth.uid}`));
    await requireActiveAccount(db, tx, auth.uid);
    if (!own.exists || new Date().getUTCFullYear() - own.data()!.birthYear < 19) throw new HttpsError('failed-precondition', 'Only an adult account with a player profile can accept a coach invitation; we check conservatively using birth year.');
    if (invite.data()!.kind !== 'coach') throw new HttpsError('invalid-argument', 'Use a coach invitation, not a player code.');
    tx.update(team.ref, { coachUids: FieldValue.arrayUnion(auth.uid) });
    tx.set(db.doc(`users/${auth.uid}`), { roles: FieldValue.arrayUnion('coach') }, { merge: true });
    tx.delete(invite.ref);
    return { teamId: team.id };
  });
}

export async function reviewTeamRequest(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  if (typeof data.approve !== 'boolean') throw new HttpsError('invalid-argument', 'Choose approve or decline.');
  return db.runTransaction(async (tx) => {
    const team = await tx.get(db.doc(`teams/${id(data.teamId)}`));
    const profile = await tx.get(db.doc(`profiles/${id(data.profileId)}`));
    const request = await tx.get(team.ref.collection('joinRequests').doc(profile.id));
    if (!team.exists || !profile.exists || !request.exists) throw new HttpsError('not-found', 'This request is no longer waiting.');
    if (team.data()!.deletingAt) throw new HttpsError('failed-precondition', 'This team is being deleted.');
    await requireActiveAccount(db, tx, auth.uid);
    await requireActiveAccount(db, tx, profile.data()!.ownerUid as string);
    const r = request.data()!;
    if (r.status === 'parentPending') {
      if (profile.data()!.ownerUid !== auth.uid) throw new HttpsError('permission-denied', 'Only this player\'s parent can approve.');
    } else coach(team, auth.uid);
    const parentRef = db.doc(`users/${profile.data()!.ownerUid}/teamRequests/${team.id}_${profile.id}`);
    if (data.approve && r.status === 'parentPending' && r.source === 'public') {
      tx.update(request.ref, { status: 'coachPending' });
      tx.update(parentRef, { status: 'coachPending' });
      return { status: 'coachPending' };
    }
    if (data.approve) addMember(db, tx, team, profile, auth.uid);
    tx.delete(request.ref);
    tx.delete(parentRef);
    return { status: data.approve ? 'joined' : 'declined' };
  });
}

export async function removeTeamMember(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  await db.runTransaction(async (tx) => {
    const team = await tx.get(db.doc(`teams/${id(data.teamId)}`));
    const profile = await tx.get(db.doc(`profiles/${id(data.profileId)}`));
    const members = await tx.get(team.ref.collection('members'));
    if (!team.exists) throw new HttpsError('not-found', 'This team no longer exists.');
    if (!profile.exists || profile.data()!.ownerUid !== auth.uid) coach(team, auth.uid);
    const remaining = members.docs.filter((m) => m.id !== profile.id);
    tx.delete(team.ref.collection('members').doc(profile.id));
    tx.update(team.ref, { memberCount: remaining.length, memberProfileIds: remaining.map((m) => m.id), memberOwnerUids: [...new Set(remaining.map((m) => m.data().ownerUid as string))] });
    if (profile.exists) tx.update(profile.ref, { teamIds: FieldValue.arrayRemove(team.id) });
    if (team.data()!.visibility === 'public') tx.set(db.doc(`teamDirectory/${team.id}`), { ...directory(team.data()!), memberCount: remaining.length });
  });
  return { removed: true };
}

/** Run before erasing profiles so other members and coaches keep consistent membership records. */
export async function removeAccountFromTeams(db: Firestore, caller: CallerAuth) {
  const owned = await db.collection('profiles').where('ownerUid', '==', caller.uid).get();
  for (const profile of owned.docs) {
    for (const teamId of (profile.data().teamIds ?? []) as string[]) await removeTeamMember(db, caller, { teamId, profileId: profile.id });
    const requests = await db.collection(`users/${caller.uid}/teamRequests`).where('profileId', '==', profile.id).get();
    for (const request of requests.docs) {
      await db.doc(`teams/${request.data().teamId}/joinRequests/${profile.id}`).delete();
      await request.ref.delete();
    }
  }
  const coached = await db.collection('teams').where('coachUids', 'array-contains', caller.uid).get();
  for (const team of coached.docs) {
    const deleting = await db.runTransaction(async (tx) => {
      const current = await tx.get(team.ref);
      if (!current.exists) return false;
      const remaining = (current.data()!.coachUids as string[]).filter((uid) => uid !== caller.uid);
      if (remaining.length > 0) {
        const nextCoach = await tx.get(db.doc(`profiles/${remaining[0]}`));
        const coachName = nextCoach.data()?.displayName ?? 'Coach';
        tx.update(team.ref, { coachUids: remaining, coachName });
        if (current.data()!.visibility === 'public') tx.set(db.doc(`teamDirectory/${team.id}`), { ...directory(current.data()!), coachName });
        return false;
      }
      tx.update(team.ref, { deletingAt: new Date() });
      tx.delete(db.doc(`teamDirectory/${team.id}`));
      return true;
    });
    if (!deleting) continue;
    for (const member of (await team.ref.collection('members').get()).docs) {
      const profile = db.doc(`profiles/${member.id}`);
      if ((await profile.get()).exists) await profile.update({ teamIds: FieldValue.arrayRemove(team.id) });
    }
    for (const request of (await team.ref.collection('joinRequests').get()).docs) await db.doc(`users/${request.data().ownerUid}/teamRequests/${team.id}_${request.id}`).delete();
    for (const code of (await db.collection('teamCodes').where('teamId', '==', team.id).get()).docs) await code.ref.delete();
    await db.doc(`teamDirectory/${team.id}`).delete();
    await db.recursiveDelete(team.ref);
  }
}

const MAX_ROUTINE_DRILLS = 10;

/** A routine from a coach: a short name and catalog drills with set counts. Nothing else is stored, so there is no free text but the name. */
export function cleanRoutine(raw: unknown) {
  const routine = raw as { name?: unknown; drills?: unknown } | null;
  const name = typeof routine?.name === 'string' ? routine.name.trim().replace(/\s+/g, ' ') : '';
  if (name.length < 2 || name.length > 40 || /[\p{C}<>]/u.test(name)) throw new HttpsError('invalid-argument', 'Use a routine name between 2 and 40 characters, without special markup.');
  if (!Array.isArray(routine?.drills) || routine.drills.length < 1 || routine.drills.length > MAX_ROUTINE_DRILLS) throw new HttpsError('invalid-argument', `A team routine has 1 to ${MAX_ROUTINE_DRILLS} drills.`);
  const drills = routine.drills.map((entry: { drillId?: unknown; sets?: unknown }) => {
    if (typeof entry?.drillId !== 'string' || !/^[a-z0-9-]{1,80}$/.test(entry.drillId)) throw new HttpsError('invalid-argument', 'Team routines use drills from the How To Hockey library.');
    if (typeof entry.sets !== 'number' || !Number.isInteger(entry.sets) || entry.sets < 1 || entry.sets > 10) throw new HttpsError('invalid-argument', 'Use 1 to 10 sets per drill.');
    return { drillId: entry.drillId, sets: entry.sets };
  });
  return { name, drills };
}

/** A team has one active routine at a time. Setting a new one archives the previous one. */
export async function setTeamRoutine(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  const routine = cleanRoutine(data.routine);
  const ref = db.doc(`teams/${id(data.teamId)}`);
  await db.runTransaction(async (tx) => {
    const team = await tx.get(ref);
    await requireActiveAccount(db, tx, auth.uid);
    coach(team, auth.uid);
    const previous = team.data()!.activeRoutine;
    if (previous) tx.create(ref.collection('routineArchive').doc(), { ...previous, archivedAt: new Date() });
    tx.update(ref, { activeRoutine: { ...routine, sharedAt: new Date(), sharedBy: auth.uid } });
  });
  return { shared: true };
}

export async function clearTeamRoutine(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const auth = requireAccount(caller);
  const ref = db.doc(`teams/${id(data.teamId)}`);
  await db.runTransaction(async (tx) => {
    const team = await tx.get(ref);
    await requireActiveAccount(db, tx, auth.uid);
    coach(team, auth.uid);
    const previous = team.data()!.activeRoutine;
    if (!previous) return;
    tx.create(ref.collection('routineArchive').doc(), { ...previous, archivedAt: new Date() });
    tx.update(ref, { activeRoutine: FieldValue.delete() });
  });
  return { cleared: true };
}
