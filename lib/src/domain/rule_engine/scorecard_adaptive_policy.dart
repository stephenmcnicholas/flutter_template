/// How often the product should surface structured check-ins (pre/post/mid).
/// Post-set RPE prompts are not implemented yet; this enum is the hook for future UI.
enum CheckInPromptDensity {
  /// Levels 1–2: full pre-workout flow; prefer explicit mood/post-session capture.
  full,

  /// Level 3: same screens, slightly lighter copy (caller may shorten subtitles).
  moderate,

  /// Levels 4–5: minimal friction; rely on behaviour-triggered prompts when built.
  minimal,
}

/// Maps [UserScorecard.computedLevel] to coaching-touchpoint density (Block 4 Task 23).
class ScorecardAdaptivePolicy {
  ScorecardAdaptivePolicy._();

  static CheckInPromptDensity checkInDensity(int computedLevel) {
    final l = computedLevel.clamp(1, 5);
    if (l <= 2) return CheckInPromptDensity.full;
    if (l == 3) return CheckInPromptDensity.moderate;
    return CheckInPromptDensity.minimal;
  }

  /// Short hint for pre-workout screen copy.
  static String preWorkoutSubtitle(CheckInPromptDensity density) {
    switch (density) {
      case CheckInPromptDensity.full:
        return 'Quick check-in before we start. Your answer helps us tailor your experience.';
      case CheckInPromptDensity.moderate:
        return 'A quick mood check helps us tune today’s session.';
      case CheckInPromptDensity.minimal:
        return 'Optional: how you feel shapes small tweaks—skip if you want to get straight to work.';
    }
  }
}
