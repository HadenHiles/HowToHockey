import { describe, expect, it } from 'vitest';

import { accountIdsInEvent, planFromSubscriber, programsFromSubscriber, revenueCatFetcher } from '../src/entitlements';

const now = new Date('2026-10-20T12:00:00Z');
const future = '2027-01-01T00:00:00Z';
const past = '2026-01-01T00:00:00Z';

describe('planFromSubscriber', () => {
  it('reads an active Player Pro plan', () => {
    expect(planFromSubscriber({ subscriber: { entitlements: { player_pro: { expires_date: future } } } }, now)).toEqual({ player: true, coach: false });
  });

  describe('programsFromSubscriber', () => {
    it('keeps active program entitlements and drops expired or unrelated entitlements', () => {
      expect(
        programsFromSubscriber(
          {
            subscriber: {
              entitlements: {
                'program_shooting-30': { expires_date: future },
                'program_hands-21': { expires_date: past },
                player_pro: { expires_date: future },
              },
            },
          },
          now,
        ),
      ).toEqual(['program_shooting-30']);
    });
  });

  it('lets Coach Pro include Player Pro even if only Coach Pro is listed', () => {
    expect(planFromSubscriber({ subscriber: { entitlements: { coach_pro: { expires_date: future } } } }, now)).toEqual({ player: true, coach: true });
  });

  it('treats an expired plan as gone', () => {
    expect(planFromSubscriber({ subscriber: { entitlements: { player_pro: { expires_date: past }, coach_pro: { expires_date: past } } } }, now)).toEqual({ player: false, coach: false });
  });

  it('keeps access during a billing grace period, and ends it when the grace runs out', () => {
    const during = { subscriber: { entitlements: { player_pro: { expires_date: past, grace_period_expires_date: future } } } };
    expect(planFromSubscriber(during, now).player).toBe(true);
    const after = { subscriber: { entitlements: { player_pro: { expires_date: past, grace_period_expires_date: past } } } };
    expect(planFromSubscriber(after, now).player).toBe(false);
  });

  it('treats a plan with no expiry as lifetime', () => {
    expect(planFromSubscriber({ subscriber: { entitlements: { player_pro: { expires_date: null } } } }, now).player).toBe(true);
  });

  it('gives no plan for empty, missing or malformed records', () => {
    for (const body of [null, undefined, {}, { subscriber: {} }, { subscriber: { entitlements: { player_pro: {} } } }, 'nope']) {
      expect(planFromSubscriber(body, now)).toEqual({ player: false, coach: false });
    }
  });
});

describe('accountIdsInEvent', () => {
  it('collects our account IDs from the buyer, aliases and transfers once each', () => {
    const ids = accountIdsInEvent({ app_user_id: 'abc123', original_app_user_id: 'abc123', aliases: ['abc123', 'def456'], transferred_from: ['ghi789'], transferred_to: ['abc123'] });
    expect(ids.sort()).toEqual(['abc123', 'def456', 'ghi789']);
  });

  it('skips RevenueCat anonymous IDs and anything that is not a plain ID', () => {
    expect(accountIdsInEvent({ app_user_id: '$RCAnonymousID:1234', aliases: ['has space', '', 42, null, 'ok_id-1'] })).toEqual(['ok_id-1']);
  });

  it('copes with a missing event', () => {
    expect(accountIdsInEvent(undefined)).toEqual([]);
  });
});

describe('revenueCatFetcher', () => {
  it('asks RevenueCat for one account with the secret key', async () => {
    let seen: { url: string; auth: string | undefined } | undefined;
    const fake = (async (url: string, init?: { headers?: Record<string, string> }) => {
      seen = { url, auth: init?.headers?.Authorization };
      return { ok: true, status: 200, json: async () => ({ subscriber: {} }) };
    }) as unknown as typeof fetch;
    await revenueCatFetcher('sk_secret', fake)('abc 1');
    expect(seen).toEqual({ url: 'https://api.revenuecat.com/v1/subscribers/abc%201', auth: 'Bearer sk_secret' });
  });

  it('fails loudly when RevenueCat is unreachable so the webhook is retried', async () => {
    const fake = (async () => ({ ok: false, status: 503, json: async () => ({}) })) as unknown as typeof fetch;
    await expect(revenueCatFetcher('sk', fake)('abc')).rejects.toThrow(/503/);
  });
});
