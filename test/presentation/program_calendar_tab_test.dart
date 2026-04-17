import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/presentation/program/program_calendar_tab.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:google_fonts/google_fonts.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('ProgramCalendarTab shows calendar when program exists for today', (tester) async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final program = Program(
      id: 'p1',
      name: 'Strength block',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: today),
      ],
    );
    const templates = [
      Workout(id: 'w1', name: 'Full body', entries: []),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) async => [program]),
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
          workoutSessionsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(
            body: ProgramCalendarTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Strength block'), findsWidgets);
    expect(find.text('Full body'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w.runtimeType.toString().startsWith('TableCalendar'),
      ),
      findsWidgets,
    );
  });

  testWidgets('ProgramCalendarTab empty state when no programs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith(
            (ref) async => const <Workout>[],
          ),
          workoutSessionsProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(
            body: ProgramCalendarTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No programs yet'), findsOneWidget);
  });

  testWidgets('shows user-friendly message when sessions fail to load', (tester) async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final program = Program(
      id: 'p1',
      name: 'Strength block',
      schedule: [ProgramWorkout(workoutId: 'w1', scheduledDate: today)],
    );
    const templates = [Workout(id: 'w1', name: 'Full body', entries: [])];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) async => [program]),
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
          workoutSessionsProvider.overrideWith(
            (ref) async => throw Exception('DB error'),
          ),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(body: ProgramCalendarTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    expect(find.textContaining('Exception:'), findsNothing);
  });

  testWidgets("bottom sheet shows 'Start workout' for today's planned workout", (tester) async {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final program = Program(
      id: 'p1',
      name: 'Strength block',
      schedule: [ProgramWorkout(workoutId: 'w1', scheduledDate: today)],
    );
    const templates = [Workout(id: 'w1', name: 'Full body', entries: [])];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) async => [program]),
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
          workoutSessionsProvider.overrideWith((ref) async => []),
          exercisesFutureProvider.overrideWith((ref) async => []),
          lastRecordedValuesProvider('w1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(body: ProgramCalendarTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Full body').first);
    await tester.pumpAndSettle();

    expect(find.text('Start workout'), findsOneWidget);
    expect(find.text('View workout'), findsOneWidget);
    expect(find.text('Edit date'), findsOneWidget);
    expect(find.text('Remove from program'), findsOneWidget);
  });

  testWidgets("bottom sheet shows 'View workout' but not 'Start workout' for a future workout", (tester) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final futureDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final program = Program(
      id: 'p1',
      name: 'Strength block',
      schedule: [ProgramWorkout(workoutId: 'w1', scheduledDate: futureDate)],
    );
    const templates = [Workout(id: 'w1', name: 'Full body', entries: [])];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          programsFutureProvider.overrideWith((ref) async => [program]),
          workoutTemplatesFutureProvider.overrideWith((ref) async => templates),
          workoutSessionsProvider.overrideWith((ref) async => []),
          exercisesFutureProvider.overrideWith((ref) async => []),
          lastRecordedValuesProvider('w1').overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const Scaffold(body: ProgramCalendarTab()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to tomorrow on the calendar
    await tester.tap(find.text('${futureDate.day}').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Full body').first);
    await tester.pumpAndSettle();

    expect(find.text('Start workout'), findsNothing);
    expect(find.text('View workout'), findsOneWidget);
  });
}
