# Module: AI (LLM Adapter)

**What it does:** Vendor-agnostic LLM integration via Firebase Cloud Functions. The Flutter app calls Cloud Function endpoints; those functions route requests through the adapter layer to whichever LLM vendor is configured. Swap vendor/model via environment variables without changing app code.

**Files:**
- `functions/src/ai/adapter.ts` — LLMAdapter interface and types
- `functions/src/ai/config.ts` — vendor/model config from environment variables
- `functions/src/ai/factory.ts` — createAdapter() factory function
- `functions/src/ai/adapters/claude.ts` — Anthropic Claude implementation
- `functions/src/ai/adapters/gemini.ts` — Google Gemini/Vertex AI implementation
- `functions/src/ai/example-function.ts` — example callable function
- `functions/package.json` dependencies: `@anthropic-ai/sdk`, `@google-cloud/vertexai`

**Configuration (Firebase environment variables):**
- `AI_VENDOR` — `claude` (default) or `gemini`
- `AI_MODEL` — model name (defaults: `claude-sonnet-4-6` / `gemini-2.5-flash`)
- `AI_API_KEY` — required for Claude
- `GOOGLE_CLOUD_PROJECT` — required for Gemini

**Dependencies:** Cloud Functions module (Firebase)

**To remove this module:**
1. Delete `functions/src/ai/` directory
2. Remove `@anthropic-ai/sdk` from `functions/package.json` (keep `@google-cloud/vertexai` if Gemini used elsewhere)
3. Remove AI function exports from `functions/src/index.ts`
4. Remove `cloud_functions` from Flutter `pubspec.yaml` if no other functions used

**To add a new AI feature:**
1. Copy `example-function.ts`, rename, adapt system prompt and response shape
2. Export the new function from `functions/src/index.ts`
3. Call it from Flutter using `FirebaseFunctions.instance.httpsCallable('yourFunctionName').call(data)`
