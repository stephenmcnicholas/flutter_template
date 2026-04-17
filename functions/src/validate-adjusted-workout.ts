/**
 * Validates adjustWorkout callable request and LLM output shape.
 */

export interface AdjustWorkoutExerciseRef {
  id: string;
  name: string;
  movementPattern?: string;
  bodyPart?: string;
  equipment?: string;
}

export interface AdjustWorkoutSetRow {
  id?: string;
  reps?: number;
  weight?: number;
  distance?: number;
  duration?: number;
  isComplete?: boolean;
}

export interface AdjustWorkoutRequest {
  workoutName: string;
  workoutId?: string;
  userIssue: string;
  exercises: AdjustWorkoutExerciseRef[];
  setsByExercise: Record<string, AdjustWorkoutSetRow[]>;
}

function isNonEmptyString(v: unknown): v is string {
  return typeof v === "string" && v.trim().length > 0;
}

function isRecord(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

/** Sanitize user text for prompts (length cap, strip control chars). */
export function sanitizeUserIssue(raw: string, maxLen = 1500): string {
  const s = raw.replace(/[\u0000-\u001F\u007F]/g, " ").trim().slice(0, maxLen);
  return s;
}

export function parseAdjustWorkoutRequest(data: unknown): AdjustWorkoutRequest | null {
  if (!isRecord(data)) return null;
  const workoutName = data.workoutName;
  if (!isNonEmptyString(workoutName)) return null;

  const userIssueRaw = data.userIssue;
  if (!isNonEmptyString(userIssueRaw)) return null;
  const userIssue = sanitizeUserIssue(userIssueRaw);

  const exercisesIn = data.exercises;
  if (!Array.isArray(exercisesIn) || exercisesIn.length === 0) return null;

  const exercises: AdjustWorkoutExerciseRef[] = [];
  for (const e of exercisesIn) {
    if (!isRecord(e)) return null;
    const id = e.id;
    const name = e.name;
    if (!isNonEmptyString(id) || !isNonEmptyString(name)) return null;
    exercises.push({
      id: id.trim(),
      name: name.trim(),
      movementPattern: typeof e.movementPattern === "string" ? e.movementPattern : undefined,
      bodyPart: typeof e.bodyPart === "string" ? e.bodyPart : undefined,
      equipment: typeof e.equipment === "string" ? e.equipment : undefined,
    });
  }

  const allowedIds = new Set(exercises.map((x) => x.id));
  const setsIn = data.setsByExercise;
  if (!isRecord(setsIn)) return null;

  const setsByExercise: Record<string, AdjustWorkoutSetRow[]> = {};
  let hasAnySet = false;

  for (const key of Object.keys(setsIn)) {
    if (!allowedIds.has(key)) return null;
    const rows = setsIn[key];
    if (!Array.isArray(rows) || rows.length === 0) return null;
    const outRows: AdjustWorkoutSetRow[] = [];
    for (const row of rows) {
      if (!isRecord(row)) return null;
      const r: AdjustWorkoutSetRow = {};
      if (typeof row.id === "string") r.id = row.id;
      if (typeof row.reps === "number" && Number.isFinite(row.reps)) r.reps = Math.round(row.reps);
      if (typeof row.weight === "number" && Number.isFinite(row.weight)) r.weight = row.weight;
      if (typeof row.distance === "number" && Number.isFinite(row.distance)) r.distance = row.distance;
      if (typeof row.duration === "number" && Number.isFinite(row.duration)) r.duration = row.duration;
      if (typeof row.isComplete === "boolean") r.isComplete = row.isComplete;
      outRows.push(r);
    }
    setsByExercise[key] = outRows;
    hasAnySet = true;
  }

  if (!hasAnySet) return null;
  for (const id of allowedIds) {
    if (!setsByExercise[id]?.length) return null;
  }

  const workoutId = data.workoutId;
  return {
    workoutName: workoutName.trim(),
    workoutId: typeof workoutId === "string" && workoutId.trim() ? workoutId.trim() : undefined,
    userIssue,
    exercises,
    setsByExercise,
  };
}

export interface AdjustedWorkoutLlmShape {
  setsByExercise: Record<string, AdjustWorkoutSetRow[]>;
  coachNote?: string;
}

/**
 * Validates LLM JSON against the original request: same exercise keys, sane numeric bounds,
 * set count per exercise between max(1, orig-1) and orig (no added sets).
 */
export function validateLlmAdjustedWorkout(
  request: AdjustWorkoutRequest,
  parsed: unknown
): AdjustedWorkoutLlmShape | null {
  if (!isRecord(parsed)) return null;
  const setsIn = parsed.setsByExercise;
  if (!isRecord(setsIn)) return null;

  const allowedIds = new Set(request.exercises.map((e) => e.id));
  const out: Record<string, AdjustWorkoutSetRow[]> = {};

  for (const id of allowedIds) {
    const orig = request.setsByExercise[id];
    if (!orig?.length) return null;

    const rowsIn = setsIn[id];
    if (!Array.isArray(rowsIn)) return null;

    const minLen = Math.max(1, orig.length - 1);
    if (rowsIn.length < minLen || rowsIn.length > orig.length) return null;

    const outRows: AdjustWorkoutSetRow[] = [];
    for (let i = 0; i < rowsIn.length; i++) {
      const row = rowsIn[i];
      if (!isRecord(row)) return null;
      const o = orig[i]!;

      const r: AdjustWorkoutSetRow = {
        id: typeof o.id === "string" ? o.id : undefined,
        reps: typeof o.reps === "number" && Number.isFinite(o.reps) ? Math.round(o.reps) : undefined,
        weight: typeof o.weight === "number" && Number.isFinite(o.weight) ? o.weight : undefined,
        distance: typeof o.distance === "number" && Number.isFinite(o.distance) ? o.distance : undefined,
        duration: typeof o.duration === "number" && Number.isFinite(o.duration) ? o.duration : undefined,
        isComplete: false,
      };

      if (typeof row.reps === "number" && Number.isFinite(row.reps)) {
        const n = Math.round(row.reps);
        if (n >= 0 && n <= 200) r.reps = n;
        else return null;
      }

      if (typeof row.weight === "number" && Number.isFinite(row.weight)) {
        const w = row.weight;
        if (w >= 0 && w <= 600) r.weight = Math.round(w * 10) / 10;
        else return null;
      }

      if (typeof row.distance === "number" && Number.isFinite(row.distance)) {
        const d = row.distance;
        if (d >= 0 && d <= 1_000_000) r.distance = d;
        else return null;
      }

      if (typeof row.duration === "number" && Number.isFinite(row.duration)) {
        const t = row.duration;
        if (t >= 0 && t <= 86400) r.duration = t;
        else return null;
      }

      if (typeof row.id === "string" && row.id) r.id = row.id;
      outRows.push(r);
    }
    out[id] = outRows;
  }

  for (const k of Object.keys(setsIn)) {
    if (!allowedIds.has(k)) return null;
  }

  const coachNote = parsed.coachNote;
  return {
    setsByExercise: out,
    coachNote: typeof coachNote === "string" ? coachNote.slice(0, 500) : undefined,
  };
}
