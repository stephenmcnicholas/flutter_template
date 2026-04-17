import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/utils/set_outcome_utils.dart';

void main() {
  group('computeSetOutcomeOnComplete', () {
    test('reps at target is completed', () {
      expect(
        computeSetOutcomeOnComplete(
          inputType: ExerciseInputType.repsAndWeight,
          set: {'reps': 10, 'targetReps': 10},
        ),
        SetOutcomeValues.completed,
      );
    });

    test('reps below target is failed', () {
      expect(
        computeSetOutcomeOnComplete(
          inputType: ExerciseInputType.repsAndWeight,
          set: {'reps': 8, 'targetReps': 10},
        ),
        SetOutcomeValues.failed,
      );
    });

    test('reps above target is completed', () {
      expect(
        computeSetOutcomeOnComplete(
          inputType: ExerciseInputType.repsOnly,
          set: {'reps': 12, 'targetReps': 10},
        ),
        SetOutcomeValues.completed,
      );
    });

    test('zero or missing target does not fail', () {
      expect(
        computeSetOutcomeOnComplete(
          inputType: ExerciseInputType.repsAndWeight,
          set: {'reps': 3, 'targetReps': 0},
        ),
        SetOutcomeValues.completed,
      );
      expect(
        computeSetOutcomeOnComplete(
          inputType: ExerciseInputType.repsAndWeight,
          set: {'reps': 3},
        ),
        SetOutcomeValues.completed,
      );
    });

    test('time-only always completed', () {
      expect(
        computeSetOutcomeOnComplete(
          inputType: ExerciseInputType.timeOnly,
          set: {'duration': 30, 'targetDuration': 60},
        ),
        SetOutcomeValues.completed,
      );
    });
  });
}
