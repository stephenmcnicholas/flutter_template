import 'package:flutter/material.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/utils/exercise_utils.dart';

Color? categoryColorForBodyPart(BuildContext context, String? bodyPart) {
  final categories = context.themeExt<AppCategoryColors>();
  switch (categoryForBodyPart(bodyPart)) {
    case ExerciseCategory.core:
      return categories.core;
    case ExerciseCategory.upperArms:
      return categories.upperArms;
    case ExerciseCategory.shoulders:
      return categories.shoulders;
    case ExerciseCategory.back:
      return categories.back;
    case ExerciseCategory.chest:
      return categories.chest;
    case ExerciseCategory.legs:
      return categories.legs;
    case ExerciseCategory.cardio:
      return categories.cardio;
    case ExerciseCategory.unknown:
      return null;
  }
}
