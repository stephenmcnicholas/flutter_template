import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/domain/user_scorecard.dart';
import 'package:fytter/src/domain/workout_session.dart';

/// Deterministic scorecard attribute updates and level computation (Block 4 Task 20).
/// Callers merge results via [UserScorecard.copyWith] and then [recomputeLevel].
class ScorecardUpdater {
  ScorecardUpdater._();

  static const double _minScore = 1.0;
  static const double _maxScore = 10.0;

  /// Same banding as tests: 4.5 → 2, 4.6 → 3.
  static int levelFromWeightedAverage(double weightedAverage) {
    if (weightedAverage < 4.0) return 1;
    if (weightedAverage < 4.6) return 2;
    if (weightedAverage < 5.5) return 3;
    if (weightedAverage < 6.5) return 4;
    return 5;
  }

  /// Sets [computedLevel] from [UserScorecard.weightedAverage] and [lastUpdated] to [at].
  static UserScorecard recomputeLevel(UserScorecard scorecard, {DateTime? at}) {
    final w = scorecard.weightedAverage;
    return scorecard.copyWith(
      computedLevel: levelFromWeightedAverage(w),
      lastUpdated: at ?? DateTime.now(),
    );
  }

  // --- Decay (plan: floor 2.0 if 50+ lifetime sessions, else 1.0) ---

  /// Pulls activity-linked attributes toward [floor] when [daysSinceAnyWorkout] > 7.
  /// Strength scales with weeks beyond the first idle week (capped).
  static UserScorecard applyInactivityDecay(
    UserScorecard scorecard, {
    required int daysSinceAnyWorkout,
    required int totalLifetimeSessions,
  }) {
    if (daysSinceAnyWorkout <= 7) return scorecard;

    final floor = totalLifetimeSessions >= 50 ? 2.0 : 1.0;
    final t = ((daysSinceAnyWorkout - 7) / 28.0).clamp(0.0, 1.0);
    final pull = 0.35 * t;

    double towardFloor(double v) => v + (floor - v) * pull;

    return scorecard.copyWith(
      consistency: _clamp(towardFloor(scorecard.consistency)),
      progression: _clamp(towardFloor(scorecard.progression)),
      endurance: _clamp(towardFloor(scorecard.endurance)),
      variety: _clamp(towardFloor(scorecard.variety)),
      reliability: _clamp(towardFloor(scorecard.reliability)),
    );
  }

  // --- Attribute updates (each returns suggested new scalar; caller merges) ---

  /// Rolling ~4-week adherence: [completedLast28] / max([scheduledLast28], 1) → target, blended with [current].
  static double updateConsistency({
    required double current,
    required int scheduledLast28Days,
    required int completedLast28Days,
    double blend = 0.35,
  }) {
    if (scheduledLast28Days <= 0) return current;
    final rate = (completedLast28Days / scheduledLast28Days).clamp(0.0, 1.5);
    final target = _clamp(1.0 + rate * 8.0);
    return _clamp(current * (1 - blend) + target * blend);
  }

  /// Trend of total session volume (weight × reps) over [recentSessions] (oldest first).
  static double updateProgression({
    required double current,
    required List<WorkoutSession> recentSessions,
    double blend = 0.35,
  }) {
    if (recentSessions.length < 2) return current;
    final volumes = recentSessions.map(_sessionVolume).toList();
    final mid = volumes.length ~/ 2;
    if (mid < 1) return current;
    final first = _mean(volumes.sublist(0, mid));
    final second = _mean(volumes.sublist(mid));
    if (first <= 0) return current;
    final delta = (second - first) / first;
    final target = _clamp(5.0 + delta * 12.0);
    return _clamp(current * (1 - blend) + target * blend);
  }

  /// [completionRatio] completed sets vs planned (0–1+). [durationRatio] actual / planned (~1 ideal).
  static double updateEndurance({
    required double current,
    required double completionRatio,
    required double durationRatio,
    double blend = 0.35,
  }) {
    final cr = completionRatio.clamp(0.0, 1.2);
    final dr = durationRatio.clamp(0.3, 2.0);
    final durationFactor = 1.0 - (dr - 1.0).abs() * 0.8;
    final target = _clamp(1.0 + cr * 7.0 * durationFactor.clamp(0.4, 1.0));
    return _clamp(current * (1 - blend) + target * blend);
  }

