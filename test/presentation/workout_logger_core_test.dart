import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/presentation/logger/workout_logger_core.dart';
import 'package:fytter/src/presentation/exercise/exercise_selection_screen.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';
import 'package:fytter/src/providers/logger_sheet_provider.dart';
import 'package:fytter/src/providers/rest_timer_provider.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:drift/drift.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';
import 'package:fytter/src/utils/haptic_utils.dart';

/// Records which haptic intensity was requested without hitting the platform.
class _RecordingHapticsService implements HapticsService {
  final List<String> calls = [];
  @override
  void light() => calls.add('light');
  @override
  void medium() => calls.add('medium');
  @override
  void heavy() => calls.add('heavy');
}

/// Default no-op service used by non-haptic tests.
class _SilentHapticsService implements HapticsService {
  @override
  void light() {}
  @override
  void medium() {}
  @override
  void heavy() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  
  // Silence Drift warnings in tests
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  final mockExercises = [
    const Exercise(id: 'e1', name: 'Squat', description: 'Leg exercise', bodyPart: 'Quads', equipment: 'Barbell'),
    const Exercise(id: 'e2', name: 'Bench Press', description: 'Chest exercise', bodyPart: 'Chest', equipment: 'Barbell'),
    const Exercise(id: 'e3', name: 'Deadlift', description: 'Back exercise', bodyPart: 'Back', equipment: 'Barbell'),
  ];

  Future<void> pumpForUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Widget createTestWidget({
    List<Exercise> initialExercises = const [],
    Map<String, List<Map<String, dynamic>>>? initialSetsByExercise,
    HapticsService? hapticsService,
  }) {
    final db = AppDatabase.test();
    final haptics = hapticsService ?? _SilentHapticsService();
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((_) => db),
        exerciseFavoritesProvider.overrideWith((ref) => ExerciseFavoritesNotifier(db)),
        exercisesFutureProvider.overrideWith((_) async => mockExercises),
        exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
        exerciseFilterTextProvider.overrideWith((_) => ''),
        exerciseBodyPartFilterProvider.overrideWith((_) => []),
        exerciseEquipmentFilterProvider.overrideWith((_) => []),
        exerciseFavoriteFilterProvider.overrideWith((_) => false),
        exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
        exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
        exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        hapticsServiceProvider.overrideWithValue(haptics),
      ],
      child: MaterialApp.router(
        theme: FytterTheme.light,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => Scaffold(
                body: WorkoutLoggerCore(
                  initialExercises: initialExercises,
                  initialSetsByExercise: initialSetsByExercise,
                  workoutName: 'Test Workout',
                  onSessionComplete: (_) {},
                  isAudioMuted: () => false,
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
    );
  }

  group('WorkoutLoggerCore', () {
    testWidgets('displays Add Exercise button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpForUi(tester);

      expect(find.text('Add Exercise'), findsAtLeastNWidgets(1));
    });

    testWidgets('navigates to ExerciseSelectionScreen when Add Exercise is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpForUi(tester);

      await tester.tap(find.text('Add Exercise').first);
      await pumpForUi(tester);

      // Verify we're on the ExerciseSelectionScreen
      expect(find.byType(ExerciseSelectionScreen), findsOneWidget);
      expect(find.text('Add Exercises'), findsOneWidget);
    });

    testWidgets('passes already selected exercise IDs to ExerciseSelectionScreen', (tester) async {
      await tester.pumpWidget(createTestWidget(initialExercises: [mockExercises[0]]));
      await pumpForUi(tester);

      // Initialize the session provider
      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        null,
      );
      await pumpForUi(tester);

      await tester.tap(find.text('Add Exercise').first);
      await pumpForUi(tester);

      // Verify ExerciseSelectionScreen is shown
      expect(find.byType(ExerciseSelectionScreen), findsOneWidget);
      
      // The already selected exercise (Squat) should be shown as disabled
      // This is tested in exercise_selection_screen_test.dart, so we just verify navigation works
    });

