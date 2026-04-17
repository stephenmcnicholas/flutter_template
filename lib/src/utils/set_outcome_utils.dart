import 'package:fytter/src/domain/exercise_input_type.dart';

/// Values persisted on [WorkoutEntry.setOutcome] / logger set maps (`setOutcome`).
abstract final class SetOutcomeValues {
  static const completed = 'completed';
  static const failed = 'failed';
  static const skipped = 'skipped';
}

/// Decides outcome when the user completes a set (not skip).
///
/// [set] should include `reps`, optional prescription `targetReps` (from template).
/// For reps-based types, [failed] means actual reps are below the positive target.
String computeSetOutcomeOnComplete({
  required ExerciseInputType inputType,
  required Map<String, dynamic> set,
}) {
  final reps = (set['reps'] as num?)?.toInt() ?? 0;
  final targetReps = (set['targetReps'] as num?)?.toInt();

  switch (inputType) {
    case ExerciseInputType.repsAndWeight:
    case ExerciseInputType.repsOnly:
      if (targetReps != null && targetReps > 0 && reps < targetReps) {
        return SetOutcomeValues.failed;
      }
      return SetOutcomeValues.completed;
    case ExerciseInputType.distanceAndTime:
    case ExerciseInputType.timeOnly:
      return SetOutcomeValues.completed;
  }
}
