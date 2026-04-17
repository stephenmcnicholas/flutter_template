import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/session_check_in_repository.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/presentation/program/mid_programme_check_in_screen.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/presentation/logger/post_workout_mood_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/presentation/workout/workout_completion_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  GoogleFonts.config.allowRuntimeFetching = false;

  final summary = WorkoutCompletionSummary(
    workoutName: 'Test Workout',
    exercisesCompleted: 3,
    totalSets: 9,
    totalReps: 72,
    totalVolume: 3600,
    duration: const Duration(minutes: 45),
  );

  Widget createTestWidget([PostWorkoutMoodArgs? args]) {
    final a = args ?? PostWorkoutMoodArgs(summary: summary, sessionId: 's1');
    final db = AppDatabase.test();
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
      ],
      child: MaterialApp(
        theme: FytterTheme.light,
        home: PostWorkoutMoodScreen(args: a),
      ),
    );
  }

  group('PostWorkoutMoodScreen', () {
    testWidgets('shows title and Skip button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('How was it?'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('shows subtitle and three mood options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.text('Quick tap — helps us tailor your experience next time.'),
        findsOneWidget,
      );
      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Tough'), findsOneWidget);
    });

    testWidgets('Skip and Strong, OK, Tough buttons are present', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Strong'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
      expect(find.text('Tough'), findsOneWidget);
      expect(
        find.textContaining('Optional note'),
        findsOneWidget,
      );
    });

    testWidgets('Strong saves check-in and navigates to completion', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.test();
      final router = GoRouter(
        initialLocation: '/mood',
        routes: [
          GoRoute(
            path: '/mood',
            builder: (context, state) => PostWorkoutMoodScreen(
              args: PostWorkoutMoodArgs(summary: summary, sessionId: 'sess-a'),
            ),
          ),
          GoRoute(
            path: '/workout/completion',
            builder: (context, state) => const Scaffold(
              body: Text('completion-screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp.router(
            theme: FytterTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Strong'));
      await tester.pumpAndSettle();

      expect(find.text('completion-screen'), findsOneWidget);
      final repo = SessionCheckInRepository(db);
      final saved = await repo.getBySession('sess-a');
      expect(saved, hasLength(1));
      expect(saved.single.checkInType, CheckInType.postSession);
      expect(saved.single.rating, CheckInRating.great);
    });

    testWidgets('OK saves okay rating', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.test();
      final router = GoRouter(
        initialLocation: '/mood',
        routes: [
          GoRoute(
            path: '/mood',
            builder: (context, state) => PostWorkoutMoodScreen(
              args: PostWorkoutMoodArgs(summary: summary, sessionId: 'sess-ok'),
            ),
          ),
          GoRoute(
            path: '/workout/completion',
            builder: (context, state) => const Scaffold(body: Text('completion-screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp.router(theme: FytterTheme.light, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final repo = SessionCheckInRepository(db);
      final saved = await repo.getBySession('sess-ok');
      expect(saved.single.rating, CheckInRating.okay);
    });

    testWidgets('Tough saves tough rating', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.test();
      final router = GoRouter(
        initialLocation: '/mood',
        routes: [
          GoRoute(
            path: '/mood',
            builder: (context, state) => PostWorkoutMoodScreen(
              args: PostWorkoutMoodArgs(summary: summary, sessionId: 'sess-t'),
            ),
          ),
          GoRoute(
            path: '/workout/completion',
            builder: (context, state) => const Scaffold(body: Text('completion-screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp.router(theme: FytterTheme.light, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tough'));
      await tester.pumpAndSettle();

      final repo = SessionCheckInRepository(db);
      final saved = await repo.getBySession('sess-t');
      expect(saved.single.rating, CheckInRating.tough);
    });

    testWidgets('Skip with programme 6th session opens mid check-in then completion', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final db = AppDatabase.test();
      final router = GoRouter(
        initialLocation: '/mood',
        routes: [
          GoRoute(
            path: '/mood',
            builder: (context, state) => PostWorkoutMoodScreen(
              args: PostWorkoutMoodArgs(
                summary: summary,
                sessionId: 'sess-b',
                programId: 'prog-mid',
                programCompletedSessionCount: 6,
              ),
            ),
          ),
          GoRoute(
            path: '/program/mid-check-in',
            builder: (context, state) => MidProgrammeCheckInScreen(
              args: state.extra! as MidProgrammeCheckInArgs,
            ),
          ),
          GoRoute(
            path: '/workout/completion',
            builder: (context, state) => const Scaffold(
              body: Text('completion-screen'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp.router(
            theme: FytterTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Programme check-in'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('completion-screen'), findsOneWidget);
    });
  });
}
