import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_repository.dart';
import 'package:fytter/src/presentation/exercise/exercise_edit_screen.dart';

void main() {
  testWidgets('ExerciseEditScreen shows form fields and Save button disabled', (tester) async {
    // 1. Pump the edit screen with no existing exercise (i.e. new)
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ExerciseEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Expect two TextFields (name and description)
    expect(find.byType(TextField), findsNWidgets(2));

    // 3. Save button exists but is disabled initially
    final saveBtn = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(saveBtn.enabled, isFalse);

    // 4. Image controls exist
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('Add image'), findsOneWidget);
  });

  testWidgets('ExerciseEditScreen can be created with exerciseId', (tester) async {
    // Test that the screen can be instantiated with an exercise ID
    // The actual loading and display of media is tested in integration tests
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ExerciseEditScreen(exerciseId: 'e1'),
        ),
      ),
    );

    await tester.pump();

    // Screen should be present
    expect(find.byType(ExerciseEditScreen), findsOneWidget);
    // TextFields should be present
    expect(find.byType(TextField), findsNWidgets(2));
  });
}

// Simple mock repository for testing
class MockExerciseRepository implements ExerciseRepository {
  final Exercise exercise;
  MockExerciseRepository(this.exercise);
  
  @override
  Future<Exercise> findById(String id) async => exercise;
  
  @override
  Future<List<Exercise>> findAll() async => [exercise];
  
  @override
  Future<void> save(Exercise e) async {}
  
  @override
  Future<void> delete(String id) async {}
}