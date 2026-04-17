/// Tests that [WorkoutLoggerCore._scheduleRestEndAudioAsync] builds the correct
/// T5 specs for each workout scenario, verified by checking what plays at rest end.
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
import 'package:fytter/src/providers/rest_timer_provider.dart';
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

// Instructions with setup and movement but no breathing cue.
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
  ],
});

// ---------------------------------------------------------------------------
// Widget factory
// ---------------------------------------------------------------------------

Widget _buildWidget({
  required FakeAudioService fakeAudio,
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

      // ---- audio coaching mode → guided so T5 is scheduled ----
      audioCoachingSettingsProvider.overrideWith(
        (_) => AudioCoachingSettingsNotifier()
          ..state = AudioCoachingSettingsState(
            mode: AudioCoachingMode.guided,
            isLoading: false,
          ),
      ),

      // ---- premium (always true so T4/T5 fire) ----
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

/// Simulate rest timer ending by calling stop() and draining.
Future<List<List<dynamic>>> _endRest(WidgetTester tester, FakeAudioService fake) async {
  final element = tester.element(find.byType(WorkoutLoggerCore));
  final container = ProviderScope.containerOf(element);
  final countBefore = fake.dispatched.length;
  container.read(restTimerProvider.notifier).stop();
  await _drainAsync(tester);
  return fake.dispatched.sublist(countBefore);
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
  // T5 in-process playback — specs dispatched at rest end
  // -------------------------------------------------------------------------

  group('T5 in-process playback — specs dispatched at rest end', () {
    testWidgets('same exercise: exercise name + its_your_second_set + lets_go played at rest end',
        (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      // 3 sets for e1. Completing set 1 → T5 for set 2 (not first, not last).
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

      final t5Dispatches = await _endRest(tester, fake);

      expect(t5Dispatches, hasLength(1), reason: 'T5 should fire exactly once at rest end');
      final t5 = t5Dispatches[0];
      // Exercise name is only spoken on the first set; subsequent sets omit it.
      expect(t5.any((s) => s.isModular && s.category == 'exercise_names'), isFalse,
          reason: 'T5 same-exercise path should NOT repeat the exercise name');
      expect(t5.any((s) => s.isModular && s.modularId == 'its_your_second_set'), isTrue,
          reason: 'T5 should contain its_your_second_set for set 2 of 3');
      expect(t5.any((s) => s.isModular && s.modularId == 'connective_lets_go'), isTrue,
          reason: 'T5 should end with connective_lets_go');
    });

    testWidgets('same exercise: its_the_last_set when completing penultimate set',
        (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      // 2 sets for e1. Completing set 1 → set 2 is the LAST set.
      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
          {'id': 's2', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      final t5Dispatches = await _endRest(tester, fake);

      expect(t5Dispatches, hasLength(1), reason: 'T5 should fire once at rest end');
      final t5 = t5Dispatches[0];
      // Exercise name is only spoken on the first set; subsequent sets omit it.
      expect(t5.any((s) => s.isModular && s.category == 'exercise_names'), isFalse,
          reason: 'T5 same-exercise path should NOT repeat the exercise name');
      expect(t5.any((s) => s.isModular && s.modularId == 'its_the_last_set'), isTrue,
          reason: 'T5 should contain its_the_last_set');
    });

    testWidgets('exercise transition: setup+movement+connective_when_ready for next exercise',
        (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      // e1 1 set (final), e2 2 sets. Completing e1 set → T5 for e2 set 1 (T3b path).
      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
        'e2': [
          {'id': 's2', 'reps': 5, 'weight': 80.0, 'isComplete': false},
          {'id': 's3', 'reps': 5, 'weight': 80.0, 'isComplete': false},
        ],
      });

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      final t5Dispatches = await _endRest(tester, fake);

      expect(t5Dispatches, hasLength(1), reason: 'T5 should fire at rest end');
      final t5 = t5Dispatches[0];
      expect(t5.any((s) => s.isModular && s.category == 'exercise_names' && s.modularId == 'e2'),
          isTrue, reason: 'T5 (T3b) should be for next exercise e2');
      // T3b path: setup + movement sentences included
      expect(t5.any((s) => s.isSentence), isTrue, reason: 'T3b should include setup/movement sentences');
      expect(t5.any((s) => s.isModular && s.modularId == 'connective_when_ready'), isTrue,
          reason: 'T3b should end with connective_when_ready');
      // No set-label clips in T3b
      expect(t5.any((s) => s.modularId == 'connective_lets_go'), isFalse,
          reason: 'T3b should not contain connective_lets_go');
    });

    testWidgets('single-set exercise transition: T3b path (connective_when_ready, no its_the_last_set)',
        (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      // e1 1 set, e2 1 set (single-set). T5 takes T3b path since isFirstSetOfExercise=true.
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

      final t5Dispatches = await _endRest(tester, fake);

      expect(t5Dispatches, hasLength(1), reason: 'T5 should fire at rest end');
      final t5 = t5Dispatches[0];
      expect(t5.any((s) => s.isModular && s.category == 'exercise_names' && s.modularId == 'e2'),
          isTrue, reason: 'T5 should be for e2');
      expect(t5.any((s) => s.isModular && s.modularId == 'connective_when_ready'), isTrue,
          reason: 'Single-set T3b ends with connective_when_ready, not connective_lets_go');
      expect(t5.any((s) => s.modularId == 'its_the_last_set'), isFalse,
          reason: 'T3b skips its_the_last_set since isFirstSetOfExercise=true takes priority');
    });

    testWidgets('no T5 dispatch after final set of final exercise', (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      // Single exercise, single set — no rest started, no T5 stored.
      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      // Rest timer was not started (final set of final exercise), so stop() is a no-op transition.
      final t5Dispatches = await _endRest(tester, fake);
      expect(t5Dispatches, isEmpty, reason: 'No T5 when no rest was scheduled');
    });
  });

  // -------------------------------------------------------------------------
  // RestTimerState.completedExerciseId
  // -------------------------------------------------------------------------

  group('RestTimerState.completedExerciseId', () {
    testWidgets('is set to current exercise ID when rest starts', (tester) async {
      final fake = FakeAudioService();
      await tester.pumpWidget(_buildWidget(fakeAudio: fake));
      await tester.pump(const Duration(milliseconds: 100));

      // 2 sets for e1, so completing set 1 starts rest for e1.
      await _startSession(tester, {
        'e1': [
          {'id': 's1', 'reps': 5, 'weight': 100.0, 'isComplete': false},
          {'id': 's2', 'reps': 5, 'weight': 100.0, 'isComplete': false},
        ],
      }, exercises: [_exercises[0]]);

      await tester.ensureVisible(find.text('Complete Set'));
      await tester.tap(find.text('Complete Set'));
      await _drainAsync(tester);

      // Read restTimerProvider from the container.
      final element = tester.element(find.byType(WorkoutLoggerCore));
      final container = ProviderScope.containerOf(element);
      final timerState = container.read(restTimerProvider);
      expect(timerState.completedExerciseId, 'e1');
    });
  });
}
