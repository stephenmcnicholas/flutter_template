/**
 * Builds system and user prompts for programme generation from the request payload.
 */

import type { GenerateProgramRequest } from "./types";

const OUTPUT_SCHEMA = `
Return ONLY valid JSON matching this schema (no markdown, no explanation).
- coachIntro: 2–3 sentences, first person, warm and direct. Shown on the programme reveal card. Reference at least one specific user input. No bullet points.
- coachRationale: 4–6 short paragraphs, first person, for the "About your programme" screen. Explains approach, structure, progression, and acknowledges injuries/preferences. Max 350 words. Plain English, beginner-friendly.
- coachRationaleSpoken: optional but strongly preferred. A shorter script for text-to-speech only — NOT shown on screen. First person, same coach persona as coachRationale. Target roughly 40–60% of the written length; max 1200 characters. Short sentences, one main idea per sentence, conversational; no markdown, no "as mentioned above", no bullet points. Must align with coachRationale (same story, no contradictory prescriptions). Omit this field only if you cannot produce a safe spoken summary.
- Each workout has briefDescription: one sentence stating the PURPOSE of this workout in the programme and how it is tailored to this user (e.g. "Upper-body emphasis with shoulder-friendly pressing options to protect your left shoulder while building strength"). Not just a label — explain why this workout exists and for whom.
- Each exercise has coachingNote: one sentence explaining WHY this exercise was chosen (rationale for selection), WHY this variant for this user (e.g. incline push-up not flat), and how it ties to their stated goals, limitations, or preferences. Do NOT give form cues or execution instructions (e.g. "focus on controlled movement", "squeeze at the top") — those belong in the workout logger. Here we need the reason for selection only.
{
  "programmeName": "string",
  "programmeDescription": "string (one short sentence)",
  "coachIntro": "string (2–3 sentences, first person, for reveal card)",
  "coachRationale": "string (4–6 paragraphs, first person, for About screen, max 350 words)",
  "coachRationaleSpoken": "string (optional; TTS-only script, max 1200 chars, shorter ear-first version of coachRationale)",
  "durationWeeks": number (4 to 8),
  "personalisationNotes": ["string", "string"],
  "workouts": [
    {
      "dayOfWeek": "monday" | "tuesday" | "wednesday" | "thursday" | "friday" | "saturday" | "sunday",
      "workoutName": "string",
      "briefDescription": "string (purpose of this workout in the programme + how tailored to this user)",
      "exercises": [
        {
          "exerciseId": "string (must be one of the provided exercise IDs)",
          "sets": [
            { "reps": number, "targetLoadKg": number (optional) }
          ],
          "restSeconds": number (optional),
          "coachingNote": "string (one sentence: WHY this exercise and this variant were chosen for this user; reference goals/limitations/preferences; no form cues)"
        }
      ]
    }
  ],
  "deloadWeek": { "when": "week_4", "guidance": "string" } (optional),
  "weeklyProgression": "string" (optional)
}
`;

const SCORECARD_CONTEXT_INSTRUCTION = `
When a "User context (scorecard)" paragraph appears in the user message:
- Treat it as a behavioural training profile inferred from how this person actually trains in the app (not medical data).
- Use it to tune session density, progression aggressiveness, variety, and how much explanation vs brevity you use.
- It must NOT override explicit user inputs elsewhere (injuries, goals, schedule, equipment). The scorecard nuances those choices; it does not replace them.
`;

