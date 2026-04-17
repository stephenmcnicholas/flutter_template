/// Defines the input type required for different exercise categories.
enum ExerciseInputType {
  /// Traditional strength training: requires reps and weight
  repsAndWeight,

  /// Bodyweight exercises: requires only reps
  repsOnly,

  /// Cardio exercises with distance tracking: requires distance and time
  distanceAndTime,

  /// Isometric holds: requires only time
  timeOnly,
}

String exerciseInputTypeToJson(ExerciseInputType value) {
  switch (value) {
    case ExerciseInputType.timeOnly:
      return 'Time only';
    case ExerciseInputType.distanceAndTime:
      return 'Time and Distance';
    case ExerciseInputType.repsOnly:
      return 'Reps only';
    case ExerciseInputType.repsAndWeight:
      return 'Reps and Weight';
  }
}

ExerciseInputType? exerciseInputTypeFromJson(String? value) {
  if (value == null) return null;
  final normalized = value.trim().toLowerCase();
  switch (normalized) {
    case 'time only':
      return ExerciseInputType.timeOnly;
    case 'time and distance':
      return ExerciseInputType.distanceAndTime;
    case 'reps only':
      return ExerciseInputType.repsOnly;
    case 'reps and weight':
      return ExerciseInputType.repsAndWeight;
    default:
      return null;
  }
}
