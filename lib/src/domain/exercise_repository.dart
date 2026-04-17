import 'package:fytter/src/domain/exercise.dart';

/// Defines CRUD operations for Exercises.
abstract class ExerciseRepository {
  /// Returns all saved exercises.
  Future<List<Exercise>> findAll();

  /// Finds a single exercise by its [id], or throws if not found.
  Future<Exercise> findById(String id);

  /// Adds a new exercise or updates an existing one.
  Future<void> save(Exercise exercise);

  /// Deletes the exercise with the given [id].
  Future<void> delete(String id);
}