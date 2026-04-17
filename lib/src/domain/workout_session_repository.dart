import 'package:fytter/src/domain/workout_session.dart';

/// Defines CRUD operations for WorkoutSession objects.
abstract class WorkoutSessionRepository {
  /// Returns all workout sessions, ordered by date (most recent first).
  Future<List<WorkoutSession>> findAll();

  /// Finds a workout session by its unique [id].
  Future<WorkoutSession?> findById(String id);

  /// Saves (inserts or updates) a workout session.
  Future<void> save(WorkoutSession session);

  /// Deletes the workout session with the given [id].
  Future<void> delete(String id);
}