const PRINCIPLES = `
Training principles (non-negotiable):
- Progressive overload: include a mechanism to gradually increase demand.
- Specificity: training matches the user's goal.
- Recovery: adequate rest days, fatigue managed across the week.
- Minimum effective dose: enough stimulus to drive adaptation without excessive volume.
- Movement pattern balance: cover push, pull, hinge, squat (and carry/rotation as appropriate).
- Only select exercises from the provided library; use exact exerciseId values.
- Respect safety tiers: no exercises above tier 2 for unsupervised users unless explicitly allowed.
- Session duration must not exceed the requested session length.
- Assign conservative starting loads; prefer "start light and progress" over aggressive prescriptions.
- Load minimums (never go below these): barbell exercises ≥ 20 kg (the empty Olympic bar); kettlebell exercises ≥ 4 kg. A beginner doing a barbell back squat starts at 20 kg — that is the bar itself. Never prescribe targetLoadKg below these floors.
- sets is an array — one object per set. For straight sets, repeat the same values. For progression within a session (e.g. pyramid, drop sets), vary reps and/or targetLoadKg across the array. Always specify targetLoadKg for barbell and kettlebell exercises; it may be omitted for bodyweight-only movements.
- Exercise selection — stimulus vs rehab level: Reserve the most regressed options (e.g. chair sit-to-stand, wall push-up) for users who have given a positive signal they need that level: e.g. explicitly stated very low impact / rehab needs, significant mobility or strength limitations, elderly with frailty, or recovering from serious illness/injury. Do NOT use these as a default for "beginner" or "never trained" alone. A healthy teenager or adult who has never trained still needs adequate stimulus (e.g. bodyweight squat, incline or knee push-up); use progressions that provide meaningful load. For a single joint or injury (e.g. frozen shoulder), prefer the least regressed option that is still safe (e.g. incline push-up) rather than the most regressed (wall push-up) unless the user has indicated they need that level.
`;

const PERSONALISATION_INSTRUCTION = `
You must include a "personalisationNotes" field in your JSON output. This is an array of 2–4 short strings (max 12 words each) that explicitly state how the programme was adapted based on the user's specific inputs.
Each note should follow the pattern: "[What was changed] — [why/because of what input]"
Examples: "No overhead pressing — modified for left shoulder recovery", "Full-body sessions — fits your 3-day schedule".
Do not generate generic notes. If the user provided no injuries or preferences, only include notes that genuinely reflect their goal/schedule/equipment choices.
`;

const COACH_INTRO_INSTRUCTION = `
Write coachIntro: a 2–3 sentence message in first person, warm and direct, that tells the user what you've built and why it fits them. Reference at least one specific detail from their inputs (injury, preference, goal, or schedule). Do not be generic. Do not use bullet points. Do not use formal language. Write like a good PT talking to a new client.
Bad: "This programme is designed to help you achieve your fitness goals through progressive overload."
Good: "I've built you a three-day full-body programme that works around your shoulder recovery. Every session is balanced and efficient — you'll hit everything without overloading the joints you're protecting."
`;

const COACH_RATIONALE_INSTRUCTION = `
Write coachRationale: 4–6 short paragraphs in first person, warm and knowledgeable, explaining: (1) The overall programme approach and why it suits this user. (2) Why the programme is this length (4–8 weeks): one short sentence on best practice (e.g. long enough for real progress, short enough to stay motivated and reassess). (3) Training structure (frequency, session format) and why these choices were made. (4) What progression will look like — what "good" means week to week. (5) Explicit acknowledgement of any injuries, limitations or preferences the user mentioned — tie programme choices to their inputs so they see it is genuinely tailored.
Rules: Match tone to the user's stated experience level (see user context). If experience is "never", you may use beginner-friendly language and simple explanations. If experience is "some" or "regular", or if experience is not stated, do NOT assume they are a beginner: use neutral, confident tone; avoid phrases like "great for beginners", "fantastic for beginners", "great starting point", or talking down. Be specific; reference actual user inputs. First person throughout. Short paragraphs; no bullet points; no headers. Avoid: "ensure", "optimal", "utilise", "maximise". Max 350 words total.
`;

const COACH_RATIONALE_SPOKEN_INSTRUCTION = `
Also write coachRationaleSpoken: a separate field for voice playback only (users read coachRationale on screen; this is what the app will read aloud). It must tell the same programme story as coachRationale but in fewer words — aim for roughly 40–60% of the written length, hard cap 1200 characters. Use short sentences, natural spoken rhythm, first person. No markdown, lists, or references like "below" or "as stated above". Do not add new numbers or prescriptions that are not implied by coachRationale. Omit coachRationaleSpoken only if you cannot comply with these rules.
`;

const WORKOUT_PURPOSE_INSTRUCTION = `
For each workout, write briefDescription: one sentence that states the PURPOSE of this workout within the programme and how it is tailored to this user. Reference their goals, limitations, or preferences where relevant. Not a generic label — explain why this workout exists and for whom.
Bad: "A balanced session hitting your whole body."
Good: "Lower-body and core focus with no overhead work, so we protect your shoulder while building lower-body strength and stability."
`;

