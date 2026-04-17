/// On-demand LLM quality tests for AI programme generation.
///
/// These tests call the real LLM (via Firebase Cloud Functions) and verify
/// that [ProgrammeGenerationService] accepts the output without falling back.
/// The service already runs [ProgrammeValidator] internally — a result with
/// [ProgrammeGenerationResult.usedFallback] == false means the LLM output
/// passed all hard validation checks.
///
/// Each test also prints a human-readable quality report. After the run, a
/// reviewer reads that output and consults REVIEW_GUIDE.md for what to check.
///
/// When to run:
///   • After changing the programme generation prompt.
///   • After changing what inputs are captured on the generation form.
///   • As a periodic baseline check before shipping a major release.
///
/// How to run:
///   RUN_LLM_TESTS=1 flutter test test/llm_quality/ --tags llm_quality
///
/// Prerequisites: see test/llm_quality/REVIEW_GUIDE.md.
@Tags(['llm_quality'])
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/program_repository_impl.dart';
import 'package:fytter/src/data/programme_generation_service.dart';
import 'package:fytter/src/data/workout_repository_impl.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';

// ---------------------------------------------------------------------------
// Guard
// ---------------------------------------------------------------------------

bool get _enabled => Platform.environment['RUN_LLM_TESTS'] == '1';
const _skipReason =
    'Set RUN_LLM_TESTS=1 to run — see test/llm_quality/REVIEW_GUIDE.md';

// ---------------------------------------------------------------------------
// Firebase options
//
// flutter test runs on macOS (host) where there is no platform-level
// GoogleService-Info.plist. We supply explicit options sourced from the iOS
// plist — they point to the same Firebase project and work for HTTPS-based
// Cloud Function calls on any platform.
// ---------------------------------------------------------------------------

const _firebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyCmrbCuO5ya4t_bHz6yarVzeHZG892_nss',
  appId: '1:984128866494:ios:57e210eedcb8d33ff676ef',
  messagingSenderId: '984128866494',
  projectId: 'fytter-df3e7',
  storageBucket: 'fytter-df3e7.firebasestorage.app',
);

// ---------------------------------------------------------------------------
// Reference exercise libraries
// ---------------------------------------------------------------------------

List<Exercise> _gymLibrary() => const [
      Exercise(id: 'squat-1',    name: 'Squat',            movementPattern: MovementPattern.squat,          equipment: 'Barbell'),
      Exercise(id: 'bench-1',    name: 'Bench Press',       movementPattern: MovementPattern.pushHorizontal, equipment: 'Barbell'),
      Exercise(id: 'row-1',      name: 'Barbell Row',       movementPattern: MovementPattern.pullHorizontal, equipment: 'Barbell'),
      Exercise(id: 'deadlift-1', name: 'Deadlift',          movementPattern: MovementPattern.hinge,          equipment: 'Barbell'),
      Exercise(id: 'ohp-1',      name: 'Overhead Press',    movementPattern: MovementPattern.pushVertical,   equipment: 'Barbell'),
      Exercise(id: 'pullup-1',   name: 'Pull-Up',           movementPattern: MovementPattern.pullVertical),
      Exercise(id: 'rdl-1',      name: 'Romanian Deadlift', movementPattern: MovementPattern.hinge,          equipment: 'Barbell'),
      Exercise(id: 'lunge-1',    name: 'Lunge',             movementPattern: MovementPattern.lunge),
      Exercise(id: 'db-curl-1',  name: 'Dumbbell Curl',     movementPattern: MovementPattern.isolationUpper, equipment: 'Dumbbell'),
      Exercise(id: 'tricep-1',   name: 'Tricep Dips',       movementPattern: MovementPattern.isolationUpper),
    ];

List<Exercise> _homeLibrary() => const [
      Exercise(id: 'pushup-1',   name: 'Push-Up',          movementPattern: MovementPattern.pushHorizontal, suitability: ['beginner_friendly', 'home_friendly']),
      Exercise(id: 'squat-bw-1', name: 'Bodyweight Squat', movementPattern: MovementPattern.squat,          suitability: ['beginner_friendly', 'home_friendly']),
      Exercise(id: 'lunge-1',    name: 'Lunge',            movementPattern: MovementPattern.lunge,          suitability: ['beginner_friendly', 'home_friendly']),
      Exercise(id: 'plank-1',    name: 'Plank',            movementPattern: MovementPattern.core,           suitability: ['beginner_friendly', 'home_friendly']),
      Exercise(id: 'tricep-1',   name: 'Tricep Dips',      movementPattern: MovementPattern.isolationUpper, suitability: ['home_friendly']),
    ];

// ---------------------------------------------------------------------------
// Report helper
// ---------------------------------------------------------------------------

