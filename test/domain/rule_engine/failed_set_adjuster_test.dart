import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/rule_engine/failed_set_adjuster.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/utils/set_outcome_utils.dart';

void main() {
  group('FailedSetAdjuster.applyLoadReductionToRemaining', () {
    test('scales later incomplete weighted sets', () {
      final sets = [
        {'isComplete': true, 'weight': 100.0},
        {'isComplete': true, 'weight': 100.0},
        {'isComplete': false, 'weight': 100.0},
        {'isComplete': false, 'weight': 50.0},
      ];
      final out = FailedSetAdjuster.applyLoadReductionToRemaining(
        sets: sets,
        afterSetIndex: 1,
      );
      expect(out[2]['weight'], closeTo(90.0, 0.01));
      expect(out[3]['weight'], closeTo(45.0, 0.01));
      expect(out[0]['weight'], 100.0);
      expect(out[1]['weight'], 100.0);
    });

    test('skips zero weight', () {
      final sets = [
        {'isComplete': false, 'weight': 0.0},
      ];
      final out = FailedSetAdjuster.applyLoadReductionToRemaining(
        sets: sets,
        afterSetIndex: -1,
      );
      expect(out[0]['weight'], 0.0);
    });
  });

  group('FailedSetAdjuster.consecutiveFailedStreakFromNewest', () {
    final t1 = DateTime(2025, 1, 3);
    final t2 = DateTime(2025, 1, 2);
    final t3 = DateTime(2025, 1, 1);

    test('counts consecutive failures from newest', () {
      final entries = [
        WorkoutEntry(
          id: 'a',
          exerciseId: 'ex',
          reps: 5,
          weight: 50,
          isComplete: true,
          timestamp: t1,
          setOutcome: SetOutcomeValues.failed,
        ),
        WorkoutEntry(
          id: 'b',
          exerciseId: 'ex',
          reps: 5,
          weight: 50,
          isComplete: true,
          timestamp: t2,
          setOutcome: SetOutcomeValues.failed,
        ),
        WorkoutEntry(
          id: 'c',
          exerciseId: 'ex',
          reps: 5,
          weight: 50,
          isComplete: true,
          timestamp: t3,
          setOutcome: SetOutcomeValues.completed,
        ),
      ];
      expect(FailedSetAdjuster.consecutiveFailedStreakFromNewest(entries), 2);
    });

    test('stops at completed', () {
      final entries = [
        WorkoutEntry(
          id: 'a',
          exerciseId: 'ex',
          reps: 5,
          weight: 50,
          isComplete: true,
          timestamp: t1,
          setOutcome: SetOutcomeValues.failed,
        ),
        WorkoutEntry(
          id: 'b',
          exerciseId: 'ex',
          reps: 5,
          weight: 50,
          isComplete: true,
          timestamp: t2,
          setOutcome: SetOutcomeValues.completed,
        ),
      ];
      expect(FailedSetAdjuster.consecutiveFailedStreakFromNewest(entries), 1);
    });
  });
}
