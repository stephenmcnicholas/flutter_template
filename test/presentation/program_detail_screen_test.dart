import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/program_repository.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/presentation/program/program_detail_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ProgramDetailScreen shows scheduled workouts list', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final program = Program(
      id: 'p1',
      name: 'Test Program',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: today),
      ],
    );
    final templates = [
      const Workout(id: 'w1', name: 'Leg Day', entries: []),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programByIdProvider.overrideWith((ref, id) async => program),
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
          workoutSessionsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgramDetailScreen(programId: 'p1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test Program'), findsOneWidget);
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.byIcon(Icons.event), findsOneWidget);
    expect(find.text('Planned'), findsOneWidget);
  });

  testWidgets('ProgramDetailScreen shows actions on workout tap', (tester) async {
    final program = Program(
      id: 'p1',
      name: 'Test Program',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2099, 1, 20)),
      ],
    );
    final templates = [
      const Workout(id: 'w1', name: 'Leg Day', entries: []),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programByIdProvider.overrideWith((ref, id) async => program),
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
          workoutSessionsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgramDetailScreen(programId: 'p1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Leg Day'));
    await tester.pumpAndSettle();

    expect(find.text('Edit date'), findsOneWidget);
    expect(find.text('Remove from program'), findsOneWidget);
    expect(find.text('Start workout'), findsNothing);
  });

  testWidgets('ProgramDetailScreen starts workout and returns to root', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final program = Program(
      id: 'p1',
      name: 'Test Program',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: today),
      ],
    );
    final templates = [
      const Workout(id: 'w1', name: 'Leg Day', entries: []),
    ];

    final container = ProviderContainer(
      overrides: [
        programByIdProvider.overrideWith((ref, id) async => program),
        workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
        workoutSessionsProvider.overrideWith((ref) async => []),
        exercisesFutureProvider.overrideWith((ref) async => []),
      ],
    );

    late final GoRouter router;
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
          routes: [
            GoRoute(
              path: 'programs/:id',
              builder: (context, state) =>
                  ProgramDetailScreen(programId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: FytterTheme.light,
        ),
      ),
    );
    router.push('/programs/p1');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leg Day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    expect(container.read(selectedTabIndexProvider), 2);
  });

  testWidgets('ProgramDetailScreen remove deletes only one duplicate scheduled workout', (tester) async {
    final duplicateDate = DateTime(2099, 1, 20);
    final program = Program(
      id: 'p1',
      name: 'Test Program',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: duplicateDate),
        ProgramWorkout(workoutId: 'w1', scheduledDate: duplicateDate),
      ],
    );
    final templates = [
      const Workout(id: 'w1', name: 'Leg Day', entries: []),
    ];
    final repo = _CapturingProgramRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programByIdProvider.overrideWith((ref, id) async => program),
          programRepositoryProvider.overrideWithValue(repo),
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
          workoutSessionsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const ProgramDetailScreen(programId: 'p1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Leg Day').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from program'));
    await tester.pumpAndSettle();

    expect(repo.savedPrograms, hasLength(1));
    expect(repo.savedPrograms.single.schedule, hasLength(1));
    expect(repo.savedPrograms.single.schedule.first.workoutId, 'w1');
    expect(repo.savedPrograms.single.schedule.first.scheduledDate, duplicateDate);
  });
}

class _CapturingProgramRepository implements ProgramRepository {
  final List<Program> savedPrograms = [];

  @override
  Future<void> delete(String id) async {}

  @override
  Future<List<Program>> findAll() async => const [];

  @override
  Future<Program> findById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<void> save(Program program) async {
    savedPrograms.add(program);
  }
}
