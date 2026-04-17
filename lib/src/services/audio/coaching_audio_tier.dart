/// Coaching depth tier for Type B audio paths (`beginner` / `intermediate` / `advanced`).
enum CoachingAudioTier {
  beginner,
  intermediate,
  advanced,
}

/// Maps [UserScorecard.computedLevel] (1–5) to a coaching tier for clip resolution.
/// Held for the whole workout session — do not re-read mid-session.
CoachingAudioTier coachingTierFromComputedLevel(int computedLevel) {
  if (computedLevel <= 2) return CoachingAudioTier.beginner;
  if (computedLevel == 3) return CoachingAudioTier.intermediate;
  return CoachingAudioTier.advanced;
}

/// Folder / prefs segment for tier (`beginner` / `intermediate` / `advanced`).
String coachingTierStorageName(CoachingAudioTier tier) => switch (tier) {
      CoachingAudioTier.beginner => 'beginner',
      CoachingAudioTier.intermediate => 'intermediate',
      CoachingAudioTier.advanced => 'advanced',
    };
