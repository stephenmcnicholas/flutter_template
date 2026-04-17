import 'package:drift/drift.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/program_repository.dart';

/// Concrete [ProgramRepository] backed by Drift.
class ProgramRepositoryImpl implements ProgramRepository {
  final AppDatabase _db;

  ProgramRepositoryImpl(this._db);

  @override
  Future<List<Program>> findAll() async {
    final programRows = await _db.select(_db.programs).get();
    final List<Program> result = [];

    for (final row in programRows) {
      // Fetch ordered scheduled workouts for this program
      final schedRows = await (_db.select(_db.programExercises)
            ..where((t) => t.programId.equals(row.id))
            ..orderBy([(t) => OrderingTerm(expression: t.position)]))
          .get();

      final schedule = schedRows.map((e) => ProgramWorkout(
        workoutId: e.workoutId,
        scheduledDate: e.scheduledDate,
      )).toList();

      result.add(Program(
        id: row.id,
        name: row.name,
        schedule: schedule,
        notificationEnabled: row.notificationEnabled,
        notificationTimeMinutes: row.notificationTimeMinutes,
        isAiGenerated: row.isAiGenerated,
        generationContext: row.generationContext,
        deloadWeek: row.deloadWeek,
        weeklyProgressionNotes: row.weeklyProgressionNotes,
        coachIntro: row.coachIntro,
        coachRationale: row.coachRationale,
        coachRationaleSpoken: row.coachRationaleSpoken,
        workoutBreakdowns: row.workoutBreakdowns,
        programmeDescriptionAudioRemotePath: row.programmeDescriptionAudioRemotePath,
      ));
    }

    return result;
  }

  @override
  Future<Program> findById(String id) async {
    final row = await (_db.select(_db.programs)
          ..where((t) => t.id.equals(id)))
        .getSingle();

    final schedRows = await (_db.select(_db.programExercises)
          ..where((t) => t.programId.equals(id))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();

    final schedule = schedRows.map((e) => ProgramWorkout(
      workoutId: e.workoutId,
      scheduledDate: e.scheduledDate,
    )).toList();

    return Program(
      id: row.id,
      name: row.name,
      schedule: schedule,
      notificationEnabled: row.notificationEnabled,
      notificationTimeMinutes: row.notificationTimeMinutes,
      isAiGenerated: row.isAiGenerated,
      generationContext: row.generationContext,
      deloadWeek: row.deloadWeek,
      weeklyProgressionNotes: row.weeklyProgressionNotes,
      coachIntro: row.coachIntro,
      coachRationale: row.coachRationale,
      coachRationaleSpoken: row.coachRationaleSpoken,
      workoutBreakdowns: row.workoutBreakdowns,
      programmeDescriptionAudioRemotePath: row.programmeDescriptionAudioRemotePath,
    );
  }

  @override
  Future<void> save(Program program) async {
    // Upsert the program record
    await _db.into(_db.programs).insertOnConflictUpdate(
      ProgramsCompanion(
        id: Value(program.id),
        name: Value(program.name),
        notificationEnabled: Value(program.notificationEnabled),
        notificationTimeMinutes: Value(program.notificationTimeMinutes),
        isAiGenerated: Value(program.isAiGenerated),
        generationContext: Value(program.generationContext),
        deloadWeek: Value(program.deloadWeek),
        weeklyProgressionNotes: Value(program.weeklyProgressionNotes),
        coachIntro: Value(program.coachIntro),
        coachRationale: Value(program.coachRationale),
        coachRationaleSpoken: Value(program.coachRationaleSpoken),
        workoutBreakdowns: Value(program.workoutBreakdowns),
        programmeDescriptionAudioRemotePath:
            Value(program.programmeDescriptionAudioRemotePath),
      ),
    );

    // Replace the program_exercises entries
    await (_db.delete(_db.programExercises)
          ..where((t) => t.programId.equals(program.id)))
        .go();

    for (var i = 0; i < program.schedule.length; i++) {
      final sched = program.schedule[i];
      await _db.into(_db.programExercises).insert(
        ProgramExercisesCompanion(
          programId: Value(program.id),
          workoutId: Value(sched.workoutId),
          scheduledDate: Value(sched.scheduledDate),
          position: Value(i),
        ),
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    // Deletes program (and cascades to program_exercises)
    await (_db.delete(_db.programs)..where((t) => t.id.equals(id))).go();
  }
}