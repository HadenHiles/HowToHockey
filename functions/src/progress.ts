/**
 * Training stats rules. This is a line-for-line twin of `lib/features/progress/progress_stats.dart`;
 * both are checked against the same cases in `functions/test/vectors/progress.json`.
 */

export type Tracking = 'volume' | 'duration' | 'density' | 'accuracy' | 'streak' | 'binary';
export type Pillar = 'shotAccuracy' | 'hands' | 'shotPower' | 'passing' | 'speedStrength' | 'endurance';
export const PILLARS: Pillar[] = ['shotAccuracy', 'hands', 'shotPower', 'passing', 'speedStrength', 'endurance'];
export type BestKind = 'accuracy' | 'shotsPerMinute' | 'streak' | 'reps' | 'seconds';

/** The tunable numbers. Defaults here match the app's; Remote Config can change them without a release. */
export interface Tuning {
  maxShotsPerSecond: number;
  maxSessionSeconds: number;
  maxDaySeconds: number;
}

export const DEFAULT_TUNING: Tuning = { maxShotsPerSecond: 5, maxSessionSeconds: 3 * 3600, maxDaySeconds: 4 * 3600 };

/** Takes remote values that are sensible and keeps the default for the rest (same ranges as the app). */
export function tuningFrom(values: Partial<Record<keyof Tuning, number | undefined>>): Tuning {
  const pick = (v: number | undefined, fallback: number, low: number, high: number) => (v != null && Number.isFinite(v) && v >= low && v <= high ? v : fallback);
  return {
    maxShotsPerSecond: pick(values.maxShotsPerSecond, DEFAULT_TUNING.maxShotsPerSecond, 1, 20),
    maxSessionSeconds: Math.round(pick(values.maxSessionSeconds, DEFAULT_TUNING.maxSessionSeconds, 600, 86400)),
    maxDaySeconds: Math.round(pick(values.maxDaySeconds, DEFAULT_TUNING.maxDaySeconds, 600, 86400)),
  };
}

const KEEP_DAYS = 400;

export interface SetLog {
  reps?: number | null;
  hits?: number | null;
  seconds?: number | null;
  streak?: number | null;
  completed?: boolean | null;
  loggedAtMs: number;
}

export interface DrillSpec {
  id: string;
  title: string;
  tracking: Tracking;
  weights: Partial<Record<Pillar, number>>;
  estimatedSecondsPerSet: number;
}

export interface WorkoutInput {
  id: string;
  startedAtMs: number;
  /** Minutes east of UTC for the player's phone when they trained, so days match what they see. */
  tzOffsetMinutes: number;
  sets: { drill: DrillSpec; log: SetLog }[];
}

export interface Best {
  key: string;
  drillId: string;
  title: string;
  kind: BestKind;
  value: number;
  achievedAtMs: number;
  workoutId: string;
}

export interface Credit {
  seconds: number;
  shots: number;
  pillarSeconds: Partial<Record<Pillar, number>>;
  bests: Record<string, Best>;
}

export interface Stats {
  workouts: number;
  seconds: number;
  shots: number;
  pillarSeconds: Partial<Record<Pillar, number>>;
  bests: Record<string, Best>;
  /** `yyyy-MM-dd` to [seconds, shots]. */
  days: Record<string, [number, number]>;
}

export const emptyStats = (): Stats => ({ workouts: 0, seconds: 0, shots: 0, pillarSeconds: {}, bests: {}, days: {} });

const activeSeconds = (drill: DrillSpec, log: SetLog): number => log.seconds ?? drill.estimatedSecondsPerSet;

export function isCountableSet(drill: DrillSpec, log: SetLog, tuning: Tuning = DEFAULT_TUNING): boolean {
  const seconds = log.seconds;
  if (seconds != null && (seconds <= 0 || seconds > 3600)) return false;
  const reps = log.reps;
  if (reps != null) {
    if (reps < 0 || reps > 10000) return false;
    const window = seconds ?? drill.estimatedSecondsPerSet;
    if (window > 0 && reps / window > tuning.maxShotsPerSecond) return false;
  }
  const streak = log.streak;
  if (streak != null && (streak < 0 || streak > 100000)) return false;
  return true;
}

export const isShootingDrill = (drill: DrillSpec): boolean => (drill.weights.shotAccuracy ?? 0) + (drill.weights.shotPower ?? 0) >= 0.5 && drill.tracking !== 'duration';

