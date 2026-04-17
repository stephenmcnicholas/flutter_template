/// Tests that the right [AudioServiceInterface.playSequence] calls are dispatched
/// at the right workout events in [WorkoutLoggerCore] and [WorkoutLoggerSheet].
///
/// Strategy: override [audioServiceProvider] with [FakeAudioService], pump the
/// widget, simulate the event, pump again to drain async chains, then assert on
/// [FakeAudioService.dispatched].
///
/// Coverage:
///   T2 — first exercise setup cue (guided mode, dispatched from WorkoutLoggerSheet intro modal)
///   T4 — set complete (guided mode, non-final set)
///   T4 — set complete (guided mode, final / only set)
///   on-demand mode — set complete dispatches nothing to audio
///   T6 — coaching panel Good Form tap
///   T7 — coaching panel Fix 1 tap
///   T8 — coaching panel Fix 2 tap
library;

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_instructions.dart';
import 'package:fytter/src/presentation/logger/workout_logger_core.dart';
import 'package:fytter/src/presentation/logger/workout_logger_sheet.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/audio_coaching_settings_provider.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_favorites_provider.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/exercise_instructions_provider.dart';
import 'package:fytter/src/providers/exercise_muscles_provider.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/providers/logger_sheet_provider.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/services/audio/sentence_library.dart';
import 'package:fytter/src/utils/shared_prefs.dart';

import '../../support/fake_audio_service.dart';

// ---------------------------------------------------------------------------
// Shared stub data
// ---------------------------------------------------------------------------

final _exercises = [
  const Exercise(id: 'e1', name: 'Squat', description: 'Leg'),
  const Exercise(id: 'e2', name: 'Bench', description: 'Chest'),
];

// Minimal sentence library — just needs to resolve without throwing.
final _stubLib = SentenceLibrary.fromJson({
  's001': {'text': 'Stand tall.', 'variants': ['mid', 'final']},
  's002': {'text': 'Brace your core.', 'variants': ['mid', 'final']},
});

// Instructions with goodFormFeels (2 sentences) and two commonFixes.
final _stubInstructions = ExerciseInstructions.fromJson({
  'setup': {
    'sentences': ['s001', 's002'],
    'tiers': {
      'beginner': [0, 1],
      'intermediate': [0],
      'advanced': [0],
    },
  },
  'movement': {
    'sentences': ['s001'],
    'tiers': {
      'beginner': [0],
      'intermediate': [0],
      'advanced': [0],
    },
  },
  'breathingCue': {
    'sentences': ['s001'],
    'tiers': {
      'beginner': [0],
      'intermediate': [0],
      'advanced': [0],
    },
  },
  'goodFormFeels': {
    'sentences': ['s001', 's002'],
    'tiers': {
      'beginner': [0, 1],
      'intermediate': [0],
      'advanced': [0],
    },
  },
  'commonFixes': [
    {
      'issue': 's001',
      'fix': ['s002'],
      'tiers': {
        'beginner': {'issue': false, 'fix': [0]},
        'intermediate': {'issue': false, 'fix': [0]},
        'advanced': {'issue': false, 'fix': [0]},
      },
    },
    {
      'issue': 's001',
      'fix': ['s001', 's002'],
      'tiers': {
        'beginner': {'issue': false, 'fix': [0, 1]},
        'intermediate': {'issue': false, 'fix': [0]},
        'advanced': {'issue': false, 'fix': [0]},
      },
    },
  ],
});

// ---------------------------------------------------------------------------
// Widget factory
// ---------------------------------------------------------------------------

