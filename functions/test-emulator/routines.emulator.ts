import { initializeApp, deleteApp, type App } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';

import { deleteProfileRoutine, saveProfileRoutine } from '../src/routines';

const parent = { uid: 'parent', isAnonymous: false };
let app: App;
let db: Firestore;

beforeAll(() => {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  if (!host || !/^(127\.0\.0\.1|localhost|\[::1\]):/.test(host)) throw new Error('Local Firestore emulator required.');
  app = initializeApp({ projectId: 'demo-how-to-hockey' }, 'routine-tests');
  db = getFirestore(app);
});
afterAll(() => deleteApp(app));
beforeEach(async () => {
  await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-how-to-hockey/databases/(default)/documents`, { method: 'DELETE' });
  await db.doc('profiles/kid').set({ ownerUid: 'parent', isChild: true, displayName: 'Kid H.', pro: false });
  await db.doc('profiles/rich-kid').set({ ownerUid: 'parent', isChild: true, displayName: 'Rich H.', pro: true });
});

const routine = (name: string) => ({ name, drills: [{ drillId: 'pick-your-corner', sets: 3 }] });

describe('profile routines', () => {
  it('lets only the parent save routines, and keeps three for a free player', async () => {
    await expect(saveProfileRoutine(db, { uid: 'stranger', isAnonymous: false }, { profileId: 'kid', routine: routine('Nope') })).rejects.toMatchObject({ code: 'permission-denied' });
    const ids: string[] = [];
    for (const name of ['One', 'Two', 'Three']) ids.push((await saveProfileRoutine(db, parent, { profileId: 'kid', routine: routine(name) })).routineId);
    await expect(saveProfileRoutine(db, parent, { profileId: 'kid', routine: routine('Four') })).rejects.toMatchObject({ code: 'resource-exhausted' });

    // Replacing one is not a new one.
    await saveProfileRoutine(db, parent, { profileId: 'kid', routineId: ids[0], routine: routine('One v2') });
    const saved = await db.collection('profiles/kid/routines').get();
    expect(saved.docs.map((d) => d.data().name).sort()).toEqual(['One v2', 'Three', 'Two']);
    expect(saved.docs.find((d) => d.id === ids[0])!.data()).toMatchObject({ updatedBy: 'parent' });

    await deleteProfileRoutine(db, parent, { profileId: 'kid', routineId: ids[1] });
    await saveProfileRoutine(db, parent, { profileId: 'kid', routine: routine('Four') });
    expect((await db.collection('profiles/kid/routines').get()).size).toBe(3);
    await expect(deleteProfileRoutine(db, { uid: 'stranger', isAnonymous: false }, { profileId: 'kid', routineId: ids[0] })).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('lifts the cap for a Pro player and validates routines', async () => {
    for (let i = 0; i < 5; i++) await saveProfileRoutine(db, parent, { profileId: 'rich-kid', routine: routine(`Routine ${i}`) });
    expect((await db.collection('profiles/rich-kid/routines').get()).size).toBe(5);
    await expect(saveProfileRoutine(db, parent, { profileId: 'kid', routine: { name: 'x', drills: [] } })).rejects.toMatchObject({ code: 'invalid-argument' });
    await expect(saveProfileRoutine(db, parent, { profileId: 'kid', routine: { name: 'Fine', drills: [{ drillId: 'Bad Id', sets: 3 }] } })).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
