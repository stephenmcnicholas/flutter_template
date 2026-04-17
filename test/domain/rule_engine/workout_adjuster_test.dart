import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/domain/rule_engine/workout_adjuster.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/domain/user_scorecard.dart';

void main() {
  final compound = Exercise(
    id: 'compound',
    name: 'Back Squat',
    movementPattern: MovementPattern.squat,
  );
  final accessory = Exercise(
    id: 'iso',
    name: 'Tricep Pushdown',
    movementPattern: MovementPattern.isolationUpper,
  );

  group('WorkoutAdjuster', () {
    test('green leaves args unchanged', () {
      const args = PreWorkoutCheckInArgs(workoutName: 'W');
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.green,
        premiumAdaptation: true,
      );
      expect(identical(out, args), isTrue);
    });

    test('green with programmeLoadScale scales positive weights', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.green,
        premiumAdaptation: true,
        programmeLoadScale: 1.1,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 110.0);
    });

    test('amber without premium leaves args unchanged', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: false,
      );
      expect(identical(out, args), isTrue);
    });

    test('amber with low consistency scorecard reduces load more than default', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      const lowConsistency = UserScorecard(id: 'local', consistency: 2.0);
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
        scorecard: lowConsistency,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 86.0);
    });

    test('amber reduces positive load by ~10% on all sets', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
            {'weight': 50, 'reps': 8},
          ],
        },
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 90.0);
      expect(out.initialSetsByExercise!['compound']![1]['weight'], 45.0);
    });

    test('amber skips load change when weight is 0 or missing', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 0, 'reps': 10},
            {'reps': 10},
          ],
        },
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 0);
      expect(out.initialSetsByExercise!['compound']![1].containsKey('weight'), isFalse);
    });

    test('high independence keeps all accessory sets on amber', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [accessory],
        initialSetsByExercise: {
          'iso': [
            {'weight': 20.0, 'reps': 12},
            {'weight': 20.0, 'reps': 12},
            {'weight': 20.0, 'reps': 12},
          ],
        },
      );
      const score = UserScorecard(id: 'local', independence: 8.0);
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
        scorecard: score,
      );
      expect(out.initialSetsByExercise!['iso']!.length, 3);
    });

    test('amber drops one set on isolation accessories when >1 set', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [accessory],
        initialSetsByExercise: {
          'iso': [
            {'weight': 20.0, 'reps': 12},
            {'weight': 20.0, 'reps': 12},
            {'weight': 20.0, 'reps': 12},
          ],
        },
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
      );
      expect(out.initialSetsByExercise!['iso']!.length, 2);
      expect(out.initialSetsByExercise!['iso']!.every((m) => m['weight'] == 18.0), isTrue);
    });

    test('amber does not drop below one set on accessories', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [accessory],
        initialSetsByExercise: {
          'iso': [
            {'weight': 20.0, 'reps': 12},
          ],
        },
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
      );
      expect(out.initialSetsByExercise!['iso']!.length, 1);
    });

    test('red unchanged until adjustWorkout (Task 16)', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.red,
        premiumAdaptation: true,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 100.0);
    });

    // ── Amber load factor thresholds ──────────────────────────────────────────

    test('amber with consistency>=7 + progression>=6 uses 0.94 factor', () {
      // consistency=7.0, progression=6.0 → _amberLoadFactorFor returns 0.94
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      const score = UserScorecard(id: 'local', consistency: 7.0, progression: 6.0);
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
        scorecard: score,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 94.0);
    });

    test('amber with computedLevel>=4 (and consistency<7) uses 0.93 factor', () {
      // computedLevel=4, consistency=5.0 → falls through to computedLevel branch → 0.93
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      const score = UserScorecard(id: 'local', computedLevel: 4, consistency: 5.0);
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
        scorecard: score,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 93.0);
    });

    test('amber: consistency at boundary 4.0 uses default 0.90 (not low-consistency branch)', () {
      // consistency==4.0 does NOT satisfy < 4.0 → uses default 0.90
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      const score = UserScorecard(id: 'local', consistency: 4.0);
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
        scorecard: score,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 90.0);
    });

    test('amber: consistency at 3.9 (below boundary) uses 0.86 factor', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      const score = UserScorecard(id: 'local', consistency: 3.9);
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
        scorecard: score,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 86.0);
    });

    // ── Accessory set-trim thresholds ─────────────────────────────────────────

    test('amber: computedLevel>=4 + consistency>=6 keeps all accessory sets', () {
      // _trimAccessorySetForAmber → computedLevel>=4 && consistency>=6.0 → false (no trim)
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [accessory],
        initialSetsByExercise: {
          'iso': [
            {'weight': 20.0, 'reps': 12},
            {'weight': 20.0, 'reps': 12},
            {'weight': 20.0, 'reps': 12},
          ],
        },
      );
      const score = UserScorecard(id: 'local', computedLevel: 4, consistency: 6.0);
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
        scorecard: score,
      );
      expect(out.initialSetsByExercise!['iso']!.length, 3);
    });

    // ── programmeLoadScale combined with amber ────────────────────────────────

    test('amber applies programmeLoadScale on top of amber load reduction', () {
      // combined factor = 0.90 * 1.1 = 0.99 → 100 * 0.99 = 99.0
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
        programmeLoadScale: 1.1,
      );
      expect(out.initialSetsByExercise!['compound']![0]['weight'], 99.0);
    });

    // ── Non-pre-workout ratings pass through unchanged ────────────────────────

    test('post-session ratings (great/okay/tough) leave args unchanged', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      for (final rating in [CheckInRating.great, CheckInRating.okay, CheckInRating.tough]) {
        final out = WorkoutAdjuster.adjust(
          args: args,
          rating: rating,
          premiumAdaptation: true,
        );
        expect(
          out.initialSetsByExercise!['compound']![0]['weight'],
          100.0,
          reason: '$rating should not modify load',
        );
      }
    });

    test('mid-programme ratings (tooEasy/aboutRight/tooHard) leave args unchanged', () {
      final args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialExercises: [compound],
        initialSetsByExercise: {
          'compound': [
            {'weight': 100.0, 'reps': 5},
          ],
        },
      );
      for (final rating in [CheckInRating.tooEasy, CheckInRating.aboutRight, CheckInRating.tooHard]) {
        final out = WorkoutAdjuster.adjust(
          args: args,
          rating: rating,
          premiumAdaptation: true,
        );
        expect(
          out.initialSetsByExercise!['compound']![0]['weight'],
          100.0,
          reason: '$rating should not modify load',
        );
      }
    });

    // ── Edge: empty/null sets map ─────────────────────────────────────────────

    test('amber with null initialSetsByExercise returns args unchanged', () {
      const args = PreWorkoutCheckInArgs(workoutName: 'W');
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
      );
      expect(identical(out, args), isTrue);
    });

    test('amber with empty initialSetsByExercise returns args unchanged', () {
      const args = PreWorkoutCheckInArgs(
        workoutName: 'W',
        initialSetsByExercise: {},
      );
      final out = WorkoutAdjuster.adjust(
        args: args,
        rating: CheckInRating.amber,
        premiumAdaptation: true,
      );
      expect(identical(out, args), isTrue);
    });
  });
}
