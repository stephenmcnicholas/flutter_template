import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/exercise_seed_version.dart';
import 'package:matcher/matcher.dart' as matcher;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize binding so rootBundle.loadString() works in tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.test(); // in-memory DB for isolation
  });

  tearDown(() async {
    await db.close();
  });

  test('can insert and read an Exercise', () async {
    final companion = ExercisesCompanion(
      id: Value('e1'),
      name: Value('Push-up'),
      description: Value('Bodyweight exercise'),
    );
    await db.insertExercise(companion);

    final all = await db.getAllExercises();
    expect(all, hasLength(1));
    expect(all.first.id, 'e1');
    expect(all.first.name, 'Push-up');
    expect(all.first.description, 'Bodyweight exercise');
  });

  test('returns empty list when no exercises inserted', () async {
    final all = await db.getAllExercises();
    expect(all, isEmpty);
  });

  test('schemaVersion is correct', () {
    expect(db.schemaVersion, 18);
  });

  test('can insert and read a WorkoutEntry', () async {
    final now = DateTime(2025, 5, 22, 12, 0);
    final entryComp = WorkoutEntriesCompanion(
      id: Value('w1'),
      exerciseId: Value('e1'),
      reps: Value(5),
      weight: Value(75.0),
      timestamp: Value(now),
      sessionId: Value('session1'),
    );
    await db.into(db.workoutEntries).insert(entryComp);

    final rows = await db.select(db.workoutEntries).get();
    expect(rows, hasLength(1));
    final row = rows.first;
    expect(row.id, 'w1');
    expect(row.exerciseId, 'e1');
    expect(row.reps, 5);
    expect(row.weight, 75.0);
    expect(row.timestamp, now);
    expect(row.sessionId, 'session1');
  });

  test('can insert and read a WorkoutEntry without sessionId (legacy)', () async {
    final entryComp = WorkoutEntriesCompanion(
      id: Value('w2'),
      exerciseId: Value('e2'),
      reps: Value(3),
      weight: Value(50.0),
      timestamp: Value(DateTime(2025, 5, 23)),
      // sessionId omitted
    );
    await db.into(db.workoutEntries).insert(entryComp);
    final rows = await db.select(db.workoutEntries).get();
    final row = rows.firstWhere((r) => r.id == 'w2');
    expect(row.sessionId, matcher.isNull);
  });

  test('seedInitialDataFromString inserts items', () async {
    const jsonString = '[{"id":"x","name":"X","description":"D","bodyPart":"Chest","equipment":"Barbell"}]';
    await db.seedInitialDataFromString(jsonString);

    final all = await db.getAllExercises();
    expect(all, hasLength(1));
    expect(all.first.id, 'x');
    expect(all.first.name, 'X');
    expect(all.first.description, 'D');
    expect(all.first.bodyPart, 'Chest');
    expect(all.first.equipment, 'Barbell');
  });

  test('seedInitialData seeds from bundled asset', () async {
    await db.seedInitialData();

    final all = await db.getAllExercises();
    expect(all.length, greaterThan(0)); // Just verify that exercises were seeded
  });

  test('seedInitialData persists exercises.json hash in SharedPreferences', () async {
    await db.seedInitialData();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kExercisesJsonAssetHashKey), isNotEmpty);
  });

  test('seedInitialData updates existing exercises if data already present', () async {
    const jsonString = '[{"id":"y","name":"Y","description":"Desc","bodyPart":"Chest","equipment":"Barbell"}]';
    await db.seedInitialDataFromString(jsonString);

    // Calling seed again should update existing exercises with bodyPart and equipment from seed file
    await db.seedInitialData();
    final all = await db.getAllExercises();
    // Should have the original exercise plus all exercises from the bundled seed file
    expect(all.length, greaterThan(1));
    // Verify the original exercise still exists
    final original = all.firstWhere((e) => e.id == 'y');
    expect(original.id, 'y');
  });

  test('default description is empty string when not provided', () async {
    final companion = ExercisesCompanion.insert(
      id: 'd1',
      name: 'Deadlift',
    );
    await db.insertExercise(companion);

    final all = await db.getAllExercises();
    expect(all, hasLength(1));
    expect(all.first.id, 'd1');
    expect(all.first.name, 'Deadlift');
    expect(all.first.description, '');
  });

  test('duplicate IDs in seedInitialDataFromString throw SqliteException', () async {
    const jsonString = '[{"id":"z","name":"Z","description":""}]';
    await db.seedInitialDataFromString(jsonString);
    // Second seed with same ID should violate PRIMARY KEY
    await expectLater(
      () => db.seedInitialDataFromString(jsonString),
      throwsA(isA<SqliteException>()),
    );
  });

  test('multiple items in seedInitialDataFromString are all inserted', () async {
    const jsonString = '''
      [
        {"id":"a","name":"A","description":""},
        {"id":"b","name":"B","description":""}
      ]
    ''';
    await db.seedInitialDataFromString(jsonString);

    final all = await db.getAllExercises();
    expect(all, hasLength(2));
    expect(all.map((e) => e.id), ['a', 'b']);
  });

  test('insertProgram and getAllPrograms', () async {
    await db.insertProgram(
      ProgramsCompanion.insert(
        id: 'prog1',
        name: 'My programme',
      ),
    );
    final programs = await db.getAllPrograms();
    expect(programs, hasLength(1));
    expect(programs.single.id, 'prog1');
    expect(programs.single.name, 'My programme');
  });

  test('insertWorkoutSession roundtrip', () async {
    final id = 'sess-1';
    await db.insertWorkoutSession(
      WorkoutSessionsCompanion.insert(
        id: id,
        workoutId: 'w1',
        date: DateTime(2025, 8, 1),
        name: const Value('Morning'),
      ),
    );
    final row = await db.getWorkoutSessionById(id);
    expect(row?.workoutId, 'w1');
    expect(row?.name, 'Morning');
  });
} 