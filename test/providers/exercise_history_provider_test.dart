import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/domain/workout_session_repository.dart';

// A simple in-memory mock for testing
class MockWorkoutSessionRepository implements WorkoutSessionRepository {
  final Map<String, WorkoutSession> _store = {};

  @override
  Future<List<WorkoutSession>> findAll() async {
    final sessions = _store.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  @override
  Future<WorkoutSession?> findById(String id) async {
    return _store[id];
  }

  @override
  Future<void> save(WorkoutSession session) async {
    _store[session.id] = session;
  }

  @override
  Future<void> delete(String id) async {
    _store.remove(id);
  }
}

void main() {
  late MockWorkoutSessionRepository mockRepo;
  late WorkoutSession session1;
  late WorkoutSession session2;
  late WorkoutSession session3;
  const String exerciseId1 = 'ex1'; // Squat
  const String exerciseId2 = 'ex2'; // Bench Press

  setUp(() {
    mockRepo = MockWorkoutSessionRepository();

    // Session 1: Contains exercise1 (Squat) - one set
    session1 = WorkoutSession(
      id: 's1',
      workoutId: 'w1',
      date: DateTime(2024, 1, 6, 13, 19),
      name: 'Test Workout #1',
      entries: [
        WorkoutEntry(
          id: 'e1',
          exerciseId: exerciseId1,
          reps: 5,
          weight: 60.0,
          isComplete: true,
          timestamp: DateTime(2024, 1, 6, 13, 19),
        ),
      ],
    );

    // Session 2: Contains exercise1 (Squat) - multiple sets
    session2 = WorkoutSession(
      id: 's2',
      workoutId: 'w1',
      date: DateTime(2024, 1, 6, 13, 21),
      name: 'Test Workout #1',
      entries: [
        WorkoutEntry(
          id: 'e2',
          exerciseId: exerciseId1,
          reps: 5,
          weight: 65.0,
          isComplete: true,
          timestamp: DateTime(2024, 1, 6, 13, 21),
        ),
        WorkoutEntry(
          id: 'e3',
          exerciseId: exerciseId1,
          reps: 5,
          weight: 72.0,
          isComplete: true,
          timestamp: DateTime(2024, 1, 6, 13, 21),
        ),
      ],
    );

    // Session 3: Contains exercise2 (Bench Press) - one set
    session3 = WorkoutSession(
      id: 's3',
      workoutId: 'w2',
      date: DateTime(2024, 1, 6, 14, 0),
      name: 'Push Day',
      entries: [
        WorkoutEntry(
          id: 'e4',
          exerciseId: exerciseId2,
          reps: 8,
          weight: 80.0,
          isComplete: true,
          timestamp: DateTime(2024, 1, 6, 14, 0),
        ),
      ],
    );
  });

  group('exerciseWorkoutCountProvider', () {
    test('counts unique workout sessions per exercise', () async {
      await mockRepo.save(session1);
      await mockRepo.save(session2);
      await mockRepo.save(session3);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final counts = await container.read(exerciseWorkoutCountProvider.future);
      
      // exerciseId1 (Squat) appears in 2 sessions (s1 and s2)
      expect(counts[exerciseId1], 2);
      // exerciseId2 (Bench Press) appears in 1 session (s3)
      expect(counts[exerciseId2], 1);
    });

    test('counts correctly when exercise appears multiple times in same session', () async {
      // Session with multiple sets of same exercise
      await mockRepo.save(session2);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final counts = await container.read(exerciseWorkoutCountProvider.future);
      
      // exerciseId1 appears in 1 session (even though it has 2 sets)
      expect(counts[exerciseId1], 1);
    });

    test('returns empty map when no sessions exist', () async {
      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final counts = await container.read(exerciseWorkoutCountProvider.future);
      expect(counts, isEmpty);
    });

    test('returns 0 for exercises not in any session', () async {
      await mockRepo.save(session1);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final counts = await container.read(exerciseWorkoutCountProvider.future);
      expect(counts['nonexistent-exercise'], isNull);
    });
  });

  group('exerciseHistoryProvider', () {
    test('returns all sessions containing the exercise', () async {
      await mockRepo.save(session1);
      await mockRepo.save(session2);
      await mockRepo.save(session3);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final history = await container.read(exerciseHistoryProvider(exerciseId1).future);
      
      // Should return 2 sessions (s1 and s2) containing exerciseId1
      expect(history.length, 2);
      expect(history[0].session.id, 's2'); // Most recent first
      expect(history[1].session.id, 's1');
    });

    test('returns all entries for the exercise in each session', () async {
      await mockRepo.save(session2); // Has 2 sets of exerciseId1

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final history = await container.read(exerciseHistoryProvider(exerciseId1).future);
      
      expect(history.length, 1);
      expect(history[0].entries.length, 2);
      expect(history[0].entries[0].weight, 65.0);
      expect(history[0].entries[1].weight, 72.0);
    });

    test('filters out entries for other exercises', () async {
      await mockRepo.save(session1);
      await mockRepo.save(session3);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final history = await container.read(exerciseHistoryProvider(exerciseId1).future);
      
      // Should only return session1 (contains exerciseId1)
      // session3 contains exerciseId2, so should be excluded
      expect(history.length, 1);
      expect(history[0].session.id, 's1');
      expect(history[0].entries.length, 1);
      expect(history[0].entries[0].exerciseId, exerciseId1);
    });

    test('returns empty list when exercise not in any session', () async {
      await mockRepo.save(session1);
      await mockRepo.save(session3);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final history = await container.read(exerciseHistoryProvider('nonexistent-exercise').future);
      expect(history, isEmpty);
    });

    test('returns sessions sorted by date (most recent first)', () async {
      await mockRepo.save(session1);
      await mockRepo.save(session2);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final history = await container.read(exerciseHistoryProvider(exerciseId1).future);
      
      expect(history.length, 2);
      // Most recent first (s2 at 13:21, then s1 at 13:19)
      expect(history[0].session.date, session2.date);
      expect(history[1].session.date, session1.date);
    });

    test('returns empty list when no sessions exist', () async {
      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final history = await container.read(exerciseHistoryProvider(exerciseId1).future);
      expect(history, isEmpty);
    });
  });

  group('lastRecordedValuesProvider', () {
    test('returns last recorded values for repsAndWeight exercise', () async {
      await mockRepo.save(session2); // Most recent session with exerciseId1

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final lastValues = await container.read(lastRecordedValuesProvider(exerciseId1).future);
      
      expect(lastValues, isNotNull);
      expect(lastValues!.reps, 5); // From last entry in session2
      expect(lastValues.weight, 72.0); // From last entry in session2 (most recently recorded set)
      expect(lastValues.distance, isNull);
      expect(lastValues.duration, isNull);
    });

    test('returns null when exercise has no history', () async {
      await mockRepo.save(session1);
      await mockRepo.save(session3);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final lastValues = await container.read(lastRecordedValuesProvider('nonexistent-exercise').future);
      expect(lastValues, isNull);
    });

    test('returns values from most recent session', () async {
      await mockRepo.save(session1); // Older: 60.0 kg
      await mockRepo.save(session2); // Newer: 65.0 kg (first entry), 72.0 kg (last entry)

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final lastValues = await container.read(lastRecordedValuesProvider(exerciseId1).future);
      
      expect(lastValues, isNotNull);
      // Should use most recent session (session2) and most recent set (last entry: 72.0 kg)
      expect(lastValues!.weight, 72.0);
    });

    test('returns last set from most recent session when multiple sets exist', () async {
      // Create a session with multiple sets for the same exercise
      final multiSetSession = WorkoutSession(
        id: 's6',
        workoutId: 'w5',
        date: DateTime(2024, 1, 8, 10, 0),
        name: 'Test Multi-Set',
        entries: [
          WorkoutEntry(
            id: 'e7',
            exerciseId: exerciseId1,
            reps: 5,
            weight: 65.0,
            isComplete: true,
            timestamp: DateTime(2024, 1, 8, 10, 0),
          ),
          WorkoutEntry(
            id: 'e8',
            exerciseId: exerciseId1,
            reps: 5,
            weight: 72.0, // This should be returned (last set)
            isComplete: true,
            timestamp: DateTime(2024, 1, 8, 10, 0),
          ),
        ],
      );
      await mockRepo.save(multiSetSession);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final lastValues = await container.read(lastRecordedValuesProvider(exerciseId1).future);
      
      expect(lastValues, isNotNull);
      // Should return the LAST set (72.0 kg), not the first set (65.0 kg)
      expect(lastValues!.weight, 72.0);
      expect(lastValues.reps, 5);
    });

    test('returns duration for time-based exercise', () async {
      final timeSession = WorkoutSession(
        id: 's4',
        workoutId: 'w3',
        date: DateTime(2024, 1, 7, 10, 0),
        name: 'Cardio',
        entries: [
          WorkoutEntry(
            id: 'e5',
            exerciseId: 'plank',
            reps: 0,
            weight: 0.0,
            duration: 58, // 0:58
            isComplete: true,
            timestamp: DateTime(2024, 1, 7, 10, 0),
          ),
        ],
      );
      await mockRepo.save(timeSession);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final lastValues = await container.read(lastRecordedValuesProvider('plank').future);
      
      expect(lastValues, isNotNull);
      expect(lastValues!.duration, 58);
      expect(lastValues.reps, 0);
      expect(lastValues.weight, 0.0);
    });

    test('returns distance and duration for distanceAndTime exercise', () async {
      final runningSession = WorkoutSession(
        id: 's5',
        workoutId: 'w4',
        date: DateTime(2024, 1, 7, 11, 0),
        name: 'Running',
        entries: [
          WorkoutEntry(
            id: 'e6',
            exerciseId: 'running',
            reps: 0,
            weight: 0.0,
            distance: 5.5,
            duration: 1800, // 30:00
            isComplete: true,
            timestamp: DateTime(2024, 1, 7, 11, 0),
          ),
        ],
      );
      await mockRepo.save(runningSession);

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final lastValues = await container.read(lastRecordedValuesProvider('running').future);
      
      expect(lastValues, isNotNull);
      expect(lastValues!.distance, 5.5);
      expect(lastValues.duration, 1800);
      expect(lastValues.reps, 0);
      expect(lastValues.weight, 0.0);
    });

    test('hasValues returns true when any value is present', () {
      final values = LastRecordedValues(reps: 5);
      expect(values.hasValues, isTrue);
    });

    test('hasValues returns false when all values are null', () {
      const values = LastRecordedValues();
      expect(values.hasValues, isFalse);
    });
  });
}

