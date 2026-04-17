import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:fytter/src/data/app_database_connection.dart';
import 'package:fytter/src/data/exercise_seed_version.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_database.g.dart';

@DataClassName('ExerciseEntity')
class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get mediaPath => text().nullable()();
  TextColumn get bodyPart => text().nullable()();
  TextColumn get equipment => text().nullable()();
  TextColumn get loggingType => text().nullable()();
  TextColumn get movementPattern => text().nullable()();
  IntColumn get safetyTier => integer().withDefault(const Constant(1))();
  TextColumn get laterality => text().nullable()();
  TextColumn get systemicFatigue => text().withDefault(const Constant('medium'))();
  TextColumn get suitability => text().nullable()();
  TextColumn get regressionId => text().nullable()();
  TextColumn get progressionId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExerciseFavoriteEntity')
class ExerciseFavorites extends Table {
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

@DataClassName('WorkoutEntryEntity')
class WorkoutEntries extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn   get reps       => integer()();
  RealColumn  get weight     => real()();
  RealColumn  get distance   => real().nullable()();
  IntColumn   get duration   => integer().nullable()();
  BoolColumn  get isComplete => boolean().withDefault(const Constant(false))();
  DateTimeColumn get timestamp => dateTime().nullable()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get setOutcome => text().nullable()();
  TextColumn get supersetGroupId => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutEntity')
class Workouts extends Table {
  TextColumn get id   => text()();
  TextColumn get name => text()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WorkoutExerciseEntity')
class WorkoutExercises extends Table {
  TextColumn get id         => text()();
  TextColumn get workoutId  => text().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn    get position   => integer()();
  IntColumn    get reps       => integer()();
  RealColumn   get weight     => real()();
  RealColumn   get distance   => real().nullable()();
  IntColumn    get duration   => integer().nullable()();
  DateTimeColumn get timestamp => dateTime().nullable()();
  TextColumn get supersetGroupId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProgramEntity')
class Programs extends Table {
  TextColumn get id   => text()();
  TextColumn get name => text()();
  BoolColumn get notificationEnabled => boolean().withDefault(const Constant(false))();
  IntColumn get notificationTimeMinutes => integer().nullable()();
  BoolColumn get isAiGenerated => boolean().withDefault(const Constant(false))();
  TextColumn get generationContext => text().nullable()();
  IntColumn get deloadWeek => integer().nullable()();
  TextColumn get weeklyProgressionNotes => text().nullable()();
  TextColumn get coachIntro => text().nullable()();
  TextColumn get coachRationale => text().nullable()();
  TextColumn get coachRationaleSpoken => text().nullable()();
  TextColumn get workoutBreakdowns => text().nullable()();
  /// Firebase Storage path for Type C programme description MP3 (e.g. audio/users/uid/.../description.mp3).
  TextColumn get programmeDescriptionAudioRemotePath => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProgramExerciseEntity')
class ProgramExercises extends Table {
  IntColumn get position  => integer()();
  TextColumn get programId   => text().references(Programs, #id, onDelete: KeyAction.cascade)();
  TextColumn get workoutId   => text()();
  DateTimeColumn get scheduledDate => dateTime()();
  @override
  Set<Column> get primaryKey => {programId, position};
}

@DataClassName('WorkoutSessionEntity')
class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get name => text().nullable()();
  TextColumn get notes => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserProfileEntity')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get primaryGoal => text().nullable()();
  IntColumn get daysPerWeek => integer().nullable()();
  IntColumn get sessionLengthMinutes => integer().nullable()();
  TextColumn get equipment => text().nullable()();
  TextColumn get experienceLevel => text().nullable()();
  TextColumn get injuriesNotes => text().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  DateTimeColumn get onboardingCompletedAt => dateTime().nullable()();
  IntColumn get age => integer().nullable()();
  TextColumn get blockedDays => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserScorecardEntity')
class UserScorecards extends Table {
  TextColumn get id => text()();
  RealColumn get consistency => real().withDefault(const Constant(5.0))();
  RealColumn get progression => real().withDefault(const Constant(3.0))();
  RealColumn get endurance => real().withDefault(const Constant(3.0))();
  RealColumn get variety => real().withDefault(const Constant(5.0))();
  RealColumn get fundamentals => real().withDefault(const Constant(1.0))();
  RealColumn get selfAwareness => real().withDefault(const Constant(5.0))();
  RealColumn get curiosity => real().withDefault(const Constant(5.0))();
  RealColumn get reliability => real().withDefault(const Constant(5.0))();
  RealColumn get adaptability => real().withDefault(const Constant(5.0))();
  RealColumn get independence => real().withDefault(const Constant(3.0))();
  IntColumn get computedLevel => integer().withDefault(const Constant(1))();
  DateTimeColumn get lastUpdated => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SessionCheckInEntity')
class SessionCheckIns extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().nullable()();
  TextColumn get programmeId => text().nullable()();
  TextColumn get checkInType => text()();
  TextColumn get rating => text()();
  TextColumn get freeText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Exercises,
  ExerciseFavorites,
  WorkoutEntries,
  Workouts,
  WorkoutExercises,
  Programs,
  ProgramExercises,
  WorkoutSessions,
  UserProfiles,
  UserScorecards,
  SessionCheckIns,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());
  AppDatabase.test() : super(openTestConnection());

