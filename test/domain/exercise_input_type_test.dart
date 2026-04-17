import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';

void main() {
  group('exerciseInputTypeToJson', () {
    test('returns expected strings', () {
      expect(exerciseInputTypeToJson(ExerciseInputType.timeOnly), 'Time only');
      expect(
        exerciseInputTypeToJson(ExerciseInputType.distanceAndTime),
        'Time and Distance',
      );
      expect(exerciseInputTypeToJson(ExerciseInputType.repsOnly), 'Reps only');
      expect(
        exerciseInputTypeToJson(ExerciseInputType.repsAndWeight),
        'Reps and Weight',
      );
    });
  });

  group('exerciseInputTypeFromJson', () {
    test('parses expected strings', () {
      expect(
        exerciseInputTypeFromJson('Time only'),
        ExerciseInputType.timeOnly,
      );
      expect(
        exerciseInputTypeFromJson('Time and Distance'),
        ExerciseInputType.distanceAndTime,
      );
      expect(
        exerciseInputTypeFromJson('Reps only'),
        ExerciseInputType.repsOnly,
      );
      expect(
        exerciseInputTypeFromJson('Reps and Weight'),
        ExerciseInputType.repsAndWeight,
      );
    });

    test('parses case-insensitive values', () {
      expect(
        exerciseInputTypeFromJson('time only'),
        ExerciseInputType.timeOnly,
      );
      expect(
        exerciseInputTypeFromJson('REPS ONLY'),
        ExerciseInputType.repsOnly,
      );
    });

    test('returns null for null or unknown values', () {
      expect(exerciseInputTypeFromJson(null), isNull);
      expect(exerciseInputTypeFromJson('unknown'), isNull);
    });
  });
}
