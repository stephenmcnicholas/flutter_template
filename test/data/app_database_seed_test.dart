import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Initialize binding so rootBundle.loadString() works in tests.
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('AppDatabase seedInitialDataFromString', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('inserts items from JSON string', () async {
      const jsonString = '''
        [
          {"id": "x", "name": "X", "description": "Desc X"},
          {"id": "y", "name": "Y", "description": null}
        ]
      ''';

      await db.seedInitialDataFromString(jsonString);
      final all = await db.getAllExercises();

      expect(all.map((e) => e.id).toList(), ['x', 'y']);
      expect(all.map((e) => e.name).toList(), ['X', 'Y']);
      // null description should default to ''
      expect(all.map((e) => e.description).toList(), ['Desc X', '']);
    });

    test('seedInitialData updates existing exercises and adds new ones if DB not empty', () async {
      // Pre-insert a single record
      final comp = ExercisesCompanion(
        id: Value('a'),
        name: Value('A'),
        description: Value('D'),
      );
      await db.insertExercise(comp);

      // Now call the normal seed (which reads assets) — it should update existing and add new exercises
      await db.seedInitialData();
      final all = await db.getAllExercises();
      // Should have the original exercise plus all exercises from the bundled seed file
      expect(all.length, greaterThan(1));
      // Verify the original exercise still exists
      final original = all.firstWhere((e) => e.id == 'a');
      expect(original.id, 'a');
    });
  });
}