void _printReport(String label, ProgrammeGenerationResult result) {
  // ignore: avoid_print
  print('\n══════════════════════════════════════════════════════');
  // ignore: avoid_print
  print('  LLM QUALITY REPORT — $label');
  // ignore: avoid_print
  print('══════════════════════════════════════════════════════');
  // ignore: avoid_print
  print('  Source   : ${result.usedFallback ? "FALLBACK ⚠" : "LLM ✓"}');
  if (result.generationFailureReason != null) {
    // ignore: avoid_print
    print('  Reason   : ${result.generationFailureReason}');
  }
  // ignore: avoid_print
  print('  Programme: ${result.program.name}');
  // ignore: avoid_print
  print('  Personalisation notes (${result.personalisationNotes.length}):');
  if (result.personalisationNotes.isEmpty) {
    // ignore: avoid_print
    print('    ⚠  none — expected at least one note');
  } else {
    for (final note in result.personalisationNotes) {
      // ignore: avoid_print
      print('    • $note');
    }
  }
  // ignore: avoid_print
  print('  (review against REVIEW_GUIDE.md)');
  // ignore: avoid_print
  print('══════════════════════════════════════════════════════\n');
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late ProgrammeGenerationService service;

  setUpAll(() async {
    if (!_enabled) return;
    // Required before any platform channel (including Firebase) is used.
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialise Firebase with explicit options (no platform plist in test env).
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: _firebaseOptions);
    }
    // Anonymous sign-in satisfies the Cloud Function's auth check.
    await FirebaseAuth.instance.signInAnonymously();
  });

  tearDownAll(() async {
    if (!_enabled) return;
    if (Firebase.apps.isNotEmpty) {
      await FirebaseAuth.instance.signOut();
    }
  });

  setUp(() {
    db = AppDatabase.test();
    service = ProgrammeGenerationService(
      programRepository: ProgramRepositoryImpl(db),
      workoutRepository: WorkoutRepositoryImpl(db),
    );
  });

  tearDown(() async => db.close());

  // Q1: Standard structured inputs ──────────────────────────────────────────
  test(
    'Q1: 3-day general fitness, full gym, intermediate — '
    'LLM responds without fallback; notes present',
    skip: _enabled ? null : _skipReason,
    () async {
      final result = await service.generateAndSave(ProgrammeGenerationRequest(
        daysPerWeek: 3,
        sessionLengthMinutes: 45,
        goal: 'general_fitness',
        equipment: 'full_gym',
        experienceLevel: 'regular',
        exerciseLibrary: _gymLibrary(),
      ));
      _printReport('Q1 — 3-day general fitness', result);

      expect(result.usedFallback, isFalse,
          reason: 'LLM should succeed and pass validation. '
              'Failure reason: ${result.generationFailureReason}');
      expect(result.personalisationNotes, isNotEmpty,
          reason: 'LLM should return at least one personalisation note.');
    },
  );

  // Q2: Home equipment + beginner + weight loss ─────────────────────────────
  test(
    'Q2: 2-day weight loss, home equipment, beginner — '
    'LLM responds; notes present',
    skip: _enabled ? null : _skipReason,
    () async {
      final result = await service.generateAndSave(ProgrammeGenerationRequest(
        daysPerWeek: 2,
        sessionLengthMinutes: 30,
        goal: 'weight_loss',
        equipment: 'home',
        experienceLevel: 'never',
        exerciseLibrary: _homeLibrary(),
      ));
      _printReport('Q2 — 2-day weight loss, home', result);

      expect(result.usedFallback, isFalse,
          reason: 'Failure reason: ${result.generationFailureReason}');
      expect(result.personalisationNotes, isNotEmpty);
    },
  );

  // Q3: Injury free-text ────────────────────────────────────────────────────
  test(
    'Q3: 3-day muscle gain, full gym, shoulder impingement free-text — '
    'notes acknowledge shoulder limitation',
    skip: _enabled ? null : _skipReason,
    () async {
      final result = await service.generateAndSave(ProgrammeGenerationRequest(
        daysPerWeek: 3,
        sessionLengthMinutes: 60,
        goal: 'muscle_gain',
        equipment: 'full_gym',
        experienceLevel: 'some',
        injuriesOrLimitations:
            'Left shoulder impingement — no overhead pressing or behind-neck movements.',
        exerciseLibrary: _gymLibrary(),
      ));
      _printReport('Q3 — 3-day muscle gain, shoulder injury', result);

      expect(result.usedFallback, isFalse,
          reason: 'Failure reason: ${result.generationFailureReason}');
      final notes = result.personalisationNotes.join(' ').toLowerCase();
      expect(
        notes,
        anyOf(contains('shoulder'), contains('overhead')),
        reason: 'Personalisation notes should acknowledge the shoulder injury.',
      );
    },
  );

  // Q4: Additional context free-text ────────────────────────────────────────
  test(
    'Q4: 4-day muscle gain, full gym, travel scheduling context — '
    'notes present',
    skip: _enabled ? null : _skipReason,
    () async {
      final result = await service.generateAndSave(ProgrammeGenerationRequest(
        daysPerWeek: 4,
        sessionLengthMinutes: 60,
        goal: 'muscle_gain',
        equipment: 'full_gym',
        experienceLevel: 'regular',
        additionalContext:
            "I travel for work two weeks per month and won't always have gym "
            'access. Please keep sessions self-contained so I can swap days.',
        exerciseLibrary: _gymLibrary(),
      ));
      _printReport('Q4 — 4-day with travel context', result);

      expect(result.usedFallback, isFalse,
          reason: 'Failure reason: ${result.generationFailureReason}');
      expect(result.personalisationNotes, isNotEmpty);
    },
  );
}
