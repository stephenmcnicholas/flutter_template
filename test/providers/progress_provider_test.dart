import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fytter/src/providers/progress_provider.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout_session_repository.dart';

// Mock repository for workout sessions
class MockWorkoutSessionRepository implements WorkoutSessionRepository {
  final List<WorkoutSession> _sessions;

  MockWorkoutSessionRepository(this._sessions);

  @override
  Future<List<WorkoutSession>> findAll() async {
    // Sort by date descending (most recent first) to match real repository behavior
    final sorted = List<WorkoutSession>.from(_sessions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  @override
  Future<WorkoutSession?> findById(String id) async => 
      _sessions.firstWhere((s) => s.id == id, orElse: () => throw Exception('Not found'));

  @override
  Future<void> save(WorkoutSession session) async {}

  @override
  Future<void> delete(String id) async {}
}

void main() {
  group('exerciseProgressProvider', () {
    test('aggregates sets by exercise from workout sessions', () async {
      final exercises = [
        const Exercise(id: 'ex1', name: 'Squat', description: ''),
        const Exercise(id: 'ex2', name: 'Bench Press', description: ''),
      ];

      final sessions = [
        WorkoutSession(
          id: 's1',
          workoutId: 'w1',
          date: DateTime(2024, 1, 1),
          name: 'Workout 1',
          entries: [
            WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 5, weight: 100, isComplete: true),
            WorkoutEntry(id: 'e2', exerciseId: 'ex1', reps: 5, weight: 105, isComplete: true),
          ],
        ),
        WorkoutSession(
          id: 's2',
          workoutId: 'w2',
          date: DateTime(2024, 1, 2),
          name: 'Workout 2',
          entries: [
            WorkoutEntry(id: 'e3', exerciseId: 'ex2', reps: 8, weight: 80, isComplete: true),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          exercisesFutureProvider.overrideWith((_) async => exercises),
          workoutSessionRepositoryProvider.overrideWith(
            (_) => MockWorkoutSessionRepository(sessions),
          ),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      final result = await container.read(exerciseProgressProvider.future);

      expect(result, hasLength(2));
      expect(result[0].exerciseId, 'ex1');
      expect(result[0].exerciseName, 'Squat');
      expect(result[0].sets, hasLength(2));
      expect(result[0].sets[0].weight, 100);
      expect(result[0].sets[1].weight, 105);

      expect(result[1].exerciseId, 'ex2');
      expect(result[1].exerciseName, 'Bench Press');
      expect(result[1].sets, hasLength(1));
      expect(result[1].sets[0].weight, 80);
    });

    test('sorts sets by date', () async {
      final exercises = [
        const Exercise(id: 'ex1', name: 'Squat', description: ''),
      ];

      final sessions = [
        WorkoutSession(
          id: 's2',
          workoutId: 'w2',
          date: DateTime(2024, 1, 2),
          name: 'Workout 2',
          entries: [
            WorkoutEntry(id: 'e2', exerciseId: 'ex1', reps: 5, weight: 105, isComplete: true),
          ],
        ),
        WorkoutSession(
          id: 's1',
          workoutId: 'w1',
          date: DateTime(2024, 1, 1),
          name: 'Workout 1',
          entries: [
            WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 5, weight: 100, isComplete: true),
          ],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          exercisesFutureProvider.overrideWith((_) async => exercises),
          workoutSessionRepositoryProvider.overrideWith(
            (_) => MockWorkoutSessionRepository(sessions),
          ),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      final result = await container.read(exerciseProgressProvider.future);

      expect(result[0].sets[0].date, DateTime(2024, 1, 1));
      expect(result[0].sets[1].date, DateTime(2024, 1, 2));
    });
  });

  group('workoutFrequencyProvider', () {
    test('calculates workouts per day', () async {
      // Sessions should be sorted most recent first (as workoutSessionsProvider does)
      final sessions = [
        WorkoutSession(
          id: 's3',
          workoutId: 'w3',
          date: DateTime(2024, 1, 2, 10, 0),
          name: 'Workout',
          entries: [],
        ),
        WorkoutSession(
          id: 's2',
          workoutId: 'w2',
          date: DateTime(2024, 1, 1, 18, 0),
          name: 'Evening Workout',
          entries: [],
        ),
        WorkoutSession(
          id: 's1',
          workoutId: 'w1',
          date: DateTime(2024, 1, 1, 10, 0),
          name: 'Morning Workout',
          entries: [],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWith(
            (_) => MockWorkoutSessionRepository(sessions),
          ),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      final result = await container.read(workoutFrequencyProvider.future);

      expect(result.totalWorkouts, 3);
      expect(result.workoutsPerDay[DateTime(2024, 1, 1)], 2);
      expect(result.workoutsPerDay[DateTime(2024, 1, 2)], 1);
    });

    test('handles empty sessions', () async {
      final container = ProviderContainer(
        overrides: [
          workoutSessionRepositoryProvider.overrideWith(
            (_) => MockWorkoutSessionRepository([]),
          ),
        ],
      );

      await container.read(workoutSessionsProvider.future);
      final result = await container.read(workoutFrequencyProvider.future);

      expect(result.totalWorkouts, 0);
      expect(result.workoutsPerDay, isEmpty);
      expect(result.averageWorkoutsPerWeek, 0.0);
    });
  });

  group('programStatsProvider', () {
    test('returns program statistics', () async {
      final programs = [
        Program(
          id: 'p1',
          name: 'Program 1',
          schedule: [
            ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2024, 1, 1)),
            ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2024, 1, 2)),
          ],
        ),
        Program(
          id: 'p2',
          name: 'Program 2',
          schedule: [
            ProgramWorkout(workoutId: 'w3', scheduledDate: DateTime(2024, 1, 3)),
          ],
        ),
      ];
      final sessions = [
        WorkoutSession(
          id: 's1',
          workoutId: 'w1',
          date: DateTime(2024, 1, 1, 8, 0),
          entries: const [],
        ),
        WorkoutSession(
          id: 's2',
          workoutId: 'w3',
          date: DateTime(2024, 1, 3, 18, 0),
          entries: const [],
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          programsFutureProvider.overrideWith((_) async => programs),
          workoutSessionRepositoryProvider.overrideWith(
            (_) => MockWorkoutSessionRepository(sessions),
          ),
        ],
      );

      final result = await container.read(programStatsProvider.future);

      expect(result.totalPrograms, 2);
      expect(result.completedPrograms, 2);
      expect(result.completionRate, closeTo(2 / 3, 0.0001));
      expect(result.programCompletionStats, hasLength(2));
      final program1 = result.programCompletionStats
          .firstWhere((stat) => stat.programName == 'Program 1');
      final program2 = result.programCompletionStats
          .firstWhere((stat) => stat.programName == 'Program 2');
      expect(program1.completedCount, 1);
      expect(program1.totalCount, 2);
      expect(DateFormat.yMMMd().format(program1.startDate!), 'Jan 1, 2024');
      expect(program2.completedCount, 1);
      expect(program2.totalCount, 1);
      expect(DateFormat.yMMMd().format(program2.startDate!), 'Jan 3, 2024');
    });

    test('handles empty programs list', () async {
      final container = ProviderContainer(
        overrides: [
          programsFutureProvider.overrideWith((_) async => []),
          workoutSessionRepositoryProvider.overrideWith(
            (_) => MockWorkoutSessionRepository([]),
          ),
        ],
      );

      final result = await container.read(programStatsProvider.future);

      expect(result.totalPrograms, 0);
      expect(result.completedPrograms, 0);
      expect(result.completionRate, 0.0);
      expect(result.programCompletionStats, isEmpty);
    });
  });
} 