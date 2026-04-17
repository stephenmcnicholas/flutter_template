import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_session_repository.dart';
import 'package:fytter/src/data/workout_session_repository_impl.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  drift.driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late WorkoutSessionRepository repo;
  late WorkoutSession session1;
  late WorkoutSession session2;

  setUp(() {
    repo = WorkoutSessionRepositoryImpl(AppDatabase.test());

    final entry1 = WorkoutEntry(
      id: 'e1',
      exerciseId: 'squat',
      reps: 5,
      weight: 100.0,
      isComplete: false,
      timestamp: DateTime.utc(2024, 5, 20, 8, 0, 0),
    );
    final entry2 = WorkoutEntry(
      id: 'e2',
      exerciseId: 'bench',
      reps: 8,
      weight: 60.0,
      isComplete: false,
      timestamp: DateTime.utc(2024, 5, 20, 8, 10, 0),
    );

    session1 = WorkoutSession(
      id: 's1',
      workoutId: 'w1',
      date: DateTime.utc(2024, 5, 20, 8, 0, 0),
      name: 'Push Day',
      notes: 'Felt good',
      entries: [entry1],
    );
    session2 = WorkoutSession(
      id: 's2',
      workoutId: 'w2',
      date: DateTime.utc(2024, 5, 21, 8, 0, 0),
      name: 'Pull Day',
      notes: 'Tough',
      entries: [entry2],
    );
  });

  test('save and findById', () async {
    await repo.save(session1);
    final found = await repo.findById('s1');
    // print('EXPECTED: ' + session1.toString());
    // print('ACTUAL:   ' + found.toString());
    expect(found, equals(session1));
  });

  test('findAll returns all sessions, most recent first', () async {
    await repo.save(session1);
    await repo.save(session2);
    final all = await repo.findAll();
    // print('ALL SESSIONS: ' + all.toString());
    expect(all.length, 2);
    expect(all.first, equals(session2)); // Most recent first
    expect(all.last, equals(session1));
  });

  test('delete removes a session', () async {
    await repo.save(session1);
    await repo.save(session2);
    await repo.delete('s1');
    final all = await repo.findAll();
    expect(all.length, 1);
    expect(all.first, equals(session2));
    final deleted = await repo.findById('s1');
    expect(deleted, isNull);
  });

  test('findById returns null for missing session', () async {
    final missing = await repo.findById('does-not-exist');
    expect(missing, isNull);
  });
}
