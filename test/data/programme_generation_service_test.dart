import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/programme_generation_service.dart';
import 'package:fytter/src/data/program_repository_impl.dart';
import 'package:fytter/src/data/workout_repository_impl.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/user_scorecard.dart';

Exercise _ex({
  required String id,
  required String name,
  MovementPattern? movementPattern,
  SafetyTier safetyTier = SafetyTier.tier1,
  String? equipment,
}) {
  return Exercise(
    id: id,
    name: name,
    movementPattern: movementPattern,
    safetyTier: safetyTier,
    equipment: equipment,
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ProgrammeGenerationService service;

  setUp(() {
    db = AppDatabase.test();
    final programRepo = ProgramRepositoryImpl(db);
    final workoutRepo = WorkoutRepositoryImpl(db);
    service = ProgrammeGenerationService(
      programRepository: programRepo,
      workoutRepository: workoutRepo,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('generateAndSave uses fallback when Cloud Function fails and saves program', () async {
    final library = [
      _ex(id: 'squat-1', name: 'Squat', movementPattern: MovementPattern.squat, equipment: 'Barbell'),
      _ex(id: 'push-1', name: 'Push', movementPattern: MovementPattern.pushHorizontal, equipment: 'Barbell'),
      _ex(id: 'pull-1', name: 'Pull', movementPattern: MovementPattern.pullHorizontal, equipment: 'Barbell'),
      _ex(id: 'hinge-1', name: 'Hinge', movementPattern: MovementPattern.hinge, equipment: 'Barbell'),
    ];
    final request = ProgrammeGenerationRequest(
      daysPerWeek: 2,
      sessionLengthMinutes: 30,
      goal: 'general_fitness',
      exerciseLibrary: library,
    );

    // Without Firebase configured, call will throw and we use fallback
    final result = await service.generateAndSave(request);

    expect(result.usedFallback, isTrue);
    expect(result.program.name, isNotEmpty);
    expect(result.program.isAiGenerated, isTrue);
    // Rule fallback: 2 days/week × 4 weeks = 8 schedule entries
    expect(result.program.schedule.length, 8);

    final programRepo = ProgramRepositoryImpl(db);
    final found = await programRepo.findById(result.program.id);
    expect(found.id, result.program.id);
    expect(found.name, result.program.name);
    expect(found.schedule.length, 8);

    final workoutRepo = WorkoutRepositoryImpl(db);
    for (final s in result.program.schedule) {
      final workout = await workoutRepo.findById(s.workoutId);
      expect(workout.entries, isNotEmpty);
    }
  });

  test('toCallablePayload includes exercise library with required fields', () {
    final library = [
      _ex(id: 'ex-1', name: 'Exercise 1', movementPattern: MovementPattern.squat),
    ];
    final request = ProgrammeGenerationRequest(
      daysPerWeek: 3,
      sessionLengthMinutes: 45,
      exerciseLibrary: library,
    );

    final payload = request.toCallablePayload();

    expect(payload['daysPerWeek'], 3);
    expect(payload['sessionLengthMinutes'], 45);
    expect(payload['exerciseLibrary'], isA<List>());
    final lib = payload['exerciseLibrary'] as List;
    expect(lib.length, 1);
    expect(lib[0]['id'], 'ex-1');
    expect(lib[0]['name'], 'Exercise 1');
    expect(lib[0]['movementPattern'], 'squat');
    expect(lib[0]['safetyTier'], 1);
  });

  test('toCallablePayload prefers scorecardNarrative string over userScorecard', () {
    final library = [
      _ex(id: 'ex-1', name: 'Exercise 1', movementPattern: MovementPattern.squat),
    ];
    final request = ProgrammeGenerationRequest(
      daysPerWeek: 3,
      sessionLengthMinutes: 45,
      exerciseLibrary: library,
      scorecardNarrative: 'Override narrative',
      userScorecard: const UserScorecard(id: 'local', consistency: 9.0),
    );
    expect(request.toCallablePayload()['scorecardNarrative'], 'Override narrative');
  });

  test('ProgrammeGenerationLimitException is an Exception', () {
    const ex = ProgrammeGenerationLimitException();
    expect(ex, isA<Exception>());
  });

  test('toCallablePayload sends userScorecard narrative when no override string', () {
    final library = [
      _ex(id: 'ex-1', name: 'Exercise 1', movementPattern: MovementPattern.squat),
    ];
    const card = UserScorecard(id: 'local', consistency: 8.0, computedLevel: 3);
    final request = ProgrammeGenerationRequest(
      daysPerWeek: 3,
      sessionLengthMinutes: 45,
      exerciseLibrary: library,
      userScorecard: card,
    );
    final narrative = request.toCallablePayload()['scorecardNarrative'] as String?;
    expect(narrative, isNotNull);
    expect(narrative, contains('show up'));
  });
}