const COACH_NOTE_INSTRUCTION = `
For each exercise, write coachingNote: one sentence that explains WHY this exercise was chosen and WHY this variant (e.g. incline push-up not flat push-up) for this user. Tie to their stated goals, limitations, or preferences. This is RATIONALE for selection only — the user will get how-to-perform cues in the workout logger. Do NOT give form cues, execution tips, or generic advice (e.g. "focus on controlled movement", "squeeze at the top", "full range of motion"). If the user mentioned an injury or preference, explicitly reference it.
Bad: "Focus on controlled movement and full range of motion."
Bad: "Squeeze your glutes at the top of the movement."
Good: "Incline push-up was chosen because you're protecting your left shoulder — we get pressing work without loading the joint."
Good: "Bodyweight squat builds leg strength with no equipment; we're using it as your main lower-body pattern for this block."
Good: "Inverted row strengthens your back and is easier on the shoulder than pull-ups; we've included it in every session for balance."
`;

export function buildSystemPrompt(): string {
  return `You are a fitness programme designer. Your task is to generate a structured, evidence-based training programme as JSON.

${PRINCIPLES}
${SCORECARD_CONTEXT_INSTRUCTION}
${PERSONALISATION_INSTRUCTION}
${COACH_INTRO_INSTRUCTION}
${COACH_RATIONALE_INSTRUCTION}
${COACH_RATIONALE_SPOKEN_INSTRUCTION}
${WORKOUT_PURPOSE_INSTRUCTION}
${COACH_NOTE_INSTRUCTION}

${OUTPUT_SCHEMA}`;
}

export function buildUserPrompt(req: GenerateProgramRequest): string {
  const days = req.daysPerWeek ?? 3;
  const minutes = req.sessionLengthMinutes ?? 45;
  const goal = req.goal ?? "general_fitness";
  const blocked = req.blockedDays?.length
    ? `Blocked days: ${req.blockedDays.join(", ")}. Do not schedule workouts on these days.`
    : "";
  const equipment = req.equipment ? `Equipment: ${req.equipment}. Only use exercises that match.` : "";
  const experience =
    req.experienceLevel === "never"
      ? "Experience level: never (new to training). Tone: beginner-friendly explanations are appropriate."
      : req.experienceLevel === "some"
        ? "Experience level: some. Tone: do not call them a beginner; use confident, neutral tone."
        : req.experienceLevel === "regular"
          ? "Experience level: regular. Tone: experienced trainee; neutral, confident; no beginner phrases."
          : "Experience level: not stated. Do NOT assume the user is a beginner. Use neutral tone; avoid 'great for beginners', 'fantastic starting point', or similar.";
  const age = req.age != null ? `Age: ${req.age}.` : "";
  const injuries = req.injuriesOrLimitations
    ? `Injuries/limitations (respect these): ${sanitise(req.injuriesOrLimitations)}`
    : "";
  const scorecard = req.scorecardNarrative
    ? `User context (scorecard — use alongside injuries/goals/schedule; do not contradict explicit user inputs): ${sanitise(req.scorecardNarrative)}`
    : "";
  const previous = req.previousProgrammeSummary
    ? `Previous programme summary: ${sanitise(req.previousProgrammeSummary)}`
    : "";
  const extra = req.additionalContext
    ? `Additional context: ${sanitise(req.additionalContext)}`
    : "";

  const exerciseList = req.exerciseLibrary
    .map((e) => `${e.id} (${e.name}${e.movementPattern ? `, ${e.movementPattern}` : ""})`)
    .join("\n");

  return `Generate a ${days}-day-per-week programme, ${minutes} minutes per session, goal: ${goal}.
Programme length: 4–8 weeks (use at least 4 weeks). Return one weekly template in "workouts" (e.g. ${days} workouts); it will be repeated for durationWeeks.

${[blocked, equipment, experience, age, injuries, scorecard, previous, extra].filter(Boolean).join("\n")}

Exercise library (use only these IDs):
${exerciseList}

Return the programme as a single JSON object matching the schema.`;
}

function sanitise(s: string): string {
  return s
    .slice(0, 2000)
    .replace(/[\r\n]+/g, " ")
    .trim();
}
