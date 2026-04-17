import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_body_region.dart';

void main() {
  group('normalizeExerciseBodyFilterToken', () {
    test('trims and hyphenates', () {
      expect(normalizeExerciseBodyFilterToken('  Upper Back  '), 'upper-back');
      expect(normalizeExerciseBodyFilterToken('Hip Flexors'), 'hip-flexors');
    });
  });

  group('exerciseBodyRegionsForMetadata', () {
    test('maps quads body part to legs', () {
      final r = exerciseBodyRegionsForMetadata(
        bodyPart: 'Quads',
        muscles: const [],
      );
      expect(r, {ExerciseBodyRegion.legs});
    });

    test('unions body part and muscles', () {
      final r = exerciseBodyRegionsForMetadata(
        bodyPart: 'Chest',
        muscles: const ['Triceps'],
      );
      expect(r, containsAll([ExerciseBodyRegion.chest, ExerciseBodyRegion.arms]));
    });

    test('secondary-style compound: chest + triceps', () {
      final r = exerciseBodyRegionsForMetadata(
        bodyPart: 'Chest',
        muscles: const ['Chest', 'Triceps'],
      );
      expect(r, containsAll([ExerciseBodyRegion.chest, ExerciseBodyRegion.arms]));
    });

    test('isolation curl maps to arms only', () {
      final r = exerciseBodyRegionsForMetadata(
        bodyPart: null,
        muscles: const ['Biceps'],
      );
      expect(r, {ExerciseBodyRegion.arms});
    });

    test('cardio from body part', () {
      final r = exerciseBodyRegionsForMetadata(
        bodyPart: 'Cardio',
        muscles: const [],
      );
      expect(r, {ExerciseBodyRegion.cardio});
    });

    test('psoas maps to legs', () {
      final r = exerciseBodyRegionsForMetadata(
        bodyPart: null,
        muscles: const ['Psoas'],
      );
      expect(r, {ExerciseBodyRegion.legs});
    });
  });

  group('exerciseBodyRegionsForExercise', () {
    test('delegates to metadata', () {
      const ex = Exercise(
        id: 'x',
        name: 'Push-up',
        description: '',
        bodyPart: 'Chest',
      );
      final r = exerciseBodyRegionsForExercise(ex, const ['Triceps']);
      expect(r, contains(ExerciseBodyRegion.arms));
      expect(r, contains(ExerciseBodyRegion.chest));
    });
  });

  group('exerciseBodyRegionsFromFilterKeys', () {
    test('parses enum names', () {
      final s = exerciseBodyRegionsFromFilterKeys(['chest', 'arms', 'bogus']);
      expect(s, {ExerciseBodyRegion.chest, ExerciseBodyRegion.arms});
    });
  });

  group('exerciseMatchesBodyRegionSelection', () {
    test('empty selection matches all', () {
      expect(
        exerciseMatchesBodyRegionSelection(
          exerciseRegions: {},
          selectedRegions: {},
        ),
        true,
      );
    });

    test('non-empty selection requires intersection', () {
      expect(
        exerciseMatchesBodyRegionSelection(
          exerciseRegions: {ExerciseBodyRegion.chest},
          selectedRegions: {ExerciseBodyRegion.arms},
        ),
        false,
      );
      expect(
        exerciseMatchesBodyRegionSelection(
          exerciseRegions: {ExerciseBodyRegion.chest, ExerciseBodyRegion.arms},
          selectedRegions: {ExerciseBodyRegion.arms},
        ),
        true,
      );
    });
  });
}
