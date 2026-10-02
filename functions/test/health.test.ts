import { describe, expect, it } from 'vitest';

import { getHealthStatus } from '../src/health';

describe('getHealthStatus', () => {
  it('returns the healthy status payload', () => {
    expect(getHealthStatus()).toEqual({ status: 'ok' });
  });
});
