import { getFirestore } from 'firebase-admin/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';

import { getHealthStatus } from './health';
import { createChildProfile as createChildProfileFor, createOwnProfile as createOwnProfileFor, type CallerAuth } from './profiles';

import { deleteAccount as deleteAccountFor } from './accounts';
import { processSession } from './sessions';
import { loadTuning } from './tuning';
import { createPairingCode as createPairingCodeFor, redeemPairingCode as redeemPairingCodeFor } from './pairing';

initializeApp();

export const healthCheck = onCall(() => getHealthStatus());

function callerOf(request: { auth?: { uid: string; token: { email?: string; profileId?: string; firebase?: { sign_in_provider?: string } } } }): CallerAuth | undefined {
  const auth = request.auth;
  if (!auth) return undefined;
  return { uid: auth.uid, isAnonymous: auth.token.firebase?.sign_in_provider === 'anonymous', email: auth.token.email, isKidDevice: typeof auth.token.profileId === 'string' };
}

export const createChildProfile = onCall((request) => createChildProfileFor(getFirestore(), callerOf(request), request.data ?? {}));

export const createOwnProfile = onCall((request) => createOwnProfileFor(getFirestore(), callerOf(request), request.data ?? {}));

export const createPairingCode = onCall((request) => createPairingCodeFor(getFirestore(), callerOf(request), request.data ?? {}));

export const redeemPairingCode = onCall((request) => redeemPairingCodeFor(getFirestore(), getAuth(), request.data ?? {}));

export const deleteAccount = onCall((request) => deleteAccountFor(getFirestore(), getAuth(), callerOf(request), request.data ?? {}));

// Runs next to the database (Toronto), which Firestore triggers require. Credits a finished workout to the profile's lifetime stats and personal bests, once.
export const onSessionCompleted = onDocumentCreated({ document: 'profiles/{profileId}/sessions/{sessionId}', region: 'northamerica-northeast2' }, async (event) => {
  await processSession(getFirestore(), event.params.profileId, event.params.sessionId, new Date(), await loadTuning());
});
