import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/workout_entry_repository_impl.dart';
import 'package:fytter/src/domain/workout_entry.dart';

void main() {
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late WorkoutEntryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.test();
    repo = WorkoutEntryRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('save and findAll/findByExercise round-trips correctly', () async {
    final entry = WorkoutEntry(
      id: 'e1',
      exerciseId: 'ex1',
      reps: 10,
      weight: 100,
      isComplete: false,
      timestamp: null,
    );
    await repo.save(entry);

    final all = await repo.findAll();
    expect(all, [entry]);

    final byExercise = await repo.findByExercise('ex1');
    expect(byExercise, [entry]);
  });

  test('save and findAll round-trips distance and duration fields', () async {
    final entry = WorkoutEntry(
      id: 'e1',
      exerciseId: 'ex1',
      reps: 0,
      weight: 0.0,
      distance: 5.0,
      duration: 1800,
      isComplete: false,
      timestamp: null,
    );
    await repo.save(entry);

    final all = await repo.findAll();
    expect(all.length, 1);
    expect(all.first.distance, 5.0);
    expect(all.first.duration, 1800);
  });

  test('save handles null distance and duration', () async {
    final entry = WorkoutEntry(
      id: 'e1',
      exerciseId: 'ex1',
      reps: 10,
      weight: 100.0,
      distance: null,
      duration: null,
      isComplete: false,
      timestamp: null,
    );
    await repo.save(entry);

    final all = await repo.findAll();
    expect(all.length, 1);
    expect(all.first.distance, isNull);
    expect(all.first.duration, isNull);
  });

  test('save overwrites existing entry with same id', () async {
    final entry = WorkoutEntry(
      id: 'e1',
      exerciseId: 'ex1',
      reps: 10,
      weight: 100,
      isComplete: false,
      timestamp: null,
    );
    await repo.save(entry);
    final updated = WorkoutEntry(
      id: 'e1',
      exerciseId: 'ex1',
      reps: 12,
      weight: 110,
      isComplete: false,
      timestamp: null,
    );
    await repo.save(updated);
    final all = await repo.findAll();
    expect(all, [updated]);
  });

  test('delete removes entry', () async {
    final entry = WorkoutEntry(
      id: 'e1',
      exerciseId: 'ex1',
      reps: 10,
      weight: 100,
      isComplete: false,
      timestamp: null,
    );
    await repo.save(entry);
    await repo.delete('e1');
    final all = await repo.findAll();
    expect(all, isEmpty);
  });
}