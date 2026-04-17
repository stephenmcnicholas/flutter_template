import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_repository.dart';

/// Concrete [WorkoutRepository] backed by Drift.
class WorkoutRepositoryImpl implements WorkoutRepository {
  final AppDatabase _db;

  WorkoutRepositoryImpl(this._db);

  @override
  Future<List<Workout>> findAll() async {
    final rows = await _db.select(_db.workouts).get();
    final result = <Workout>[];

    for (final row in rows) {
      // Pull out the ordered entries for this workout:
      final entryRows = await (_db.select(_db.workoutExercises)
            ..where((t) => t.workoutId.equals(row.id))
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .get();

      final entries = entryRows.map((e) => WorkoutEntry(
        id: e.id,
        exerciseId: e.exerciseId,
        reps: e.reps,
        weight: e.weight,
        distance: e.distance,
        duration: e.duration,
        isComplete: false,
        timestamp: e.timestamp, // may be null for templates
        supersetGroupId: e.supersetGroupId,
      )).toList();

      result.add(Workout(id: row.id, name: row.name, entries: entries));
    }

    return result;
  }

  @override
  Future<Workout> findById(String id) async {
    final row = await (_db.select(_db.workouts)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final entryRows = await (_db.select(_db.workoutExercises)
          ..where((t) => t.workoutId.equals(id))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();

    final entries = entryRows.map((e) => WorkoutEntry(
      id: e.id,
      exerciseId: e.exerciseId,
      reps: e.reps,
      weight: e.weight,
      distance: e.distance,
      duration: e.duration,
      isComplete: false,
      timestamp: e.timestamp,
      supersetGroupId: e.supersetGroupId,
    )).toList();

    return Workout(id: row.id, name: row.name, entries: entries);
  }

  @override
  Future<void> save(Workout workout) async {
    // 1) Upsert the workout record itself
    await _db.into(_db.workouts).insertOnConflictUpdate(
      WorkoutsCompanion(
        id: Value(workout.id),
        name: Value(workout.name),
      ),
    );

    // 2) Clear out any old mappings
    await (_db.delete(_db.workoutExercises)
          ..where((t) => t.workoutId.equals(workout.id)))
        .go();

    // 3) Re-insert each entry in order
    for (var i = 0; i < workout.entries.length; i++) {
      final entry = workout.entries[i];
      await _db.into(_db.workoutExercises).insert(
        WorkoutExercisesCompanion(
          id: Value(entry.id),
          workoutId: Value(workout.id),
          exerciseId: Value(entry.exerciseId),
          position: Value(i),
          reps: Value(entry.reps),
          weight: Value(entry.weight),
          distance: Value(entry.distance),
          duration: Value(entry.duration),
          timestamp: Value(entry.timestamp),
          supersetGroupId: Value(entry.supersetGroupId),
        ),
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    // Deleting the workout will cascade and remove the mappings
    await (_db.delete(_db.workouts)..where((t) => t.id.equals(id))).go();
  }
}