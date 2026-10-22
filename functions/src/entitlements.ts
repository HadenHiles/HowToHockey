import { timingSafeEqual } from 'node:crypto';

import type { Firestore } from 'firebase-admin/firestore';

export const PLAYER_PRO = 'player_pro';
export const COACH_PRO = 'coach_pro';

export interface PlanState {
  player: boolean;
  coach: boolean;
}

export function programsFromSubscriber(body: unknown, now: Date): string[] {
  const entitlements = ((body as { subscriber?: { entitlements?: Record<string, SubscriberEntitlement> } } | null)?.subscriber?.entitlements ?? {}) as Record<string, SubscriberEntitlement>;
  return Object.entries(entitlements)
    .filter(([id, entitlement]) => id.startsWith('program_') && stillActive(entitlement, now))
    .map(([id]) => id)
    .sort();
}

interface SubscriberEntitlement {
  expires_date?: string | null;
  grace_period_expires_date?: string | null;
}

function stillActive(entitlement: SubscriberEntitlement | undefined, now: Date): boolean {
  if (!entitlement) return false;
  // A billing grace period keeps access until it runs out; no expiry at all means a lifetime grant.
  const until = entitlement.grace_period_expires_date ?? entitlement.expires_date;
  if (until === null) return true;
  return until !== undefined && new Date(until).getTime() > now.getTime();
}

/** Reads the plans an account holds from a RevenueCat subscriber record. Coach Pro always includes Player Pro. */
export function planFromSubscriber(body: unknown, now: Date): PlanState {
  const entitlements = ((body as { subscriber?: { entitlements?: Record<string, SubscriberEntitlement> } } | null)?.subscriber?.entitlements ?? {}) as Record<string, SubscriberEntitlement>;
  const coach = stillActive(entitlements[COACH_PRO], now);
  return { coach, player: coach || stillActive(entitlements[PLAYER_PRO], now) };
}

/** Our account IDs are what we give RevenueCat to identify a buyer; its own anonymous and alias IDs are skipped. */
export function accountIdsInEvent(event: Record<string, unknown> | undefined): string[] {
  if (!event) return [];
  const listed = (value: unknown): unknown[] => (Array.isArray(value) ? value : [value]);
  const raw = [event.app_user_id, event.original_app_user_id, ...listed(event.aliases ?? []), ...listed(event.transferred_from ?? []), ...listed(event.transferred_to ?? [])];
  return [...new Set(raw.filter((id): id is string => typeof id === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(id)))];
}

/**
 * Records an account's plans, and the one flag the rest of the system reads: `pro` on every profile it owns.
 * A plan on the account covers its own profile and every child profile, so one flag on each is enough for a
 * kid device, which can't hold a plan itself. Accounts that no longer exist are left alone.
 */
export async function applyPlan(db: Firestore, uid: string, plan: PlanState, now: Date, programs: string[] = []): Promise<boolean> {
  const userRef = db.collection('users').doc(uid);
  const [user, owned] = await Promise.all([userRef.get(), db.collection('profiles').where('ownerUid', '==', uid).get()]);
  if (!user.exists && owned.empty) return false;
  const batch = db.batch();
  batch.set(userRef, { entitlements: { playerPro: plan.player, coachPro: plan.coach, programs, updatedAt: now } }, { merge: true });
  for (const profile of owned.docs) batch.update(profile.ref, { pro: plan.player });
  await batch.commit();
  return true;
}

export interface WebhookRequest {
  authorization: string | undefined;
  body: unknown;
}

export interface WebhookDependencies {
  db: Firestore;
  expectedAuthorization: string;
  fetchSubscriber: (uid: string) => Promise<unknown>;
  now?: Date;
}

function sameSecret(given: string | undefined, expected: string): boolean {
  if (!given || expected.length === 0) return false;
  const a = Buffer.from(given);
  const b = Buffer.from(expected);
  return a.length === b.length && timingSafeEqual(a, b);
}

/**
 * Handles a RevenueCat webhook. The event only says who to look at; the account's current plans are always
 * re-read from RevenueCat, so out-of-order or repeated events can't leave a stale answer behind.
 */
export async function handleRevenueCatWebhook(request: WebhookRequest, deps: WebhookDependencies): Promise<{ status: number; message: string }> {
  if (!sameSecret(request.authorization, deps.expectedAuthorization)) return { status: 401, message: 'Not allowed.' };
  const event = (request.body as { event?: Record<string, unknown> } | null)?.event;
  if (!event || typeof event !== 'object') return { status: 400, message: 'No event.' };

  const now = deps.now ?? new Date();
  let updated = 0;
  for (const uid of accountIdsInEvent(event)) {
    const subscriber = await deps.fetchSubscriber(uid);
    const plan = planFromSubscriber(subscriber, now);
    if (await applyPlan(deps.db, uid, plan, now, programsFromSubscriber(subscriber, now))) updated += 1;
  }
  return { status: 200, message: `Updated ${updated}.` };
}

/** Reads one account's record with RevenueCat's REST API, using a secret key that only the server holds. */
export function revenueCatFetcher(secretKey: string, fetcher: typeof fetch = fetch): (uid: string) => Promise<unknown> {
  return async (uid) => {
    const response = await fetcher(`https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`, { headers: { Authorization: `Bearer ${secretKey}`, 'Content-Type': 'application/json' } });
    if (!response.ok) throw new Error(`RevenueCat answered ${response.status}.`);
    return response.json();
  };
}
