import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';

const bool _logExerciseHistory = false;

/// Provider that returns a map of exerciseId -> count of unique workout sessions
/// that include that exercise.
final exerciseWorkoutCountProvider = FutureProvider<Map<String, int>>((ref) async {
  final sessions = await ref.watch(workoutSessionsProvider.future);
  final countMap = <String, int>{};
  for (final session in sessions) {
    // Get unique exercise IDs in this session
    final exerciseIds = session.entries
        .map((e) => e.exerciseId)
        .toSet();
    for (final exerciseId in exerciseIds) {
      countMap[exerciseId] = (countMap[exerciseId] ?? 0) + 1;
    }
  }
  return countMap;
});

/// Represents a workout session that contains a specific exercise, with the relevant entries.
class ExerciseWorkoutHistory {
  final WorkoutSession session;
  final List<WorkoutEntry> entries; // Only entries for this exercise

  const ExerciseWorkoutHistory({
    required this.session,
    required this.entries,
  });
}

/// Represents the last recorded values for an exercise (from the most recent workout session).
/// All fields are nullable - only fields that were recorded will have values.
class LastRecordedValues {
  final int? reps;
  final double? weight;
  final double? distance;
  final int? duration;

  const LastRecordedValues({
    this.reps,
    this.weight,
    this.distance,
    this.duration,
  });

  /// Returns true if any values are present
  bool get hasValues => reps != null || weight != null || distance != null || duration != null;
}

/// Provider that returns a map of exerciseId -> most recent workout session date
/// (or null if the exercise has never been performed).
final exerciseMostRecentDateProvider = FutureProvider<Map<String, DateTime?>>((ref) async {
  final sessions = await ref.watch(workoutSessionsProvider.future);
  final mostRecentMap = <String, DateTime?>{};
  
  for (final session in sessions) {
    // Get unique exercise IDs in this session
    final exerciseIds = session.entries
        .map((e) => e.exerciseId)
        .toSet();
    
    for (final exerciseId in exerciseIds) {
      final currentMostRecent = mostRecentMap[exerciseId];
      // If no date recorded yet, or this session is more recent, update it
      if (currentMostRecent == null || session.date.isAfter(currentMostRecent)) {
        mostRecentMap[exerciseId] = session.date;
      }
    }
  }
  
  return mostRecentMap;
});

/// Provider that returns workout history for a specific exercise, sorted by date (most recent first).
final exerciseHistoryProvider = FutureProvider.family<List<ExerciseWorkoutHistory>, String>(
  (ref, exerciseId) async {
    final sessions = await ref.watch(workoutSessionsProvider.future);
    final history = <ExerciseWorkoutHistory>[];
    
    if (_logExerciseHistory) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('exerciseHistoryProvider: Starting search');
      debugPrint('  Searching for exerciseId: "$exerciseId"');
      debugPrint('  Total sessions loaded: ${sessions.length}');
      debugPrint('═══════════════════════════════════════════════════════════');
    }
    
    // Collect all unique exercise IDs found across all sessions for comparison
    final allExerciseIds = <String>{};
    
    for (final session in sessions) {
      // Collect all exercise IDs in this session
      final sessionExerciseIds = session.entries.map((e) => e.exerciseId).toSet();
      allExerciseIds.addAll(sessionExerciseIds);
      
      // Find all entries for this exercise in this session
      final exerciseEntries = session.entries
          .where((e) => e.exerciseId == exerciseId)
          .toList();
      
      if (_logExerciseHistory) {
        debugPrint('Session: ${session.id}');
        debugPrint('  Date: ${session.date}');
        debugPrint('  Name: ${session.name ?? "Unnamed"}');
        debugPrint('  Total entries: ${session.entries.length}');
        debugPrint('  Exercise IDs in session: $sessionExerciseIds');
        debugPrint('  Matching entries found: ${exerciseEntries.length}');
      }
      
      if (exerciseEntries.isNotEmpty) {
        if (_logExerciseHistory) {
          debugPrint('  ✓ ADDING to history (${exerciseEntries.length} entries)');
          for (var i = 0; i < exerciseEntries.length; i++) {
            final entry = exerciseEntries[i];
            debugPrint('    Entry ${i + 1}: ${entry.reps} reps @ ${entry.weight} kg (id: ${entry.id})');
          }
        }
        history.add(ExerciseWorkoutHistory(
          session: session,
          entries: exerciseEntries,
        ));
      } else {
        if (_logExerciseHistory) {
          debugPrint('  ✗ NOT adding (no matching entries)');
        }
      }
    }
    
    if (_logExerciseHistory) {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('exerciseHistoryProvider: Search complete');
      debugPrint('  All unique exercise IDs found in database: $allExerciseIds');
      debugPrint('  Searched exerciseId "$exerciseId" ${allExerciseIds.contains(exerciseId) ? "WAS FOUND" : "WAS NOT FOUND"} in database');
      debugPrint('  Total sessions with matching entries: ${history.length}');
      debugPrint('  Total entries across all matching sessions: ${history.fold<int>(0, (sum, h) => sum + h.entries.length)}');
      debugPrint('═══════════════════════════════════════════════════════════');
    }
    
    // Already sorted by date (most recent first) from workoutSessionsProvider
    return history;
  },
);

/// Provider that returns the last recorded values for a specific exercise.
/// Returns null if the exercise has never been performed.
/// Uses the most recent workout session entry for that exercise.
final lastRecordedValuesProvider = FutureProvider.family<LastRecordedValues?, String>(
  (ref, exerciseId) async {
    final history = await ref.watch(exerciseHistoryProvider(exerciseId).future);
    if (history.isEmpty) return null;

    // Get most recent entry (history is sorted most recent first)
    // Use the last entry from the most recent session (most recently recorded set)
    final mostRecentHistory = history.first;
    if (mostRecentHistory.entries.isEmpty) return null;

    final mostRecentEntry = mostRecentHistory.entries.last;
    return LastRecordedValues(
      reps: mostRecentEntry.reps,
      weight: mostRecentEntry.weight,
      distance: mostRecentEntry.distance,
      duration: mostRecentEntry.duration,
    );
  },
);
