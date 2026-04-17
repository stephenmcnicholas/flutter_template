import 'package:flutter/material.dart';
import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_repository.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/presentation/workout/workout_builder_screen.dart';
import 'package:fytter/src/presentation/exercise/exercise_selection_screen.dart';
import 'package:fytter/src/presentation/shared/exercise_card.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  
  Future<void> pumpForUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }
  // Helper function to create router with both WorkoutBuilderScreen and ExerciseSelectionScreen routes
  GoRouter createTestRouter({String? initialPath, WorkoutBuilderScreen? builderScreen}) {
    return GoRouter(
      initialLocation: initialPath ?? '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => builderScreen ?? const WorkoutBuilderScreen(),
        ),
        GoRoute(
          path: '/exercises/select',
          builder: (context, state) {
            final alreadySelected = state.queryParameters['alreadySelected'];
            final List<String> alreadySelectedIds = alreadySelected != null
                ? (Uri.decodeComponent(alreadySelected).split(','))
                : [];
            return ExerciseSelectionScreen(alreadySelectedIds: alreadySelectedIds);
          },
        ),
      ],
    );
  }

  // Helper function to create provider overrides for tests
  List<Override> createProviderOverrides(List<Exercise> exercises) {
    final db = AppDatabase.test();
    return [
      appDatabaseProvider.overrideWith((_) => db),
      exerciseFavoritesProvider.overrideWith((ref) => ExerciseFavoritesNotifier(db)),
      exercisesFutureProvider.overrideWith((_) async => exercises),
      exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
      exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
      exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
      exerciseFavoriteFilterProvider.overrideWith((_) => false),
    ];
  }

  testWidgets('WorkoutBuilderScreen shows name field and exercise list', (tester) async {
    final dummyExercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench', description: ''),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: createProviderOverrides(dummyExercises),
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: createTestRouter(),
        ),
      ),
    );
    await pumpForUi(tester);
    // Name field should be visible
    expect(find.byType(TextField), findsOneWidget);
    // No exercises selected initially, but the "Add Exercise" button should be present
    expect(find.text('Add Exercise'), findsOneWidget);
    final saveBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save'));
    expect(saveBtn.enabled, isFalse);
  });

  testWidgets('Save button enables only after name + one exercise selected', (tester) async {
    final dummyExercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench', description: ''),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: createProviderOverrides(dummyExercises),
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: createTestRouter(),
        ),
      ),
    );
    await pumpForUi(tester);
    var saveBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save'));
    expect(saveBtn.enabled, isFalse);
    await tester.enterText(find.byKey(const Key('workoutName')), 'MyWorkout');
    await tester.pump();
    saveBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save'));
    expect(saveBtn.enabled, isFalse);

    // Open exercise picker (navigates to ExerciseSelectionScreen)
    await tester.tap(find.text('Add Exercise'));
    await pumpForUi(tester);

    // Verify we're on the ExerciseSelectionScreen
    expect(find.byType(ExerciseSelectionScreen), findsOneWidget);
    expect(find.text('Add Exercises'), findsOneWidget);

    // Select the first exercise by tapping its AppCard
    final squatCard = find.ancestor(
      of: find.text('Squat'),
      matching: find.byType(AppCard),
    );
    await tester.tap(squatCard.first);
    await pumpForUi(tester);

    // Verify selection count updated
    expect(find.text('1 selected'), findsOneWidget);
    expect(find.text('Add (1)'), findsOneWidget);

    // Confirm selection by tapping the "Add" button
    final addButton = find.ancestor(
      of: find.text('Add (1)'),
      matching: find.byType(TextButton),
    );
    await tester.tap(addButton);
    await pumpForUi(tester);

    // Now we should be back on WorkoutBuilderScreen
    // The save button should be enabled (name + at least one exercise)
    saveBtn = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Save'));
    expect(saveBtn.enabled, isTrue);
  });

  testWidgets('WorkoutBuilderScreen shows loading indicator while exercises load', (tester) async {
    final completer = Completer<List<Exercise>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => AppDatabase.test()),
          exerciseFavoritesProvider
              .overrideWith((ref) => ExerciseFavoritesNotifier(ref.read(appDatabaseProvider))),
          exercisesFutureProvider.overrideWith((_) => completer.future),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: createTestRouter(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('WorkoutBuilderScreen shows error message when exercises load fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => AppDatabase.test()),
          exerciseFavoritesProvider
              .overrideWith((ref) => ExerciseFavoritesNotifier(ref.read(appDatabaseProvider))),
          exercisesFutureProvider.overrideWith((_) async => throw Exception('oops')),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: createTestRouter(),
        ),
      ),
    );
    await pumpForUi(tester);
    expect(find.textContaining('Error:'), findsOneWidget);
  });

  testWidgets('WorkoutBuilderScreen in edit mode pre-fills fields and updates workout', (tester) async {
    final dummyExercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench', description: ''),
    ];
    final dummyWorkout = Workout(
      id: 'w1',
      name: 'EditMe',
      entries: [
        WorkoutEntry(id: 'we1', exerciseId: 'e1', reps: 5, weight: 50, isComplete: false, timestamp: null, sessionId: null),
      ],
    );
    final mockRepo = _MockWorkoutRepository(workouts: [dummyWorkout]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...createProviderOverrides(dummyExercises),
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: createTestRouter(
            builderScreen: WorkoutBuilderScreen(workoutId: 'w1'),
          ),
        ),
      ),
    );
    await pumpForUi(tester);
    final nameField = find.byKey(const Key('workoutName'));
    expect(nameField, findsOneWidget);
    expect((tester.widget(nameField) as TextField).controller?.text ?? '', 'EditMe');
    // Existing workout should have its first exercise displayed with at least one set
    expect(find.text('Squat'), findsOneWidget);
    expect(find.byType(SetEditor), findsWidgets);
    await tester.enterText(nameField, 'UpdatedName');
    await tester.pump();
    final saveBtn = find.widgetWithText(ElevatedButton, 'Save');
    expect(tester.widget<ElevatedButton>(saveBtn).enabled, isTrue);
    await tester.tap(saveBtn);
    await pumpForUi(tester);
    expect(mockRepo.savedWorkouts.last.name, 'UpdatedName');
  });

  testWidgets('WorkoutBuilderScreen in edit mode renders superset group card', (tester) async {
    final dummyExercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench', description: ''),
    ];
    const groupId = 'group-123';
    final dummyWorkout = Workout(
      id: 'w1',
      name: 'Superset Workout',
      entries: [
        WorkoutEntry(
          id: 'we1', exerciseId: 'e1', reps: 5, weight: 50,
          isComplete: false, timestamp: null, sessionId: null,
          supersetGroupId: groupId,
        ),
        WorkoutEntry(
          id: 'we2', exerciseId: 'e2', reps: 8, weight: 60,
          isComplete: false, timestamp: null, sessionId: null,
          supersetGroupId: groupId,
        ),
      ],
    );
    final mockRepo = _MockWorkoutRepository(workouts: [dummyWorkout]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...createProviderOverrides(dummyExercises),
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: createTestRouter(
            builderScreen: const WorkoutBuilderScreen(workoutId: 'w1'),
          ),
        ),
      ),
    );
    await pumpForUi(tester);
    // Group card header should show SUPERSET label
    expect(find.text('SUPERSET'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Bench'), findsOneWidget);
    expect(find.text('+ Add exercise to superset'), findsOneWidget);
  });

  testWidgets('Superset button appears in builder header', (tester) async {
    final exercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench', description: ''),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: createProviderOverrides(exercises),
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: createTestRouter(),
        ),
      ),
    );
    await pumpForUi(tester);
    expect(find.text('Superset'), findsOneWidget);
    expect(find.text('Add Exercise'), findsOneWidget);
  });

  testWidgets('ExerciseSelectionScreen confirm button disabled when fewer than minRequired selected',
      (tester) async {
    final exercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench', description: ''),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: createProviderOverrides(exercises),
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => const ExerciseSelectionScreen(
                  minRequired: 2,
                  actionLabel: 'Add Superset',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await pumpForUi(tester);
    // Button label shows 0 selected
    final btn = find.text('Add Superset (0)');
    expect(btn, findsOneWidget);
    // Tap one exercise — still disabled (need 2)
    await tester.tap(find.text('Squat'));
    await tester.pump();
    expect(find.text('Add Superset (1)'), findsOneWidget);
    // Confirm is still disabled — tapping doesn't pop
    final actionBtn = find.ancestor(
      of: find.text('Add Superset (1)'),
      matching: find.byType(TextButton),
    );
    final widget = tester.widget<TextButton>(actionBtn);
    expect(widget.onPressed, equals(null));
  });

  testWidgets('Add Set in builder copies values from the last existing set instead of using defaults',
      (tester) async {
    // An exercise already has one set with custom values (15 reps, 40 kg).
    // Tapping "Add Set" should produce a second set with the same values,
    // not the system defaults (5 reps / 50 kg).
    final exercises = [const Exercise(id: 'e1', name: 'Squat', description: '')];
    final existingWorkout = Workout(
      id: 'w1',
      name: 'My Workout',
      entries: [
        WorkoutEntry(
          id: 'we1',
          exerciseId: 'e1',
          reps: 15,
          weight: 40.0,
          isComplete: false,
          timestamp: null,
          sessionId: null,
        ),
      ],
    );
    final mockRepo = _MockWorkoutRepository(workouts: [existingWorkout]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...createProviderOverrides(exercises),
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: createTestRouter(
            builderScreen: const WorkoutBuilderScreen(workoutId: 'w1'),
          ),
        ),
      ),
    );
    await pumpForUi(tester);

    // Confirm one set is shown initially.
    expect(find.byType(SetEditor), findsOneWidget);

    await tester.tap(find.text('Add Set'));
    await pumpForUi(tester);

    // Two sets should now be visible.
    expect(find.byType(SetEditor), findsNWidgets(2));

    // Save and inspect the persisted entries.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await pumpForUi(tester);

    expect(mockRepo.savedWorkouts, hasLength(1));
    final saved = mockRepo.savedWorkouts.last;
    expect(saved.entries, hasLength(2));
    expect(saved.entries[1].reps, 15);
    expect(saved.entries[1].weight, 40.0);
  });
}

class _MockWorkoutRepository implements WorkoutRepository {
  final List<Workout> workouts;
  final List<Workout> savedWorkouts = [];
  _MockWorkoutRepository({required this.workouts});
  @override
  Future<List<Workout>> findAll() async => workouts;
  @override
  Future<Workout> findById(String id) async =>
      workouts.firstWhere((w) => w.id == id);
  @override
  Future<void> save(Workout workout) async => savedWorkouts.add(workout);
  @override
  Future<void> delete(String id) async {}
}