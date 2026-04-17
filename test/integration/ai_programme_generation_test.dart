import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/programme_generation_service.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';

List<Exercise> _testExerciseLibrary() => [
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

/// Integration tests for the AI programme generation flow: generation (with
/// fallback when CF is unavailable), persistence, and visibility on program list.
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

  test('Full flow: generate request → fallback → programme saved → appears in program list', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exercisesFutureProvider.overrideWith((ref) => Future.value(_testExerciseLibrary())),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(programmeGenerationProvider.notifier);
    final request = ProgrammeGenerationRequest(
      daysPerWeek: 3,
      sessionLengthMinutes: 45,
      goal: 'general_fitness',
      blockedDays: [],
      equipment: 'full_gym',
      exerciseLibrary: _testExerciseLibrary(),
    );

    await notifier.generate(request);

    final state = container.read(programmeGenerationProvider);
    expect(state, isA<ProgrammeGenerationSuccess>());
    final success = state as ProgrammeGenerationSuccess;
    expect(success.result.usedFallback, isTrue);
    expect(success.result.program.name, isNotEmpty);
    expect(success.result.program.isAiGenerated, isTrue);
    // Rule fallback: 3 days/week × 4 weeks = 12 schedule entries
    expect(success.result.program.schedule.length, 12);

    final programRepo = container.read(programRepositoryProvider);
    final allPrograms = await programRepo.findAll();
    expect(allPrograms.any((p) => p.id == success.result.program.id), isTrue);
    final saved = allPrograms.firstWhere((p) => p.id == success.result.program.id);
    expect(saved.name, success.result.program.name);
    expect(saved.schedule.length, 12);

    container.invalidate(programsFutureProvider);
    final programsFromProvider = await container.read(programsFutureProvider.future);
    expect(programsFromProvider.any((p) => p.id == success.result.program.id), isTrue);
    final onList = programsFromProvider.firstWhere((p) => p.id == success.result.program.id);
    expect(onList.name, success.result.program.name);
    expect(onList.schedule.length, 12);
  });

  test('Fallback path: no Firebase → rule-built programme generated and saved', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        exercisesFutureProvider.overrideWith((ref) => Future.value(_testExerciseLibrary())),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(programmeGenerationProvider.notifier);
    final request = ProgrammeGenerationRequest(
      daysPerWeek: 4,
      sessionLengthMinutes: 60,
      goal: 'build_muscle',
      blockedDays: ['sunday'],
      equipment: 'full_gym',
      exerciseLibrary: _testExerciseLibrary(),
    );

    await notifier.generate(request);

    final state = container.read(programmeGenerationProvider);
    expect(state, isA<ProgrammeGenerationSuccess>());
    final success = state as ProgrammeGenerationSuccess;
    expect(success.result.usedFallback, isTrue);

    final program = success.result.program;
    // Rule fallback: 4 days/week × 4 weeks = 16 schedule entries
    expect(program.schedule.length, 16);
    final workoutRepo = container.read(workoutRepositoryProvider);
    for (final s in program.schedule) {
      final workout = await workoutRepo.findById(s.workoutId);
      expect(workout.entries, isNotEmpty);
    }
  });
}
