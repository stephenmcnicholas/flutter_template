import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/programme_generation_service.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/user_scorecard.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';

List<Exercise> _library() => [
      Exercise(
        id: 'squat-1',
        name: 'Squat',
        movementPattern: MovementPattern.squat,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
      Exercise(
        id: 'push-1',
        name: 'Bench Press',
        movementPattern: MovementPattern.pushHorizontal,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
      Exercise(
        id: 'pull-1',
        name: 'Row',
        movementPattern: MovementPattern.pullHorizontal,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
      Exercise(
        id: 'hinge-1',
        name: 'Deadlift',
        movementPattern: MovementPattern.hinge,
        equipment: 'barbell',
        safetyTier: SafetyTier.tier1,
      ),
    ];

int? _firstExerciseSets(Program program) {
  final raw = program.workoutBreakdowns;
  if (raw == null || raw.isEmpty) return null;
  final list = jsonDecode(raw) as List<dynamic>;
  if (list.isEmpty) return null;
  final first = list.first as Map<String, dynamic>;
  final exercises = first['exercises'] as List<dynamic>?;
  if (exercises == null || exercises.isEmpty) return null;
  final ex = exercises.first as Map<String, dynamic>;
  return ex['sets'] as int?;
}

/// Block 4 Task 24: scorecard-influenced generation path + persistence sanity.
void main() {
  late AppDatabase db;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    db = AppDatabase.test();
  });

  tearDown(() async {
    await db.close();
  });

  test('Scorecard low consistency yields fewer sets in rule fallback than default', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exercisesFutureProvider.overrideWith((ref) => Future.value(_library())),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(programmeGenerationProvider.notifier);

    final baseline = ProgrammeGenerationRequest(
      daysPerWeek: 3,
      sessionLengthMinutes: 45,
      goal: 'general_fitness',
      blockedDays: const [],
      equipment: 'full_gym',
      exerciseLibrary: _library(),
    );
    await notifier.generate(baseline);
    expect(container.read(programmeGenerationProvider), isA<ProgrammeGenerationSuccess>());
    final baseProgram = (container.read(programmeGenerationProvider) as ProgrammeGenerationSuccess)
        .result
        .program;
    final baseSets = _firstExerciseSets(baseProgram);
    expect(baseSets, isNotNull);

    notifier.reset();
    final lowConsistency = ProgrammeGenerationRequest(
      daysPerWeek: 3,
      sessionLengthMinutes: 45,
      goal: 'general_fitness',
      blockedDays: const [],
      equipment: 'full_gym',
      exerciseLibrary: _library(),
      userScorecard: const UserScorecard(
        id: 'local',
        consistency: 2.0,
        fundamentals: 5.0,
        endurance: 5.0,
      ),
    );
    await notifier.generate(lowConsistency);
    expect(container.read(programmeGenerationProvider), isA<ProgrammeGenerationSuccess>());
    final lowProgram = (container.read(programmeGenerationProvider) as ProgrammeGenerationSuccess)
        .result
        .program;
    final lowSets = _firstExerciseSets(lowProgram);
    expect(lowSets, isNotNull);
    expect(lowSets, lessThan(baseSets!));
  });
}
