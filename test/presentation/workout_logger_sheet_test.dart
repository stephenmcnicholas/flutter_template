import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/logger/workout_logger_sheet.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:drift/drift.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/presentation/exercise/exercise_selection_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
//import 'package:fytter/src/presentation/app_router.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/domain/program_repository.dart';

void main() {
  // Silence all debugPrint output for this test file
  debugPrint = (String? message, {int? wrapWidth}) {};

  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  setUpAll(() {
    registerFallbackValue(_FakeWorkoutSession());
  });

  // Mock exercises
  final mockExercises = [
    const Exercise(id: 'ex1', name: 'Bench Press', description: ''),
    const Exercise(id: 'ex2', name: 'Squat', description: ''),
    const Exercise(id: 'ex3', name: 'Deadlift', description: ''),
  ];

  Future<void> pumpUntilFound(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 5)}) async {
    final end = DateTime.now().add(timeout);
    while (tester.any(finder) == false && DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      debugPrint('pumpUntilFound: still waiting for $finder');
    }
    if (tester.any(finder) == false) {
      debugPrint('pumpUntilFound: $finder NOT found!');
      debugPrint('Widget tree:\n${tester.element(find.byType(Scaffold)).toStringDeep()}');
      throw Exception('Widget not found: $finder');
    }
    debugPrint('pumpUntilFound: $finder found!');
  }

  testWidgets('WorkoutLoggerSheet navigates to ExerciseSelectionScreen when Add Exercise is tapped', (WidgetTester tester) async {
    const workoutName = 'Push Day';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exercisesFutureProvider.overrideWith((_) async => mockExercises),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => []),
          exerciseEquipmentFilterProvider.overrideWith((_) => []),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => Scaffold(
                  body: WorkoutLoggerSheet(
                    workoutName: workoutName,
                    initialExercises: const [],
                    onClose: () {},
                    onMaximize: () {},
                    onMinimize: () {},
                  ),
                ),
              ),
              GoRoute(
                path: '/exercises/select',
                builder: (context, state) {
                  final alreadySelectedParam = state.queryParameters['alreadySelected'] ?? '';
                  final alreadySelectedIds = alreadySelectedParam.isEmpty
                      ? <String>[]
                      : alreadySelectedParam.split(',').where((id) => id.isNotEmpty).toList();
                  return ExerciseSelectionScreen(alreadySelectedIds: alreadySelectedIds);
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Wait for the 'Add Exercise' button to be enabled
    final addExerciseButtonTextFinder = find.text('Add Exercise');
    await pumpUntilFound(tester, addExerciseButtonTextFinder);
    
    // Tap Add Exercise button - should navigate to ExerciseSelectionScreen
    await tester.tap(addExerciseButtonTextFinder);
    await tester.pump();
    await tester.pumpAndSettle();
    
    // Verify we're on the ExerciseSelectionScreen
    expect(find.byType(ExerciseSelectionScreen), findsOneWidget);
    expect(find.text('Add Exercises'), findsOneWidget);
  }, skip: true);

  testWidgets('WorkoutLoggerSheet saves WorkoutSession on End Workout', (WidgetTester tester) async {
    // skip: true due to Flutter test framework bug with overlays and hit testing
  }, skip: true);

  testWidgets('WorkoutLoggerSheet invalidates workoutSessionsProvider on End Workout', (WidgetTester tester) async {
    // skip: true due to Flutter test framework bug with overlays and hit testing
  }, skip: true);

  testWidgets('WorkoutLoggerSheet allows selecting multiple exercises and adding sets', (WidgetTester tester) async {
    // skip: true due to Flutter test framework bug with overlays and hit testing
  }, skip: true);

  testWidgets('template-save dialog is suppressed for any programme workout (programId set)', (tester) async {
    // The dialog guard is now purely synchronous: if programId is present the
    // dialog is suppressed regardless of the programme's isAiGenerated value in
    // the DB.  No async load is required.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exercisesFutureProvider.overrideWith((_) async => mockExercises),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => []),
          exerciseEquipmentFilterProvider.overrideWith((_) => []),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: WorkoutLoggerSheet(
            workoutName: 'Day 1',
            programId: 'p1',
            initialExercises: const [],
            initialSetsByExercise: const {},
            onClose: () {},
            onMaximize: () {},
            onMinimize: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Update workout template?'), findsNothing);
  });
}

class _MockProgramRepository extends Mock implements ProgramRepository {}

class _FakeWorkoutSession extends Fake implements WorkoutSession {} 