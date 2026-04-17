import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_session_repository.dart';
import 'package:fytter/src/data/app_database.dart';
import 'package:drift/drift.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:flutter/foundation.dart';

// This is a placeholder for your actual database or storage mechanism.
// Replace with your real data source (e.g., Drift DAO, Hive box, etc.).
class WorkoutSessionRepositoryImpl implements WorkoutSessionRepository {
  final AppDatabase db;
  WorkoutSessionRepositoryImpl(this.db);

  @override
  Future<List<WorkoutSession>> findAll() async {
    try {
      final sessionEntities = await db.getAllWorkoutSessions();
      final entryEntities = await db.getAllEntries();
      return sessionEntities.map((session) {
        final entries = entryEntities
          .where((e) => e.sessionId == session.id)
          .map((e) {
            return WorkoutEntry(
              id: e.id,
              exerciseId: e.exerciseId,
              reps: e.reps,
              weight: e.weight,
              distance: e.distance,
              duration: e.duration,
              isComplete: e.isComplete,
              timestamp: e.timestamp?.toUtc(),
              setOutcome: e.setOutcome,
              supersetGroupId: e.supersetGroupId,
            );
          })
          .toList();
        return WorkoutSession(
          id: session.id,
          workoutId: session.workoutId,
          date: session.date.toUtc(),
          name: session.name,
          notes: session.notes,
          entries: entries,
        );
      }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e, stackTrace) {
      debugPrint('WorkoutSessionRepositoryImpl.findAll ERROR: ${e.toString()}');
      debugPrint('StackTrace: ${stackTrace.toString()}');
      rethrow;
    }
  }

  @override
  Future<WorkoutSession?> findById(String id) async {
    final session = await db.getWorkoutSessionById(id);
    if (session == null) return null;
    final entryEntities = await db.getAllEntries();
    final entries = entryEntities
      .where((e) => e.sessionId == session.id)
      .map((e) => WorkoutEntry(
        id: e.id,
        exerciseId: e.exerciseId,
        reps: e.reps,
        weight: e.weight,
        distance: e.distance,
        duration: e.duration,
        isComplete: e.isComplete,
        timestamp: e.timestamp?.toUtc(),
        setOutcome: e.setOutcome,
        supersetGroupId: e.supersetGroupId,
      ))
      .toList();
    return WorkoutSession(
      id: session.id,
      workoutId: session.workoutId,
      date: session.date.toUtc(),
      name: session.name,
      notes: session.notes,
      entries: entries,
    );
  }

  @override
  Future<void> save(WorkoutSession session) async {
    // Save session (upsert to handle updates)
    await db.insertWorkoutSession(WorkoutSessionsCompanion(
      id: Value(session.id),
      workoutId: Value(session.workoutId),
      date: Value(session.date),
      name: Value(session.name),
      notes: Value(session.notes),
    ));
    
    // Delete old entries for THIS session only (prevents cross-session data loss)
    await (db.delete(db.workoutEntries)..where((e) => e.sessionId.equals(session.id))).go();
    
    // Save entries using insert (not insertOnConflictUpdate) since we:
    // 1. Just deleted all old entries for this session
    // 2. Generate new UUIDs for each entry to ensure uniqueness
    // This prevents entries from being "stolen" by other sessions due to ID collisions
    for (final entry in session.entries) {
      await db.into(db.workoutEntries).insert(
        WorkoutEntriesCompanion(
          id: Value(entry.id),
          exerciseId: Value(entry.exerciseId),
          reps: Value(entry.reps),
          weight: Value(entry.weight),
          distance: Value(entry.distance),
          duration: Value(entry.duration),
          isComplete: Value(entry.isComplete),
          timestamp: Value(entry.timestamp),
          sessionId: Value(session.id), // Always set sessionId to ensure entry belongs to this session
          setOutcome: Value(entry.setOutcome),
          supersetGroupId: Value(entry.supersetGroupId),
        ),
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    await db.deleteWorkoutSession(id);
    // Optionally, delete entries for this session
    // (delete(db.workoutEntries)..where((e) => e.sessionId.equals(id))).go();
  }
}
