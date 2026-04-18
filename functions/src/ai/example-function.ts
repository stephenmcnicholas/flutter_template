import * as functions from 'firebase-functions';
import { createAdapter } from './factory';

// Example callable Cloud Function using the LLM adapter.
// Copy and adapt this pattern for each AI feature in your app.
// Flutter app calls this via:
//   FirebaseFunctions.instance.httpsCallable('exampleAiFunction').call({'prompt': 'Hello'})
export const exampleAiFunction = functions.https.onCall(async (data, context) => {
  const { prompt } = data;

  if (!prompt || typeof prompt !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'prompt is required');
  }

  const adapter = createAdapter();

  const result = await adapter.generateText({
    systemPrompt: 'You are a helpful assistant.',
    userPrompt: prompt,
    maxTokens: 512,
  });

  return { response: result.content, model: result.model, vendor: result.vendor };
});
