import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/program_repository_impl.dart';
import 'package:fytter/src/domain/program.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late ProgramRepositoryImpl repo;

  setUp(() {
    // In-memory DB for isolation
    db = AppDatabase.test();
    repo = ProgramRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Save and findAll/findById round-trips correctly', () async {
    final prog = Program(
      id: 'p1',
      name: 'Full Body',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2025, 6, 1)),
        ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2025, 6, 3)),
      ],
    );
    await repo.save(prog);

    final all = await repo.findAll();
    expect(all, [prog]);

    final byId = await repo.findById('p1');
    expect(byId, prog);
  });

  test('Saving a program with the same ID replaces its schedule (upsert)', () async {
    final initial = Program(
      id: 'p2',
      name: 'Week 1',
      schedule: [
        ProgramWorkout(workoutId: 'w1', scheduledDate: DateTime(2025, 6, 1)),
      ],
    );
    await repo.save(initial);

    final updated = Program(
      id: 'p2',
      name: 'Week 1',
      schedule: [
        ProgramWorkout(workoutId: 'w2', scheduledDate: DateTime(2025, 6, 3)),
        ProgramWorkout(workoutId: 'w3', scheduledDate: DateTime(2025, 6, 5)),
      ],
    );
    await repo.save(updated);

    final all = await repo.findAll();
    expect(all, [updated]);

    final fetched = await repo.findById('p2');
    expect(fetched.schedule.map((e) => e.workoutId).toList(), ['w2', 'w3']);
  });

  test('delete() removes the program and its schedule', () async {
    final prog = Program(
      id: 'p3',
      name: 'Solo',
      schedule: [
        ProgramWorkout(workoutId: 'w4', scheduledDate: DateTime(2025, 6, 7)),
      ],
    );
    await repo.save(prog);

    // remove prog
    await repo.delete('p3');

    final remaining = await repo.findAll();
    expect(remaining, isEmpty);

    // findById should now throw because prog is gone
    expect(() => repo.findById('p3'), throwsA(isA<StateError>()));
  });
}