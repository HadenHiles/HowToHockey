import { readFileSync } from 'node:fs';

import { describe, expect, it } from 'vitest';

import { normalizeDisplayName, validateBirthYear, yearsSinceBirthYear } from '../src/profiles';

const vectors = JSON.parse(readFileSync(new URL('./vectors/display-names.json', import.meta.url), 'utf8')) as {
  valid: { input: string; expected: string }[];
  invalid: string[];
};

describe('normalizeDisplayName', () => {
  it.each(vectors.valid)('accepts and tidies %j', ({ input, expected }) => {
    expect(normalizeDisplayName(input)).toBe(expected);
  });

  it.each(vectors.invalid)('rejects %j', (input) => {
    expect(() => normalizeDisplayName(input)).toThrow(/first name and last initial/i);
  });

  it('rejects values that are not text', () => {
    for (const value of [undefined, null, 12, {}, ['Jamie H.']]) {
      expect(() => normalizeDisplayName(value)).toThrow();
    }
  });
});

describe('validateBirthYear', () => {
  const now = new Date('2026-10-16T12:00:00Z');

  it('accepts a whole-number year in the last hundred years', () => {
    expect(validateBirthYear(2012, now)).toBe(2012);
    expect(validateBirthYear(2026, now)).toBe(2026);
    expect(validateBirthYear(1926, now)).toBe(1926);
  });

  it('rejects the future, ancient years, and anything that is not an integer', () => {
    for (const value of [2027, 1925, 2012.5, '2012', null, undefined, NaN]) {
      expect(() => validateBirthYear(value, now)).toThrow();
    }
  });

  it('reads age from the year difference', () => {
    expect(yearsSinceBirthYear(2012, now)).toBe(14);
  });
});
