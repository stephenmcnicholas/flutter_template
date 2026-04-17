import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/workout_entry.dart';

void main() {
  group('showWorkoutNameDialog', () {
    testWidgets('returns entered name', (WidgetTester tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showWorkoutNameDialog(context, initial: 'Test');
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'My Workout');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(result, 'My Workout');
    });

    testWidgets('returns null when cancelled', (WidgetTester tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showWorkoutNameDialog(context);
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('getExercisesForEntries', () {
    test('returns exercises in order matching entries', () {
      final exercises = [
        const Exercise(id: 'e1', name: 'Exercise 1', description: ''),
        const Exercise(id: 'e2', name: 'Exercise 2', description: ''),
        const Exercise(id: 'e3', name: 'Exercise 3', description: ''),
      ];

      final entries = [
        WorkoutEntry(id: 'entry1', exerciseId: 'e2', reps: 10, weight: 100, isComplete: false),
        WorkoutEntry(id: 'entry2', exerciseId: 'e1', reps: 8, weight: 80, isComplete: false),
        WorkoutEntry(id: 'entry3', exerciseId: 'e3', reps: 12, weight: 60, isComplete: false),
      ];

      final result = getExercisesForEntries(entries, exercises);
      expect(result, hasLength(3));
      expect(result[0].id, 'e2');
      expect(result[1].id, 'e1');
      expect(result[2].id, 'e3');
    });

    test('filters out entries with non-existent exercise IDs', () {
      final exercises = [
        const Exercise(id: 'e1', name: 'Exercise 1', description: ''),
      ];

      final entries = [
        WorkoutEntry(id: 'entry1', exerciseId: 'e1', reps: 10, weight: 100, isComplete: false),
        WorkoutEntry(id: 'entry2', exerciseId: 'e999', reps: 8, weight: 80, isComplete: false), // Doesn't exist
        WorkoutEntry(id: 'entry3', exerciseId: 'e1', reps: 12, weight: 60, isComplete: false),
      ];

      final result = getExercisesForEntries(entries, exercises);
      expect(result, hasLength(2));
      expect(result[0].id, 'e1');
      expect(result[1].id, 'e1');
    });
  });

  group('showSetInputBottomSheet', () {
    testWidgets('returns reps and weight when saved', (WidgetTester tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showSetInputBottomSheet(
                context,
                initialReps: 5,
                initialWeight: 100.0,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      
      // Enter values (first field is reps, second is weight)
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.first, '8');
      await tester.enterText(textFields.last, '120');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      expect(result, isNotNull);
      expect(result!['reps'], 8);
      expect(result!['weight'], 120.0);
    });

    testWidgets('returns null when cancelled', (WidgetTester tester) async {
      Map<String, dynamic>? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showSetInputBottomSheet(context);
            },
            child: const Text('Open'),
          ),
        ),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

} 