export function creditFor(workout: WorkoutInput, daySecondsSoFar = 0, tuning: Tuning = DEFAULT_TUNING): Credit {
  const counted = workout.sets.filter((s) => isCountableSet(s.drill, s.log, tuning)).map((s) => ({ ...s, seconds: activeSeconds(s.drill, s.log) }));
  const raw = counted.reduce((sum, s) => sum + s.seconds, 0);
  const allowed = Math.min(raw, tuning.maxSessionSeconds, Math.max(0, tuning.maxDaySeconds - daySecondsSoFar));
  const factor = raw === 0 ? 0 : allowed / raw;

  const pillarSeconds: Partial<Record<Pillar, number>> = {};
  const bests: Record<string, Best> = {};
  let shots = 0;
  const consider = (key: string, drill: DrillSpec, kind: BestKind, value: number, at: number) => {
    if (value <= 0) return;
    const current = bests[key];
    if (!current || value > current.value) bests[key] = { key, drillId: drill.id, title: drill.title, kind, value, achievedAtMs: at, workoutId: workout.id };
  };

  for (const set of counted) {
    const credited = set.seconds * factor;
    for (const pillar of PILLARS) {
      const weight = set.drill.weights[pillar];
      if (weight != null) pillarSeconds[pillar] = (pillarSeconds[pillar] ?? 0) + credited * weight;
    }
    const { log, drill } = set;
    if (isShootingDrill(drill)) shots += log.reps ?? 0;
    switch (drill.tracking) {
      case 'accuracy':
        if (log.hits != null && log.reps != null && log.reps > 0 && log.reps >= 10) consider(`accuracy:${drill.id}`, drill, 'accuracy', (log.hits / log.reps) * 100, log.loggedAtMs);
        break;
      case 'density':
        if (log.reps != null && log.seconds != null && log.seconds > 0) consider(`density:${drill.id}`, drill, 'shotsPerMinute', (log.reps / log.seconds) * 60, log.loggedAtMs);
        break;
      case 'streak':
        consider(`streak:${drill.id}`, drill, 'streak', log.streak ?? 0, log.loggedAtMs);
        break;
      case 'volume':
        consider(`reps:${drill.id}`, drill, 'reps', log.reps ?? 0, log.loggedAtMs);
        break;
      case 'duration':
        consider(`seconds:${drill.id}`, drill, 'seconds', log.seconds ?? 0, log.loggedAtMs);
        break;
      case 'binary':
        break;
    }
  }
  return { seconds: allowed, shots, pillarSeconds, bests };
}

/** The player's calendar day for a moment, given their phone's offset from UTC. */
export function dayKey(ms: number, tzOffsetMinutes: number): string {
  const shifted = new Date(ms + tzOffsetMinutes * 60_000);
  return `${String(shifted.getUTCFullYear()).padStart(4, '0')}-${String(shifted.getUTCMonth() + 1).padStart(2, '0')}-${String(shifted.getUTCDate()).padStart(2, '0')}`;
}

/** Adds a workout to the stats. Returns the new stats and the personal bests it set. */
export function addWorkout(stats: Stats, workout: WorkoutInput, tuning: Tuning = DEFAULT_TUNING): { stats: Stats; newBests: Best[] } {
  const key = dayKey(workout.startedAtMs, workout.tzOffsetMinutes);
  const day = stats.days[key] ?? [0, 0];
  const credit = creditFor(workout, day[0], tuning);

  const bests = { ...stats.bests };
  const newBests: Best[] = [];
  for (const best of Object.values(credit.bests)) {
    const current = bests[best.key];
    if (!current || best.value > current.value) {
      bests[best.key] = best;
      newBests.push(best);
    }
  }
  const pillarSeconds = { ...stats.pillarSeconds };
  for (const pillar of PILLARS) {
    const add = credit.pillarSeconds[pillar];
    if (add != null) pillarSeconds[pillar] = (pillarSeconds[pillar] ?? 0) + add;
  }
  const days = { ...stats.days, [key]: [day[0] + credit.seconds, day[1] + credit.shots] as [number, number] };
  const keys = Object.keys(days).sort();
  for (const old of keys.slice(0, Math.max(0, keys.length - KEEP_DAYS))) delete days[old];
  return {
    stats: { workouts: stats.workouts + 1, seconds: stats.seconds + credit.seconds, shots: stats.shots + credit.shots, pillarSeconds, bests, days },
    newBests,
  };
}
