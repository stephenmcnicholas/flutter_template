import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/workout_session_repository_impl.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late WorkoutSessionRepositoryImpl repo;
  late WorkoutSession sessionA;
  late WorkoutSession sessionB;

  setUp(() {
    repo = WorkoutSessionRepositoryImpl(AppDatabase.test());

    sessionA = WorkoutSession(
      id: 's1',
      workoutId: 'w1',
      date: DateTime.utc(2024, 5, 20, 8, 0, 0),
      name: 'Push Day',
      notes: 'Felt good',
      entries: [
        WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 10, weight: 100, isComplete: false, timestamp: null),
      ],
    );
    sessionB = WorkoutSession(
      id: 's2',
      workoutId: 'w2',
      date: DateTime.utc(2024, 5, 21, 8, 0, 0),
      name: 'Pull Day',
      notes: 'Tough',
      entries: [
        WorkoutEntry(id: 'e2', exerciseId: 'ex2', reps: 8, weight: 80, isComplete: false, timestamp: null),
      ],
    );
  });

  test('save and findAll/findById', () async {
    await repo.save(sessionA);
    await repo.save(sessionB);

    final all = await repo.findAll();
    expect(all, containsAll([sessionA, sessionB]));

    final foundA = await repo.findById('s1');
    expect(foundA, sessionA);
    final foundB = await repo.findById('s2');
    expect(foundB, sessionB);
  });

  test('delete removes session', () async {
    await repo.save(sessionA);
    await repo.save(sessionB);
    await repo.delete('s1');
    final all = await repo.findAll();
    expect(all, [sessionB]);
    expect(await repo.findById('s1'), isNull);
  });

  test('save overwrites existing session with same id', () async {
    await repo.save(sessionA);
    final db = AppDatabase.test();
    db.delete(db.workoutEntries).where((e) => e.sessionId.equals('s1'));
    final updated = WorkoutSession(
      id: 's1',
      workoutId: 'w1',
      date: DateTime.utc(2024, 5, 20, 8, 0, 0),
      name: 'Push Day',
      notes: 'Updated',
      entries: [
        WorkoutEntry(id: 'e1', exerciseId: 'ex1', reps: 12, weight: 110, isComplete: false, timestamp: null),
      ],
    );
    await repo.save(updated);
    final found = await repo.findById('s1');
    expect(found, updated);
  });

  test('can save different sessions with entries having unique ids', () async {
    // Each session has entries with unique IDs (as would be the case with UUIDs)
    final entryA = WorkoutEntry(id: 'entry1', exerciseId: 'ex1', reps: 10, weight: 100, isComplete: false, timestamp: null);
    final entryB = WorkoutEntry(id: 'entry2', exerciseId: 'ex2', reps: 8, weight: 80, isComplete: false, timestamp: null);

    final session1 = WorkoutSession(
      id: 's1',
      workoutId: 'w1',
      date: DateTime.utc(2024, 5, 20, 8, 0, 0),
      name: 'Push Day',
      notes: 'First',
      entries: [entryA],
    );
    final session2 = WorkoutSession(
      id: 's2',
      workoutId: 'w2',
      date: DateTime.utc(2024, 5, 21, 8, 0, 0),
      name: 'Pull Day',
      notes: 'Second',
      entries: [entryB],
    );

    await repo.save(session1);
    await repo.save(session2);

    // Both sessions should be saved, and no UNIQUE constraint error should occur
    final all = await repo.findAll();
    expect(all.length, 2);
    final sessionIds = all.map((s) => s.id).toSet();
    expect(sessionIds, containsAll(['s1', 's2']));

    // Both entries should exist since they have unique IDs
    final entries = all.expand((s) => s.entries).toList();
    expect(entries.length, 2);
    expect(entries.map((e) => e.id).toSet(), containsAll(['entry1', 'entry2']));
    expect(entries.first.exerciseId, 'ex2');
  });
}
