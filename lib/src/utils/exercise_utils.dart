import '../domain/exercise.dart';
import '../domain/exercise_input_type.dart';

/// Determines the input type required for an exercise based on its JSON definition.
ExerciseInputType getExerciseInputType(Exercise exercise) {
  return exercise.loggingType ?? ExerciseInputType.repsAndWeight;
}

/// Normalized exercise categories for UI grouping.
enum ExerciseCategory { core, upperArms, shoulders, back, chest, legs, cardio, unknown }

/// Maps bodyPart strings into a normalized category.
ExerciseCategory categoryForBodyPart(String? bodyPart) {
  if (bodyPart == null || bodyPart.trim().isEmpty) {
    return ExerciseCategory.unknown;
  }

  final value = bodyPart.toLowerCase();

  if (value.contains('cardio')) return ExerciseCategory.cardio;
  if (value.contains('chest') || value.contains('pec')) return ExerciseCategory.chest;
  if (value.contains('back') || value.contains('lat') || value.contains('trap')) {
    return ExerciseCategory.back;
  }
  if (value.contains('shoulder') || value.contains('delt')) {
    return ExerciseCategory.shoulders;
  }
  if (value.contains('bicep') ||
      value.contains('tricep') ||
      value.contains('forearm') ||
      value.contains('arm')) {
    return ExerciseCategory.upperArms;
  }
  if (value.contains('leg') ||
      value.contains('quad') ||
      value.contains('hamstring') ||
      value.contains('calf') ||
      value.contains('glute') ||
      value.contains('hip') ||
      value.contains('adductor') ||
      value.contains('abductor')) {
    return ExerciseCategory.legs;
  }
  if (value.contains('core') || value.contains('abs') || value.contains('abdom') || value.contains('oblique')) {
    return ExerciseCategory.core;
  }

  return ExerciseCategory.unknown;
}

/// Checks if an exercise requires weight input.
bool exerciseRequiresWeight(Exercise exercise) {
  return getExerciseInputType(exercise) == ExerciseInputType.repsAndWeight;
}
