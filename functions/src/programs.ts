import type { Firestore } from 'firebase-admin/firestore';
import { HttpsError } from 'firebase-functions/v2/https';

import type { CallerAuth } from './profiles';

type ProgramDay = {
  lessonTitle: string;
  lessonMinutes: number;
  drillIds: string[];
  sets: number[];
  challenge: { title: string; description: string };
};

type Program = {
  id: string;
  title: string;
  skill: string;
  detail: string;
  price: string;
  days: number;
  entitlement: string;
  templates: ProgramDay[];
};

const day = (lessonTitle: string, lessonMinutes: number, drills: [string, number][], challenge: [string, string]): ProgramDay => ({
  lessonTitle,
  lessonMinutes,
  drillIds: drills.map(([id]) => id),
  sets: drills.map(([, sets]) => sets),
  challenge: { title: challenge[0], description: challenge[1] },
});

export const PROGRAMS: Program[] = [
  {
    id: 'shooting-30',
    title: '30 Days to a Harder Shot',
    skill: 'Shot power',
    detail: 'Build a quicker, stronger release with focused shooting sessions and a new challenge each day.',
    price: '$29.99',
    days: 30,
    entitlement: 'program_shooting-30',
    templates: [
      day('Build a quick release', 8, [['quick-release-wrist-shots', 3], ['shot-burst-30', 2]], ['Beat your best', 'Count your shots in 30 seconds. Try to beat your own score.']),
      day('Pick your target', 7, [['pick-your-corner', 2], ['quick-release-wrist-shots', 3]], ['Pick a corner', 'Choose one target and hit it 5 times before switching sides.']),
      day('Repeat with power', 8, [['shot-burst-30', 3], ['quick-release-wrist-shots', 2]], ['Smooth streak', 'Take 10 smooth shots in a row. Reset if your form slips.']),
    ],
  },
  {
    id: 'hands-21',
    title: 'Elite Hands in 21 Days',
    skill: 'Quick hands',
    detail: 'Build soft hands and faster puck control with short, varied stickhandling sessions.',
    price: '$19.99',
    days: 21,
    entitlement: 'program_hands-21',
    templates: [
      day('Soft hands', 7, [['quiet-hands-quick-feet', 3], ['pass-and-settle', 2]], ['Eyes up', 'Keep your eyes up for the whole final set.']),
      day('Quick feet, quick hands', 6, [['quiet-hands-quick-feet', 2], ['athletic-stance-reset', 2]], ['Quick feet', 'Stay light on your feet while keeping the puck close.']),
      day('Control every touch', 8, [['pass-and-settle', 3], ['quiet-hands-quick-feet', 2]], ['Clean touches', 'Try to finish the set without losing control of the puck.']),
    ],
  },
  {
    id: 'power-skating-14',
    title: 'Power Skating Kickstart',
    skill: 'Speed & explosiveness',
    detail: 'Practice a balanced stance, quick feet and powerful starts in a two-week plan.',
    price: '$14.99',
    days: 14,
    entitlement: 'program_power-skating-14',
    templates: [
      day('Build a strong position', 7, [['athletic-stance-reset', 3], ['quiet-hands-quick-feet', 2]], ['Strong position', 'Hold a balanced athletic stance through every rep.']),
      day('Explode into motion', 8, [['athletic-stance-reset', 2], ['shot-burst-30', 2]], ['Fast start', 'Make each first step quick and controlled.']),
      day('Stay balanced at speed', 7, [['quiet-hands-quick-feet', 3], ['athletic-stance-reset', 2]], ['Stay steady', 'Keep your balance from the first rep to the last.']),
    ],
  },
];

type Input = { profileId?: unknown; programId?: unknown; day?: unknown };

function validId(value: unknown, name: string): string {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new HttpsError('invalid-argument', `Choose a valid ${name}.`);
  return value;
}