  @override
  int get schemaVersion => 18;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from == 17 && to == 18) {
        // Production-safe migration: add supersetGroupId column to session entries
        await m.addColumn(workoutEntries, workoutEntries.supersetGroupId);
      } else {
        // For older dev installs: wipe and recreate
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
      }
    },
    beforeOpen: (details) async {},
  );

  // CRUD helpers for Exercises
  Future<List<ExerciseEntity>> getAllExercises() => select(exercises).get();
  Future<void> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry);

  // CRUD helpers for ExerciseFavorites
  Future<List<ExerciseFavoriteEntity>> getAllExerciseFavorites() =>
      select(exerciseFavorites).get();
  Future<void> addExerciseFavorite(String exerciseId) =>
      into(exerciseFavorites).insertOnConflictUpdate(
        ExerciseFavoritesCompanion(exerciseId: Value(exerciseId)),
      );
  Future<void> removeExerciseFavorite(String exerciseId) =>
      (delete(exerciseFavorites)
            ..where((t) => t.exerciseId.equals(exerciseId)))
          .go();

  // CRUD helpers for WorkoutEntries
  Future<List<WorkoutEntryEntity>> getAllEntries() => select(workoutEntries).get();
  Future<void> insertEntry(WorkoutEntriesCompanion entry) =>
      into(workoutEntries).insert(entry);

  // CRUD helpers for Workouts
  Future<List<WorkoutEntity>> getAllWorkouts() => select(workouts).get();
  Future<void> insertWorkout(WorkoutsCompanion workout) =>
      into(workouts).insert(workout);

  // CRUD helpers for Program
  Future<List<ProgramEntity>> getAllPrograms() => select(programs).get();
  Future<void> insertProgram(ProgramsCompanion program) =>
      into(programs).insert(program);

  // CRUD helpers for WorkoutSessions
  Future<List<WorkoutSessionEntity>> getAllWorkoutSessions() => select(workoutSessions).get();
  Future<WorkoutSessionEntity?> getWorkoutSessionById(String id) => (select(workoutSessions)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  Future<void> insertWorkoutSession(WorkoutSessionsCompanion session) => into(workoutSessions).insertOnConflictUpdate(session);
  Future<void> deleteWorkoutSession(String id) => (delete(workoutSessions)..where((tbl) => tbl.id.equals(id))).go();

  // User profile (onboarding / AI program generation)
  Future<UserProfileEntity?> getUserProfile() =>
      (select(userProfiles)..where((t) => t.id.equals('local'))).getSingleOrNull();
  Future<void> upsertUserProfile(UserProfilesCompanion p) =>
      into(userProfiles).insertOnConflictUpdate(p);
}

/// Extension to seed initial exercises from JSON.
extension AppDatabaseSeed on AppDatabase {
  /// Seeds from bundled asset on first run, or updates existing exercises with media paths.
  ///
  /// When the SHA-256 of `assets/exercises/exercises.json` changes (or a debug
  /// force-resync flag is set), performs a full upsert from the bundle so
  /// [ExerciseEntity.name] and [ExerciseEntity.description] stay aligned with the asset.
  Future<void> seedInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = await rootBundle.loadString(
      'assets/exercises/exercises.json',
    );
    final list = json.decode(jsonString) as List<dynamic>;
    final seedData = list.cast<Map<String, dynamic>>();

