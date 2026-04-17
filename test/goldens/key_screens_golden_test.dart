@Tags(['golden'])
library key_screens_golden_test;

import 'package:drift/drift.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/presentation/exercise/exercise_list_screen.dart';
import 'package:fytter/src/presentation/history/history_list_screen.dart';
import 'package:fytter/src/presentation/program/program_list_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  GoogleFonts.config.allowRuntimeFetching = false;

  setUpAll(() async {
    final fontLoader = FontLoader('Roboto');
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
        Directory(Platform.resolvedExecutable)
            .parent
            .parent
            .parent
            .parent
            .path;
    final candidates = [
      '$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      '$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
    ];
    File? fontFile;
    for (final path in candidates) {
      final candidate = File(path);
      if (candidate.existsSync()) {
        fontFile = candidate;
        break;
      }
    }
    if (fontFile == null) {
      throw Exception('Unable to locate Roboto font in Flutter SDK.');
    }
    final bytes = await fontFile.readAsBytes();
    fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await fontLoader.load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'notifications_enabled': false,
      'notifications_reminder_time_minutes': 8 * 60,
    });
    SharedPrefs.instance.resetForTests();
  });

  final goldenTheme = FytterTheme.light.copyWith(
    textTheme: FytterTheme.light.textTheme.apply(fontFamily: 'Roboto'),
    primaryTextTheme:
        FytterTheme.light.primaryTextTheme.apply(fontFamily: 'Roboto'),
  );

  Future<void> pumpForGolden(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(child);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('Exercise list empty state', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });
    final db = AppDatabase.test();
    await pumpForGolden(
      tester,
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          exercisesFutureProvider.overrideWith((_) async => <Exercise>[]),
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
          theme: goldenTheme,
          home: const Scaffold(
            body: ExerciseListScreen(onStartWorkout: _noopStartWorkout),
          ),
        ),
      ),
    );

    expect(find.text('No exercises yet'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/exercise_list_empty.png'),
    );
  });

  testWidgets('Workout history empty state', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });
    final db = AppDatabase.test();
    await pumpForGolden(
      tester,
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          workoutSessionsProvider.overrideWith((_) async => <WorkoutSession>[]),
          exercisesFutureProvider.overrideWith((_) async => <Exercise>[]),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          workoutTemplatesFutureProvider.overrideWith((_) async => const []),
          workoutSessionFilterTextProvider.overrideWith((_) => ''),
          workoutSessionBodyPartFilterProvider.overrideWith((_) => []),
          workoutSessionEquipmentFilterProvider.overrideWith((_) => []),
          workoutSessionSortOrderProvider.overrideWith((_) => WorkoutSessionSortOrder.dateNewest),
          workoutSessionDateFilterProvider.overrideWith((_) => null),
        ],
        child: MaterialApp(
          theme: goldenTheme,
          home: const Scaffold(
            body: HistoryListScreen(),
          ),
        ),
      ),
    );

    expect(find.text('No workouts yet'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/history_list_empty.png'),
    );
  });

  testWidgets('Program list empty state', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });
    final db = AppDatabase.test();
    await pumpForGolden(
      tester,
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => db),
          programsFutureProvider.overrideWith((_) async => <Program>[]),
          programDateFilterProvider.overrideWith((_) => null),
        ],
        child: MaterialApp(
          theme: goldenTheme,
          home: const Scaffold(
            body: ProgramListScreen(),
          ),
        ),
      ),
    );

    expect(find.text('No programs yet'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/program_list_empty.png'),
    );
  });
}

void _noopStartWorkout(String _) {}
