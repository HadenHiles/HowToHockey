import { describe, expect, it } from 'vitest';

import { DEFAULT_TUNING } from '../src/progress';
import { numberFrom, tuningFromTemplate } from '../src/tuning';

describe('tuning from the Remote Config template', () => {
  it('reads the published numbers', () => {
    const tuning = tuningFromTemplate({
      progress_max_shots_per_second: { defaultValue: { value: '8' } },
      progress_max_session_seconds: { defaultValue: { value: '7200' } },
      progress_max_day_seconds: { defaultValue: { value: '9000' } },
    });
    expect(tuning).toEqual({ maxShotsPerSecond: 8, maxSessionSeconds: 7200, maxDaySeconds: 9000 });
  });

  it('keeps the defaults for anything missing, in-app, or out of range', () => {
    expect(tuningFromTemplate({})).toEqual(DEFAULT_TUNING);
    expect(
      tuningFromTemplate({
        progress_max_shots_per_second: { defaultValue: { useInAppDefault: true } },
        progress_max_session_seconds: { defaultValue: { value: 'lots' } },
        progress_max_day_seconds: { defaultValue: { value: '5' } },
      }),
    ).toEqual(DEFAULT_TUNING);
    expect(numberFrom({ a: { defaultValue: { value: '' } } }, 'a')).toBe(0);
  });
});
