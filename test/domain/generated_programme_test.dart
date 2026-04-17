import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/generated_programme.dart';

void main() {
  group('GeneratedProgrammeSet', () {
    test('toJson/fromJson round-trip', () {
      const s = GeneratedProgrammeSet(reps: 10, targetLoadKg: 60.0);
      final restored = GeneratedProgrammeSet.fromJson(s.toJson());
      expect(restored.reps, 10);
      expect(restored.targetLoadKg, 60.0);
    });

    test('toJson omits null targetLoadKg', () {
      const s = GeneratedProgrammeSet(reps: 8);
      expect(s.toJson().containsKey('targetLoadKg'), isFalse);
    });
  });

  group('GeneratedProgrammeExercise', () {
    test('toJson/fromJson round-trip with per-set array', () {
      final ex = GeneratedProgrammeExercise(
        exerciseId: 'ex-1',
        sets: [
          const GeneratedProgrammeSet(reps: 10, targetLoadKg: 60.0),
          const GeneratedProgrammeSet(reps: 8, targetLoadKg: 65.0),
        ],
        restSeconds: 90,
        coachingNote: 'Why chosen for you.',
      );
      final restored = GeneratedProgrammeExercise.fromJson(ex.toJson());
      expect(restored.exerciseId, 'ex-1');
      expect(restored.sets.length, 2);
      expect(restored.sets[0].reps, 10);
      expect(restored.sets[0].targetLoadKg, 60.0);
      expect(restored.sets[1].reps, 8);
      expect(restored.sets[1].targetLoadKg, 65.0);
      expect(restored.restSeconds, 90);
      expect(restored.coachingNote, 'Why chosen for you.');
    });

    test('fromJson handles legacy flat format (sets: number, reps: number)', () {
      final ex = GeneratedProgrammeExercise.fromJson({
        'exerciseId': 'squat-1',
        'sets': 3,
        'reps': 10,
        'targetLoadKg': 60.0,
        'restSeconds': 90,
      });
      expect(ex.sets.length, 3);
      expect(ex.sets.every((s) => s.reps == 10 && s.targetLoadKg == 60.0), isTrue);
      expect(ex.restSeconds, 90);
    });

    test('fromJson uses defaults for missing sets', () {
      final ex = GeneratedProgrammeExercise.fromJson({'exerciseId': 'squat-1'});
      // Legacy: sets missing → defaults to 3 sets × 8 reps
      expect(ex.sets.length, 3);
      expect(ex.sets.first.reps, 8);
      expect(ex.sets.first.targetLoadKg, isNull);
      expect(ex.restSeconds, isNull);
      expect(ex.coachingNote, isNull);
    });

    test('toJson omits null optionals', () {
      final ex = GeneratedProgrammeExercise(
        exerciseId: 'ex-1',
        sets: [const GeneratedProgrammeSet(reps: 8)],
      );
      final json = ex.toJson();
      expect(json.containsKey('restSeconds'), isFalse);
      expect(json.containsKey('coachingNote'), isFalse);
    });
  });

  group('GeneratedProgrammeWorkout', () {
    test('toJson/fromJson round-trip with briefDescription', () {
      final workout = GeneratedProgrammeWorkout(
        dayOfWeek: 'monday',
        workoutName: 'Full Body A',
        briefDescription: 'Upper emphasis, shoulder-friendly.',
        exercises: [
          GeneratedProgrammeExercise(
            exerciseId: 'e1',
            sets: [const GeneratedProgrammeSet(reps: 10, targetLoadKg: 60)],
          ),
        ],
      );
      final restored = GeneratedProgrammeWorkout.fromJson(workout.toJson());
      expect(restored.dayOfWeek, workout.dayOfWeek);
      expect(restored.workoutName, workout.workoutName);
      expect(restored.briefDescription, workout.briefDescription);
      expect(restored.exercises.length, 1);
      expect(restored.exercises.first.exerciseId, 'e1');
      expect(restored.exercises.first.sets.first.reps, 10);
    });

    test('fromJson uses defaults for missing dayOfWeek/workoutName', () {
      final workout = GeneratedProgrammeWorkout.fromJson({'exercises': []});
      expect(workout.dayOfWeek, 'monday');
      expect(workout.workoutName, 'Workout');
      expect(workout.briefDescription, isNull);
      expect(workout.exercises, isEmpty);
    });
  });

  group('GeneratedProgrammeDeload', () {
    test('fromJson returns null for null input', () {
      expect(GeneratedProgrammeDeload.fromJson(null), isNull);
    });

    test('fromJson returns null when when or guidance missing', () {
      expect(GeneratedProgrammeDeload.fromJson({}), isNull);
      expect(GeneratedProgrammeDeload.fromJson({'when': 'week 4'}), isNull);
      expect(GeneratedProgrammeDeload.fromJson({'guidance': 'Reduce load'}), isNull);
    });

    test('toJson/fromJson round-trip', () {
      const deload = GeneratedProgrammeDeload(when: 'week 4', guidance: 'Reduce load 50%.');
      final restored = GeneratedProgrammeDeload.fromJson(deload.toJson());
      expect(restored!.when, deload.when);
      expect(restored.guidance, deload.guidance);
    });
  });

  group('GeneratedProgramme', () {
    test('toJson/fromJson round-trip with full payload', () {
      final programme = GeneratedProgramme(
        programmeName: 'My Plan',
        programmeDescription: 'Built for you.',
        coachIntro: 'Welcome.',
        coachRationale: 'We chose 4 weeks because…',
        coachRationaleSpoken: 'Four weeks gives you time to progress.',
        durationWeeks: 4,
        personalisationNotes: const ['Note 1', 'Note 2'],
        workouts: [
          GeneratedProgrammeWorkout(
            dayOfWeek: 'monday',
            workoutName: 'A',
            exercises: [
              GeneratedProgrammeExercise(
                exerciseId: 'e1',
                sets: [const GeneratedProgrammeSet(reps: 8, targetLoadKg: 50)],
              ),
            ],
          ),
        ],
        deloadWeek: const GeneratedProgrammeDeload(when: 'week 4', guidance: 'Deload.'),
        weeklyProgression: 'Add weight when able.',
      );
      final restored = GeneratedProgramme.fromJson(programme.toJson());
      expect(restored.programmeName, programme.programmeName);
      expect(restored.durationWeeks, programme.durationWeeks);
      expect(restored.personalisationNotes, programme.personalisationNotes);
      expect(restored.workouts.length, 1);
      expect(restored.workouts.first.exercises.first.sets.first.reps, 8);
      expect(restored.deloadWeek?.when, 'week 4');
      expect(restored.weeklyProgression, 'Add weight when able.');
    });

    test('fromJson uses defaults for missing name/description/duration', () {
      final programme = GeneratedProgramme.fromJson({'workouts': []});
      expect(programme.programmeName, 'Generated Programme');
      expect(programme.programmeDescription, 'Rule-built programme.');
      expect(programme.durationWeeks, 4);
      expect(programme.coachIntro, isNull);
      expect(programme.coachRationale, isNull);
      expect(programme.coachRationaleSpoken, isNull);
      expect(programme.personalisationNotes, isEmpty);
      expect(programme.deloadWeek, isNull);
      expect(programme.weeklyProgression, isNull);
    });

    test('fromJson parses personalisationNotes and filters empty', () {
      final programme = GeneratedProgramme.fromJson({
        'programmeName': 'P',
        'programmeDescription': 'D',
        'durationWeeks': 4,
        'personalisationNotes': ['a', '', 'b'],
        'workouts': [],
      });
      expect(programme.personalisationNotes, ['a', 'b']);
    });

    test('toJson omits null coachIntro, coachRationale, deloadWeek, weeklyProgression', () {
      const programme = GeneratedProgramme(
        programmeName: 'P',
        programmeDescription: 'D',
        durationWeeks: 4,
        workouts: [],
      );
      final json = programme.toJson();
      expect(json.containsKey('coachIntro'), isFalse);
      expect(json.containsKey('coachRationale'), isFalse);
      expect(json.containsKey('coachRationaleSpoken'), isFalse);
      expect(json.containsKey('deloadWeek'), isFalse);
      expect(json.containsKey('weeklyProgression'), isFalse);
    });

    test('fromJson parses coachRationaleSpoken when present', () {
      final programme = GeneratedProgramme.fromJson({
        'programmeName': 'P',
        'programmeDescription': 'D',
        'durationWeeks': 4,
        'coachRationaleSpoken': 'Short script for voice.',
        'workouts': [],
      });
      expect(programme.coachRationaleSpoken, 'Short script for voice.');
    });
  });
}