Widget _buildWidget({
  required FakeAudioService fakeAudio,
  AudioCoachingMode mode = AudioCoachingMode.guided,
  List<Exercise>? exercises,
}) {
  final db = AppDatabase.test();
  final exList = exercises ?? _exercises;

  return ProviderScope(
    overrides: [
      // ---- database ----
      appDatabaseProvider.overrideWith((_) => db),
      exerciseFavoritesProvider.overrideWith((ref) => ExerciseFavoritesNotifier(db)),

      // ---- exercise data ----
      exercisesFutureProvider.overrideWith((_) async => exList),
      exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
      exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
      exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),

      // ---- filter / sort ----
      exerciseFilterTextProvider.overrideWith((_) => ''),
      exerciseBodyPartFilterProvider.overrideWith((_) => []),
      exerciseEquipmentFilterProvider.overrideWith((_) => []),
      exerciseFavoriteFilterProvider.overrideWith((_) => false),
      exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),

      // ---- exercise instructions (avoids asset loading) ----
      exerciseInstructionsMapProvider.overrideWith(
        (_) async => {
          'e1': _stubInstructions,
          'e2': _stubInstructions,
        },
      ),

      // ---- sentence library (avoids asset loading) ----
      sentenceLibraryProvider.overrideWith((_) async => _stubLib),

      // ---- audio service → fake ----
      audioServiceProvider.overrideWithValue(fakeAudio),

      // ---- rest-end scheduler → null to avoid file I/O & notification OS calls ----
      restTimerAudioSchedulerProvider.overrideWithValue(null),

      // ---- audio coaching mode ----
      audioCoachingSettingsProvider.overrideWith(
        (_) => AudioCoachingSettingsNotifier()
          ..state = AudioCoachingSettingsState(
            mode: mode,
            isLoading: false,
          ),
      ),

      // ---- premium (always true so speaker icon shows and T4 fires) ----
      aiProgrammePremiumProvider.overrideWithValue(true),
    ],
    child: MaterialApp.router(
      theme: FytterTheme.light,
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
              body: WorkoutLoggerCore(
                initialExercises: exList,
                workoutName: 'Test',
                onSessionComplete: (_) {},
                testExercises: exList,
                isAudioMuted: () => false,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Pump enough to drain async chains (premium futures, Riverpod FutureProvider
/// resolutions, fake playSequence, etc.) without triggering the rest timer.
/// Riverpod FutureProvider chains (e.g. exerciseInstructions → exerciseInstructionsMap)
/// need multiple frames to propagate state changes, so we use several pumps.
Future<void> _drainAsync(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Start a session with [exercises] and [setsByExercise] and advance past loading.
Future<void> _startSession(
  WidgetTester tester,
  Map<String, List<Map<String, dynamic>>> setsByExercise, {
  List<Exercise>? exercises,
}) async {
  final element = tester.element(find.byType(WorkoutLoggerCore));
  final container = ProviderScope.containerOf(element);
  container.read(loggerSessionProvider.notifier).startSession(
    'Test',
    exercises ?? _exercises,
    setsByExercise,
  );
  await tester.pump(const Duration(milliseconds: 100));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();
  });

  // -------------------------------------------------------------------------
  // Template 4 — guided mode, set complete
  // -------------------------------------------------------------------------

  group('Template 4 dispatch (set complete, guided mode)', () {
    testWidgets('non-final set: dispatches 2-clip T4 sequence', (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
          {'id': 's2', 'reps': 5, 'weight': 100.0, 'isComplete': false},
          {'id': 's3', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      // T4 non-final: 2 clips (encouragement + weight_direction)
      expect(fake.dispatched, hasLength(1));
      expect(fake.dispatched[0], hasLength(2));
      expect(fake.dispatched[0].every((s) => s.isModular), isTrue);
    });

    testWidgets('final (only) set: dispatches 1-clip T4 sequence (encouragement only)', (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      // T4 final: 1 clip (encouragement only, no its_the_last_set — that moves to T5)
      expect(fake.dispatched, isNotEmpty);
      expect(fake.dispatched[0], hasLength(1));
      expect(fake.dispatched[0].every((s) => s.isModular), isTrue);
      expect(fake.dispatched[0].any((s) => s.modularId == 'its_the_last_set'), isFalse);
    });

    testWidgets('second dispatch is T3a (teaser) when transitioning to new exercise',
        (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
        'e2': [
          {'id': 's2', 'reps': 5, 'weight': 80.0, 'isComplete': false},
        ],
      });

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      // dispatched[0] = T4 (1 clip: encouragement only, final set)
      // dispatched[1] = T3a (3 clips: connective_take_rest + transition_next_up + exercise name)
      expect(fake.dispatched, hasLength(2));

      final t3a = fake.dispatched[1];
      expect(t3a, hasLength(3));
      expect(t3a[0].modularId, 'connective_take_rest');
      expect(t3a[1].modularId, 'transition_next_up');
      expect(t3a[2].isModular && t3a[2].category == 'exercise_names' && t3a[2].modularId == 'e2',
          isTrue,
          reason: 'T3a third clip must be exercise_names/e2');
    });

    testWidgets('no audio dispatch for rest after final set of final exercise', (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      // Single exercise, single set: final set of final exercise
      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      // Only T4 (encouragement), no T3a (no next exercise)
      expect(fake.dispatched, hasLength(1));
      expect(fake.dispatched[0], hasLength(1)); // T4 final = 1 clip
    });
  });

  // -------------------------------------------------------------------------
  // On-demand mode — no auto-dispatch on set complete
  // -------------------------------------------------------------------------

  group('on-demand mode', () {
    testWidgets('completing a set does not dispatch to audio', (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(
        _buildWidget(fakeAudio: fake, mode: AudioCoachingMode.onDemand),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
          {'id': 's2', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      expect(fake.dispatched, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Coaching panel — Templates 6 / 7 / 8
  // -------------------------------------------------------------------------

  group('on-demand speaker tap dispatch', () {
    Future<FakeAudioService> setupWithCoachingIcon(WidgetTester tester) async {
      final fake = FakeAudioService();
      // Coaching icon shown when premiumStatus resolves true.
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      // Pump to resolve premiumStatusProvider → true (so coaching icon is visible)
      await tester.pump(const Duration(milliseconds: 100));

      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
          {'id': 's2', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      return fake;
    }

    /// Opens the coaching panel sheet and returns without tapping any button.
    Future<void> openCoachingSheet(WidgetTester tester) async {
      final icon = find.byIcon(Icons.tips_and_updates_outlined);
      await tester.tap(icon.first);
      await _drainAsync(tester);
    }

    testWidgets('first tap dispatches T6 (good form — sentence specs only)', (tester) async {
      final fake = await setupWithCoachingIcon(tester);
      fake.reset(); // clear any T4 from session start

      await openCoachingSheet(tester);

      // Tap "Good form feels like" row in the CoachingPanel sheet
      final goodFormRow = find.byIcon(Icons.star_border_rounded);
      expect(goodFormRow, findsOneWidget);
      await tester.tap(goodFormRow);
      await _drainAsync(tester);

      expect(fake.dispatched, hasLength(1));
      // T6 = audioSpecsForCueField(goodFormFeels) — all sentence specs
      expect(fake.dispatched[0].every((s) => s.isSentence), isTrue,
          reason: 'T6 good-form cue should be entirely sentence specs');
      expect(fake.dispatched[0], isNotEmpty);
    });

    testWidgets('second tap dispatches T7 (common fix 1 — sentence specs)', (tester) async {
      final fake = await setupWithCoachingIcon(tester);
      fake.reset();

      await openCoachingSheet(tester);

      // Tap the first fix row (lightbulb icon — there are two, take first)
      final fixRows = find.byIcon(Icons.lightbulb_outline);
      expect(fixRows, findsAtLeastNWidgets(1));
      await tester.tap(fixRows.first);
      await _drainAsync(tester);

      expect(fake.dispatched, hasLength(1));
      final t7 = fake.dispatched[0];
      expect(t7.every((s) => s.isSentence), isTrue,
          reason: 'T7 common-fix cue should be entirely sentence specs');
      expect(t7, isNotEmpty);
    });

    testWidgets('third tap dispatches T8 (common fix 2 / replay)', (tester) async {
      final fake = await setupWithCoachingIcon(tester);
      fake.reset();

      await openCoachingSheet(tester);

      // Tap the second fix row (second lightbulb icon)
      final fixRows = find.byIcon(Icons.lightbulb_outline);
      expect(fixRows, findsAtLeastNWidgets(2));
      await tester.tap(fixRows.at(1));
      await _drainAsync(tester);

      expect(fake.dispatched, hasLength(1));
      final t8 = fake.dispatched[0];
      expect(t8.every((s) => s.isSentence), isTrue,
          reason: 'T8 replay cue should be entirely sentence specs');
      expect(t8, isNotEmpty);
    });

    testWidgets('T6 last spec has variant=final', (tester) async {
      final fake = await setupWithCoachingIcon(tester);
      fake.reset();

      await openCoachingSheet(tester);

      final goodFormRow = find.byIcon(Icons.star_border_rounded);
      await tester.tap(goodFormRow);
      await _drainAsync(tester);

      final t6 = fake.dispatched[0];
      expect(t6.last.variant, 'final',
          reason: 'Last sentence in a cue should have final intonation');
    });
  });

  // -------------------------------------------------------------------------
  // On-demand cue field dispatch — setup / movement / breathing (#135)
  // -------------------------------------------------------------------------

  group('on-demand setup/movement/breathing tap dispatch', () {
    Future<FakeAudioService> setupWithCoachingIconForCueFields(WidgetTester tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
          {'id': 's2', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      fake.reset(); // clear any T4 from session start
      return fake;
    }

    Future<void> openSheet(WidgetTester tester) async {
      final icon = find.byIcon(Icons.tips_and_updates_outlined);
      await tester.tap(icon.first);
      await _drainAsync(tester);
    }

    testWidgets('tapping "How to set up" dispatches sentence specs', (tester) async {
      final fake = await setupWithCoachingIconForCueFields(tester);

      await openSheet(tester);

      expect(find.text('How to set up'), findsOneWidget,
          reason: '"How to set up" row should appear — _stubInstructions has setup sentences');

      await tester.tap(find.text('How to set up'));
      await _drainAsync(tester);

      expect(fake.dispatched, hasLength(1));
      expect(fake.dispatched[0].every((s) => s.isSentence), isTrue,
          reason: 'Setup cue specs should all be sentence specs');
      expect(fake.dispatched[0], isNotEmpty);
    });

    testWidgets('tapping "Movement cue" dispatches sentence specs', (tester) async {
      final fake = await setupWithCoachingIconForCueFields(tester);

      await openSheet(tester);

      expect(find.text('Movement cue'), findsOneWidget);

      await tester.tap(find.text('Movement cue'));
      await _drainAsync(tester);

      expect(fake.dispatched, hasLength(1));
      expect(fake.dispatched[0].every((s) => s.isSentence), isTrue,
          reason: 'Movement cue specs should all be sentence specs');
      expect(fake.dispatched[0], isNotEmpty);
    });

    testWidgets('tapping "Breathing" dispatches sentence specs', (tester) async {
      final fake = await setupWithCoachingIconForCueFields(tester);

      await openSheet(tester);

      expect(find.text('Breathing'), findsOneWidget,
          reason: '"Breathing" row should appear — _stubInstructions now has breathingCue');

      await tester.tap(find.text('Breathing'));
      await _drainAsync(tester);

      expect(fake.dispatched, hasLength(1));
      expect(fake.dispatched[0].every((s) => s.isSentence), isTrue,
          reason: 'Breathing cue specs should all be sentence specs');
      expect(fake.dispatched[0], isNotEmpty);
    });

    testWidgets('setup/movement/breathing taps are no-ops when audio muted', (tester) async {
      final fake = FakeAudioService();
      // Build with isAudioMuted returning true
      await tester.pumpWidget(ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((_) => AppDatabase.test()),
          exerciseFavoritesProvider.overrideWith((ref) => ExerciseFavoritesNotifier(AppDatabase.test())),
          exercisesFutureProvider.overrideWith((_) async => [_exercises[0]]),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => []),
          exerciseEquipmentFilterProvider.overrideWith((_) => []),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),
          exerciseInstructionsMapProvider.overrideWith((_) async => {'e1': _stubInstructions, 'e2': _stubInstructions}),
          sentenceLibraryProvider.overrideWith((_) async => _stubLib),
          audioServiceProvider.overrideWithValue(fake),
          restTimerAudioSchedulerProvider.overrideWithValue(null),
          audioCoachingSettingsProvider.overrideWith(
            (_) => AudioCoachingSettingsNotifier()
              ..state = AudioCoachingSettingsState(mode: AudioCoachingMode.onDemand, isLoading: false),
          ),
          aiProgrammePremiumProvider.overrideWithValue(true),
        ],
        child: MaterialApp.router(
          theme: FytterTheme.light,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, __) => Scaffold(
                  body: WorkoutLoggerCore(
                    initialExercises: [_exercises[0]],
                    workoutName: 'Test',
                    onSessionComplete: (_) {},
                    testExercises: [_exercises[0]],
                    isAudioMuted: () => true, // <-- muted
                  ),
                ),
              ),
            ],
          ),
        ),
      ));

      await tester.pump(const Duration(milliseconds: 100));

      final element = tester.element(find.byType(WorkoutLoggerCore));
      final container = ProviderScope.containerOf(element);
      container.read(loggerSessionProvider.notifier).startSession(
        'Test',
        [_exercises[0]],
        {
          'e1': [
            {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
          ],
        },
      );
      await tester.pump(const Duration(milliseconds: 100));

      fake.reset();

      final icon = find.byIcon(Icons.tips_and_updates_outlined);
      await tester.tap(icon.first);
      await _drainAsync(tester);

      expect(find.text('How to set up'), findsOneWidget);
      await tester.tap(find.text('How to set up'));
      await _drainAsync(tester);

      expect(fake.dispatched, isEmpty,
          reason: 'Muted session should dispatch nothing when setup row tapped');
    });
  });

  // -------------------------------------------------------------------------
  // Template 2 — WorkoutLoggerSheet intro modal dismiss
  // Note: T2 is dispatched from WorkoutLoggerSheet._playTemplate2FirstExercise,
  // which fires when the WorkoutIntroModal "Ready to go" button is tapped.
  // This tests the full T2 dispatch chain via WorkoutLoggerSheet.
  // -------------------------------------------------------------------------

  group('Template 2 dispatch (first exercise, guided mode)', () {
    Widget buildSheetWidget(FakeAudioService fakeAudio) {
      final db = AppDatabase.test();
      final exList = [_exercises[0]]; // single exercise so T2 fires for e1

      return ProviderScope(
        overrides: [
          // ---- database ----
          appDatabaseProvider.overrideWith((_) => db),
          exerciseFavoritesProvider.overrideWith((ref) => ExerciseFavoritesNotifier(db)),

          // ---- exercise data ----
          exercisesFutureProvider.overrideWith((_) async => exList),
          exerciseMusclesMapProvider.overrideWith((_) async => <String, List<String>>{}),
          exerciseWorkoutCountProvider.overrideWith((_) async => <String, int>{}),
          exerciseMostRecentDateProvider.overrideWith((_) async => <String, DateTime?>{}),

          // ---- filter / sort ----
          exerciseFilterTextProvider.overrideWith((_) => ''),
          exerciseBodyPartFilterProvider.overrideWith((_) => []),
          exerciseEquipmentFilterProvider.overrideWith((_) => []),
          exerciseFavoriteFilterProvider.overrideWith((_) => false),
          exerciseSortOrderProvider.overrideWith((_) => ExerciseSortOrder.nameAsc),

          // ---- exercise instructions (avoids asset loading) ----
          exerciseInstructionsMapProvider.overrideWith(
            (_) async => {
              'e1': _stubInstructions,
              'e2': _stubInstructions,
            },
          ),

          // ---- sentence library (avoids asset loading) ----
          sentenceLibraryProvider.overrideWith((_) async => _stubLib),

          // ---- audio service → fake ----
          audioServiceProvider.overrideWithValue(fakeAudio),

          // ---- rest-end scheduler → null to avoid OS notifications ----
          restTimerAudioSchedulerProvider.overrideWithValue(null),

          // ---- audio coaching mode → guided so T2 fires ----
          audioCoachingSettingsProvider.overrideWith(
            (_) => AudioCoachingSettingsNotifier()
              ..state = AudioCoachingSettingsState(
                mode: AudioCoachingMode.guided,
                isLoading: false,
              ),
          ),

          // ---- premium (always true so intro modal shows) ----
          aiProgrammePremiumProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: FytterTheme.light,
          home: Scaffold(
            body: WorkoutLoggerSheet(
              workoutName: 'Test',
              workoutId: 'test_workout',
              initialExercises: exList,
              initialSetsByExercise: {
                'e1': [
                  {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
                ],
              },
              minimized: false,
              onMinimize: () {},
              onMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('dismissing intro modal dispatches T2 (transition_first_exercise + name + setup + movement + connective_when_ready)',
        (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(buildSheetWidget(fake));

      // Drain session startup + intro modal scheduling (postFrameCallbacks)
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // The intro modal should now be visible
      expect(find.text('Ready to go'), findsOneWidget,
          reason: 'Intro modal should appear for premium + guided mode');

      // Reset dispatched — T1 (workout intro) may have fired before "Ready to go"
      fake.reset();

      // Dismiss the modal → triggers T2
      await tester.tap(find.text('Ready to go'));
      await _drainAsync(tester);

      // T2 should be dispatched once
      expect(fake.dispatched, isNotEmpty,
          reason: 'T2 should fire after modal dismiss');
      final t2 = fake.dispatched[0];

      // transition_first_exercise modular clip
      expect(t2.any((s) => s.isModular && s.modularId == 'transition_first_exercise'), isTrue,
          reason: 'T2 must contain transition_first_exercise clip');

      // exercise name modular clip
      expect(t2.any((s) => s.isModular && s.category == 'exercise_names' && s.modularId == 'e1'),
          isTrue,
          reason: 'T2 must contain exercise name clip for e1');

      // sentence specs (setup + movement)
      expect(t2.any((s) => s.isSentence), isTrue,
          reason: 'T2 must contain sentence specs from setup/movement');

      // connective_when_ready modular clip
      expect(t2.any((s) => s.isModular && s.modularId == 'connective_when_ready'), isTrue,
          reason: 'T2 must end with connective_when_ready clip');
    });
  });
}
