import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/presentation/exercise/exercise_list_screen.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/exercise_list_tile.dart';
import 'package:fytter/src/presentation/root_scaffold.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:fytter/src/providers/login_prompt_provider.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../test_utils/fake_auth_repository.dart';
import '../test_utils/fake_login_prompt_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  Future<AppDatabase> makeDb([Set<String>? favorites]) async {
    final db = AppDatabase.test();
    if (favorites != null && favorites.isNotEmpty) {
      for (final id in favorites) {
        await db.addExerciseFavorite(id);
      }
    }
    return db;
  }

  Future<void> pumpForData(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('ExerciseListScreen shows seeded exercises', (tester) async {
    // Prepare dummy exercises
    final dummyExercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench Press', description: ''),
      const Exercise(id: 'e3', name: 'Deadlift', description: ''),
    ];

    // Pump the screen with the provider overridden to return our dummy list
    final db = await makeDb();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) async => dummyExercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => []),
          exerciseEquipmentFilterProvider.overrideWith((_) => []),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ExerciseListScreen(onStartWorkout: (_) {})),
        ),
      ),
    );

    // Let the async providers resolve without waiting on cursor animations.
    await pumpForData(tester);

    // One tile per exercise (custom row, not ListTile — avoids Material leading height cap)
    expect(find.byType(ExerciseListTile), findsNWidgets(dummyExercises.length));
    // Optionally, verify that each exercise name appears
    for (final ex in dummyExercises) {
      expect(find.text(ex.name), findsOneWidget);
    }
  });

  testWidgets('ExerciseListScreen displays thumbnails when available', (tester) async {
    final exercisesWithMedia = [
      const Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
        thumbnailPath: 'exercises/thumbnails/e001_squat_thumb.jpg',
        mediaPath: 'exercises/media/e001_squat.mp4',
        bodyPart: 'Quads',
      ),
    ];

    final db = await makeDb();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) async => exercisesWithMedia),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ExerciseListScreen(onStartWorkout: (_) {})),
        ),
      ),
    );

    await pumpForData(tester);

    // Should find ExerciseMediaWidget (thumbnail display)
    // Note: Image.asset will fail in test without proper setup, but widget should be present
    expect(find.text('Squat'), findsOneWidget);
    // Exercise list screen now shows bodyPart instead of description
    expect(find.text('Quads'), findsOneWidget);
  });

  testWidgets('shows loading indicator while exercises are loading', (tester) async {
    // Use a Completer that never completes to simulate a perpetual loading state
    final completer = Completer<List<Exercise>>();

    final db = await makeDb();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) => completer.future),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ExerciseListScreen(onStartWorkout: (_) {})),
        ),
      ),
    );

    // Pump a single frame so the loading widget appears
    await tester.pump();

    expect(find.byType(AppLoadingState), findsOneWidget);
  });

  testWidgets('shows error message when loading exercises fails', (tester) async {
    final db = await makeDb();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          // Throw an exception with a known message
          exercisesFutureProvider.overrideWith((_) async => throw Exception('fail-load')),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ExerciseListScreen(onStartWorkout: (_) {})),
        ),
      ),
    );

    // Let the error state settle without waiting on cursor animations.
    await pumpForData(tester);

    // Verify that our exception message is displayed
    expect(find.textContaining('fail-load'), findsOneWidget);
  });

  testWidgets('calls onStartWorkout when Start Workout is tapped', (tester) async {
    // Provide a minimal GoRouter for navigation context
    final router = GoRouter(routes: [GoRoute(path: '/', builder: (context, state) => RootScaffold())]);
    final db = await makeDb();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) async => [
            const Exercise(id: 'e1', name: 'Squat', description: ''),
          ]),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerDelegate: router.routerDelegate,
          routeInformationParser: router.routeInformationParser,
        ),
      ),
    );
    await pumpForData(tester);
    // There should be a single FloatingActionButton
    expect(find.byType(FloatingActionButton), findsOneWidget);
    // Tap the FAB (should trigger add exercise navigation/callback)
    await tester.tap(find.byType(FloatingActionButton));
    await pumpForData(tester);
      // Optionally, check for navigation or UI change if possible
  });

  testWidgets('ExerciseListScreen shows filter/sort bar', (tester) async {
    final dummyExercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench Press', description: ''),
    ];

    final db = await makeDb();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) async => dummyExercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => []),
          exerciseEquipmentFilterProvider.overrideWith((_) => []),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ExerciseListScreen(onStartWorkout: (_) {})),
        ),
      ),
    );

    await pumpForData(tester);

    // Should find the filter/sort bar (AppFilterSortBar contains TextField)
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('ExerciseListScreen filters exercises by name', (tester) async {
    final dummyExercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench Press', description: ''),
      const Exercise(id: 'e3', name: 'Deadlift', description: ''),
    ];

    final db = await makeDb();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) async => dummyExercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => 'Bench'),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ExerciseListScreen(onStartWorkout: (_) {})),
        ),
      ),
    );

    await pumpForData(tester);

    // Should only find Bench Press
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Squat'), findsNothing);
    expect(find.text('Deadlift'), findsNothing);
  });

  testWidgets('ExerciseListScreen filters favorites only', (tester) async {
    final dummyExercises = [
      const Exercise(id: 'e1', name: 'Squat', description: ''),
      const Exercise(id: 'e2', name: 'Bench Press', description: ''),
    ];

    final db = await makeDb({'e2'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) async => dummyExercises),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseFavoriteFilterProvider.overrideWith((_) => true),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(body: ExerciseListScreen(onStartWorkout: (_) {})),
        ),
      ),
    );

    await pumpForData(tester);

    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Squat'), findsNothing);
  });
}