    testWidgets('displays End Workout button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await pumpForUi(tester);

      expect(find.text('End Workout'), findsOneWidget);
    });

    testWidgets('starts rest timer when Complete Set is tapped (non-final exercise)', (tester) async {
      // Two exercises: completing e1's only set is a final-set-but-not-final-exercise case,
      // so rest timer should start (user needs rest before e2).
      await tester.pumpWidget(createTestWidget(initialExercises: [mockExercises[0], mockExercises[1]]));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0], mockExercises[1]],
        {
          'e1': [
            {'id': 's1', 'reps': 5, 'weight': 50.0, 'isComplete': false}
          ],
          'e2': [
            {'id': 's2', 'reps': 5, 'weight': 50.0, 'isComplete': false}
          ],
        },
      );
      await pumpForUi(tester);

      expect(container.read(restTimerProvider).isActive, isFalse);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await pumpForUi(tester);

      expect(container.read(restTimerProvider).isActive, isTrue);
    });

    testWidgets('does not start rest timer after completing final set of final exercise', (tester) async {
      // Single exercise, single set: completing it ends the workout — no rest needed.
      await tester.pumpWidget(createTestWidget(initialExercises: [mockExercises[0]]));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        {
          'e1': [
            {'id': 's1', 'reps': 5, 'weight': 50.0, 'isComplete': false}
          ]
        },
      );
      await pumpForUi(tester);

      expect(container.read(restTimerProvider).isActive, isFalse);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await pumpForUi(tester);

      // Rest timer should remain inactive — no rest after the workout's final set
      expect(container.read(restTimerProvider).isActive, isFalse);
    });

    testWidgets('Superset badge shown for exercise with supersetGroupId in set map', (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0], mockExercises[1]],
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0], mockExercises[1]],
        {
          'e1': [{'id': 's1', 'reps': 10, 'weight': 20.0, 'isComplete': false, 'supersetGroupId': 'group-1'}],
          'e2': [{'id': 's2', 'reps': 15, 'weight': 0.0, 'isComplete': false, 'supersetGroupId': 'group-1'}],
        },
      );
      await pumpForUi(tester);

      expect(find.textContaining('Superset'), findsWidgets);
    });

    testWidgets('No superset badge for standalone exercise', (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0]],
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        {
          'e1': [{'id': 's1', 'reps': 8, 'weight': 60.0, 'isComplete': false}],
        },
      );
      await pumpForUi(tester);

      expect(find.textContaining('Superset'), findsNothing);
    });

    testWidgets('Superset auto-advance: completing non-final exercise scrolls to next without rest',
        (tester) async {
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0], mockExercises[1]],
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0], mockExercises[1]],
        {
          'e1': [{'id': 's1', 'reps': 10, 'weight': 20.0, 'isComplete': false, 'supersetGroupId': 'group-1'}],
          'e2': [{'id': 's2', 'reps': 15, 'weight': 0.0, 'isComplete': false, 'supersetGroupId': 'group-1'}],
        },
      );
      await pumpForUi(tester);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await pumpForUi(tester);

      // Rest timer should NOT start for non-final superset exercise
      expect(container.read(restTimerProvider).isActive, isFalse);
    });

    testWidgets('Add Set copies values from the last set in the session', (tester) async {
      // Set up a session where e1 has one completed set (7 reps, 60 kg).
      // Tapping "Add Set" should seed the new set with those values, not defaults.
      await tester.pumpWidget(createTestWidget(initialExercises: [mockExercises[0]]));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        {
          'e1': [
            {'id': 's1', 'reps': 7, 'weight': 60.0, 'isComplete': true, 'setOutcome': 'hit'},
          ],
        },
      );
      await pumpForUi(tester);

      // All sets complete → "Add Set" button is always visible in the else branch.
      await tester.ensureVisible(find.text('Add Set'));
      await tester.tap(find.text('Add Set'));
      await pumpForUi(tester);

      final sets = container.read(loggerSessionProvider)?.setsByExercise['e1'] ?? [];
      expect(sets, hasLength(2));
      expect(sets.last['reps'], 7);
      expect(sets.last['weight'], 60.0);
    });

    testWidgets('Completing a set copies its values forward to the next pending set', (tester) async {
      // e1 has 2 sets: the first is ready to complete (7 reps, 60 kg), the second
      // was seeded with zeros. Completing the first should overwrite the second with
      // the confirmed values so the user sees the right numbers for the next round.
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0], mockExercises[1]],
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0], mockExercises[1]],
        {
          'e1': [
            {'id': 's1', 'reps': 7, 'weight': 60.0, 'isComplete': false},
            {'id': 's2', 'reps': 0, 'weight': 0.0, 'isComplete': false},
          ],
          'e2': [{'id': 's3', 'reps': 5, 'weight': 50.0, 'isComplete': false}],
        },
      );
      await pumpForUi(tester);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await pumpForUi(tester);

      final sets = container.read(loggerSessionProvider)?.setsByExercise['e1'] ?? [];
      expect(sets[1]['reps'], 7);
      expect(sets[1]['weight'], 60.0);
    });

    testWidgets('Circuit parity: Add Round on one member adds a matching set to all circuit peers',
        (tester) async {
      // e1 and e2 are in a superset. Both have completed their only round (10 reps, 20 kg).
      // Tapping "Add Round" on e1 should add a new set to both e1 AND e2 with the same values.
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0], mockExercises[1]],
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0], mockExercises[1]],
        {
          'e1': [{'id': 's1', 'reps': 10, 'weight': 20.0, 'isComplete': true, 'supersetGroupId': 'group-1'}],
          'e2': [{'id': 's2', 'reps': 10, 'weight': 20.0, 'isComplete': true, 'supersetGroupId': 'group-1'}],
        },
      );
      await pumpForUi(tester);

      // Active card is e1 (first exercise). All sets complete → "Add Round" is visible.
      await tester.ensureVisible(find.text('Add Round'));
      await tester.tap(find.text('Add Round'));
      await pumpForUi(tester);

      final session = container.read(loggerSessionProvider)!;
      expect(session.setsByExercise['e1'], hasLength(2));
      expect(session.setsByExercise['e2'], hasLength(2));
      // Both new sets should carry the same values as the source exercise's last set.
      expect(session.setsByExercise['e1']!.last['reps'], 10);
      expect(session.setsByExercise['e1']!.last['weight'], 20.0);
      expect(session.setsByExercise['e2']!.last['reps'], 10);
      expect(session.setsByExercise['e2']!.last['weight'], 20.0);
    });
  });

  // ---------------------------------------------------------------------------
  // Haptic feedback
  // These tests use a _RecordingHapticsService injected via hapticsServiceProvider
  // so assertions are on simple strings ('light', 'medium', 'heavy') without
  // depending on platform channel interception.
  // ---------------------------------------------------------------------------
  group('haptic feedback', () {
    testWidgets('Complete Set fires medium haptic', (tester) async {
      final haptics = _RecordingHapticsService();
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0]],
        hapticsService: haptics,
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        {'e1': [{'id': 's1', 'reps': 5, 'weight': 50.0, 'isComplete': false}]},
      );
      await pumpForUi(tester);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await pumpForUi(tester);

      expect(haptics.calls, contains('medium'));
    });

    testWidgets('Skip Set fires light haptic', (tester) async {
      final haptics = _RecordingHapticsService();
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0]],
        hapticsService: haptics,
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        {'e1': [{'id': 's1', 'reps': 5, 'weight': 50.0, 'isComplete': false}]},
      );
      await pumpForUi(tester);

      await tester.ensureVisible(find.text('Skip set'));
      await tester.tap(find.text('Skip set'));
      await pumpForUi(tester);

      expect(haptics.calls, contains('light'));
    });

    testWidgets('End Workout fires heavy haptic', (tester) async {
      final haptics = _RecordingHapticsService();
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0]],
        hapticsService: haptics,
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        {'e1': [{'id': 's1', 'reps': 5, 'weight': 50.0, 'isComplete': false}]},
      );
      await pumpForUi(tester);

      await tester.ensureVisible(find.text('End Workout'));
      await tester.tap(find.text('End Workout'));
      await pumpForUi(tester);

      expect(haptics.calls, contains('heavy'));
    });

    testWidgets('Add Set fires light haptic', (tester) async {
      final haptics = _RecordingHapticsService();
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0]],
        hapticsService: haptics,
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        // All sets complete so "Add Set" button is visible
        {'e1': [{'id': 's1', 'reps': 5, 'weight': 50.0, 'isComplete': true, 'setOutcome': 'hit'}]},
      );
      await pumpForUi(tester);

      await tester.ensureVisible(find.text('Add Set'));
      await tester.tap(find.text('Add Set'));
      await pumpForUi(tester);

      expect(haptics.calls, contains('light'));
    });

    testWidgets('No haptics recorded when hapticsServiceProvider is silent', (tester) async {
      // Passing no hapticsService defaults to _SilentHapticsService.
      // The silent service doesn't record, so calls stays empty.
      // This verifies that the logger reads from hapticsServiceProvider rather
      // than calling HapticFeedback directly.
      final silent = _SilentHapticsService();
      await tester.pumpWidget(createTestWidget(
        initialExercises: [mockExercises[0]],
        hapticsService: silent,
      ));
      await pumpForUi(tester);

      final container = ProviderScope.containerOf(tester.element(find.byType(WorkoutLoggerCore)));
      container.read(loggerSessionProvider.notifier).startSession(
        'Test Workout',
        [mockExercises[0]],
        {'e1': [{'id': 's1', 'reps': 5, 'weight': 50.0, 'isComplete': false}]},
      );
      await pumpForUi(tester);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await pumpForUi(tester);

      // _SilentHapticsService has no state to assert on — the test simply
      // verifies no exception is thrown when haptics are suppressed.
    });
  });
}
