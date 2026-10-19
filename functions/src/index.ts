import { getFirestore } from 'firebase-admin/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { onCall } from 'firebase-functions/v2/https';

import { getHealthStatus } from './health';
import { createChildProfile as createChildProfileFor, createOwnProfile as createOwnProfileFor, type CallerAuth } from './profiles';

import { createPairingCode as createPairingCodeFor, redeemPairingCode as redeemPairingCodeFor } from './pairing';

initializeApp();

export const healthCheck = onCall(() => getHealthStatus());

function callerOf(request: { auth?: { uid: string; token: { email?: string; firebase?: { sign_in_provider?: string } } } }): CallerAuth | undefined {
  const auth = request.auth;
  if (!auth) return undefined;
  return { uid: auth.uid, isAnonymous: auth.token.firebase?.sign_in_provider === 'anonymous', email: auth.token.email };
}

export const createChildProfile = onCall((request) => createChildProfileFor(getFirestore(), callerOf(request), request.data ?? {}));

export const createOwnProfile = onCall((request) => createOwnProfileFor(getFirestore(), callerOf(request), request.data ?? {}));

export const createPairingCode = onCall((request) => createPairingCodeFor(getFirestore(), callerOf(request), request.data ?? {}));

export const redeemPairingCode = onCall((request) => redeemPairingCodeFor(getFirestore(), getAuth(), request.data ?? {}));
