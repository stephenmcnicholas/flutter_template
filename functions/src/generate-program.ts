/**
 * Firebase callable: generateProgram. Requires auth.
 * Builds prompts, calls LLM (Vertex AI), validates response, returns programme JSON or error.
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { callLLM } from "./llm-adapter";
import { buildSystemPrompt, buildUserPrompt } from "./prompt-templates";
import { validateProgramme } from "./validate-program";
import type { GenerateProgramRequest, GeneratedProgramme } from "./types";

export interface GenerateProgramResult {
  success: true;
  programme: GeneratedProgramme;
  source: "llm" | "fallback";
}

export interface GenerateProgramError {
  success: false;
  error: string;
  code?: string;
}

export type GenerateProgramResponse = GenerateProgramResult | GenerateProgramError;

/** Returns the UTC year-month key used for monthly usage bucketing, e.g. "2026-04". */
function monthKey(): string {
  const d = new Date();
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

/**
 * Parse LLM response as JSON. Strips markdown code fences (```json ... ```) and
 * extracts a single JSON object if the response has leading/trailing text.
 */
function parseProgrammeJson(raw: string): unknown {
  let s = raw.trim();
  const codeFence = /^```(?:json)?\s*\n?([\s\S]*?)\n?```\s*$/im;
  const match = s.match(codeFence);
  if (match) s = match[1].trim();
  const firstBrace = s.indexOf("{");
  if (firstBrace >= 0) {
    let depth = 0;
    let end = -1;
    for (let i = firstBrace; i < s.length; i++) {
      if (s[i] === "{") depth++;
      else if (s[i] === "}") {
        depth--;
        if (depth === 0) {
          end = i;
          break;
        }
      }
    }
    if (end >= 0) s = s.slice(firstBrace, end + 1);
  }
  return JSON.parse(s);
}

export const generateProgram = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "512MB",
  })
  .region("us-central1")
  .https.onCall(async (data: unknown, context): Promise<GenerateProgramResponse> => {
    if (!context.auth) {
      return { success: false, error: "Unauthorized", code: "unauthenticated" };
    }

    const req = data as GenerateProgramRequest;
    if (!req?.exerciseLibrary?.length) {
      return {
        success: false,
        error: "Missing or empty exerciseLibrary",
        code: "invalid-argument",
      };
    }

    const projectId = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT;
    if (!projectId) {
      return {
        success: false,
        error: "Server misconfiguration: project ID not set",
        code: "internal",
      };
    }

    // --- Monthly usage rate limit ---
    const MONTHLY_LIMIT = 4;
    const db = admin.firestore();
    const usageRef = db.collection("usageLimits").doc(context.auth.uid);
    const usageSnap = await usageRef.get();
    const usageData = usageSnap.data() ?? {};
    const currentMonth = monthKey();
    if (
      usageData.programmeMonthKey === currentMonth &&
      (usageData.programmeCount ?? 0) >= MONTHLY_LIMIT
    ) {
      functions.logger.info("[generateProgram] Rate limit reached", { uid: context.auth.uid });
      throw new functions.https.HttpsError("resource-exhausted", "generation_limit_reached");
    }
    // --- End rate limit check ---

    const systemPrompt = buildSystemPrompt();
    const userPrompt = buildUserPrompt(req);

    const debugPayloads = process.env.GENERATE_PROGRAM_DEBUG_PAYLOADS === "1";

    functions.logger.info("[generateProgram] Invoked", {
      uid: context.auth.uid,
      exerciseLibrarySize: req.exerciseLibrary?.length ?? 0,
      userPromptLength: userPrompt.length,
    });

    if (debugPayloads) {
      functions.logger.info("[generateProgram] Request payload (user prompt preview)", {
        systemPromptLength: systemPrompt.length,
        userPromptPreview: userPrompt.slice(0, 1500),
      });
    }

    try {
      functions.logger.info("[generateProgram] Calling Vertex AI...");
      const rawResponse = await callLLM(projectId, systemPrompt, userPrompt);
      functions.logger.info("[generateProgram] Vertex responded", {
        responseLength: rawResponse?.length ?? 0,
      });

      if (debugPayloads && rawResponse) {
        functions.logger.info("[generateProgram] Response payload (preview)", {
          responsePreview: rawResponse.slice(0, 2500),
        });
      }
      let parsed: unknown;
      try {
        parsed = parseProgrammeJson(rawResponse ?? "");
      } catch (e) {
        const preview = (rawResponse ?? "").slice(0, 300);
        functions.logger.warn("[generateProgram] LLM returned invalid JSON", {
          uid: context.auth.uid,
          parseError: e instanceof Error ? e.message : String(e),
          responsePreview: preview,
        });
        return {
          success: false,
          error: "LLM returned invalid JSON; try again or use rule-built programme",
          code: "invalid-json",
        };
      }

      const validation = validateProgramme(parsed, req);
      if (!validation.ok) {
        functions.logger.warn("[generateProgram] Validation failed", {
          errors: validation.errors,
          uid: context.auth.uid,
        });
        return {
          success: false,
          error: `Validation failed: ${validation.errors.join("; ")}`,
          code: "validation-failed",
        };
      }

      functions.logger.info("[generateProgram] Success (llm)", { uid: context.auth.uid });

      // Increment monthly usage counter (non-fatal if Firestore write fails).
      try {
        if (usageData.programmeMonthKey === currentMonth) {
          await usageRef.update({ programmeCount: admin.firestore.FieldValue.increment(1) });
        } else {
          await usageRef.set({ programmeMonthKey: currentMonth, programmeCount: 1 }, { merge: true });
        }
      } catch (counterErr) {
        functions.logger.warn("[generateProgram] Failed to update usage counter", {
          uid: context.auth.uid,
          error: counterErr instanceof Error ? counterErr.message : String(counterErr),
        });
      }

      return {
        success: true,
        programme: validation.programme,
        source: "llm",
      };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      const stack = err instanceof Error ? err.stack : undefined;
      functions.logger.warn(`[generateProgram] LLM call failed: ${message}`, {
        uid: context.auth.uid,
        errorMessage: message,
        ...(stack && { stack: stack.slice(0, 500) }),
      });
      return {
        success: false,
        error: message,
        code: "llm-error",
      };
    }
  });
