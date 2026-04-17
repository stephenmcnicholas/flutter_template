import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/rule_engine/scorecard_session_metrics.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';

void main() {
  group('scorecardDateOnlyLocal', () {
    test('strips time in local zone', () {
      final d = DateTime(2025, 6, 10, 15, 30);
      final only = scorecardDateOnlyLocal(d);
      expect(only.hour, 0);
      expect(only.minute, 0);
      expect(only.year, 2025);
      expect(only.month, 6);
      expect(only.day, 10);
    });
  });

  group('rolling window counts', () {
    test('counts sessions whose local day is within 28 days ending today', () {
      final today = DateTime(2025, 6, 15, 12);
      final old = WorkoutSession(
        id: 'a',
        workoutId: 'w',
        date: today.subtract(const Duration(days: 29)),
        entries: const [],
        name: 'n',
      );
      final recent = WorkoutSession(
        id: 'b',
        workoutId: 'w',
        date: today.subtract(const Duration(days: 5)),
        entries: const [],
        name: 'n',
      );
      final n = scorecardCountSessionsInRollingDayWindow(
        [old, recent],
        today,
      );
      expect(n, 1);
    });

    test('counts scheduled slots in window', () {
      final today = DateTime(2025, 6, 15);
      final programs = [
        Program(
          id: 'p',
          name: 'P',
          schedule: [
            ProgramWorkout(
              workoutId: 'w',
              scheduledDate: today.subtract(const Duration(days: 2)),
            ),
            ProgramWorkout(
              workoutId: 'w',
              scheduledDate: today.subtract(const Duration(days: 40)),
            ),
          ],
        ),
      ];
      final n = scorecardCountScheduledSlotsInRollingDayWindow(programs, today);
      expect(n, 1);
    });
  });

  group('movement patterns', () {
    test('maps exercise ids to pattern keys', () {
      const ex = Exercise(
        id: 'e1',
        name: 'Squat',
        movementPattern: MovementPattern.squat,
      );
      final keys = scorecardMovementPatternKeysForExerciseIds({'e1', 'missing'}, [ex]);
      expect(keys, {movementPatternToStorage(MovementPattern.squat)});
    });
  });

  group('nearest schedule', () {
    test('returns null when no row within max distance', () {
      final program = Program(
        id: 'p',
        name: 'P',
        schedule: [
          ProgramWorkout(
            workoutId: 'w',
            scheduledDate: DateTime(2025, 6, 1),
          ),
        ],
      );
      final session = WorkoutSession(
        id: 's',
        workoutId: 'w',
        date: DateTime(2025, 6, 20),
        entries: const [],
        name: 'n',
      );
      expect(
        scorecardNearestScheduledWorkout(program, session, maxDayDistance: 4),
        isNull,
      );
    });

    test('trained on or before scheduled day', () {
      final nearest = ProgramWorkout(
        workoutId: 'w',
        scheduledDate: DateTime(2025, 6, 12),
      );
      final early = WorkoutSession(
        id: 's',
        workoutId: 'w',
        date: DateTime(2025, 6, 10, 18),
        entries: const [
          WorkoutEntry(
            id: 'x',
            exerciseId: 'e',
            reps: 5,
            weight: 0,
            isComplete: true,
          ),
        ],
        name: 'n',
      );
      expect(
        scorecardTrainedOnOrBeforeScheduledDay(early, nearest),
        isTrue,
      );
      final late = WorkoutSession(
        id: 's2',
        workoutId: 'w',
        date: DateTime(2025, 6, 14),
        entries: const [],
        name: 'n',
      );
      expect(
        scorecardTrainedOnOrBeforeScheduledDay(late, nearest),
        isFalse,
      );
    });
  });
}
