import { onCall } from 'firebase-functions/v2/https';

import { getHealthStatus } from './health';

export const healthCheck = onCall(() => getHealthStatus());
