import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/domain/user_scorecard.dart';

/// Rule-based adjustments after pre-workout check-in (Block 3).
///
/// Green: unchanged. Amber (premium): ~10% less load where weight is logged;
/// one fewer set on isolation accessories when multiple sets exist.
/// Red: unchanged here — the pre-workout flow calls the `adjustWorkout` callable when premium and the user adds issue text.
class WorkoutAdjuster {
  WorkoutAdjuster._();

  static const double _amberLoadFactor = 0.9;

  /// Applies deterministic rules when [premiumAdaptation] is true.
  /// [programmeLoadScale] scales working weights (e.g. from mid-programme check-in), default 1.0.
  /// [scorecard] optionally scales amber load reduction and accessory set trimming.
  static PreWorkoutCheckInArgs adjust({
    required PreWorkoutCheckInArgs args,
    required CheckInRating rating,
    required bool premiumAdaptation,
    double programmeLoadScale = 1.0,
    UserScorecard? scorecard,
  }) {
    if (!premiumAdaptation) return args;

    switch (rating) {
      case CheckInRating.green:
        return programmeLoadScale == 1.0 ? args : _applyLoadScale(args, programmeLoadScale);
      case CheckInRating.amber:
        return _applyAmber(
          args,
          programmeLoadScale: programmeLoadScale,
          scorecard: scorecard,
        );
      case CheckInRating.red:
      case CheckInRating.great:
      case CheckInRating.okay:
      case CheckInRating.tough:
      case CheckInRating.tooEasy:
      case CheckInRating.aboutRight:
      case CheckInRating.tooHard:
        return args;
    }
  }

  static PreWorkoutCheckInArgs _applyLoadScale(PreWorkoutCheckInArgs args, double scale) {
    final setsMap = args.initialSetsByExercise;
    if (setsMap == null || setsMap.isEmpty || scale == 1.0) return args;
    final newMap = <String, List<Map<String, dynamic>>>{};
    for (final MapEntry(:key, :value) in setsMap.entries) {
      final sets = value.map((m) => Map<String, dynamic>.from(m)).toList();
      for (final m in sets) {
        final weight = m['weight'];
        if (weight is num && weight > 0) {
          m['weight'] = _roundLoad(weight.toDouble() * scale);
        }
      }
      newMap[key] = sets;
    }
    return PreWorkoutCheckInArgs(
      workoutName: args.workoutName,
      workoutId: args.workoutId,
      programId: args.programId,
      initialExercises: args.initialExercises,
      initialSetsByExercise: newMap,
    );
  }

  static double _amberLoadFactorFor(UserScorecard? s) {
    if (s == null) return _amberLoadFactor;
    if (s.consistency < 4.0) return 0.86;
    if (s.consistency >= 7.0 && s.progression >= 6.0) return 0.94;
    if (s.computedLevel >= 4) return 0.93;
    return _amberLoadFactor;
  }

  static bool _trimAccessorySetForAmber(UserScorecard? s) {
    if (s == null) return true;
    if (s.independence >= 7.0) return false;
    if (s.computedLevel >= 4 && s.consistency >= 6.0) return false;
    return true;
  }

  static PreWorkoutCheckInArgs _applyAmber(
    PreWorkoutCheckInArgs args, {
    double programmeLoadScale = 1.0,
    UserScorecard? scorecard,
  }) {
    final setsMap = args.initialSetsByExercise;
    if (setsMap == null || setsMap.isEmpty) return args;

    final exerciseById = {for (final e in args.initialExercises) e.id: e};
    final newMap = <String, List<Map<String, dynamic>>>{};
    final loadFactor = _amberLoadFactorFor(scorecard);
    final combinedFactor = loadFactor * programmeLoadScale;
    final trimAccessory = _trimAccessorySetForAmber(scorecard);

    for (final MapEntry(:key, :value) in setsMap.entries) {
      final ex = exerciseById[key];
      final isAccessory = ex != null && _isAccessoryPattern(ex);

      var sets = value
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: true);

      if (trimAccessory && isAccessory && sets.length > 1) {
        sets = sets.sublist(0, sets.length - 1);
      }

      for (final m in sets) {
        final weight = m['weight'];
        if (weight is num && weight > 0) {
          m['weight'] = _roundLoad(weight.toDouble() * combinedFactor);
        }
      }
      newMap[key] = sets;
    }

    return PreWorkoutCheckInArgs(
      workoutName: args.workoutName,
      workoutId: args.workoutId,
      programId: args.programId,
      initialExercises: args.initialExercises,
      initialSetsByExercise: newMap,
    );
  }

  static bool _isAccessoryPattern(Exercise ex) {
    final p = ex.movementPattern;
    return p == MovementPattern.isolationUpper ||
        p == MovementPattern.isolationLower;
  }

  /// One decimal for kg-style loads; keeps small values readable.
  static double _roundLoad(double v) => (v * 10).round() / 10;
}
