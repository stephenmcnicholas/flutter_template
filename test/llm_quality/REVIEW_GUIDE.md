# LLM Quality Test — Review Guide

This guide accompanies `ai_programme_quality_test.dart`. It explains:

1. When to run the tests
2. How to set up and run them
3. What each test sends to the LLM
4. What the human reviewer should look for in the output

---

## When to Run

Run the LLM quality tests when **any of the following change**:

- The `generateProgram` Cloud Function prompt is modified
- The programme generation form captures a new input field (or removes one)
- The `ProgrammeGenerationRequest` payload shape changes
- A major model or provider change on the backend

You do **not** need to run them on every build. They are non-deterministic
and their value is in manual review, not automated pass/fail.

---

## Prerequisites

1. **Firebase configured locally.** The tests call the real `generateProgram`
   Cloud Function. You need a Firebase project with the function deployed and
   credentials available.

   If your project uses `firebase_options.dart`, ensure Firebase is
   initialised in the test `setUp`. The simplest approach is to run the tests
   from a device/emulator where Firebase is already initialised via the app.

2. **Network access.** Tests make real HTTP calls to Cloud Functions.

3. **The `@Tags(['llm_quality'])` filter.** Normal `flutter test` runs exclude
   these tests automatically. Run them explicitly:

   ```sh
   RUN_LLM_TESTS=1 flutter test test/llm_quality/ --tags llm_quality
   ```

---

## Test Cases and Input Variables

### Q1 — Standard structured inputs

| Input | Value |
|---|---|
| `daysPerWeek` | 3 |
| `sessionLengthMinutes` | 45 |
| `goal` | `general_fitness` |
| `equipment` | `full_gym` |
| `experienceLevel` | `regular` |
| `injuriesOrLimitations` | *(none)* |
| `additionalContext` | *(none)* |

**Expected output shape:**
- 3 workouts (one per training day)
- Standard compound movements from a barbell gym library
- `personalisationNotes` list is non-empty

**What the reviewer should check:**
- Are the exercises appropriate for a full gym? (barbells, racks expected; no bodyweight-only)
- Do the rep/set ranges make sense for general fitness? (3–5 sets, 5–12 reps typical)
- Do personalisation notes mention the 3-day frequency or general fitness goal?
- Are rest times sensible? (60–180s for compounds; shorter for isolation)
- Are any coaching notes present and coherent?

---

### Q2 — Home equipment + beginner + weight loss

| Input | Value |
|---|---|
| `daysPerWeek` | 2 |
| `sessionLengthMinutes` | 30 |
| `goal` | `weight_loss` |
| `equipment` | `home` |
| `experienceLevel` | `never` |
| `injuriesOrLimitations` | *(none)* |
| `additionalContext` | *(none)* |

**Expected output shape:**
- 2 workouts
- Exercises from the home library only (push-ups, bodyweight squats, lunges, plank)
- No barbell or machine exercises

**What the reviewer should check:**
- Are all prescribed exercises achievable at home with no equipment?
- Are rep ranges appropriate for a beginner? (fewer sets, lower volume than intermediate)
- Does the programme feel achievable for someone who has never trained before?
- Do personalisation notes reference home training or beginner context?
- Are session lengths within 30 minutes at the prescribed sets/reps?

---

### Q3 — Injury free-text: shoulder impingement

| Input | Value |
|---|---|
| `daysPerWeek` | 3 |
| `sessionLengthMinutes` | 60 |
| `goal` | `muscle_gain` |
| `equipment` | `full_gym` |
| `experienceLevel` | `some` |
| `injuriesOrLimitations` | `"Left shoulder impingement — no overhead pressing or behind-neck movements."` |
| `additionalContext` | *(none)* |

**Expected output shape:**
- 3 workouts
- No overhead press (`ohp-1`) prescribed, or if present, with a note acknowledging the limitation
- Personalisation notes mention the shoulder or overhead restriction

**What the reviewer should check:**
- Is overhead press absent, or replaced with a safer alternative?
- Are there any other shoulder-loading exercises that should have been avoided?
- Do personalisation notes explicitly acknowledge the injury? (Test asserts this — look at the note text)
- Is the free-text limitation clearly understood by the LLM, or is it ignored?

---

### Q4 — Additional context free-text: travel scheduling

| Input | Value |
|---|---|
| `daysPerWeek` | 4 |
| `sessionLengthMinutes` | 60 |
| `goal` | `muscle_gain` |
| `equipment` | `full_gym` |
| `experienceLevel` | `regular` |
| `injuriesOrLimitations` | *(none)* |
| `additionalContext` | `"I travel for work two weeks per month and won't always have gym access. Please keep sessions self-contained so I can swap days."` |

**Expected output shape:**
- 4 workouts
- Sessions are self-contained (not split across sequential days in a way that breaks when swapped)
- Personalisation notes acknowledge the travel context

**What the reviewer should check:**
- Are sessions designed as standalone units? (e.g. upper/lower rather than a continuation split that requires Day N to follow Day N-1)
- Do personalisation notes mention travel, flexibility, or swappable sessions?
- Is the free-text `additionalContext` reflected anywhere in the output?
- Are the 4 sessions appropriately distributed across days with rest days between intense sessions?

---

## How to Interpret the Test Output

Each test prints a report like this:

```
══════════════════════════════════════════════════════
  LLM QUALITY REPORT — Q1 — 3-day general fitness
══════════════════════════════════════════════════════
  Source   : LLM ✓
  Programme: 3-Day Barbell Strength
  Personalisation notes (3):
    • 3 training days selected with full recovery between sessions.
    • Full gym equipment enables compound barbell work.
    • General fitness goal: balanced push, pull, squat patterns.
  (review against REVIEW_GUIDE.md)
══════════════════════════════════════════════════════
```

**Source: `LLM ✓`** — The LLM responded and passed all hard validation checks.
The test assertion also checks this (`expect(result.usedFallback, isFalse)`).

**Source: `FALLBACK ⚠`** — The LLM either failed (network error, Cloud Function
error) or returned output that failed hard validation. Check
`generationFailureReason` for details. This is a test failure — investigate
before treating the output as valid.

---

## What Counts as a Pass

The automated tests assert:

1. `result.usedFallback == false` — LLM responded and passed structural validation
2. `result.personalisationNotes.isNotEmpty` — at least one note returned
3. (Q3 only) Personalisation notes contain "shoulder" or "overhead"

Anything beyond those three assertions is **human judgement**. Read the
printed personalisation notes and ask yourself: does the programme make sense
for this user?

---

## Re-running After Prompt Changes

After updating the Cloud Function prompt:

1. Run all four tests and save the output.
2. Compare personalisation notes to the previous run.
3. Check that injury/context free-text is still correctly reflected.
4. If the output improved, no action required.
5. If the output regressed on any dimension above, investigate the prompt change.
