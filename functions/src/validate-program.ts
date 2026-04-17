/**
 * Validates LLM programme JSON: exercise IDs in library, safety tiers, duration, movement balance.
 * Returns the validated programme or a list of error messages.
 */

import * as functions from "firebase-functions";
import type {
  GeneratedProgramme,
  ProgrammeWorkoutSpec,
  GenerateProgramRequest,
} from "./types";

export interface ValidationResult {
  ok: true;
  programme: GeneratedProgramme;
}

export interface ValidationError {
  ok: false;
  errors: string[];
}

export type ValidateProgrammeResult = ValidationResult | ValidationError;

/** Max length for coachRationaleSpoken (TTS script); must stay under Type C callable budget with style prompt. */
export const COACH_RATIONALE_SPOKEN_MAX_CHARS = 1200;

const VALID_DAYS = new Set([
  "monday",
  "tuesday",
  "wednesday",
  "thursday",
  "friday",
  "saturday",
  "sunday",
]);

export function validateProgramme(
  raw: unknown,
  req: GenerateProgramRequest
): ValidateProgrammeResult {
  const errors: string[] = [];

  if (raw === null || typeof raw !== "object") {
    return { ok: false, errors: ["Response is not a JSON object"] };
  }

  const obj = raw as Record<string, unknown>;
  const programmeName = obj.programmeName;
  const programmeDescription = obj.programmeDescription;
  const coachIntro = obj.coachIntro;
  const coachRationale = obj.coachRationale;
  const coachRationaleSpoken = obj.coachRationaleSpoken;
  const durationWeeks = obj.durationWeeks;
  const personalisationNotes = obj.personalisationNotes;
  const workouts = obj.workouts;
  const deloadWeek = obj.deloadWeek;
  const weeklyProgression = obj.weeklyProgression;

  if (typeof programmeName !== "string" || !programmeName.trim()) {
    errors.push("Missing or invalid programmeName");
  }
  if (typeof programmeDescription !== "string") {
    errors.push("Missing or invalid programmeDescription");
  }
  if (typeof durationWeeks !== "number" || durationWeeks < 4 || durationWeeks > 52) {
    errors.push("durationWeeks must be a number between 4 and 52 (minimum 4 weeks for an effective programme)");
  }
  if (!Array.isArray(workouts) || workouts.length === 0) {
    errors.push("workouts must be a non-empty array");
  }

  const exerciseIds = new Set(req.exerciseLibrary.map((e) => e.id));
  const exerciseById = new Map(req.exerciseLibrary.map((e) => [e.id, e]));
  const sessionLengthMinutes = req.sessionLengthMinutes ?? 60;

  if (Array.isArray(workouts)) {
    const seenDays = new Set<string>();
    const movementPatterns = new Set<string>();

    for (let i = 0; i < workouts.length; i++) {
      const w = workouts[i] as Record<string, unknown>;
      const day = w.dayOfWeek;
      const workoutName = w.workoutName;
      const exercises = w.exercises;

      const dayStr = typeof day === "string" ? day.toLowerCase() : "";
      if (typeof day !== "string" || !VALID_DAYS.has(dayStr)) {
        errors.push(`workouts[${i}]: invalid dayOfWeek "${day}"`);
      } else if (seenDays.has(dayStr)) {
        errors.push(`workouts[${i}]: duplicate dayOfWeek ${day}`);
      } else {
        seenDays.add(dayStr);
      }

      if (req.blockedDays?.includes(dayStr)) {
        errors.push(`workouts[${i}]: ${day} is a blocked day`);
      }

      if (typeof workoutName !== "string" || !workoutName.trim()) {
        errors.push(`workouts[${i}]: missing or invalid workoutName`);
      }

      if (!Array.isArray(exercises)) {
        errors.push(`workouts[${i}]: exercises must be an array`);
      } else {
        let estimatedMinutes = 0;
        for (let j = 0; j < exercises.length; j++) {
          const ex = exercises[j] as Record<string, unknown>;
          const exerciseId = ex.exerciseId;
          if (typeof exerciseId !== "string" || !exerciseId.trim()) {
            errors.push(`workouts[${i}].exercises[${j}]: missing exerciseId`);
          } else if (!exerciseIds.has(exerciseId)) {
            errors.push(`workouts[${i}].exercises[${j}]: unknown exerciseId "${exerciseId}"`);
          } else {
            const libEx = exerciseById.get(exerciseId);
            if (libEx?.movementPattern) {
              movementPatterns.add(libEx.movementPattern);
            }
            if (typeof libEx?.safetyTier === "number" && libEx.safetyTier > 2) {
              errors.push(
                `workouts[${i}].exercises[${j}]: exercise "${exerciseId}" has safety tier ${libEx.safetyTier} (max 2 for generated programmes)`
              );
            }
          }
          const setsRaw = ex.sets;
          const restSec = (ex.restSeconds as number) ?? 90;
          if (!Array.isArray(setsRaw) || setsRaw.length === 0) {
            errors.push(`workouts[${i}].exercises[${j}]: sets must be a non-empty array of { reps, targetLoadKg? }`);
          } else {
            const libEx = exerciseById.get(typeof ex.exerciseId === "string" ? ex.exerciseId : "");
            const equipment = libEx?.equipment?.toLowerCase() ?? "";
            const isBarbell = equipment.includes("barbell");
            const isKettlebell = equipment.includes("kettlebell");
            const loadFloor = isBarbell ? 20 : isKettlebell ? 4 : 0;

            for (let k = 0; k < setsRaw.length; k++) {
              const s = setsRaw[k] as Record<string, unknown>;
              const reps = s.reps as number | undefined;
              if (typeof reps !== "number" || reps <= 0) {
                errors.push(`workouts[${i}].exercises[${j}].sets[${k}]: reps must be a positive number`);
              }
              const load = s.targetLoadKg as number | undefined;
              if (load != null && loadFloor > 0 && load < loadFloor) {
                // Soft warning — log but do not fail validation; client will clamp
                functions.logger.warn("[validateProgramme] suspicious load", {
                  exerciseId: ex.exerciseId,
                  setIndex: k,
                  targetLoadKg: load,
                  loadFloor,
                  equipment,
                });
              }
              // Accumulate duration per set
              if (typeof reps === "number") {
                estimatedMinutes += (reps * 4 + restSec) / 60;
              }
            }
          }
        }
        if (estimatedMinutes > sessionLengthMinutes + 15) {
          errors.push(
            `workouts[${i}]: estimated duration ~${Math.round(estimatedMinutes)} min exceeds session length ${sessionLengthMinutes} min`
          );
        }
      }
    }

    if (workouts.length >= 2 && movementPatterns.size < 2) {
      errors.push("Programme should include variety in movement patterns (push, pull, squat, hinge, etc.)");
    }
  }

  if (deloadWeek !== undefined && deloadWeek !== null) {
    if (typeof deloadWeek !== "object" || Array.isArray(deloadWeek)) {
      errors.push("deloadWeek must be an object { when, guidance } or omitted");
    } else {
      const d = deloadWeek as Record<string, unknown>;
      if (typeof d.when !== "string" || typeof d.guidance !== "string") {
        errors.push("deloadWeek must have when and guidance strings");
      }
    }
  }

  if (errors.length > 0) {
    return { ok: false, errors };
  }

  const workoutSpecs = workouts as ProgrammeWorkoutSpec[];
  const notes: string[] =
    Array.isArray(personalisationNotes) ?
      personalisationNotes.filter((n): n is string => typeof n === "string").slice(0, 4) :
      [];

  let spokenOut: string | undefined;
  if (typeof coachRationaleSpoken === "string") {
    const t = coachRationaleSpoken.trim();
    if (t.length > 0 && t.length <= COACH_RATIONALE_SPOKEN_MAX_CHARS) {
      spokenOut = t;
    }
  }

  const programme: GeneratedProgramme = {
    programmeName: String(programmeName).trim(),
    programmeDescription: typeof programmeDescription === "string" ? programmeDescription : "",
    coachIntro: typeof coachIntro === "string" && coachIntro.trim() ? coachIntro.trim() : undefined,
    coachRationale: typeof coachRationale === "string" && coachRationale.trim() ? coachRationale.trim() : undefined,
    coachRationaleSpoken: spokenOut,
    durationWeeks: Number(durationWeeks),
    personalisationNotes: notes.length > 0 ? notes : undefined,
    workouts: workoutSpecs.map((w) => ({
      dayOfWeek: String(w.dayOfWeek).toLowerCase(),
      workoutName: String(w.workoutName).trim(),
      briefDescription: (w as { briefDescription?: string }).briefDescription?.trim(),
      exercises: w.exercises.map((e) => ({
        exerciseId: String(e.exerciseId).trim(),
        sets: e.sets.map((s) => ({
          reps: Number(s.reps) || 8,
          ...(s.targetLoadKg != null ? { targetLoadKg: Number(s.targetLoadKg) } : {}),
        })),
        restSeconds: e.restSeconds != null ? Number(e.restSeconds) : undefined,
        coachingNote: e.coachingNote != null ? String(e.coachingNote) : undefined,
      })),
    })),
    deloadWeek:
      deloadWeek && typeof deloadWeek === "object" && !Array.isArray(deloadWeek)
        ? {
            when: String((deloadWeek as Record<string, unknown>).when),
            guidance: String((deloadWeek as Record<string, unknown>).guidance),
          }
        : undefined,
    weeklyProgression:
      typeof weeklyProgression === "string" ? weeklyProgression : undefined,
  };

  return { ok: true, programme };
}
