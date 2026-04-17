import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_session_repository.dart';
import 'package:fytter/src/data/workout_session_repository_impl.dart';
import 'package:fytter/src/providers/data_providers.dart';

/// Provider for the WorkoutSessionRepository implementation.
/// Swap this with a real DB-backed implementation as needed.
final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>(
  (ref) {
    final db = ref.watch(appDatabaseProvider);
    return WorkoutSessionRepositoryImpl(db);
  },
);

/// Provider for the list of all workout sessions (most recent first).
final workoutSessionsProvider = FutureProvider<List<WorkoutSession>>((ref) {
  final repo = ref.watch(workoutSessionRepositoryProvider);
  return repo.findAll();
});

/// Provider for a single workout session by ID.
final workoutSessionByIdProvider =
    FutureProvider.family<WorkoutSession?, String>((ref, id) {
  final repo = ref.watch(workoutSessionRepositoryProvider);
  return repo.findById(id);
});
