import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:fytter/src/presentation/app_router.dart';
import 'package:fytter/src/presentation/workout/workout_builder_screen.dart';
import 'package:fytter/src/presentation/program/program_builder_screen.dart';
import 'package:fytter/src/presentation/program/program_detail_screen.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_repository.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/program_repository.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeWorkoutRepository implements WorkoutRepository {
  @override
  Future<List<Workout>> findAll() async => [];
  @override
  Future<Workout> findById(String id) async => Workout(id: id, name: '', entries: []);
  @override
  Future<void> save(Workout workout) async {}
  @override
  Future<void> delete(String id) async {}
}

class _FakeProgramRepository implements ProgramRepository {
  @override
  Future<List<Program>> findAll() async => [];

  @override
  Future<Program> findById(String id) async =>
      Program(id: id, name: 'Program', schedule: const []);

  @override
  Future<void> save(Program program) async {}

  @override
  Future<void> delete(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  
  setUpAll(() {
    // Suppress Drift warning about multiple database instances in tests
    // Each test creates its own ProviderScope with isolated state
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('Navigating to /workouts/new loads WorkoutBuilderScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exercisesFutureProvider.overrideWith((_) async => [const Exercise(id: 'e1', name: 'Test', description: '')]),
          workoutRepositoryProvider.overrideWithValue(_FakeWorkoutRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: FytterTheme.light,
        ),
      ),
    );
    router.go('/workouts/new');
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutBuilderScreen), findsOneWidget);
  });

  testWidgets('Navigating to /workouts/edit/:id loads WorkoutBuilderScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exercisesFutureProvider.overrideWith((_) async => [const Exercise(id: 'e1', name: 'Test', description: '')]),
          workoutRepositoryProvider.overrideWithValue(_FakeWorkoutRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: FytterTheme.light,
        ),
      ),
    );
    router.go('/workouts/edit/w123');
    await tester.pumpAndSettle();
    expect(find.byType(WorkoutBuilderScreen), findsOneWidget);
  });

  testWidgets('Navigating to /programs/new loads WorkoutBuilderScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exercisesFutureProvider.overrideWith((_) async => [const Exercise(id: 'e1', name: 'Test', description: '')]),
          workoutRepositoryProvider.overrideWithValue(_FakeWorkoutRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: FytterTheme.light,
        ),
      ),
    );
    router.go('/programs/new');
    await tester.pumpAndSettle();
    expect(find.byType(ProgramBuilderScreen), findsOneWidget);
  });

  testWidgets('Navigating to /programs/edit/:id loads ProgramBuilderScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exercisesFutureProvider.overrideWith((_) async => [const Exercise(id: 'e1', name: 'Test', description: '')]),
          workoutRepositoryProvider.overrideWithValue(_FakeWorkoutRepository()),
          programRepositoryProvider.overrideWithValue(_FakeProgramRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: FytterTheme.light,
        ),
      ),
    );
    router.go('/programs/edit/w123');
    await tester.pumpAndSettle();
    expect(find.byType(ProgramBuilderScreen), findsOneWidget);
  });

  testWidgets('Navigating to /programs/:id loads ProgramDetailScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exercisesFutureProvider.overrideWith((_) async => []),
          programsFutureProvider.overrideWith((_) async => []),
          programByIdProvider.overrideWith((ref, id) async => const Program(id: 'p1', name: 'Test', schedule: [])),
          workoutTemplatesFutureProvider.overrideWith((_) async => []),
          programRepositoryProvider.overrideWithValue(_FakeProgramRepository()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: FytterTheme.light,
        ),
      ),
    );
    router.go('/programs/p1');
    await tester.pumpAndSettle();
    expect(find.byType(ProgramDetailScreen), findsOneWidget);
  });

  testWidgets('Navigating to /exercise/new loads ExerciseEditScreen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exercisesFutureProvider.overrideWith((_) async => []),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: FytterTheme.light,
        ),
      ),
    );
    router.go('/exercise/new');
    await tester.pumpAndSettle();
    // ExerciseEditScreen should be present
    expect(find.text('New Exercise'), findsOneWidget);
  });
} 