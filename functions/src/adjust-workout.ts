/**
 * Callable: adjustWorkout. Auth required. Adjusts today's session sets from user issue (Vertex AI).
 */

import * as functions from "firebase-functions";
import { callLLM } from "./llm-adapter";
import {
  parseAdjustWorkoutRequest,
  validateLlmAdjustedWorkout,
  type AdjustWorkoutRequest,
} from "./validate-adjusted-workout";

function parseJsonObject(raw: string): unknown {
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

function buildAdjustSystemPrompt(): string {
  return [
    "You are a cautious strength and conditioning assistant for a workout logging app.",
    "The user reported how they feel before starting a planned session.",
    "Adjust ONLY numeric prescription: weight (kg), reps, duration (seconds), distance (meters).",
    "Rules:",
    "- Keep exactly the same exercise IDs as in the input. Do not add or remove exercises.",
    "- For each exercise, output the same number of sets as in the input OR one fewer set (never more sets).",
    "- Prefer conservative reductions when the user reports fatigue, pain, illness, or poor sleep.",
    "- If the user mentions a specific body area, reduce load or volume for matching movements when obvious from name/bodyPart/movementPattern.",
    "- Preserve id fields on set rows if provided in the input (copy them through).",
    "- Output a single JSON object only, no markdown.",
    'Schema: { "setsByExercise": { "<exerciseId>": [ { "weight"?: number, "reps"?: number, "duration"?: number, "distance"?: number, "id"?: string } ] }, "coachNote"?: string }',
  ].join("\n");
}

function buildAdjustUserPrompt(req: AdjustWorkoutRequest): string {
  return [
    `Workout name: ${req.workoutName}`,
    `User issue: ${req.userIssue}`,
    "",
    "Exercises (JSON):",
    JSON.stringify(req.exercises),
    "",
    "Current setsByExercise (JSON):",
    JSON.stringify(req.setsByExercise),
    "",
    "Return adjusted setsByExercise following the rules.",
  ].join("\n");
}

export interface AdjustWorkoutSuccess {
  success: true;
  setsByExercise: Record<string, Array<Record<string, unknown>>>;
  coachNote?: string;
  source: "llm";
}

export interface AdjustWorkoutError {
  success: false;
  error: string;
  code?: string;
}

export type AdjustWorkoutResponse = AdjustWorkoutSuccess | AdjustWorkoutError;

export const adjustWorkout = functions
  .runWith({
    timeoutSeconds: 45,
    memory: "512MB",
  })
  .region("us-central1")
  .https.onCall(async (data: unknown, context): Promise<AdjustWorkoutResponse> => {
    if (!context.auth) {
      return { success: false, error: "Unauthorized", code: "unauthenticated" };
    }

    const req = parseAdjustWorkoutRequest(data);
    if (!req) {
      return {
        success: false,
        error: "Invalid request: workoutName, userIssue, exercises, and setsByExercise required",
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

    functions.logger.info("[adjustWorkout] Invoked", {
      uid: context.auth.uid,
      exerciseCount: req.exercises.length,
      userIssueLength: req.userIssue.length,
    });

    const systemPrompt = buildAdjustSystemPrompt();
    const userPrompt = buildAdjustUserPrompt(req);

    try {
      const raw = await callLLM(projectId, systemPrompt, userPrompt);
      let parsed: unknown;
      try {
        parsed = parseJsonObject(raw ?? "");
      } catch (e) {
        functions.logger.warn("[adjustWorkout] Invalid JSON from LLM", {
          uid: context.auth.uid,
          err: e instanceof Error ? e.message : String(e),
        });
        return { success: false, error: "Model returned invalid JSON", code: "internal" };
      }

      const validated = validateLlmAdjustedWorkout(req, parsed);
      if (!validated) {
        functions.logger.warn("[adjustWorkout] LLM output failed validation", {
          uid: context.auth.uid,
        });
        return { success: false, error: "Adjusted plan failed safety checks", code: "internal" };
      }

      const out: Record<string, Array<Record<string, unknown>>> = {};
      for (const [k, rows] of Object.entries(validated.setsByExercise)) {
        out[k] = rows.map((r) => {
          const row: Record<string, unknown> = {};
          if (r.id != null) row.id = r.id;
          if (r.reps != null) row.reps = r.reps;
          if (r.weight != null) row.weight = r.weight;
          if (r.distance != null) row.distance = r.distance;
          if (r.duration != null) row.duration = r.duration;
          row.isComplete = false;
          return row;
        });
      }

      return {
        success: true,
        setsByExercise: out,
        coachNote: validated.coachNote,
        source: "llm",
      };
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      functions.logger.error("[adjustWorkout] Failed", { uid: context.auth.uid, msg });
      return { success: false, error: msg.length > 200 ? `${msg.slice(0, 200)}…` : msg, code: "internal" };
    }
  });
