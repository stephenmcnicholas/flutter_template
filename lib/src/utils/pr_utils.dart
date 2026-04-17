import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';

class ExercisePersonalRecord {
  final int? maxReps;
  final double? maxWeightKg;
  final int? maxDurationSec;
  final double? maxDistanceKm;

  const ExercisePersonalRecord({
    this.maxReps,
    this.maxWeightKg,
    this.maxDurationSec,
    this.maxDistanceKm,
  });

  bool get hasAny =>
      maxReps != null ||
      maxWeightKg != null ||
      maxDurationSec != null ||
      maxDistanceKm != null;
}

class WorkoutTotals {
  final int totalReps;
  final double totalVolumeKg;

  const WorkoutTotals({
    required this.totalReps,
    required this.totalVolumeKg,
  });
}

ExercisePersonalRecord calculateExercisePr({
  required ExerciseInputType inputType,
  required Iterable<WorkoutEntry> entries,
}) {
  int? maxReps;
  double? maxWeight;
  int? maxDuration;
  double? maxDistance;

  for (final entry in entries) {
    if (!entry.isComplete) continue;
    switch (inputType) {
      case ExerciseInputType.repsOnly:
        if (entry.reps > (maxReps ?? -1)) {
          maxReps = entry.reps;
        }
        break;
      case ExerciseInputType.repsAndWeight:
        if (entry.weight > (maxWeight ?? -1)) {
          maxWeight = entry.weight;
        }
        break;
      case ExerciseInputType.timeOnly:
        final duration = entry.duration;
        if (duration != null && duration > (maxDuration ?? -1)) {
          maxDuration = duration;
        }
        break;
      case ExerciseInputType.distanceAndTime:
        final duration = entry.duration;
        final distance = entry.distance;
        if (duration != null && duration > (maxDuration ?? -1)) {
          maxDuration = duration;
        }
        if (distance != null && distance > (maxDistance ?? -1)) {
          maxDistance = distance;
        }
        break;
    }
  }

  return ExercisePersonalRecord(
    maxReps: maxReps,
    maxWeightKg: maxWeight,
    maxDurationSec: maxDuration,
    maxDistanceKm: maxDistance,
  );
}

Map<String, ExercisePersonalRecord> calculateAllExercisePrs({
  required List<WorkoutSession> sessions,
  required Map<String, ExerciseInputType> inputTypes,
}) {
  final groupedEntries = <String, List<WorkoutEntry>>{};
  for (final session in sessions) {
    for (final entry in session.entries) {
      groupedEntries.putIfAbsent(entry.exerciseId, () => []).add(entry);
    }
  }

  final prs = <String, ExercisePersonalRecord>{};
  for (final entry in groupedEntries.entries) {
    final inputType = inputTypes[entry.key];
    if (inputType == null) continue;
    prs[entry.key] = calculateExercisePr(
      inputType: inputType,
      entries: entry.value,
    );
  }
  return prs;
}

WorkoutTotals calculateWorkoutTotals({
  required List<WorkoutEntry> entries,
  required Map<String, ExerciseInputType> inputTypes,
}) {
  int totalReps = 0;
  double totalVolume = 0.0;

  for (final entry in entries) {
    if (!entry.isComplete) continue;
    final inputType = inputTypes[entry.exerciseId];
    if (inputType == ExerciseInputType.repsOnly ||
        inputType == ExerciseInputType.repsAndWeight) {
      totalReps += entry.reps;
    }
    if (inputType == ExerciseInputType.repsAndWeight) {
      totalVolume += entry.reps * entry.weight;
    }
  }

  return WorkoutTotals(
    totalReps: totalReps,
    totalVolumeKg: totalVolume,
  );
}

Set<String> exercisesWithNewPrsInSession({
  required WorkoutSession session,
  required List<WorkoutSession> allSessions,
  required Map<String, ExerciseInputType> inputTypes,
}) {
  final priorSessions =
      allSessions.where((other) => other.id != session.id).toList();
  final priorPrs = calculateAllExercisePrs(
    sessions: priorSessions,
    inputTypes: inputTypes,
  );

  final exerciseIds = <String>{};
  for (final entry in session.entries) {
    if (!entry.isComplete) continue;
    final inputType = inputTypes[entry.exerciseId];
    if (inputType == null) continue;
    final prior = priorPrs[entry.exerciseId] ??
        const ExercisePersonalRecord();
    if (_entryExceedsPr(entry, inputType, prior)) {
      exerciseIds.add(entry.exerciseId);
    }
  }
  return exerciseIds;
}

bool _entryExceedsPr(
  WorkoutEntry entry,
  ExerciseInputType inputType,
  ExercisePersonalRecord prior,
) {
  switch (inputType) {
    case ExerciseInputType.repsOnly:
      return entry.reps > (prior.maxReps ?? -1);
    case ExerciseInputType.repsAndWeight:
      return entry.weight > (prior.maxWeightKg ?? -1);
    case ExerciseInputType.timeOnly:
      final duration = entry.duration;
      return duration != null && duration > (prior.maxDurationSec ?? -1);
    case ExerciseInputType.distanceAndTime:
      final duration = entry.duration;
      final distance = entry.distance;
      final beatsDuration =
          duration != null && duration > (prior.maxDurationSec ?? -1);
      final beatsDistance =
          distance != null && distance > (prior.maxDistanceKm ?? -1);
      return beatsDuration || beatsDistance;
  }
}
