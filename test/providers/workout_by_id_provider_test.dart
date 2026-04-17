import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/providers/workout_by_id_provider.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/domain/workout_repository.dart';

// Mock WorkoutRepository
class MockWorkoutRepository implements WorkoutRepository {
  @override
  Future<Workout> findById(String id) async {
    if (id == '1') {
      return Workout(
        id: 'w1',
        name: 'Push Day',
        entries: [
          WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 10, weight: 100, isComplete: false, timestamp: null),
          WorkoutEntry(id: 'e2', exerciseId: 'ex2', reps: 8, weight: 80, isComplete: false, timestamp: null),
        ],
      );
    } else if (id == '2') {
      return Workout(
        id: 'w2',
        name: 'Pull Day',
        entries: [
          WorkoutEntry(id: 'e3', exerciseId: 'ex3', reps: 12, weight: 60, isComplete: false, timestamp: null),
        ],
      );
    }
    throw Exception('Not found');
  }

  @override
  Future<List<Workout>> findAll() async => [];

  @override
  Future<void> save(Workout workout) async {}

  @override
  Future<void> delete(String id) async {}
}

void main() {
  test('workoutByIdProvider returns the correct workout for a given ID', () async {
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
      ],
    );

    final result = await container.read(workoutByIdProvider('1').future);

    expect(result, isA<Workout>());
    expect(result.id, 'w1');
    expect(result.name, 'Push Day');
  });

  test('workoutByIdProvider throws for missing workout', () async {
    final container = ProviderContainer(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
      ],
    );

    expect(
      () => container.read(workoutByIdProvider('999').future),
      throwsException,
    );
  });
}
