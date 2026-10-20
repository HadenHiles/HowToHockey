import { getRemoteConfig } from 'firebase-admin/remote-config';

import { DEFAULT_TUNING, tuningFrom, type Tuning } from './progress';

/** The same parameter names the app reads. */
export const TUNING_KEYS = {
  maxShotsPerSecond: 'progress_max_shots_per_second',
  maxSessionSeconds: 'progress_max_session_seconds',
  maxDaySeconds: 'progress_max_day_seconds',
} as const;

const REFRESH_MS = 5 * 60_000;
let cached: { tuning: Tuning; at: number } | undefined;

type Parameters = Record<string, { defaultValue?: { value?: string } | { useInAppDefault?: boolean } } | undefined>;

/** Reads a number from a template's default values (conditions are not used for these settings). */
export function numberFrom(parameters: Parameters, key: string): number | undefined {
  const value = (parameters[key]?.defaultValue as { value?: string } | undefined)?.value;
  const parsed = value == null ? Number.NaN : Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

export function tuningFromTemplate(parameters: Parameters): Tuning {
  return tuningFrom({
    maxShotsPerSecond: numberFrom(parameters, TUNING_KEYS.maxShotsPerSecond),
    maxSessionSeconds: numberFrom(parameters, TUNING_KEYS.maxSessionSeconds),
    maxDaySeconds: numberFrom(parameters, TUNING_KEYS.maxDaySeconds),
  });
}

/** Reads the published Remote Config template, remembering it for a few minutes. Falls back to the defaults if it can't. */
export async function loadTuning(now = Date.now()): Promise<Tuning> {
  if (cached && now - cached.at < REFRESH_MS) return cached.tuning;
  try {
    const template = await getRemoteConfig().getTemplate();
    const tuning = tuningFromTemplate(template.parameters as Parameters);
    cached = { tuning, at: now };
    return tuning;
  } catch (error) {
    console.warn('Using the default progress settings:', error);
    return cached?.tuning ?? DEFAULT_TUNING;
  }
}
