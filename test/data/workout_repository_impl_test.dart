import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/workout_repository_impl.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_entry.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late WorkoutRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.test();                // in-memory DB
    repo = WorkoutRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Initially, findAll returns empty list', () async {
    final all = await repo.findAll();
    expect(all, isEmpty);
  });

  test('Save and findAll/findById round-trips correctly', () async {
    final workout = Workout(
      id: 'w1',
      name: 'Day 1',
      entries: [
        WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 10, weight: 100, isComplete: false, timestamp: null),
        WorkoutEntry(id: 'e2', exerciseId: 'ex2', reps: 8, weight: 80, isComplete: false, timestamp: null),
      ],
    );

    await repo.save(workout);

    final all = await repo.findAll();
    expect(all, [workout]);

    final byId = await repo.findById('w1');
    expect(byId, workout);
  });
 
  test('Saving a workout with the same ID replaces its entries (upsert)', () async {
    final first = Workout(
      id: 'w1',
      name: 'Day 1',
      entries: [
        WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 10, weight: 100, isComplete: false, timestamp: null),
      ],
    );
    await repo.save(first);

    final updated = Workout(
      id: 'w1',
      name: 'Day 1',
      entries: [
        WorkoutEntry(id: 'e2', exerciseId: 'ex2', reps: 8, weight: 80, isComplete: false, timestamp: null),
        WorkoutEntry(id: 'e3', exerciseId: 'ex3', reps: 12, weight: 60, isComplete: false, timestamp: null),
      ],
    );
    await repo.save(updated);

    final all = await repo.findAll();
    expect(all, [updated]);

    final fetched = await repo.findById('w1');
    expect(fetched.entries.map((e) => e.id).toList(), ['e2', 'e3']);
  });

  test('delete() removes the workout and its entries', () async {
    final w1 = Workout(
      id: 'w1',
      name: 'W1',
      entries: [
        WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 10, weight: 100, isComplete: false, timestamp: null),
      ],
    );
    final w2 = Workout(
      id: 'w2',
      name: 'W2',
      entries: [
        WorkoutEntry(id: 'e2', exerciseId: 'ex2', reps: 8, weight: 80, isComplete: false, timestamp: null),
      ],
    );
    await repo.save(w1);
    await repo.save(w2);

    // remove w1
    await repo.delete('w1');

    final remaining = await repo.findAll();
    expect(remaining, [w2]);

    // findById should now throw because w1 is gone
    expect(() => repo.findById('w1'), throwsA(isA<StateError>()));
  });
}