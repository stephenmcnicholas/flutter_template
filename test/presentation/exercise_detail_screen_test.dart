import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/exercise/exercise_detail_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  group('ExerciseDetailScreen', () {
    const testExerciseId = 'test-exercise-1';

    final testExercise = Exercise(
      id: testExerciseId,
      name: 'Bench Press',
      description: 'Chest exercise',
      bodyPart: 'Chest',
      equipment: 'Barbell',
      loggingType: ExerciseInputType.repsAndWeight,
    );

    final testSession = WorkoutSession(
      id: 'session1',
      workoutId: 'w1',
      date: DateTime(2024, 5, 20, 8, 0),
      name: 'Push Day',
      entries: [
        WorkoutEntry(
          id: 'e1',
          exerciseId: testExerciseId,
          reps: 5,
          weight: 100.0,
          isComplete: true,
          timestamp: DateTime(2024, 5, 20, 8, 0),
        ),
        WorkoutEntry(
          id: 'e2',
          exerciseId: testExerciseId,
          reps: 5,
          weight: 100.0,
          isComplete: true,
          timestamp: DateTime(2024, 5, 20, 8, 0),
        ),
      ],
    );

    final testHistory = [
      ExerciseWorkoutHistory(
        session: testSession,
        entries: testSession.entries,
      ),
    ];

    testWidgets('shows loading indicator while loading', (tester) async {
      final exerciseCompleter = Completer<Exercise?>();
      final historyCompleter = Completer<List<ExerciseWorkoutHistory>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) => exerciseCompleter.future),
            exerciseHistoryProvider.overrideWith((ref, id) => historyCompleter.future),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: testExerciseId),
          ),
        ),
      );

      expect(find.byType(AppLoadingState), findsOneWidget);
    });

    testWidgets('shows error message on error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) => throw Exception('fail')),
            exerciseHistoryProvider.overrideWith((ref, id) => throw Exception('fail')),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: testExerciseId),
          ),
        ),
      );

      await tester.pumpAndSettle();
      // When exercise provider throws, it shows "Error: $err" not "Exercise not found"
      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('displays exercise history with repsAndWeight format', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) async => testExercise),
            exerciseHistoryProvider.overrideWith((ref, id) async => testHistory),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: testExerciseId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to History tab
      // Switch to History tab
      await tester.tap(find.text('History'));
      await tester.pump(); // Allow tab animation
      await tester.pumpAndSettle();

      // Verify we're on the History tab
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Push Day'), findsOneWidget);
      expect(find.text('Sets Performed'), findsOneWidget);
      
      // The text is split: "Set 1: " in one AppText, "5 reps @ 100.0 kg" in another
      // Weight is a double (100.0), so it displays as "100.0" not "100"
      expect(find.text('Set 1: '), findsOneWidget);
      expect(find.text('5 reps @ 100.0 kg'), findsNWidgets(2)); // Should appear twice (for both sets)
      expect(find.text('Set 2: '), findsOneWidget);
    });

    testWidgets('displays exercise history with repsOnly format', (tester) async {
      final repsOnlyExercise = Exercise(
        id: 'burpees',
        name: 'Burpees',
        description: 'Bodyweight exercise',
        bodyPart: 'Full Body',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.repsOnly,
      );

      final repsOnlySession = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Workout',
        entries: [
          WorkoutEntry(
            id: 'e1',
            exerciseId: 'burpees',
            reps: 10,
            weight: 0.0,
            isComplete: true,
            timestamp: DateTime(2024, 5, 20, 8, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) async => repsOnlyExercise),
            exerciseHistoryProvider.overrideWith((ref, id) async => [
              ExerciseWorkoutHistory(
                session: repsOnlySession,
                entries: repsOnlySession.entries,
              ),
            ]),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: 'burpees'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Text is split across multiple AppText widgets
      expect(find.textContaining('Set 1:'), findsOneWidget);
      expect(find.textContaining('10 reps'), findsOneWidget);
      expect(find.textContaining('kg'), findsNothing); // Should not show weight
    });

    testWidgets('displays exercise history with distanceAndTime format', (tester) async {
      final runningExercise = Exercise(
        id: 'running',
        name: 'Running',
        description: 'Cardio',
        bodyPart: 'Cardio',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.distanceAndTime,
      );

      final runningSession = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Workout',
        entries: [
          WorkoutEntry(
            id: 'e1',
            exerciseId: 'running',
            reps: 0,
            weight: 0.0,
            distance: 5.0,
            duration: 1800,
            isComplete: true,
            timestamp: DateTime(2024, 5, 20, 8, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) async => runningExercise),
            exerciseHistoryProvider.overrideWith((ref, id) async => [
              ExerciseWorkoutHistory(
                session: runningSession,
                entries: runningSession.entries,
              ),
            ]),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: 'running'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.textContaining('5.0 km'), findsOneWidget);
      expect(find.textContaining('30:00'), findsOneWidget);
      expect(find.textContaining('reps'), findsNothing); // Should not show reps
      expect(find.textContaining('kg'), findsNothing); // Should not show weight
    });

    testWidgets('displays exercise history with timeOnly format', (tester) async {
      final plankExercise = Exercise(
        id: 'plank',
        name: 'Plank',
        description: 'Isometric hold',
        bodyPart: 'Core',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.timeOnly,
      );

      final plankSession = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Workout',
        entries: [
          WorkoutEntry(
            id: 'e1',
            exerciseId: 'plank',
            reps: 0,
            weight: 0.0,
            duration: 60,
            isComplete: true,
            timestamp: DateTime(2024, 5, 20, 8, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) async => plankExercise),
            exerciseHistoryProvider.overrideWith((ref, id) async => [
              ExerciseWorkoutHistory(
                session: plankSession,
                entries: plankSession.entries,
              ),
            ]),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: 'plank'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Text is split across multiple AppText widgets
      expect(find.textContaining('Set 1:'), findsOneWidget);
      expect(find.textContaining('1:00'), findsOneWidget);
      expect(find.textContaining('reps'), findsNothing); // Should not show reps
      expect(find.textContaining('kg'), findsNothing); // Should not show weight
      expect(find.textContaining('km'), findsNothing); // Should not show distance
    });

    testWidgets('shows 1RM only for repsAndWeight exercises', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) async => testExercise),
            exerciseHistoryProvider.overrideWith((ref, id) async => testHistory),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: testExerciseId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // 1RM should be calculated for 100kg × 5 reps = 117.0 kg
      expect(find.textContaining('1RM: 117.0 kg'), findsNWidgets(2));
    });

    testWidgets('does not show 1RM for non-repsAndWeight exercises', (tester) async {
      final repsOnlyExercise = Exercise(
        id: 'burpees',
        name: 'Burpees',
        description: 'Bodyweight exercise',
        bodyPart: 'Full Body',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.repsOnly,
      );

      final repsOnlySession = WorkoutSession(
        id: 'session1',
        workoutId: 'w1',
        date: DateTime(2024, 5, 20, 8, 0),
        name: 'Workout',
        entries: [
          WorkoutEntry(
            id: 'e1',
            exerciseId: 'burpees',
            reps: 10,
            weight: 0.0,
            isComplete: true,
            timestamp: DateTime(2024, 5, 20, 8, 0),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) async => repsOnlyExercise),
            exerciseHistoryProvider.overrideWith((ref, id) async => [
              ExerciseWorkoutHistory(
                session: repsOnlySession,
                entries: repsOnlySession.entries,
              ),
            ]),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: 'burpees'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.textContaining('1RM'), findsNothing);
    });

    testWidgets('shows empty state when no history', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseProgressProvider.overrideWith((ref) async => []),
            exerciseByIdProvider.overrideWith((ref, id) async => testExercise),
            exerciseHistoryProvider.overrideWith((ref, id) async => []),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: const ExerciseDetailScreen(exerciseId: testExerciseId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('No workout history for this exercise'), findsOneWidget);
    });
  });
}
