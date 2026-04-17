import 'package:fytter/src/domain/exercise.dart';

/// Arguments for the pre-workout check-in flow. Passed as route extra and
/// returned from the screen so the logger receives adjusted sets when rules apply.
class PreWorkoutCheckInArgs {
  final String workoutName;
  final String? workoutId;
  /// When set, session completion can run programme milestone prompts and load scaling.
  final String? programId;
  final List<Exercise> initialExercises;
  final Map<String, List<Map<String, dynamic>>>? initialSetsByExercise;

  const PreWorkoutCheckInArgs({
    required this.workoutName,
    this.workoutId,
    this.programId,
    this.initialExercises = const [],
    this.initialSetsByExercise,
  });
}
