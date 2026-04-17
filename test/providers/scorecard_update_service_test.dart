import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/program_repository_impl.dart';
import 'package:fytter/src/data/user_scorecard_repository.dart';
import 'package:fytter/src/data/workout_session_repository_impl.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/rule_engine/scorecard_updater.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';
import 'package:fytter/src/providers/scorecard_update_service.dart';
import 'package:fytter/src/utils/shared_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Exercise> _exercises() => [
      Exercise(
        id: 'e1',
        name: 'Squat',
        movementPattern: MovementPattern.squat,
        safetyTier: SafetyTier.tier1,
      ),
      Exercise(
        id: 'e2',
        name: 'Press',
        movementPattern: MovementPattern.pushHorizontal,
        safetyTier: SafetyTier.tier1,
      ),
    ];

Future<void> _waitForRestTimer(ProviderContainer container) async {
  for (var i = 0; i < 50; i++) {
    final state = container.read(restTimerSettingsProvider);
    if (!state.isLoading) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPrefs.instance.resetForTests();
  });

  group('ScorecardUpdateService', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.test();
    });

    tearDown(() async {
      await db.close();
    });

    ProviderContainer createTestContainer() {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          exercisesFutureProvider.overrideWith((ref) => Future.value(_exercises())),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('onPostWorkoutCheckIn persists selfAwareness and level', () async {
      final container = createTestContainer();
      await _waitForRestTimer(container);

      final scoreRepo = UserScorecardRepository(db);
      await scoreRepo.loadOrCreate();

      await container.read(scorecardUpdateServiceProvider).onPostWorkoutCheckIn(
            rating: CheckInRating.great,
            performanceWasWeakerThanCheckIn: false,
          );

      final updated = await scoreRepo.getScorecard();
      expect(updated, isNotNull);
      expect(updated!.selfAwareness, greaterThan(5.0));
      expect(updated.computedLevel, inInclusiveRange(1, 5));
    });

    test('onPreWorkoutAdaptability updates adaptability', () async {
      final container = createTestContainer();
      await _waitForRestTimer(container);

      final scoreRepo = UserScorecardRepository(db);
      await scoreRepo.loadOrCreate();

      await container.read(scorecardUpdateServiceProvider).onPreWorkoutAdaptability(
            adjustmentAccepted: true,
          );

      final updated = await scoreRepo.getScorecard();
      expect(updated!.adaptability, greaterThan(5.0));
    });

    test('onCuriosityInteraction updates curiosity', () async {
      final container = createTestContainer();
      await _waitForRestTimer(container);

      final scoreRepo = UserScorecardRepository(db);
      await scoreRepo.loadOrCreate();

      await container
          .read(scorecardUpdateServiceProvider)
          .onCuriosityInteraction(ScorecardInteractionKind.aboutProgrammeOpened);

      final updated = await scoreRepo.getScorecard();
      expect(updated!.curiosity, greaterThan(5.0));
    });

    test('onSessionCompleted aggregates sessions and persists scorecard', () async {
      final container = createTestContainer();
      await _waitForRestTimer(container);

      final sessionRepo = WorkoutSessionRepositoryImpl(db);
      final past = DateTime(2026, 3, 1, 10);
      await sessionRepo.save(
        WorkoutSession(
          id: 'sess-past',
          workoutId: 'w1',
          date: past,
          entries: [
            WorkoutEntry(
              id: 'pe1',
              exerciseId: 'e1',
              reps: 5,
              weight: 40,
              isComplete: true,
              sessionId: 'sess-past',
            ),
          ],
        ),
      );

      final sessionDate = DateTime(2026, 3, 5, 12);
      final session = WorkoutSession(
        id: 'sess-new',
        workoutId: 'w1',
        date: sessionDate,
        entries: [
          WorkoutEntry(
            id: 'ne1',
            exerciseId: 'e1',
            reps: 5,
            weight: 45,
            isComplete: true,
            sessionId: 'sess-new',
          ),
          WorkoutEntry(
            id: 'ne2',
            exerciseId: 'e2',
            reps: 8,
            weight: 20,
            isComplete: true,
            sessionId: 'sess-new',
          ),
        ],
      );

      final allSetsByExercise = <String, List<Map<String, dynamic>>>{
        'e1': [
          {'reps': 5, 'weight': 45.0},
          {'reps': 5, 'weight': 45.0},
        ],
        'e2': [
          {'reps': 8, 'weight': 20.0},
        ],
      };

      await container.read(scorecardUpdateServiceProvider).onSessionCompleted(
            session: session,
            allSetsByExercise: allSetsByExercise,
            sessionExercises: _exercises(),
            sessionDuration: const Duration(minutes: 40),
            programId: null,
          );

      final scoreRepo = UserScorecardRepository(db);
      final updated = await scoreRepo.getScorecard();
      expect(updated, isNotNull);
      expect(updated!.lastUpdated, isNotNull);
      expect(updated.computedLevel, inInclusiveRange(1, 5));
    });

    test('onSessionCompleted with programId updates reliability when schedule matches',
        () async {
      final container = createTestContainer();
      await _waitForRestTimer(container);

      final programRepo = ProgramRepositoryImpl(db);
      final workoutId = 'scheduled-w';
      final scheduledDay = DateTime(2026, 3, 10);
      await programRepo.save(
        Program(
          id: 'prog-1',
          name: 'Test',
          schedule: [
            ProgramWorkout(workoutId: workoutId, scheduledDate: scheduledDay),
          ],
        ),
      );

      final sessionRepo = WorkoutSessionRepositoryImpl(db);
      await sessionRepo.save(
        WorkoutSession(
          id: 'sess-prev',
          workoutId: workoutId,
          date: scheduledDay.subtract(const Duration(days: 7)),
          entries: [
            WorkoutEntry(
              id: 'p1',
              exerciseId: 'e1',
              reps: 5,
              weight: 40,
              isComplete: true,
              sessionId: 'sess-prev',
            ),
          ],
        ),
      );

      final session = WorkoutSession(
        id: 'sess-today',
        workoutId: workoutId,
        date: DateTime(2026, 3, 10, 9),
        entries: [
          WorkoutEntry(
            id: 't1',
            exerciseId: 'e1',
            reps: 5,
            weight: 42,
            isComplete: true,
            sessionId: 'sess-today',
          ),
        ],
      );

      final sets = <String, List<Map<String, dynamic>>>{
        'e1': [
          {'reps': 5, 'weight': 42.0},
        ],
      };

      final before = await UserScorecardRepository(db).loadOrCreate();
      final reliabilityBefore = before.reliability;

      await container.read(scorecardUpdateServiceProvider).onSessionCompleted(
            session: session,
            allSetsByExercise: sets,
            sessionExercises: [_exercises().first],
            sessionDuration: const Duration(minutes: 30),
            programId: 'prog-1',
          );

      final after = await UserScorecardRepository(db).getScorecard();
      expect(after!.reliability, isNot(equals(reliabilityBefore)));
    });
  });
}