    final hash = sha256HexOfUtf8(jsonString);
    final storedHash = prefs.getString(kExercisesJsonAssetHashKey);
    final forceReseed =
        kDebugMode && (prefs.getBool(kDebugForceReseedExercisesKey) ?? false);
    final needsFullReseed =
        forceReseed || storedHash == null || storedHash != hash;

    final existingExercises = await select(exercises).get();

    if (existingExercises.isEmpty) {
      await seedInitialDataFromString(jsonString);
    } else if (needsFullReseed) {
      await _syncAllExercisesFromSeedPreservingUserMedia(seedData);
    } else {
      await _incrementalExerciseMetadataUpdate(seedData);
    }

    await prefs.setString(kExercisesJsonAssetHashKey, hash);
    if (forceReseed) {
      await prefs.setBool(kDebugForceReseedExercisesKey, false);
    }
  }

  /// Full upsert of every bundled exercise: updates name/description and metadata,
  /// while preserving user-uploaded media paths when present.
  Future<void> _syncAllExercisesFromSeedPreservingUserMedia(
    List<Map<String, dynamic>> seedData,
  ) async {
    for (final seedItem in seedData) {
      final exerciseId = seedItem['id'] as String;
      final existing = await (select(exercises)
            ..where((t) => t.id.equals(exerciseId)))
          .getSingleOrNull();

      final seedThumbnail = seedItem['thumbnailPath'] as String?;
      final seedMedia = seedItem['mediaPath'] as String?;
      final keepThumbnail = existing != null && _isLocalFilePath(existing.thumbnailPath);
      final keepMedia = existing != null && _isLocalFilePath(existing.mediaPath);

      await into(exercises).insertOnConflictUpdate(
        ExercisesCompanion(
          id: Value(exerciseId),
          name: Value(seedItem['name'] as String),
          description: Value(seedItem['description'] as String? ?? ''),
          thumbnailPath: Value(
            keepThumbnail ? existing.thumbnailPath : seedThumbnail,
          ),
          mediaPath: Value(keepMedia ? existing.mediaPath : seedMedia),
          bodyPart: Value(seedItem['bodyPart'] as String?),
          equipment: Value(seedItem['equipment'] as String?),
          loggingType: Value(seedItem['loggingType'] as String?),
          movementPattern: Value(seedItem['movementPattern'] as String?),
          safetyTier: Value((seedItem['safetyTier'] as int?) ?? 1),
          laterality: Value(seedItem['laterality'] as String?),
          systemicFatigue:
              Value((seedItem['systemicFatigue'] as String?) ?? 'medium'),
          suitability: Value(_encodeSuitability(seedItem['suitability'])),
          regressionId: Value(seedItem['regressionId'] as String?),
          progressionId: Value(seedItem['progressionId'] as String?),
        ),
      );
    }
  }