  /// Share of [availablePatterns] represented in [recentMovementPatternIds] (last N sessions).
  static double updateVariety({
    required double current,
    required Set<String> recentMovementPatternIds,
    required Set<String> availablePatterns,
    double blend = 0.35,
  }) {
    if (availablePatterns.isEmpty) return current;
    final covered = recentMovementPatternIds.where(availablePatterns.contains).length;
    final ratio = covered / availablePatterns.length;
    final target = _clamp(1.0 + ratio * 8.0);
    return _clamp(current * (1 - blend) + target * blend);
  }

  /// Lags training attributes — composite, slightly below their average.
  static double updateFundamentals(UserScorecard scorecard, {double blend = 0.25}) {
    final trainingAvg = (scorecard.consistency +
            scorecard.progression +
            scorecard.endurance +
            scorecard.variety) /
        4.0;
    final target = _clamp(trainingAvg * 0.92);
    return _clamp(scorecard.fundamentals * (1 - blend) + target * blend);
  }

  /// [performanceWasWeakerThanCheckIn] true e.g. many failed sets while user rated session "great".
  static double updateSelfAwareness({
    required double current,
    required CheckInRating checkInRating,
    required bool performanceWasWeakerThanCheckIn,
    double blend = 0.4,
  }) {
    var target = current;
    if (performanceWasWeakerThanCheckIn &&
        (checkInRating == CheckInRating.great || checkInRating == CheckInRating.okay)) {
      target = _clamp(current - 1.2);
    } else if (checkInRating == CheckInRating.tough && !performanceWasWeakerThanCheckIn) {
      target = _clamp(current + 0.35);
    } else {
      target = _clamp(current + 0.08);
    }
    return _clamp(current * (1 - blend) + target * blend);
  }

  /// Lightweight engagement signal for explanations / instructions.
  static double updateCuriosity({
    required double current,
    required ScorecardInteractionKind interaction,
    double blend = 0.45,
  }) {
    final bump = switch (interaction) {
      ScorecardInteractionKind.instructionViewed => 0.22,
      ScorecardInteractionKind.coachingCuePlayed => 0.08,
      ScorecardInteractionKind.aboutProgrammeOpened => 0.18,
    };
    final target = _clamp(current + bump);
    return _clamp(current * (1 - blend) + target * blend);
  }

  /// [trainedOnOrBeforeScheduledDay] true if user logged on or before the scheduled calendar day.
  static double updateReliability({
    required double current,
    required bool trainedOnOrBeforeScheduledDay,
    double blend = 0.35,
  }) {
    final target = trainedOnOrBeforeScheduledDay ? _clamp(current + 0.45) : _clamp(current - 0.55);
    return _clamp(current * (1 - blend) + target * blend);
  }

  static double updateAdaptability({
    required double current,
    required bool adjustmentAccepted,
    double blend = 0.4,
  }) {
    final target =
        adjustmentAccepted ? _clamp(current + 0.4) : _clamp(current - 0.25);
    return _clamp(current * (1 - blend) + target * blend);
  }

  /// [sensibleModificationCount] / max([totalModifications], 1) — swaps/adds that stay within plan intent.
  static double updateIndependence({
    required double current,
    required int sensibleModificationCount,
    required int totalModifications,
    double blend = 0.35,
  }) {
    if (totalModifications <= 0) return current;
    final ratio = (sensibleModificationCount / totalModifications).clamp(0.0, 1.0);
    final target = _clamp(2.0 + ratio * 7.0);
    return _clamp(current * (1 - blend) + target * blend);
  }

  // --- Internals ---

  static double _sessionVolume(WorkoutSession s) {
    var v = 0.0;
    for (final e in s.entries) {
      v += e.weight * e.reps;
    }
    return v;
  }

  static double _mean(List<double> xs) {
    if (xs.isEmpty) return 0;
    return xs.reduce((a, b) => a + b) / xs.length;
  }

  static double _clamp(double v) => v.clamp(_minScore, _maxScore);
}

/// Inputs for [ScorecardUpdater.updateCuriosity].
enum ScorecardInteractionKind {
  instructionViewed,
  coachingCuePlayed,
  aboutProgrammeOpened,
}
