import 'exercise.dart';

/// Coarse body areas for beginner-friendly exercise filtering.
/// Granular muscle strings from seed data map into these regions.
enum ExerciseBodyRegion {
  chest,
  back,
  shoulders,
  arms,
  core,
  legs,
  cardio;

  /// User-visible chip label in the filter sheet.
  String get filterLabel => switch (this) {
        ExerciseBodyRegion.chest => 'Chest',
        ExerciseBodyRegion.back => 'Back',
        ExerciseBodyRegion.shoulders => 'Shoulders',
        ExerciseBodyRegion.arms => 'Arms',
        ExerciseBodyRegion.core => 'Core',
        ExerciseBodyRegion.legs => 'Legs',
        ExerciseBodyRegion.cardio => 'Cardio',
      };

  /// Stable key stored in filter state providers (`ExerciseBodyRegion.name`).
  String get storageKey => name;
}

/// Order of chips in filter sheets (large muscle groups first, cardio last).
const List<ExerciseBodyRegion> kExerciseBodyRegionFilterOrder = [
  ExerciseBodyRegion.chest,
  ExerciseBodyRegion.back,
  ExerciseBodyRegion.shoulders,
  ExerciseBodyRegion.arms,
  ExerciseBodyRegion.core,
  ExerciseBodyRegion.legs,
  ExerciseBodyRegion.cardio,
];

/// Same normalization as legacy body-part filter tokens (hyphenated lowercase).
String normalizeExerciseBodyFilterToken(String value) {
  return value.trim().toLowerCase().replaceAll(' ', '-').replaceAll('_', '-');
}

ExerciseBodyRegion? exerciseBodyRegionFromStorageKey(String key) {
  for (final r in ExerciseBodyRegion.values) {
    if (r.name == key) return r;
  }
  return null;
}

Set<ExerciseBodyRegion> exerciseBodyRegionsFromFilterKeys(
    Iterable<String> keys) {
  final out = <ExerciseBodyRegion>{};
  for (final k in keys) {
    final r = exerciseBodyRegionFromStorageKey(k);
    if (r != null) out.add(r);
  }
  return out;
}

/// Derives coarse regions from [Exercise.bodyPart] plus primary/secondary
/// muscle strings (merged). Secondary muscles are included so compound moves
/// (e.g. push-ups) appear under supporting areas such as arms.
Set<ExerciseBodyRegion> exerciseBodyRegionsForMetadata({
  String? bodyPart,
  required List<String> muscles,
}) {
  final tokens = <String>{};
  final bp = bodyPart?.trim();
  if (bp != null && bp.isNotEmpty) tokens.add(bp);
  for (final m in muscles) {
    final t = m.trim();
    if (t.isNotEmpty) tokens.add(t);
  }
  final out = <ExerciseBodyRegion>{};
  for (final token in tokens) {
    final key = normalizeExerciseBodyFilterToken(token);
    final mapped = _tokenToRegions[key];
    if (mapped != null) out.addAll(mapped);
  }
  return out;
}

Set<ExerciseBodyRegion> exerciseBodyRegionsForExercise(
  Exercise exercise,
  List<String> primaryAndSecondaryMuscles,
) {
  return exerciseBodyRegionsForMetadata(
    bodyPart: exercise.bodyPart,
    muscles: primaryAndSecondaryMuscles,
  );
}

bool exerciseMatchesBodyRegionSelection({
  required Set<ExerciseBodyRegion> exerciseRegions,
  required Set<ExerciseBodyRegion> selectedRegions,
}) {
  if (selectedRegions.isEmpty) return true;
  return exerciseRegions.intersection(selectedRegions).isNotEmpty;
}

// Keys are [normalizeExerciseBodyFilterToken] outputs for seed vocabulary
// (`assets/exercises/exercises.json` body parts + muscles).
final Map<String, Set<ExerciseBodyRegion>> _tokenToRegions = {
  // Chest
  'chest': {ExerciseBodyRegion.chest},
  'upper-chest': {ExerciseBodyRegion.chest},
  'lower-chest': {ExerciseBodyRegion.chest},
  // Back
  'back': {ExerciseBodyRegion.back},
  'upper-back': {ExerciseBodyRegion.back},
  'lower-back': {ExerciseBodyRegion.back},
  'lats': {ExerciseBodyRegion.back},
  'rhomboids': {ExerciseBodyRegion.back},
  'traps': {ExerciseBodyRegion.back},
  'thoracic-spine': {ExerciseBodyRegion.back},
  // Shoulders
  'shoulders': {ExerciseBodyRegion.shoulders},
  'front-delts': {ExerciseBodyRegion.shoulders},
  'rear-delts': {ExerciseBodyRegion.shoulders},
  'side-delts': {ExerciseBodyRegion.shoulders},
  'front-shoulders': {ExerciseBodyRegion.shoulders},
  'rotator-cuff': {ExerciseBodyRegion.shoulders},
  'shoulder-stabilisers': {ExerciseBodyRegion.shoulders},
  // Arms
  'arms': {ExerciseBodyRegion.arms},
  'biceps': {ExerciseBodyRegion.arms},
  'triceps': {ExerciseBodyRegion.arms},
  'forearms': {ExerciseBodyRegion.arms},
  'brachialis': {ExerciseBodyRegion.arms},
  // Core
  'core': {ExerciseBodyRegion.core},
  'abs': {ExerciseBodyRegion.core},
  'obliques': {ExerciseBodyRegion.core},
  // Legs / hips (single beginner bucket)
  'legs': {ExerciseBodyRegion.legs},
  'quads': {ExerciseBodyRegion.legs},
  'hamstrings': {ExerciseBodyRegion.legs},
  'calves': {ExerciseBodyRegion.legs},
  'glutes': {ExerciseBodyRegion.legs},
  'hips': {ExerciseBodyRegion.legs},
  'hip-flexors': {ExerciseBodyRegion.legs},
  'psoas': {ExerciseBodyRegion.legs},
  'adductors': {ExerciseBodyRegion.legs},
  'abductors': {ExerciseBodyRegion.legs},
  'ankle': {ExerciseBodyRegion.legs},
  'ankles': {ExerciseBodyRegion.legs},
  'soleus': {ExerciseBodyRegion.legs},
  'achilles': {ExerciseBodyRegion.legs},
  // Cardio — explicit tag only (not inferred from time/distance logging)
  'cardio': {ExerciseBodyRegion.cardio},
};
