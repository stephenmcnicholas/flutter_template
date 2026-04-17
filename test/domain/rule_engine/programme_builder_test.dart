import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/rule_engine/programme_builder.dart';
import 'package:fytter/src/domain/user_scorecard.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _ex({
  required String id,
  required String name,
  MovementPattern? movementPattern,
  SafetyTier safetyTier = SafetyTier.tier1,
  String? equipment,
  List<String> suitability = const [],
}) {
  return Exercise(
    id: id,
    name: name,
    movementPattern: movementPattern,
    safetyTier: safetyTier,
    equipment: equipment,
    suitability: suitability,
  );
}

void main() {
  final fullGymLibrary = [
    _ex(id: 'squat-1', name: 'Back Squat', movementPattern: MovementPattern.squat, equipment: 'Barbell'),
    _ex(id: 'hinge-1', name: 'Deadlift', movementPattern: MovementPattern.hinge, equipment: 'Barbell'),
    _ex(id: 'push-h-1', name: 'Bench Press', movementPattern: MovementPattern.pushHorizontal, equipment: 'Barbell'),
    _ex(id: 'pull-h-1', name: 'Row', movementPattern: MovementPattern.pullHorizontal, equipment: 'Barbell'),
    _ex(id: 'push-v-1', name: 'OHP', movementPattern: MovementPattern.pushVertical, equipment: 'Barbell'),
    _ex(id: 'pull-v-1', name: 'Pull-up', movementPattern: MovementPattern.pullVertical, equipment: 'Bodyweight'),
    _ex(id: 'lunge-1', name: 'Lunge', movementPattern: MovementPattern.lunge, equipment: 'Dumbbell'),
  ];

  final bodyweightOnly = [
    _ex(id: 'bw-squat', name: 'Bodyweight Squat', movementPattern: MovementPattern.squat, equipment: 'Bodyweight'),
    _ex(id: 'bw-push', name: 'Push-up', movementPattern: MovementPattern.pushHorizontal, equipment: 'Bodyweight'),
    _ex(id: 'bw-pull', name: 'Inverted Row', movementPattern: MovementPattern.pullHorizontal, equipment: 'Bodyweight'),
    _ex(id: 'bw-hinge', name: 'Glute Bridge', movementPattern: MovementPattern.hinge, equipment: 'Bodyweight'),
  ];

  group('ProgrammeBuilder', () {
    test('low consistency reduces sets in prescription vs default', () {
      final input = ProgrammeBuilderInput(
        daysPerWeek: 3,
        sessionLengthMinutes: 45,
        goal: 'general_fitness',
        exerciseLibrary: fullGymLibrary,
        userScorecard: const UserScorecard(id: 'l', consistency: 2.0, fundamentals: 5.0, endurance: 5.0),
      );
      final programme = ProgrammeBuilder.build(input);
      expect(programme.workouts.first.exercises.first.sets.length, 2);
      expect(programme.workouts.first.exercises.first.sets.first.reps, greaterThan(10));
    });

    test('given 3 days full gym get_stronger produces full body programme with compounds', () {
      final input = ProgrammeBuilderInput(
        daysPerWeek: 3,
        sessionLengthMinutes: 45,
        goal: 'get_stronger',
        exerciseLibrary: fullGymLibrary,
      );
      final programme = ProgrammeBuilder.build(input);

      expect(programme.workouts.length, 3);
      expect(programme.programmeName, 'Rule-built programme');
      expect(programme.durationWeeks, 4);

      for (final w in programme.workouts) {
        expect(w.exercises.length, greaterThanOrEqualTo(4));
        expect(w.exercises.length, lessThanOrEqualTo(6));
        for (final e in w.exercises) {
          expect(e.sets.length, 4);
          expect(e.sets.first.reps, 5);
          expect(e.restSeconds, 180);
        }
      }

      final allPatterns = programme.workouts.expand((w) => w.exercises).map((e) => e.exerciseId).toSet();
      expect(allPatterns.contains('squat-1'), isTrue);
      expect(allPatterns.contains('hinge-1'), isTrue);
      expect(allPatterns.contains('push-h-1'), isTrue);
      expect(allPatterns.contains('pull-h-1'), isTrue);
    });

    test('given 2 days bodyweight only produces bodyweight programme', () {
      final input = ProgrammeBuilderInput(
        daysPerWeek: 2,
        sessionLengthMinutes: 30,
        goal: 'general_fitness',
        equipment: 'bodyweight',
        exerciseLibrary: bodyweightOnly,
      );
      final programme = ProgrammeBuilder.build(input);

      expect(programme.workouts.length, 2);
      final allIds = programme.workouts.expand((w) => w.exercises).map((e) => e.exerciseId).toSet();
      expect(allIds, contains('bw-squat'));
      expect(allIds, contains('bw-push'));
      expect(allIds, contains('bw-pull'));
      expect(allIds, contains('bw-hinge'));
    });

    test('equipment constraint excludes exercises requiring missing equipment', () {
      final mixed = [
        ...bodyweightOnly,
        _ex(id: 'barbell-1', name: 'Barbell Squat', movementPattern: MovementPattern.squat, equipment: 'Barbell'),
      ];
      final input = ProgrammeBuilderInput(
        daysPerWeek: 2,
        sessionLengthMinutes: 30,
        equipment: 'bodyweight',
        exerciseLibrary: mixed,
      );
      final programme = ProgrammeBuilder.build(input);

      final allIds = programme.workouts.expand((w) => w.exercises).map((e) => e.exerciseId).toList();
      expect(allIds.contains('barbell-1'), isFalse);
    });

    test('movement pattern balance: programme includes push pull squat hinge', () {
      final input = ProgrammeBuilderInput(
        daysPerWeek: 3,
        sessionLengthMinutes: 45,
        exerciseLibrary: fullGymLibrary,
      );
      final programme = ProgrammeBuilder.build(input);

      final day1Ids = programme.workouts.first.exercises.map((e) => e.exerciseId).toSet();
      final hasSquat = day1Ids.any((id) => id.contains('squat') || id == 'squat-1');
      final hasHinge = day1Ids.any((id) => id.contains('hinge') || id == 'hinge-1');
      final hasPush = day1Ids.any((id) => id.contains('push') || id == 'push-h-1' || id == 'push-v-1');
      final hasPull = day1Ids.any((id) => id.contains('pull') || id == 'pull-h-1' || id == 'pull-v-1');

      expect(hasSquat, isTrue);
      expect(hasHinge, isTrue);
      expect(hasPush, isTrue);
      expect(hasPull, isTrue);
    });

    test('blocked days are not scheduled', () {
      final input = ProgrammeBuilderInput(
        daysPerWeek: 3,
        sessionLengthMinutes: 45,
        blockedDays: ['saturday', 'sunday'],
        exerciseLibrary: fullGymLibrary,
      );
      final programme = ProgrammeBuilder.build(input);

      final days = programme.workouts.map((w) => w.dayOfWeek).toList();
      expect(days.contains('saturday'), isFalse);
      expect(days.contains('sunday'), isFalse);
      expect(days.length, 3);
    });

    test('deload week and weekly progression are set', () {
      final input = ProgrammeBuilderInput(
        daysPerWeek: 2,
        sessionLengthMinutes: 30,
        exerciseLibrary: bodyweightOnly,
      );
      final programme = ProgrammeBuilder.build(input);

      expect(programme.deloadWeek, isNotNull);
      expect(programme.deloadWeek!.when, 'week_4');
      expect(programme.weeklyProgression, isNotNull);
    });

    test('rehab_safe exercises are excluded from rule-built programme', () {
      final library = [
        _ex(id: 'chair-stand', name: 'Chair Sit-to-Stand', movementPattern: MovementPattern.squat, equipment: 'Bodyweight', suitability: ['rehab_safe']),
        _ex(id: 'bw-squat', name: 'Bodyweight Squat', movementPattern: MovementPattern.squat, equipment: 'Bodyweight'),
        _ex(id: 'wall-push', name: 'Wall Push-Up', movementPattern: MovementPattern.pushHorizontal, equipment: 'Bodyweight', suitability: ['rehab_safe']),
        _ex(id: 'bw-push', name: 'Push-up', movementPattern: MovementPattern.pushHorizontal, equipment: 'Bodyweight'),
        _ex(id: 'bw-pull', name: 'Inverted Row', movementPattern: MovementPattern.pullHorizontal, equipment: 'Bodyweight'),
        _ex(id: 'bw-hinge', name: 'Glute Bridge', movementPattern: MovementPattern.hinge, equipment: 'Bodyweight'),
      ];
      final input = ProgrammeBuilderInput(
        daysPerWeek: 2,
        sessionLengthMinutes: 30,
        equipment: 'bodyweight',
        exerciseLibrary: library,
      );
      final programme = ProgrammeBuilder.build(input);

      final allIds = programme.workouts.expand((w) => w.exercises).map((e) => e.exerciseId).toSet();
      expect(allIds.contains('chair-stand'), isFalse);
      expect(allIds.contains('wall-push'), isFalse);
      expect(allIds.contains('bw-squat'), isTrue);
      expect(allIds.contains('bw-push'), isTrue);
    });

    test('no single workout has multiple exercises from same movement pattern when patterns available', () {
      final library = [
        _ex(id: 'squat-1', name: 'Squat', movementPattern: MovementPattern.squat, equipment: 'Barbell'),
        _ex(id: 'hinge-1', name: 'Deadlift', movementPattern: MovementPattern.hinge, equipment: 'Barbell'),
        _ex(id: 'push-h-1', name: 'Bench', movementPattern: MovementPattern.pushHorizontal, equipment: 'Barbell'),
        _ex(id: 'push-h-2', name: 'Push-up', movementPattern: MovementPattern.pushHorizontal, equipment: 'Bodyweight'),
        _ex(id: 'pull-h-1', name: 'Row', movementPattern: MovementPattern.pullHorizontal, equipment: 'Barbell'),
        _ex(id: 'push-v-1', name: 'OHP', movementPattern: MovementPattern.pushVertical, equipment: 'Barbell'),
      ];
      final input = ProgrammeBuilderInput(
        daysPerWeek: 1,
        sessionLengthMinutes: 45,
        exerciseLibrary: library,
      );
      final programme = ProgrammeBuilder.build(input);

      expect(programme.workouts.length, 1);
      final workout = programme.workouts.single;
      final patternCounts = <MovementPattern, int>{};
      for (final ex in workout.exercises) {
        final exObj = library.firstWhere((e) => e.id == ex.exerciseId);
        if (exObj.movementPattern != null) {
          patternCounts[exObj.movementPattern!] = (patternCounts[exObj.movementPattern!] ?? 0) + 1;
        }
      }
      for (final count in patternCounts.values) {
        expect(count, lessThanOrEqualTo(1), reason: 'Each pattern should appear at most once per workout when enough patterns exist');
      }
    });
  });
}
