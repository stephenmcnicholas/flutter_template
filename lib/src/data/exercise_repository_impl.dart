import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/domain/exercise_repository.dart';

/// Concrete implementation of [ExerciseRepository] using Drift.
class ExerciseRepositoryImpl implements ExerciseRepository {
  final AppDatabase _db;
  ExerciseRepositoryImpl(this._db);

  @override
  Future<List<Exercise>> findAll() async {
    final rows = await _db.getAllExercises();
    return rows.map(_entityToDomain).toList();
  }

  @override
  Future<Exercise> findById(String id) async {
    final row = await (_db.select(_db.exercises)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) throw Exception('Exercise not found: $id');
    return _entityToDomain(row);
  }

  @override
  Future<void> save(Exercise exercise) {
    final companion = ExercisesCompanion(
      id: Value(exercise.id),
      name: Value(exercise.name),
      description: Value(exercise.description),
      thumbnailPath: Value(exercise.thumbnailPath),
      mediaPath: Value(exercise.mediaPath),
      bodyPart: Value(exercise.bodyPart),
      equipment: Value(exercise.equipment),
      loggingType: Value(exercise.loggingType == null
          ? null
          : exerciseInputTypeToJson(exercise.loggingType!)),
      movementPattern: Value(exercise.movementPattern == null
          ? null
          : movementPatternToStorage(exercise.movementPattern!)),
      safetyTier: Value(safetyTierToStorage(exercise.safetyTier)),
      laterality: Value(exercise.laterality == null
          ? null
          : lateralityToStorage(exercise.laterality!)),
      systemicFatigue:
          Value(systemicFatigueToStorage(exercise.systemicFatigue)),
      suitability: Value(suitabilityToStorage(exercise.suitability)),
      regressionId: Value(exercise.regressionId),
      progressionId: Value(exercise.progressionId),
    );
    return _db.into(_db.exercises).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> delete(String id) {
    return (_db.delete(_db.exercises)..where((t) => t.id.equals(id))).go();
  }

  Exercise _entityToDomain(ExerciseEntity e) => Exercise(
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
      );
}
