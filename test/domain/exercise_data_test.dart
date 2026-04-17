/// Validates the exercises.json seed data: field completeness, canonical
/// loggingType strings, and correct type assignments for the 9 exercises
/// corrected in issue #139.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/utils/exercise_utils.dart';
import 'package:uuid/uuid.dart';

void main() {
  const _uuid = Uuid();

  // Load and parse the seed file once for the whole suite.
  late List<Map<String, dynamic>> rawList;
  late List<Exercise> exercises;

  setUpAll(() {
    final file = File('assets/exercises/exercises.json');
    rawList = (jsonDecode(file.readAsStringSync()) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    exercises = rawList.map(Exercise.fromJson).toList();
  });

  // ---------------------------------------------------------------------------
  // Field completeness
  // ---------------------------------------------------------------------------
  group('field completeness', () {
    test('seed file contains exactly 144 exercises', () {
      expect(exercises, hasLength(144));
    });

    test('every exercise has a non-empty id and name', () {
      for (final ex in exercises) {
        expect(ex.id.trim(), isNotEmpty,
            reason: 'Exercise "${ex.name}" has an empty id');
        expect(ex.name.trim(), isNotEmpty,
            reason: 'Exercise with id "${ex.id}" has an empty name');
      }
    });

    test('every exercise id is unique', () {
      final ids = exercises.map((e) => e.id).toList();
      final unique = ids.toSet();
      expect(unique, hasLength(ids.length),
          reason: 'Duplicate exercise ids found');
    });

    test('every exercise carries a loggingType field in the raw JSON', () {
      for (final raw in rawList) {
        expect(raw.containsKey('loggingType'), isTrue,
            reason: '"${raw['name']}" is missing a loggingType field');
        expect(raw['loggingType'], isNotNull,
            reason: '"${raw['name']}" has a null loggingType');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Canonical loggingType strings
  // ---------------------------------------------------------------------------
  group('canonical loggingType strings', () {
    const validStrings = {
      'Reps and Weight',
      'Reps only',
      'Time only',
      'Time and Distance',
    };

    test('every loggingType is a recognised canonical string', () {
      for (final raw in rawList) {
        final type = raw['loggingType'] as String;
        expect(validStrings.contains(type), isTrue,
            reason:
                '"${raw['name']}" has unrecognised loggingType: "$type". '
                'Accepted values: $validStrings');
      }
    });

    test('exerciseInputTypeFromJson never returns null for any exercise', () {
      for (final raw in rawList) {
        final parsed = exerciseInputTypeFromJson(raw['loggingType'] as String?);
        expect(parsed, isNotNull,
            reason:
                '"${raw['name']}" loggingType "${raw['loggingType']}" failed to parse');
      }
    });

    test('getExerciseInputType returns a valid enum for every exercise', () {
      for (final ex in exercises) {
        final type = getExerciseInputType(ex);
        expect(ExerciseInputType.values.contains(type), isTrue,
            reason: '"${ex.name}" produced an invalid ExerciseInputType');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Type distribution (expected counts after issue-139 corrections)
  // ---------------------------------------------------------------------------
  group('type distribution', () {
    late Map<ExerciseInputType, List<String>> grouped;

    setUp(() {
      grouped = {};
      for (final ex in exercises) {
        final type = getExerciseInputType(ex);
        grouped.putIfAbsent(type, () => []).add(ex.name);
      }
    });

    test('repsAndWeight count', () {
      expect(grouped[ExerciseInputType.repsAndWeight], hasLength(73),
          reason: grouped[ExerciseInputType.repsAndWeight].toString());
    });

    test('repsOnly count', () {
      expect(grouped[ExerciseInputType.repsOnly], hasLength(45),
          reason: grouped[ExerciseInputType.repsOnly].toString());
    });

    test('timeOnly count', () {
      expect(grouped[ExerciseInputType.timeOnly], hasLength(23),
          reason: grouped[ExerciseInputType.timeOnly].toString());
    });

    test('distanceAndTime count', () {
      expect(grouped[ExerciseInputType.distanceAndTime], hasLength(3),
          reason: grouped[ExerciseInputType.distanceAndTime].toString());
    });
  });

  // ---------------------------------------------------------------------------
  // Spot-checks: issue-139 corrections
  // ---------------------------------------------------------------------------
  group('issue-139 type corrections', () {
    Exercise find(String name) =>
        exercises.firstWhere((e) => e.name == name,
            orElse: () => throw TestFailure('Exercise "$name" not found'));

    // Category A — legacy format strings fixed
    test('Nordic Hamstring Curl → repsOnly', () {
      expect(getExerciseInputType(find('Nordic Hamstring Curl')),
          ExerciseInputType.repsOnly);
    });

    test('Single-Leg Hip Thrust → repsOnly', () {
      expect(getExerciseInputType(find('Single-Leg Hip Thrust')),
          ExerciseInputType.repsOnly);
    });

    test('Band Pull-Apart → repsOnly', () {
      expect(getExerciseInputType(find('Band Pull-Apart')),
          ExerciseInputType.repsOnly);
    });

    test('Thoracic Rotation (Quadruped) → repsOnly', () {
      expect(getExerciseInputType(find('Thoracic Rotation (Quadruped)')),
          ExerciseInputType.repsOnly);
    });

    test('Ankle Mobility Wall Drill → repsOnly', () {
      expect(getExerciseInputType(find('Ankle Mobility Wall Drill')),
          ExerciseInputType.repsOnly);
    });

    test('Kneeling Hip Flexor Stretch → timeOnly', () {
      expect(getExerciseInputType(find('Kneeling Hip Flexor Stretch')),
          ExerciseInputType.timeOnly);
    });

    // Category B — inconsistency corrections
    test('Chin-Up → repsOnly (consistent with Pull-Up, not repsAndWeight)', () {
      expect(getExerciseInputType(find('Chin-Up')), ExerciseInputType.repsOnly);
    });

    test('Tricep Dips → repsAndWeight (consistent with Dips (Chest-Focused))',
        () {
      expect(getExerciseInputType(find('Tricep Dips')),
          ExerciseInputType.repsAndWeight);
    });

    test('Weighted Push-Up → repsAndWeight (name implies load tracking)', () {
      expect(getExerciseInputType(find('Weighted Push-Up')),
          ExerciseInputType.repsAndWeight);
    });
  });

  // ---------------------------------------------------------------------------
  // WorkoutEntry creation: every exercise can seed a valid set map
  // ---------------------------------------------------------------------------
  group('WorkoutEntry creation', () {
    test('a WorkoutEntry can be created for every exercise', () {
      for (final ex in exercises) {
        final entry = WorkoutEntry(
          id: _uuid.v4(),
          exerciseId: ex.id,
          reps: 0,
          weight: 0.0,
          isComplete: false,
          timestamp: null,
          sessionId: null,
        );
        expect(entry.exerciseId, ex.id,
            reason: 'WorkoutEntry creation failed for "${ex.name}"');
      }
    });

    test('exercises with weight-based types accept non-zero weight entries', () {
      for (final ex in exercises) {
        if (getExerciseInputType(ex) != ExerciseInputType.repsAndWeight) {
          continue;
        }
        final entry = WorkoutEntry(
          id: _uuid.v4(),
          exerciseId: ex.id,
          reps: 10,
          weight: 60.0,
          isComplete: false,
          timestamp: null,
          sessionId: null,
        );
        expect(entry.weight, 60.0,
            reason: '"${ex.name}" should accept a weight value');
      }
    });

    test('exercises with repsOnly type accept zero-weight entries', () {
      for (final ex in exercises) {
        if (getExerciseInputType(ex) != ExerciseInputType.repsOnly) continue;
        final entry = WorkoutEntry(
          id: _uuid.v4(),
          exerciseId: ex.id,
          reps: 10,
          weight: 0.0,
          isComplete: false,
          timestamp: null,
          sessionId: null,
        );
        expect(entry.weight, 0.0,
            reason: '"${ex.name}" should have zero weight');
      }
    });

    test('exercises with timeOnly type accept duration entries', () {
      for (final ex in exercises) {
        if (getExerciseInputType(ex) != ExerciseInputType.timeOnly) continue;
        final entry = WorkoutEntry(
          id: _uuid.v4(),
          exerciseId: ex.id,
          reps: 0,
          weight: 0.0,
          duration: 60,
          isComplete: false,
          timestamp: null,
          sessionId: null,
        );
        expect(entry.duration, 60,
            reason: '"${ex.name}" should accept a duration value');
      }
    });

    test('exercises with distanceAndTime type accept distance and duration',
        () {
      for (final ex in exercises) {
        if (getExerciseInputType(ex) != ExerciseInputType.distanceAndTime) {
          continue;
        }
        final entry = WorkoutEntry(
          id: _uuid.v4(),
          exerciseId: ex.id,
          reps: 0,
          weight: 0.0,
          distance: 5.0,
          duration: 1800,
          isComplete: false,
          timestamp: null,
          sessionId: null,
        );
        expect(entry.distance, 5.0,
            reason: '"${ex.name}" should accept a distance value');
        expect(entry.duration, 1800,
            reason: '"${ex.name}" should accept a duration value');
      }
    });
  });
}
