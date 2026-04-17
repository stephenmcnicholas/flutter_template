import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/data/app_database.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test(); // in-memory DB
  });
  tearDown(() async {
    await db.close();
  });

  test('seedInitialDataFromString loads exercises from seed file', () async {
    // Read the JSON file directly
    final seedJson = File('assets/exercises/exercises.json').readAsStringSync();
    await db.seedInitialDataFromString(seedJson);

    final all = await db.getAllExercises();
    // Verify that exercises were loaded (the seed file contains many exercises)
    expect(all.length, greaterThan(0));
    // Verify that exercises have the expected structure
    expect(all.first.id, isNotEmpty);
    expect(all.first.name, isNotEmpty);
  });
}