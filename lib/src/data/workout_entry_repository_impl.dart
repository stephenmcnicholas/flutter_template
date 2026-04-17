import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_entry_repository.dart';

/// Concrete implementation of [WorkoutEntryRepository] using Drift.
class WorkoutEntryRepositoryImpl implements WorkoutEntryRepository {
  final AppDatabase _db;
  WorkoutEntryRepositoryImpl(this._db);

  @override
  Future<List<WorkoutEntry>> findAll() async {
    final rows = await _db.select(_db.workoutEntries).get();
    return rows.map(_entityToDomain).toList();
  }

  @override
  Future<List<WorkoutEntry>> findByExercise(String exerciseId) async {
    final rows = await (_db.select(_db.workoutEntries)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();
    return rows.map(_entityToDomain).toList();
  }

  @override
  Future<void> save(WorkoutEntry entry) {
    final companion = WorkoutEntriesCompanion(
      id: Value(entry.id),
      exerciseId: Value(entry.exerciseId),
      reps: Value(entry.reps),
      weight: Value(entry.weight),
      distance: Value(entry.distance),
      duration: Value(entry.duration),
      isComplete: Value(entry.isComplete),
      timestamp: Value(entry.timestamp),
      sessionId: Value(entry.sessionId),
      setOutcome: Value(entry.setOutcome),
      supersetGroupId: Value(entry.supersetGroupId),
    );
    return _db.into(_db.workoutEntries).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> delete(String id) {
    return (_db.delete(_db.workoutEntries)..where((t) => t.id.equals(id)))
        .go();
  }

  WorkoutEntry _entityToDomain(WorkoutEntryEntity e) => WorkoutEntry(
        id: e.id,
        exerciseId: e.exerciseId,
        reps: e.reps,
        weight: e.weight,
        distance: e.distance,
        duration: e.duration,
        isComplete: e.isComplete,
        timestamp: e.timestamp,
        sessionId: e.sessionId,
        setOutcome: e.setOutcome,
        supersetGroupId: e.supersetGroupId,
      );
}