import 'package:fytter/src/domain/workout_entry.dart';

/// Defines CRUD operations for WorkoutEntries.
abstract class WorkoutEntryRepository {
  /// Returns all workout entries.
  Future<List<WorkoutEntry>> findAll();

  /// Finds entries for a given exercise.
  Future<List<WorkoutEntry>> findByExercise(String exerciseId);

  /// Adds or updates a workout entry.
  Future<void> save(WorkoutEntry entry);

  /// Deletes the workout entry with the given [id].
  Future<void> delete(String id);
}