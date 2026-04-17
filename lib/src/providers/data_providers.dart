import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/data/exercise_repository_impl.dart';
import 'package:fytter/src/data/workout_entry_repository_impl.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/domain/exercise_repository.dart';
import 'package:fytter/src/domain/workout_entry_repository.dart';
import 'package:fytter/src/data/program_repository_impl.dart';
import 'package:fytter/src/domain/program_repository.dart';
import 'package:fytter/src/domain/workout_repository.dart';
import 'package:fytter/src/data/workout_repository_impl.dart';
import 'package:fytter/src/data/session_check_in_repository.dart';
import 'package:fytter/src/domain/session_check_in.dart';
import 'package:fytter/src/data/workout_adjustment_service.dart';
import 'package:fytter/src/domain/program.dart';

/// Provides a singleton [AppDatabase] instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  return db;
});

/// Provides an [ExerciseRepository] using Drift.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ExerciseRepositoryImpl(db);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WorkoutRepositoryImpl(db);
});

/// Provides a [WorkoutEntryRepository] using Drift.
final workoutEntryRepositoryProvider = Provider<WorkoutEntryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return WorkoutEntryRepositoryImpl(db);
});

/// A FutureProvider that seeds DB and returns all exercises.
final exercisesFutureProvider = FutureProvider<List<Exercise>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  await db.seedInitialData();
  final entities = await db.getAllExercises();
  return entities.map((e) => Exercise(
    id: e.id,
    name: e.name,
    description: e.description,
    thumbnailPath: e.thumbnailPath,
    mediaPath: e.mediaPath,
    bodyPart: e.bodyPart,
    equipment: e.equipment,
    loggingType: exerciseInputTypeFromJson(e.loggingType),
    movementPattern: movementPatternFromStorage(e.movementPattern),
    safetyTier: safetyTierFromStorage(e.safetyTier),
    laterality: lateralityFromStorage(e.laterality),
    systemicFatigue: systemicFatigueFromStorage(e.systemicFatigue),
    suitability: suitabilityFromStorage(e.suitability),
    regressionId: e.regressionId,
    progressionId: e.progressionId,
  )).toList();
});

/// A FutureProvider that returns a single exercise by ID.
final exerciseByIdProvider = FutureProvider.family<Exercise?, String>((ref, exerciseId) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  try {
    return await repo.findById(exerciseId);
  } catch (e) {
    return null;
  }
});

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProgramRepositoryImpl(db);
});

/// Provides [SessionCheckInRepository] for persisting pre-workout and post-workout check-ins.
final sessionCheckInRepositoryProvider = Provider<SessionCheckInRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SessionCheckInRepository(db);
});

/// Check-ins for a single workout session, keyed by session ID.
final sessionCheckInsForSessionProvider =
    FutureProvider.family<List<SessionCheckIn>, String>((ref, sessionId) async {
  final repo = ref.watch(sessionCheckInRepositoryProvider);
  return repo.getBySession(sessionId);
});

/// Pre-workout LLM session adjustment ([adjustWorkout] callable).
final workoutAdjustmentServiceProvider = Provider<WorkoutAdjustmentService>((ref) {
  return WorkoutAdjustmentService();
});

final programsFutureProvider = FutureProvider<List<Program>>((ref) async {
  final repo = ref.watch(programRepositoryProvider);
  return repo.findAll();
});

final programByIdProvider = FutureProvider.family<Program?, String>((ref, programId) async {
  final repo = ref.watch(programRepositoryProvider);
  try {
    return await repo.findById(programId);
  } catch (e) {
    return null;
  }
});