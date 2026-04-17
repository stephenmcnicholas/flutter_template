import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_enums.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';

/// Callable [adjustWorkout] failed or returned an error payload.
class WorkoutAdjustmentException implements Exception {
  WorkoutAdjustmentException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic>? _toMapStringDynamic(Object? value) {
  if (value == null) return null;
  if (value is! Map) return null;
  final result = <String, dynamic>{};
  for (final e in value.entries) {
    final k = e.key;
    if (k is! String) continue;
    final v = e.value;
    if (v is Map) {
      final nested = _toMapStringDynamic(v);
      if (nested != null) result[k] = nested;
    } else if (v is List) {
      result[k] = [
        for (final item in v)
          item is Map ? _toMapStringDynamic(item) ?? <String, dynamic>{} : item,
      ];
    } else {
      result[k] = v;
    }
  }
  return result;
}

/// Calls [adjustWorkout] and maps response into [PreWorkoutCheckInArgs].
class WorkoutAdjustmentService {
  /// Merges server rows onto [original] preserving set `id` and `isComplete: false`.
  @visibleForTesting
  static Map<String, List<Map<String, dynamic>>> mergeAdjustedSets(
    Map<String, List<Map<String, dynamic>>> original,
    Object? setsByExerciseRaw,
  ) {
    final serverRoot = setsByExerciseRaw;
    if (serverRoot is! Map) {
      throw WorkoutAdjustmentException('Invalid setsByExercise type');
    }
    final out = <String, List<Map<String, dynamic>>>{};

    for (final id in original.keys) {
      final origList = original[id]!;
      final rawList = serverRoot[id];
      if (rawList is! List) {
        throw WorkoutAdjustmentException('Missing or invalid sets for exercise $id');
      }

      final merged = <Map<String, dynamic>>[];
      for (var i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        final patch = item is Map ? _toMapStringDynamic(item) : null;
        if (patch == null) {
          throw WorkoutAdjustmentException('Invalid set row for $id');
        }
        final base = Map<String, dynamic>.from(
          i < origList.length ? origList[i] : origList.last,
        );

        if (patch.containsKey('weight')) base['weight'] = patch['weight'];
        if (patch.containsKey('reps')) base['reps'] = patch['reps'];
        if (patch.containsKey('distance')) base['distance'] = patch['distance'];
        if (patch.containsKey('duration')) base['duration'] = patch['duration'];
        if (patch['id'] != null) {
          base['id'] = patch['id'];
        }
        base['isComplete'] = false;
        merged.add(base);
      }
      out[id] = merged;
    }

    return out;
  }

  static List<Map<String, dynamic>> _exercisesPayload(List<Exercise> exercises) {
    return exercises
        .map((e) => {
              'id': e.id,
              'name': e.name,
              if (e.movementPattern != null) 'movementPattern': movementPatternToStorage(e.movementPattern!),
              if (e.bodyPart != null) 'bodyPart': e.bodyPart,
              if (e.equipment != null) 'equipment': e.equipment,
            })
        .toList();
  }

  /// Returns new args with LLM-adjusted `initialSetsByExercise`.
  Future<PreWorkoutCheckInArgs> adjustPreWorkoutWithLlm({
    required PreWorkoutCheckInArgs args,
    required String userIssue,
  }) async {
    final sets = args.initialSetsByExercise;
    if (sets == null || sets.isEmpty) {
      throw WorkoutAdjustmentException('No sets to adjust');
    }
    if (args.initialExercises.isEmpty) {
      throw WorkoutAdjustmentException('No exercises in session');
    }

    final payload = <String, dynamic>{
      'workoutName': args.workoutName,
      if (args.workoutId != null) 'workoutId': args.workoutId,
      'userIssue': userIssue.trim(),
      'exercises': _exercisesPayload(args.initialExercises),
      'setsByExercise': sets,
    };

    if (kDebugMode) {
      // ignore: avoid_print
      print('[WorkoutAdjustment] Calling adjustWorkout (${sets.length} exercises)');
    }

    final callable = FirebaseFunctions.instance.httpsCallable('adjustWorkout');
    final result = await callable.call(payload);
    final data = result.data;

    if (data is! Map) {
      throw WorkoutAdjustmentException('Empty or invalid response');
    }

    if (data['success'] != true) {
      final err = data['error']?.toString() ?? 'adjustWorkout failed';
      throw WorkoutAdjustmentException(err);
    }

    final merged = mergeAdjustedSets(sets, data['setsByExercise']);

    if (kDebugMode) {
      // ignore: avoid_print
      print('[WorkoutAdjustment] LLM adjustment applied');
    }

    return PreWorkoutCheckInArgs(
      workoutName: args.workoutName,
      workoutId: args.workoutId,
      programId: args.programId,
      initialExercises: args.initialExercises,
      initialSetsByExercise: merged,
    );
  }
}
