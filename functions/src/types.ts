/**
 * Types for the generateProgram callable request and LLM programme output.
 */

export interface GenerateProgramRequest {
  /** Days per week (2–7). */
  daysPerWeek: number;
  /** Session length in minutes. */
  sessionLengthMinutes: number;
  /** Goal: e.g. "get_stronger", "build_muscle", "general_fitness". */
  goal?: string;
  /** Blocked weekdays, e.g. ["saturday", "sunday"]. */
  blockedDays?: string[];
  /** Available equipment: "full_gym", "home", "bodyweight", etc. */
  equipment?: string;
  /** Age if provided. */
  age?: number;
  /** Optional injury/limitation notes (sanitised before prompt). */
  injuriesOrLimitations?: string;
  /** Optional free-text context. */
  additionalContext?: string;
  /** Self-reported experience: "never" | "some" | "regular". If absent, do not assume beginner in copy. */
  experienceLevel?: string;
  /** Scorecard narrative from UserScorecard.toNarrative(). */
  scorecardNarrative?: string;
  /** Exercise library subset: id, name, movementPattern, safetyTier, equipment, etc. */
  exerciseLibrary: Array<{
    id: string;
    name: string;
    movementPattern?: string;
    safetyTier?: number;
    equipment?: string;
    bodyPart?: string;
  }>;
  /** Recent programme/history summary for context. */
  previousProgrammeSummary?: string;
}

export interface ProgrammeSetSpec {
  /** Reps for this set. */
  reps: number;
  /** Target load in kg for this set. Must respect equipment minimums (barbell ≥ 20 kg, kettlebell ≥ 4 kg). */
  targetLoadKg?: number;
}

export interface ProgrammeExerciseSpec {
  exerciseId: string;
  /** One entry per set. Repeat identical values for straight sets; vary for pyramid/drop sets. */
  sets: ProgrammeSetSpec[];
  restSeconds?: number;
  coachingNote?: string;
}

export interface ProgrammeWorkoutSpec {
  dayOfWeek: string;
  workoutName: string;
  briefDescription?: string;
  exercises: ProgrammeExerciseSpec[];
}

export interface DeloadSpec {
  when: string;
  guidance: string;
}

export interface GeneratedProgramme {
  programmeName: string;
  programmeDescription: string;
  coachIntro?: string;
  coachRationale?: string;
  /** Ear-first script for Type C TTS only; not shown on About screen. */
  coachRationaleSpoken?: string;
  durationWeeks: number;
  personalisationNotes?: string[];
  workouts: ProgrammeWorkoutSpec[];
  deloadWeek?: DeloadSpec;
  weeklyProgression?: string;
}
