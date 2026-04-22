import { onCall, HttpsError, type CallableRequest } from 'firebase-functions/v2/https';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';
import { createAdapter } from './factory';

/**
 * Returns the UTC year-month key used for monthly usage bucketing, e.g. "2026-04".
 * Used to reset the per-user counter each calendar month.
 */
function monthKey(): string {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

/**
 * Maximum LLM calls allowed per user per calendar month.
 * Adjust this constant per-function based on expected cost.
 */
const MONTHLY_LIMIT = 50;

/**
 * Example callable Cloud Function using the LLM adapter.
 *
 * Demonstrates the full production pattern:
 *   1. Auth guard (unauthenticated callers rejected)
 *   2. App Check monitoring (log missing tokens before enforcement is enabled)
 *   3. Monthly rate limit (usageLimits/{uid} Firestore document)
 *   4. LLM adapter call (vendor-agnostic via env vars)
 *   5. Usage counter increment on success
 *
 * Copy and adapt this file for each AI feature in your app.
 * Change: function name, MONTHLY_LIMIT, systemPrompt, input shape, response shape.
 * Do not change: auth guard, App Check logging, rate limit pattern.
 *
 * Flutter calls this via:
 *   final result = await FirebaseFunctions.instance
 *     .httpsCallable('exampleAiFunction')
 *     .call({'prompt': 'Hello'});
 *
 * To switch enforceAppCheck to true once App Check is confirmed working,
 * change the onCall options below and remove the monitoring log.
 */
export const exampleAiFunction = onCall(
  {
    timeoutSeconds: 60,
    region: 'us-central1',
    enforceAppCheck: false, // set true after confirming App Check in monitoring mode
  },
  async (request: CallableRequest<{ prompt: string }>) => {
    // 1. Auth guard
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    // 2. App Check monitoring — log before enforcement is enabled
    if (!request.app) {
      logger.warn('[exampleAiFunction] App Check token missing or invalid', {
        uid: request.auth.uid,
      });
    }

    // 3. Monthly rate limit
    const db = admin.firestore();
    const usageRef = db.collection('usageLimits').doc(request.auth.uid);
    const usageSnap = await usageRef.get();
    const usageData = usageSnap.data() ?? {};
    const currentMonth = monthKey();

    if (
      usageData.aiMonthKey === currentMonth &&
      (usageData.aiCount ?? 0) >= MONTHLY_LIMIT
    ) {
      logger.info('[exampleAiFunction] Monthly limit reached', { uid: request.auth.uid });
      throw new HttpsError('resource-exhausted', 'monthly_limit_reached');
    }

    // 4. Validate input
    const { prompt } = request.data;
    if (!prompt || typeof prompt !== 'string') {
      throw new HttpsError('invalid-argument', 'prompt is required');
    }

    // 5. Call LLM adapter
    const adapter = createAdapter();
    const result = await adapter.generateText({
      systemPrompt: 'You are a helpful assistant.',
      userPrompt: prompt,
      maxTokens: 512,
    });

    // 6. Increment usage counter on success
    await usageRef.set(
      { aiMonthKey: currentMonth, aiCount: admin.firestore.FieldValue.increment(1) },
      { merge: true },
    );

    return { response: result.content, model: result.model, vendor: result.vendor };
  },
);
