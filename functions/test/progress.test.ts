import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

import { addWorkout, creditFor, dayKey, emptyStats, tuningFrom, type DrillSpec, type SetLog, type Tuning, type WorkoutInput } from '../src/progress';

interface VectorWorkout {
  id: string;
  startedAtMs: number;
  tzOffsetMinutes: number;
  sets: { drill: string; log: SetLog }[];
}

const vectors = JSON.parse(readFileSync(new URL('./vectors/progress.json', import.meta.url), 'utf8')) as {
  drills: Record<string, DrillSpec>;
  cases: { name: string; daySecondsSoFar: number; tuning?: Partial<Record<keyof Tuning, number>>; workout: VectorWorkout; expected: Record<string, unknown> }[];
  sequences: { name: string; workouts: VectorWorkout[]; expected: Record<string, unknown> }[];
};

const toInput = (w: VectorWorkout): WorkoutInput => ({ id: w.id, startedAtMs: w.startedAtMs, tzOffsetMinutes: w.tzOffsetMinutes, sets: w.sets.map((s) => ({ drill: vectors.drills[s.drill], log: s.log })) });

const round6 = (v: number) => Math.round(v * 1e6) / 1e6;
const roundMap = (m: Record<string, number | undefined>) => Object.fromEntries(Object.entries(m).map(([k, v]) => [k, round6(v as number)]));
const bestValues = (bests: Record<string, { value: number }>) => Object.fromEntries(Object.entries(bests).map(([k, b]) => [k, round6(b.value)]));

describe('stats rules match the app', () => {
  for (const c of vectors.cases) {
    it(`credit: ${c.name}`, () => {
      const credit = creditFor(toInput(c.workout), c.daySecondsSoFar, tuningFrom(c.tuning ?? {}));
      expect({ seconds: round6(credit.seconds), shots: credit.shots, pillarSeconds: roundMap(credit.pillarSeconds), bests: bestValues(credit.bests) }).toEqual(c.expected);
    });
  }

  for (const s of vectors.sequences) {
    it(`stats: ${s.name}`, () => {
      let stats = emptyStats();
      const newBestKeys: string[][] = [];
      for (const w of s.workouts) {
        const result = addWorkout(stats, toInput(w));
        stats = result.stats;
        newBestKeys.push(result.newBests.map((b) => b.key).sort());
      }
      expect({
        workouts: stats.workouts,
        seconds: round6(stats.seconds),
        shots: stats.shots,
        pillarSeconds: roundMap(stats.pillarSeconds),
        bests: bestValues(stats.bests),
        days: Object.fromEntries(Object.entries(stats.days).map(([k, v]) => [k, [round6(v[0]), v[1]]])),
        newBestKeys,
      }).toEqual(s.expected);
    });
  }

  it('ignores remote values that are missing or out of range', () => {
    expect(tuningFrom({})).toEqual({ maxShotsPerSecond: 5, maxSessionSeconds: 10800, maxDaySeconds: 14400 });
    expect(tuningFrom({ maxShotsPerSecond: 8, maxSessionSeconds: 7200, maxDaySeconds: 9000 })).toEqual({ maxShotsPerSecond: 8, maxSessionSeconds: 7200, maxDaySeconds: 9000 });
    expect(tuningFrom({ maxShotsPerSecond: 0, maxSessionSeconds: -1, maxDaySeconds: Number.NaN })).toEqual({ maxShotsPerSecond: 5, maxSessionSeconds: 10800, maxDaySeconds: 14400 });
  });

  it('turns a moment into the player\'s own calendar day', () => {
    const lateEvening = Date.UTC(2026, 9, 21, 2, 0);
    expect(dayKey(lateEvening, 0)).toBe('2026-10-21');
    expect(dayKey(lateEvening, -300)).toBe('2026-10-20');
    expect(dayKey(lateEvening, 600)).toBe('2026-10-21');
  });
});
