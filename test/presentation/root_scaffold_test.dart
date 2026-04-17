import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/root_scaffold.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:fytter/src/providers/login_prompt_provider.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../test_utils/fake_auth_repository.dart';
import '../test_utils/fake_login_prompt_notifier.dart';
import 'package:fytter/src/domain/auth_user.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fytter/src/providers/logger_sheet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> pumpForUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> pumpRootScaffold(
    WidgetTester tester, {
    AuthUser? authUser,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          if (authUser != null)
            authUserProvider.overrideWith((ref) => Stream.value(authUser)),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          // Main tab async providers
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const RootScaffold(),
        ),
      ),
    );

    await pumpForUi(tester);
  }
  testWidgets('RootScaffold shows correct screen for each tab and responds to navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          // Progress tab providers
          workoutFrequencyProvider.overrideWith((ref) => Future.value(WorkoutFrequency(workoutsPerDay: {}, totalWorkouts: 0, averageWorkoutsPerWeek: 0.0))),
          programStatsProvider.overrideWith((ref) => Future.value(ProgramStats(totalPrograms: 0, completedPrograms: 0, completionRate: 0.0, programCompletionStats: []))),
          // Main tab async providers
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const RootScaffold(),
        ),
      ),
    );

    await pumpForUi(tester); // Let the widget tree build and futures resolve

    // Tab 0: Exercises (ModernAppBar title + bottom nav label)
    expect(find.text('Exercises'), findsAtLeastNWidgets(1));

    // Tap 'Workouts' tab (index 1)
    await tester.tap(find.text('Workouts'));
    await pumpForUi(tester);
    expect(find.text('Workouts'), findsAtLeastNWidgets(1));

    // Tap 'Programs' tab (index 2)
    await tester.tap(find.text('Programs'));
    await pumpForUi(tester);
    expect(find.text('Programs'), findsAtLeastNWidgets(1));
    expect(find.text('List'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);

    // Tap 'Progress' tab (index 3)
    await tester.tap(find.text('Progress'));
    await pumpForUi(tester);
    expect(find.text('Workout Frequency'), findsOneWidget);
    expect(find.text('Program Stats'), findsOneWidget);

    // Tap 'More' tab (index 4) and check for MoreMenu modal
    await tester.tap(find.text('More'));
    await pumpForUi(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('Quickstart Workout FAB opens WorkoutLoggerSheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: RootScaffold(),
        ),
      ),
    );

    await pumpForUi(tester);
    // Tap 'Workouts' tab
    await tester.tap(find.text('Workouts'));
    await pumpForUi(tester);
    // Open Actions FAB (SpeedDial)
    await tester.tap(find.byType(SpeedDial));
    await pumpForUi(tester);
    // Tap Quickstart Workout -> empty quickstart skips check-in and opens logger directly
    await tester.tap(find.text('Quickstart Workout'));
    await pumpForUi(tester);
    // Logger sheet should now be visible (Quick Start may appear in sheet and elsewhere)
    expect(find.text('Quick Start'), findsAtLeastNWidgets(1));
    expect(find.text('End Workout'), findsOneWidget);
  });

  testWidgets('Avatar shows initials from display name', (tester) async {
    await pumpRootScaffold(
      tester,
      authUser: const AuthUser(
        uid: '1',
        email: 'sam@example.com',
        displayName: 'Sam McNicholas',
        isEmailVerified: true,
        photoUrl: '',
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    final text = avatar.child as Text;
    expect(text.data, 'SM');
  });

  testWidgets('Avatar shows email initial when no display name', (tester) async {
    await pumpRootScaffold(
      tester,
      authUser: const AuthUser(
        uid: '2',
        email: 'alex@example.com',
        displayName: null,
        isEmailVerified: true,
        photoUrl: '',
      ),
    );

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    final text = avatar.child as Text;
    expect(text.data, 'A');
  });

  testWidgets('Login prompt navigates to sign-in when accepted',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'loginPromptDismissed': false});
    SharedPrefs.instance.resetForTests();

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const RootScaffold(),
        ),
        GoRoute(
          path: '/auth/login',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Login Screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          authUserProvider.overrideWith((ref) => Stream.value(null)),
          loginPromptProvider.overrideWith((ref) => LoginPromptNotifier()),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: router,
        ),
      ),
    );

    await pumpForUi(tester);
    expect(find.text('Sign in to back up your data'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await pumpForUi(tester);

    expect(find.text('Login Screen'), findsOneWidget);
  });

  testWidgets('Programs FAB navigates to new program screen',
      (WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const RootScaffold(),
        ),
        GoRoute(
          path: '/programs/new',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('New Program')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: router,
        ),
      ),
    );

    await pumpForUi(tester);
    await tester.tap(find.text('Programs'));
    await pumpForUi(tester);

    await tester.tap(find.byType(SpeedDial));
    await pumpForUi(tester);
    await tester.tap(find.text('Create Program'));
    await pumpForUi(tester);

    expect(find.text('New Program'), findsOneWidget);
  });

  testWidgets('Programs tab clears selection on tab tap',
      (WidgetTester tester) async {
    await pumpRootScaffold(tester);

    await tester.tap(find.text('Programs'));
    await pumpForUi(tester);

    await tester.tap(find.text('Calendar'));
    await pumpForUi(tester);

    expect(find.text('Calendar'), findsOneWidget);
  });

  testWidgets('Minimized logger sheet renders overlay banner',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();

    final loggerNotifier = LoggerSheetNotifier();
    loggerNotifier.state = const LoggerSheetState(
      visible: true,
      minimized: true,
      workoutName: 'Leg Day',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          loggerSheetProvider.overrideWith((ref) => loggerNotifier),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const RootScaffold(),
        ),
      ),
    );

    await pumpForUi(tester);
    expect(find.text('Workout in progress: Leg Day'), findsOneWidget);
  });

  testWidgets('Minimized logger sheet tap maximizes',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();

    final loggerNotifier = LoggerSheetNotifier();
    loggerNotifier.state = const LoggerSheetState(
      visible: true,
      minimized: true,
      workoutName: 'Leg Day',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          loggerSheetProvider.overrideWith((ref) => loggerNotifier),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const RootScaffold(),
        ),
      ),
    );

    await pumpForUi(tester);
    await tester.tap(find.text('Workout in progress: Leg Day'));
    await pumpForUi(tester);

    expect(loggerNotifier.state.minimized, isFalse);
  });

  testWidgets('Minimized logger sheet close hides logger',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();

    final loggerNotifier = LoggerSheetNotifier();
    loggerNotifier.state = const LoggerSheetState(
      visible: true,
      minimized: true,
      workoutName: 'Leg Day',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          loggerSheetProvider.overrideWith((ref) => loggerNotifier),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: const RootScaffold(),
        ),
      ),
    );

    await pumpForUi(tester);
    await tester.tap(find.byIcon(Icons.close));
    await pumpForUi(tester);

    expect(loggerNotifier.state.visible, isFalse);
  });

  testWidgets('Avatar tap navigates to Profile screen',
      (WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const RootScaffold(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Profile Screen')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          authUserProvider.overrideWith(
            (ref) => Stream.value(const AuthUser(
              uid: '1',
              email: 'stephen@example.com',
              displayName: 'Stephen McNicholas',
              isEmailVerified: true,
              photoUrl: '',
            )),
          ),
          loginPromptProvider.overrideWith((ref) => FakeLoginPromptNotifier()),
          appDatabaseProvider.overrideWith((ref) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith(
            (ref) => _TestExerciseFavoritesNotifier(ref.read(appDatabaseProvider)),
          ),
          exerciseFavoriteFilterProvider.overrideWith((ref) => false),
          exercisesFutureProvider.overrideWith((ref) async => []),
          exerciseMusclesMapProvider.overrideWith((ref) async => <String, List<String>>{}),
          workoutSessionsProvider.overrideWith((ref) async => []),
          workoutTemplatesFutureProvider.overrideWith((ref) async => []),
          programsFutureProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: router,
        ),
      ),
    );

    await pumpForUi(tester);
    await tester.tap(find.byType(CircleAvatar));
    await pumpForUi(tester);

    expect(find.text('Profile Screen'), findsOneWidget);
  });
} 

class _TestExerciseFavoritesNotifier extends ExerciseFavoritesNotifier {
  _TestExerciseFavoritesNotifier(super.db) {
    state = const AsyncValue.data(<String>{});
  }
}