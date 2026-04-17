import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/presentation/logger/pre_workout_check_in_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  GoogleFonts.config.allowRuntimeFetching = false;

  const args = PreWorkoutCheckInArgs(
    workoutName: 'Test Workout',
    workoutId: 'w1',
    initialExercises: [],
    initialSetsByExercise: null,
  );

  Widget createTestWidget() {
    final db = AppDatabase.test();
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => db),
      ],
      child: MaterialApp(
        theme: FytterTheme.light,
        home: PreWorkoutCheckInScreen(args: args),
      ),
    );
  }

  group('PreWorkoutCheckInScreen', () {
    testWidgets('shows title and Skip button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('How are you feeling?'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('shows three check-in options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text("Let's go"), findsOneWidget);
      expect(find.text('Fine'), findsOneWidget);
      expect(find.text('Some concerns'), findsOneWidget);
    });

    testWidgets('Skip pops with args', (tester) async {
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push<PreWorkoutCheckInArgs>(
                      MaterialPageRoute(
                        builder: (_) => PreWorkoutCheckInScreen(args: args),
                      ),
                    );
                    // Push returns when check-in pops; we stay on home route
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('tapping Fine immediately proceeds without showing text field', (tester) async {
      PreWorkoutCheckInArgs? poppedResult;
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<PreWorkoutCheckInArgs>(
                      MaterialPageRoute(
                        builder: (_) => PreWorkoutCheckInScreen(args: args),
                      ),
                    );
                    poppedResult = result;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fine'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Amber tapped → should pop immediately; no TextField visible
      expect(poppedResult, isNotNull);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('tap Let\'s go proceeds and pops with args', (tester) async {
      PreWorkoutCheckInArgs? poppedResult;
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWith((ref) => db)],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<PreWorkoutCheckInArgs>(
                      MaterialPageRoute(
                        builder: (_) => PreWorkoutCheckInScreen(args: args),
                      ),
                    );
                    poppedResult = result;
                    // Push returns when check-in pops
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(poppedResult != null, isTrue);
      expect(poppedResult!.workoutName, 'Test Workout');
    });

    testWidgets('red path shows text field for premium users', (tester) async {
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            workoutAdaptationPremiumProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: PreWorkoutCheckInScreen(args: args),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Some concerns'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Continue anyway'), findsNothing);
    });

    testWidgets('red path shows upsell for free users (no text field)', (tester) async {
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            workoutAdaptationPremiumProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: PreWorkoutCheckInScreen(args: args),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Some concerns'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Continue anyway'), findsOneWidget);
      // Both the subtitle and the red expand show 'premium' for free users
      expect(find.textContaining('premium'), findsAtLeastNWidgets(1));
    });

    testWidgets('free user on red sees body-copy upsell, not old caption', (tester) async {
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            workoutAdaptationPremiumProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: PreWorkoutCheckInScreen(args: args),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Some concerns'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining("we'll adjust today's session"),
        findsOneWidget,
      );
      expect(
        find.textContaining('Intelligent session adjustments are available'),
        findsNothing,
      );
    });

    testWidgets('free user can still proceed on red path without text', (tester) async {
      PreWorkoutCheckInArgs? poppedResult;
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            workoutAdaptationPremiumProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<PreWorkoutCheckInArgs>(
                      MaterialPageRoute(
                        builder: (_) => PreWorkoutCheckInScreen(args: args),
                      ),
                    );
                    poppedResult = result;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Some concerns'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue anyway'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(poppedResult, isNotNull);
    });

    testWidgets('free user sees upsell subtitle, not tailor copy', (tester) async {
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            workoutAdaptationPremiumProvider.overrideWith((ref) => false),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: PreWorkoutCheckInScreen(args: args),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('premium'), findsOneWidget);
      expect(find.textContaining('tailor'), findsNothing);
    });

    testWidgets('premium user sees adaptive tailor copy, not upsell', (tester) async {
      final db = AppDatabase.test();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWith((ref) => db),
            workoutAdaptationPremiumProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            theme: FytterTheme.light,
            home: PreWorkoutCheckInScreen(args: args),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('tailor'), findsOneWidget);
      expect(find.textContaining('Upgrade'), findsNothing);
    });
  });
}
