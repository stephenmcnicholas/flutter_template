import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/workout_adjustment_service.dart';

void main() {
  group('WorkoutAdjustmentService.mergeAdjustedSets', () {
    test('merges server weights and preserves set ids from original', () {
      final original = {
        'ex1': [
          {'id': 's1', 'weight': 100.0, 'reps': 5, 'isComplete': true},
          {'id': 's2', 'weight': 100.0, 'reps': 5, 'isComplete': false},
        ],
      };
      final server = {
        'ex1': [
          {'weight': 90.0, 'reps': 5},
          {'weight': 90.0, 'reps': 4},
        ],
      };

      final merged = WorkoutAdjustmentService.mergeAdjustedSets(original, server);

      expect(merged['ex1']!.length, 2);
      expect(merged['ex1']![0]['id'], 's1');
      expect(merged['ex1']![0]['weight'], 90.0);
      expect(merged['ex1']![0]['isComplete'], false);
      expect(merged['ex1']![1]['id'], 's2');
      expect(merged['ex1']![1]['reps'], 4);
    });

    test('throws when server omits an exercise', () {
      final original = {
        'a': [
          {'weight': 1.0, 'reps': 1},
        ],
        'b': [
          {'weight': 2.0, 'reps': 2},
        ],
      };
      expect(
        () => WorkoutAdjustmentService.mergeAdjustedSets(original, {
          'a': [
            {'weight': 1.0},
          ],
        }),
        throwsA(isA<WorkoutAdjustmentException>()),
      );
    });

    test('throws when setsByExercise is not a Map', () {
      final original = {
        'a': [
          {'weight': 1.0, 'reps': 1},
        ],
      };
      expect(
        () => WorkoutAdjustmentService.mergeAdjustedSets(original, 'bad'),
        throwsA(isA<WorkoutAdjustmentException>()),
      );
    });

    test('extends rows from last original set when server returns more sets', () {
      final original = {
        'ex1': [
          {'id': 'only', 'weight': 50.0, 'reps': 10, 'isComplete': true},
        ],
      };
      final server = {
        'ex1': [
          {'weight': 48.0},
          {'weight': 46.0, 'reps': 9},
        ],
      };
      final merged = WorkoutAdjustmentService.mergeAdjustedSets(original, server);
      expect(merged['ex1']!.length, 2);
      expect(merged['ex1']![0]['id'], 'only');
      expect(merged['ex1']![1]['id'], 'only');
      expect(merged['ex1']![1]['weight'], 46.0);
      expect(merged['ex1']![1]['reps'], 9);
      expect(merged['ex1']![1]['isComplete'], false);
    });

    test('applies distance and duration from server patch', () {
      final original = {
        'c': [
          {
            'id': 'r1',
            'weight': 0.0,
            'reps': 0,
            'distance': 1.0,
            'duration': 60,
            'isComplete': false,
          },
        ],
      };
      final server = {
        'c': [
          {'distance': 2.5, 'duration': 90},
        ],
      };
      final merged = WorkoutAdjustmentService.mergeAdjustedSets(original, server);
      expect(merged['c']![0]['distance'], 2.5);
      expect(merged['c']![0]['duration'], 90);
    });

    test('throws when a server row is not a Map', () {
      final original = {
        'x': [
          {'weight': 1.0, 'reps': 1},
        ],
      };
      expect(
        () => WorkoutAdjustmentService.mergeAdjustedSets(original, {
          'x': [1],
        }),
        throwsA(isA<WorkoutAdjustmentException>()),
      );
    });
  });
}