async function ownedProfile(db: Firestore, caller: CallerAuth | undefined, profileId: string) {
  if (!caller) throw new HttpsError('unauthenticated', 'Sign in to continue.');
  const profile = await db.collection('profiles').doc(profileId).get();
  if (!profile.exists) throw new HttpsError('not-found', 'Player profile not found.');
  const ownerUid = profile.data()!.ownerUid;
  if (typeof ownerUid !== 'string' || (caller.isKidDevice ? caller.uid !== `kid-${profileId}` : ownerUid !== caller.uid)) {
    throw new HttpsError('permission-denied', 'Choose one of your own player profiles.');
  }
  return { profile, ownerUid };
}

function programById(id: string): Program {
  const program = PROGRAMS.find((candidate) => candidate.id === id);
  if (!program) throw new HttpsError('not-found', 'Program not found.');
  return program;
}

function completedDays(value: unknown): number[] {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.filter((n): n is number => Number.isInteger(n) && n > 0))].sort((a, b) => a - b);
}

/** Program content is authored and versioned with Functions, not accepted from a player's device. */
export function getProgramCatalog() {
  return PROGRAMS;
}

export function programContent(id: string, dayNumber: number): ProgramDay | undefined {
  const program = PROGRAMS.find((candidate) => candidate.id === id);
  if (!program || !Number.isInteger(dayNumber) || dayNumber < 1 || dayNumber > program.days) return undefined;
  return program.templates[(dayNumber - 1) % program.templates.length];
}

/** Resolves a profile's program purchases through its owner and returns server-written progress. */
export async function getProgramDashboard(db: Firestore, caller: CallerAuth | undefined, data: Input) {
  const profileId = validId(data.profileId, 'player');
  const { ownerUid } = await ownedProfile(db, caller, profileId);
  const [user, progress] = await Promise.all([
    db.collection('users').doc(ownerUid).get(),
    db.collection('profiles').doc(profileId).collection('programs').get(),
  ]);
  const entitlements = user.data()?.entitlements as { programs?: unknown; playerPro?: unknown } | undefined;
  const owned = Array.isArray(entitlements?.programs) ? entitlements!.programs.filter((id): id is string => typeof id === 'string') : [];
  return {
    ownedProgramIds: owned,
    proDiscountEligible: entitlements?.playerPro === true,
    progress: Object.fromEntries(progress.docs.map((doc) => [doc.id, { completedDays: completedDays(doc.data().completedDays) }])),
  };
}

/** Issues one server-tracked workout run, enforcing purchase access and linear progression. */
export async function startProgramDay(db: Firestore, caller: CallerAuth | undefined, data: Input, now = new Date()) {
  const profileId = validId(data.profileId, 'player');
  const id = validId(data.programId, 'program');
  const program = programById(id);
  const dayNumber = data.day;
  if (typeof dayNumber !== 'number' || !Number.isInteger(dayNumber) || dayNumber < 1 || dayNumber > program.days) {
    throw new HttpsError('invalid-argument', 'Choose a valid program day.');
  }
  const { ownerUid } = await ownedProfile(db, caller, profileId);
  const profileRef = db.collection('profiles').doc(profileId);
  const progressRef = profileRef.collection('programs').doc(id);
  const userRef = db.collection('users').doc(ownerUid);
  const runRef = profileRef.collection('programRuns').doc();

  await db.runTransaction(async (tx) => {
    const [profile, user, progress] = await Promise.all([tx.get(profileRef), tx.get(userRef), tx.get(progressRef)]);
    if (!profile.exists || profile.data()!.ownerUid !== ownerUid) throw new HttpsError('permission-denied', 'Choose one of your own player profiles.');
    const owned = (user.data()?.entitlements as { programs?: unknown } | undefined)?.programs;
    const hasPurchase = Array.isArray(owned) && owned.includes(program.entitlement);
    if (dayNumber > 1 && !hasPurchase) throw new HttpsError('permission-denied', 'Unlock this program to start this day.');
    const completed = completedDays(progress.data()?.completedDays);
    const nextDay = completed.length + 1;
    if (dayNumber > nextDay) throw new HttpsError('failed-precondition', 'Finish the earlier days first.');
    tx.create(runRef, { programId: id, day: dayNumber, ownerUid, status: 'started', startedAt: now });
  });
  return { runId: runRef.id };
}