  /// Between app releases, refresh metadata without touching name/description (avoids
  /// overwriting user edits if we add those later). New exercises still insert fully.
  Future<void> _incrementalExerciseMetadataUpdate(
    List<Map<String, dynamic>> seedData,
  ) async {
    for (final seedItem in seedData) {
      final exerciseId = seedItem['id'] as String;
      final existing = await (select(exercises)
            ..where((t) => t.id.equals(exerciseId)))
          .getSingleOrNull();

      if (existing != null) {
        final seedThumbnail = seedItem['thumbnailPath'] as String?;
        final seedMedia = seedItem['mediaPath'] as String?;
        final keepThumbnail = _isLocalFilePath(existing.thumbnailPath);
        final keepMedia = _isLocalFilePath(existing.mediaPath);

        await (update(exercises)..where((t) => t.id.equals(exerciseId))).write(
          ExercisesCompanion(
            thumbnailPath: Value(
              keepThumbnail ? existing.thumbnailPath : seedThumbnail,
            ),
            mediaPath: Value(keepMedia ? existing.mediaPath : seedMedia),
            bodyPart: Value(seedItem['bodyPart'] as String?),
            equipment: Value(seedItem['equipment'] as String?),
            loggingType: Value(seedItem['loggingType'] as String?),
            movementPattern: Value(seedItem['movementPattern'] as String?),
            safetyTier: Value((seedItem['safetyTier'] as int?) ?? 1),
            laterality: Value(seedItem['laterality'] as String?),
            systemicFatigue:
                Value((seedItem['systemicFatigue'] as String?) ?? 'medium'),
            suitability: Value(_encodeSuitability(seedItem['suitability'])),
            regressionId: Value(seedItem['regressionId'] as String?),
            progressionId: Value(seedItem['progressionId'] as String?),
          ),
        );
      } else {
        final companion = ExercisesCompanion(
          id: Value(seedItem['id'] as String),
          name: Value(seedItem['name'] as String),
          description: Value(seedItem['description'] as String? ?? ''),
          thumbnailPath: Value(seedItem['thumbnailPath'] as String?),
          mediaPath: Value(seedItem['mediaPath'] as String?),
          bodyPart: Value(seedItem['bodyPart'] as String?),
          equipment: Value(seedItem['equipment'] as String?),
          loggingType: Value(seedItem['loggingType'] as String?),
          movementPattern: Value(seedItem['movementPattern'] as String?),
          safetyTier: Value((seedItem['safetyTier'] as int?) ?? 1),
          laterality: Value(seedItem['laterality'] as String?),
          systemicFatigue:
              Value((seedItem['systemicFatigue'] as String?) ?? 'medium'),
          suitability: Value(_encodeSuitability(seedItem['suitability'])),
          regressionId: Value(seedItem['regressionId'] as String?),
          progressionId: Value(seedItem['progressionId'] as String?),
        );
        await into(exercises).insert(companion);
      }
    }
  }

  /// Seeds from a raw JSON string (for tests).
  Future<void> seedInitialDataFromString(String jsonString) async {
    final list = json.decode(jsonString) as List<dynamic>;
    for (final item in list.cast<Map<String, dynamic>>()) {
      final companion = ExercisesCompanion(
        id: Value(item['id'] as String),
        name: Value(item['name'] as String),
        description: Value(item['description'] as String? ?? ''),
        thumbnailPath: Value(item['thumbnailPath'] as String?),
        mediaPath: Value(item['mediaPath'] as String?),
        bodyPart: Value(item['bodyPart'] as String?),
        equipment: Value(item['equipment'] as String?),
        loggingType: Value(item['loggingType'] as String?),
        movementPattern: Value(item['movementPattern'] as String?),
        safetyTier: Value((item['safetyTier'] as int?) ?? 1),
        laterality: Value(item['laterality'] as String?),
        systemicFatigue: Value((item['systemicFatigue'] as String?) ?? 'medium'),
        suitability: Value(_encodeSuitability(item['suitability'])),
        regressionId: Value(item['regressionId'] as String?),
        progressionId: Value(item['progressionId'] as String?),
      );
      await into(exercises).insert(companion);
    }
  }
}

String? _encodeSuitability(dynamic value) {
  if (value == null) return null;
  if (value is List) return value.cast<String>().join(',');
  return value as String?;
}

bool _isLocalFilePath(String? path) {
  if (path == null || path.isEmpty) return false;
  return path.startsWith('/') ||
      path.startsWith('file://') ||
      path.startsWith('exercise_media/');
}
