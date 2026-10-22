import { getFirestore } from 'firebase-admin/firestore';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onCall, onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

import { deleteProfileRoutine as deleteProfileRoutineFor, saveProfileRoutine as saveProfileRoutineFor } from './routines';
import { correctSession as correctSessionFor } from './corrections';
import { getHealthStatus } from './health';
import { createChildProfile as createChildProfileFor, createOwnProfile as createOwnProfileFor, type CallerAuth } from './profiles';

import { deleteAccount as deleteAccountFor } from './accounts';
import { handleRevenueCatWebhook, revenueCatFetcher } from './entitlements';
import { processSession } from './sessions';
import { getProgramCatalog as getProgramCatalogData, getProgramDashboard as getProgramDashboardFor, startProgramDay as startProgramDayFor } from './programs';
import { loadTuning } from './tuning';
import { createPairingCode as createPairingCodeFor, redeemPairingCode as redeemPairingCodeFor } from './pairing';
import * as teams from './teams';

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

export const createTeam = onCall((request) => teams.createTeam(getFirestore(), callerOf(request), request.data ?? {}));
export const updateTeam = onCall((request) => teams.updateTeam(getFirestore(), callerOf(request), request.data ?? {}));
export const createTeamInvite = onCall((request) => teams.createTeamInvite(getFirestore(), callerOf(request), request.data ?? {}));
export const previewTeamInvite = onCall((request) => teams.previewTeamInvite(getFirestore(), callerOf(request), request.data ?? {}));
export const joinTeam = onCall((request) => teams.joinTeam(getFirestore(), callerOf(request), request.data ?? {}));
export const acceptCoachInvite = onCall((request) => teams.acceptCoachInvite(getFirestore(), callerOf(request), request.data ?? {}));
export const reviewTeamRequest = onCall((request) => teams.reviewTeamRequest(getFirestore(), callerOf(request), request.data ?? {}));
export const correctSession = onCall(async (request) => correctSessionFor(getFirestore(), callerOf(request), request.data ?? {}, new Date(), await loadTuning()));
export const saveProfileRoutine = onCall((request) => saveProfileRoutineFor(getFirestore(), callerOf(request), request.data ?? {}));
export const deleteProfileRoutine = onCall((request) => deleteProfileRoutineFor(getFirestore(), callerOf(request), request.data ?? {}));
export const getProgramCatalog = onCall(() => ({ programs: getProgramCatalogData() }));
export const getProgramDashboard = onCall((request) => getProgramDashboardFor(getFirestore(), callerOf(request), request.data ?? {}));
export const startProgramDay = onCall((request) => startProgramDayFor(getFirestore(), callerOf(request), request.data ?? {}));
export const setTeamRoutine = onCall((request) => teams.setTeamRoutine(getFirestore(), callerOf(request), request.data ?? {}));
export const clearTeamRoutine = onCall((request) => teams.clearTeamRoutine(getFirestore(), callerOf(request), request.data ?? {}));
export const removeTeamMember = onCall((request) => teams.removeTeamMember(getFirestore(), callerOf(request), request.data ?? {}));

// Runs next to the database (Toronto), which Firestore triggers require. Credits a finished workout to the profile's lifetime stats and personal bests, once.
// Runs when a session is created as completed, or when a parent confirms a pending one. Pending drafts and
// sessions that were already credited are skipped.
export const onSessionCompleted = onDocumentWritten({ document: 'profiles/{profileId}/sessions/{sessionId}', region: 'northamerica-northeast2' }, async (event) => {
  const after = event.data?.after;
  if (!after?.exists || after.data()?.status !== 'completed' || after.data()?.processedAt) return;
  await processSession(getFirestore(), event.params.profileId, event.params.sessionId, new Date(), await loadTuning());
});

const revenueCatWebhookAuth = defineSecret('REVENUECAT_WEBHOOK_AUTH');
const revenueCatSecretKey = defineSecret('REVENUECAT_SECRET_KEY');

// RevenueCat calls this when someone buys, renews, cancels or expires. It keeps the account's plans, and the
// `pro` flag on each profile it owns, in step with the store.
export const revenueCatWebhook = onRequest({ secrets: [revenueCatWebhookAuth, revenueCatSecretKey], invoker: 'public' }, async (request, response) => {
  if (request.method !== 'POST') {
    response.status(405).send('Use POST.');
    return;
  }
  try {
    const result = await handleRevenueCatWebhook(
      { authorization: request.get('authorization'), body: request.body },
      { db: getFirestore(), expectedAuthorization: revenueCatWebhookAuth.value(), fetchSubscriber: revenueCatFetcher(revenueCatSecretKey.value()) },
    );
    response.status(result.status).send(result.message);
  } catch (error) {
    console.error('RevenueCat webhook failed', error);
    // A server error makes RevenueCat retry, which is what we want when its record or ours was unreachable.
    response.status(500).send('Try again.');
  }
});
