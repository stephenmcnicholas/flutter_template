import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/generated_programme.dart';
import 'package:fytter/src/domain/programme_validator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _knownIds = {'squat-1', 'bench-1', 'row-1', 'deadlift-1'};
const _validator = ProgrammeValidator();

GeneratedProgrammeExercise _ex(
  String id, {
  int setCount = 3,
  int reps = 8,
  double? load,
}) =>
    GeneratedProgrammeExercise(
      exerciseId: id,
      sets: List.generate(
        setCount,
        (_) => GeneratedProgrammeSet(reps: reps, targetLoadKg: load),
      ),
    );

GeneratedProgramme _programme({
  List<GeneratedProgrammeWorkout>? workouts,
  String name = 'Test Programme',
}) {
  return GeneratedProgramme(
    programmeName: name,
    programmeDescription: 'A test programme.',
    durationWeeks: 4,
    workouts: workouts ??
        [
          GeneratedProgrammeWorkout(
            dayOfWeek: 'monday',
            workoutName: 'Full Body',
            exercises: [_ex('squat-1'), _ex('bench-1')],
          ),
        ],
  );
}

GeneratedProgrammeWorkout _workout({
  String day = 'monday',
  String name = 'Workout',
  List<GeneratedProgrammeExercise>? exercises,
}) {
  return GeneratedProgrammeWorkout(
    dayOfWeek: day,
    workoutName: name,
    exercises: exercises ?? [_ex('squat-1')],
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ProgrammeValidator — valid programme', () {
    test('no violations for a well-formed single-workout programme', () {
      final result = _validator.validate(
        _programme(),
        knownExerciseIds: _knownIds,
      );
      expect(result.violations, isEmpty);
      expect(result.isValid, isTrue);
    });

    test('no violations when daysPerWeek matches workout count', () {
      final programme = _programme(workouts: [
        _workout(day: 'monday'),
        _workout(day: 'wednesday'),
        _workout(day: 'friday'),
      ]);
      final result = _validator.validate(
        programme,
        knownExerciseIds: _knownIds,
        requestedDaysPerWeek: 3,
      );
      expect(result.violations, isEmpty);
      expect(result.isValid, isTrue);
    });

    test('no hard violations when soft violation present — isValid is true', () {
      final exerciseById = {
        'squat-1': const Exercise(
          id: 'squat-1',
          name: 'Squat',
          safetyTier: SafetyTier.tier3,
        ),
      };
      final result = _validator.validate(
        _programme(),
        knownExerciseIds: _knownIds,
        exerciseById: exerciseById,
      );
      expect(result.hardViolations, isEmpty);
      expect(result.isValid, isTrue);
      expect(result.softViolations, isNotEmpty);
    });
  });

  group('ProgrammeValidator — hard violation: emptyWorkoutList', () {
    test('reported when workouts list is empty', () {
      final result = _validator.validate(
        _programme(workouts: []),
        knownExerciseIds: _knownIds,
      );
      expect(result.isValid, isFalse);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.emptyWorkoutList),
      );
    });

    test('returns early — no further violations checked', () {
      final result = _validator.validate(
        _programme(workouts: []),
        knownExerciseIds: {},
      );
      expect(result.violations.length, 1);
      expect(result.violations.first.type, ViolationType.emptyWorkoutList);
    });
  });

  group('ProgrammeValidator — hard violation: emptyExercisesInWorkout', () {
    test('reported when a workout has no exercises', () {
      final result = _validator.validate(
        _programme(workouts: [_workout(exercises: [])]),
        knownExerciseIds: _knownIds,
      );
      expect(result.isValid, isFalse);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.emptyExercisesInWorkout),
      );
    });

    test('message names the workout', () {
      const workoutName = 'Leg Day';
      final result = _validator.validate(
        _programme(workouts: [
          GeneratedProgrammeWorkout(
            dayOfWeek: 'monday',
            workoutName: workoutName,
            exercises: const [],
          ),
        ]),
        knownExerciseIds: _knownIds,
      );
      final violation = result.hardViolations
          .firstWhere((v) => v.type == ViolationType.emptyExercisesInWorkout);
      expect(violation.message, contains(workoutName));
    });
  });

  group('ProgrammeValidator — hard violation: unknownExerciseId', () {
    test('reported when exercise ID is not in library', () {
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex('hallucinated-ex-999')]),
        ]),
        knownExerciseIds: _knownIds,
      );
      expect(result.isValid, isFalse);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.unknownExerciseId),
      );
    });

    test('message includes the unknown ID', () {
      const badId = 'hallucinated-ex-999';
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex(badId)]),
        ]),
        knownExerciseIds: _knownIds,
      );
      final violation = result.hardViolations
          .firstWhere((v) => v.type == ViolationType.unknownExerciseId);
      expect(violation.message, contains(badId));
    });

    test('multiple unknown IDs each produce a separate violation', () {
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex('bad-1'), _ex('bad-2')]),
        ]),
        knownExerciseIds: _knownIds,
      );
      expect(
        result.hardViolations
            .where((v) => v.type == ViolationType.unknownExerciseId)
            .length,
        2,
      );
    });
  });

  group('ProgrammeValidator — hard violation: invalidSets', () {
    test('reported when sets list is empty', () {
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [
            const GeneratedProgrammeExercise(exerciseId: 'squat-1', sets: []),
          ]),
        ]),
        knownExerciseIds: _knownIds,
      );
      expect(result.isValid, isFalse);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.invalidSets),
      );
    });
  });

  group('ProgrammeValidator — hard violation: invalidReps', () {
    test('reported when reps is zero in a set', () {
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex('squat-1', reps: 0)]),
        ]),
        knownExerciseIds: _knownIds,
      );
      expect(result.isValid, isFalse);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.invalidReps),
      );
    });

    test('reported when reps is negative in a set', () {
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex('squat-1', reps: -5)]),
        ]),
        knownExerciseIds: _knownIds,
      );
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.invalidReps),
      );
    });
  });

  group('ProgrammeValidator — soft violation: suspiciousLoad', () {
    test('reported when barbell exercise load is below 20 kg', () {
      final exerciseById = {
        'squat-1': const Exercise(
          id: 'squat-1',
          name: 'Barbell Back Squat',
          equipment: 'Barbell',
        ),
      };
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex('squat-1', load: 18.0)]),
        ]),
        knownExerciseIds: _knownIds,
        exerciseById: exerciseById,
      );
      expect(
        result.softViolations.map((v) => v.type),
        contains(ViolationType.suspiciousLoad),
      );
      expect(result.hardViolations, isEmpty);
    });

    test('not reported when barbell load is exactly 20 kg', () {
      final exerciseById = {
        'squat-1': const Exercise(
          id: 'squat-1',
          name: 'Barbell Back Squat',
          equipment: 'Barbell',
        ),
      };
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex('squat-1', load: 20.0)]),
        ]),
        knownExerciseIds: _knownIds,
        exerciseById: exerciseById,
      );
      expect(
        result.violations.map((v) => v.type),
        isNot(contains(ViolationType.suspiciousLoad)),
      );
    });

    test('reported when kettlebell load is below 4 kg', () {
      final exerciseById = {
        'squat-1': const Exercise(
          id: 'squat-1',
          name: 'Kettlebell Swing',
          equipment: 'Kettlebell',
        ),
      };
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex('squat-1', load: 2.0)]),
        ]),
        knownExerciseIds: _knownIds,
        exerciseById: exerciseById,
      );
      expect(
        result.softViolations.map((v) => v.type),
        contains(ViolationType.suspiciousLoad),
      );
    });

    test('not reported for dumbbell exercises (no floor)', () {
      final exerciseById = {
        'squat-1': const Exercise(
          id: 'squat-1',
          name: 'Dumbbell Curl',
          equipment: 'Dumbbell',
        ),
      };
      final result = _validator.validate(
        _programme(workouts: [
          _workout(exercises: [_ex('squat-1', load: 1.0)]),
        ]),
        knownExerciseIds: _knownIds,
        exerciseById: exerciseById,
      );
      expect(
        result.violations.map((v) => v.type),
        isNot(contains(ViolationType.suspiciousLoad)),
      );
    });
  });

  group('ProgrammeValidator — soft violation: tier3ExerciseIncluded', () {
    test('reported when a tier-3 exercise is prescribed', () {
      final exerciseById = {
        'squat-1': const Exercise(
          id: 'squat-1',
          name: 'High-Risk Move',
          safetyTier: SafetyTier.tier3,
        ),
        'bench-1': const Exercise(
          id: 'bench-1',
          name: 'Bench Press',
          safetyTier: SafetyTier.tier1,
        ),
      };
      final result = _validator.validate(
        _programme(),
        knownExerciseIds: _knownIds,
        exerciseById: exerciseById,
      );
      expect(
        result.softViolations.map((v) => v.type),
        contains(ViolationType.tier3ExerciseIncluded),
      );
      expect(result.hardViolations, isEmpty);
    });

    test('not reported when exerciseById is null', () {
      final result = _validator.validate(
        _programme(),
        knownExerciseIds: _knownIds,
      );
      expect(
        result.violations.map((v) => v.type),
        isNot(contains(ViolationType.tier3ExerciseIncluded)),
      );
    });
  });

  group('ProgrammeValidator — soft violation: workoutCountMismatch', () {
    test('reported when workout count differs from requestedDaysPerWeek', () {
      final result = _validator.validate(
        _programme(workouts: [
          _workout(day: 'monday'),
          _workout(day: 'wednesday'),
        ]),
        knownExerciseIds: _knownIds,
        requestedDaysPerWeek: 3,
      );
      expect(
        result.softViolations.map((v) => v.type),
        contains(ViolationType.workoutCountMismatch),
      );
      expect(result.hardViolations, isEmpty);
    });

    test('not reported when requestedDaysPerWeek is null', () {
      final result = _validator.validate(
        _programme(workouts: [_workout()]),
        knownExerciseIds: _knownIds,
      );
      expect(
        result.violations.map((v) => v.type),
        isNot(contains(ViolationType.workoutCountMismatch)),
      );
    });
  });

  group('ProgrammeValidator — multiple violations', () {
    test('hard violations collected across workouts', () {
      final programme = _programme(workouts: [
        _workout(
          day: 'monday',
          exercises: [
            const GeneratedProgrammeExercise(exerciseId: 'squat-1', sets: []),
            _ex('squat-1', reps: 0),
          ],
        ),
        _workout(
          day: 'wednesday',
          exercises: [_ex('bad-id')],
        ),
      ]);
      final result = _validator.validate(
        programme,
        knownExerciseIds: _knownIds,
      );
      final types = result.hardViolations.map((v) => v.type).toSet();
      expect(types, contains(ViolationType.invalidSets));
      expect(types, contains(ViolationType.invalidReps));
      expect(types, contains(ViolationType.unknownExerciseId));
    });
  });

  group('ProgrammeValidationResult', () {
    test('isValid is true when violations list is empty', () {
      const result = ProgrammeValidationResult(violations: []);
      expect(result.isValid, isTrue);
    });

    test('isValid is false when at least one hard violation exists', () {
      const result = ProgrammeValidationResult(violations: [
        ProgrammeViolation(
          type: ViolationType.emptyWorkoutList,
          severity: ViolationSeverity.hard,
          message: 'No workouts.',
        ),
      ]);
      expect(result.isValid, isFalse);
    });

    test('isValid is true when all violations are soft', () {
      const result = ProgrammeValidationResult(violations: [
        ProgrammeViolation(
          type: ViolationType.workoutCountMismatch,
          severity: ViolationSeverity.soft,
          message: 'Count mismatch.',
        ),
      ]);
      expect(result.isValid, isTrue);
    });

    test('hardViolations and softViolations filter correctly', () {
      const result = ProgrammeValidationResult(violations: [
        ProgrammeViolation(
          type: ViolationType.invalidSets,
          severity: ViolationSeverity.hard,
          message: 'Bad sets.',
        ),
        ProgrammeViolation(
          type: ViolationType.workoutCountMismatch,
          severity: ViolationSeverity.soft,
          message: 'Count mismatch.',
        ),
      ]);
      expect(result.hardViolations.length, 1);
      expect(result.softViolations.length, 1);
    });
  });
}
