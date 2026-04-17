/// Fixture-based validation tests.
///
/// Each test loads a JSON fixture from test/fixtures/ai_programme/, parses it
/// through [GeneratedProgramme.fromJson], and runs [ProgrammeValidator].
///
/// Valid fixtures (F1–F4) must produce no hard violations.
/// Violation fixtures (V1–V5) must each trigger the expected hard violation.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/generated_programme.dart';
import 'package:fytter/src/domain/programme_validator.dart';

// ---------------------------------------------------------------------------
// Test exercise library
//
// Exercise IDs used by the valid fixtures. All are tier1 so no soft
// tier-3 violations appear. The library is intentionally minimal — it
// only needs to contain the IDs referenced by the fixtures.
// ---------------------------------------------------------------------------

const _knownIds = {
  'squat-1',
  'bench-1',
  'row-1',
  'deadlift-1',
  'ohp-1',
  'pullup-1',
  'rdl-1',
  'db-curl-1',
  'tricep-1',
  'pushup-1',
  'squat-bw-1',
  'lunge-1',
  'plank-1',
  'incline-bench-1',
  'cable-row-1',
  'leg-press-1',
  'lat-pulldown-1',
};

Map<String, Exercise> get _exerciseById => {
      for (final id in _knownIds)
        id: Exercise(id: id, name: id, safetyTier: SafetyTier.tier1),
    };

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _fixtureDir = 'test/fixtures/ai_programme';
const _validator = ProgrammeValidator();

GeneratedProgramme _load(String filename) {
  final content =
      File('$_fixtureDir/$filename').readAsStringSync();
  final json = jsonDecode(content) as Map<String, dynamic>;
  return GeneratedProgramme.fromJson(json);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Valid fixtures — no hard violations', () {
    test('F1: 3-day general fitness, barbell gym', () {
      final programme = _load('f1_general_fitness_3day.json');
      final result = _validator.validate(
        programme,
        knownExerciseIds: _knownIds,
        requestedDaysPerWeek: 3,
        exerciseById: _exerciseById,
      );
      expect(result.hardViolations, isEmpty,
          reason: result.hardViolations.map((v) => v.toString()).join('\n'));
      expect(programme.workouts.length, 3);
      expect(programme.durationWeeks, 4);
      expect(programme.personalisationNotes, isNotEmpty);
    });

    test('F2: 5-day muscle gain, full gym', () {
      final programme = _load('f2_muscle_gain_5day.json');
      final result = _validator.validate(
        programme,
        knownExerciseIds: _knownIds,
        requestedDaysPerWeek: 5,
        exerciseById: _exerciseById,
      );
      expect(result.hardViolations, isEmpty,
          reason: result.hardViolations.map((v) => v.toString()).join('\n'));
      expect(programme.workouts.length, 5);
    });

    test('F3: 2-day weight loss, home/bodyweight', () {
      final programme = _load('f3_weight_loss_2day_home.json');
      final result = _validator.validate(
        programme,
        knownExerciseIds: _knownIds,
        requestedDaysPerWeek: 2,
        exerciseById: _exerciseById,
      );
      expect(result.hardViolations, isEmpty,
          reason: result.hardViolations.map((v) => v.toString()).join('\n'));
      expect(programme.workouts.length, 2);
    });

    test('F4: 3-day with injury note (knee)', () {
      final programme = _load('f4_with_injury_note.json');
      final result = _validator.validate(
        programme,
        knownExerciseIds: _knownIds,
        requestedDaysPerWeek: 3,
        exerciseById: _exerciseById,
      );
      expect(result.hardViolations, isEmpty,
          reason: result.hardViolations.map((v) => v.toString()).join('\n'));
      // Personalisation notes must mention the injury accommodation.
      final notes = programme.personalisationNotes.join(' ').toLowerCase();
      expect(notes, contains('knee'),
          reason: 'Expected personalisation notes to reference knee injury.');
    });
  });

  group('Violation fixtures — expected hard violations detected', () {
    test('V1: empty workouts → emptyWorkoutList', () {
      final programme = _load('v1_empty_workouts.json');
      final result =
          _validator.validate(programme, knownExerciseIds: _knownIds);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.emptyWorkoutList),
      );
    });

    test('V2: workout with no exercises → emptyExercisesInWorkout', () {
      final programme = _load('v2_empty_exercises.json');
      final result =
          _validator.validate(programme, knownExerciseIds: _knownIds);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.emptyExercisesInWorkout),
      );
    });

    test('V3: hallucinated exercise ID → unknownExerciseId', () {
      final programme = _load('v3_unknown_exercise_id.json');
      final result =
          _validator.validate(programme, knownExerciseIds: _knownIds);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.unknownExerciseId),
      );
    });

    test('V4: sets = 0 → invalidSets', () {
      final programme = _load('v4_invalid_sets.json');
      final result =
          _validator.validate(programme, knownExerciseIds: _knownIds);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.invalidSets),
      );
    });

    test('V5: reps = 0 → invalidReps', () {
      final programme = _load('v5_invalid_reps.json');
      final result =
          _validator.validate(programme, knownExerciseIds: _knownIds);
      expect(
        result.hardViolations.map((v) => v.type),
        contains(ViolationType.invalidReps),
      );
    });
  });
}
