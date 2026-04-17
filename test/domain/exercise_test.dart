import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';

void main() {
  group('Exercise model', () {
    const sample = Exercise(
      id: 'e1',
      name: 'Squat',
      description: 'Compound leg exercise',
    );

    test('value equality and hashCode', () {
      const same = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
      );
      expect(sample, equals(same));
      expect(sample.hashCode, same.hashCode);
    });

    test('toJson/fromJson round-trip', () {
      final json = sample.toJson();
      final restored = Exercise.fromJson(json);
      expect(restored, equals(sample));
    });

    test('description defaults to empty string', () {
      const noDesc = Exercise(id: 'e2', name: 'Push-up');
      expect(noDesc.description, isEmpty);
    });

    test('includes thumbnailPath and mediaPath in equality', () {
      const withMedia = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
        thumbnailPath: 'exercises/thumbnails/squat.jpg',
        mediaPath: 'exercises/media/squat.mp4',
      );
      const withoutMedia = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
      );
      expect(withMedia, isNot(equals(withoutMedia)));
      expect(withMedia.hashCode, isNot(equals(withoutMedia.hashCode)));
    });

    test('includes bodyPart and equipment in equality', () {
      const withMetadata = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
        bodyPart: 'Quads',
        equipment: 'Barbell',
      );
      const withoutMetadata = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
      );
      expect(withMetadata, isNot(equals(withoutMetadata)));
      expect(withMetadata.hashCode, isNot(equals(withoutMetadata.hashCode)));
    });

    test('includes loggingType in equality', () {
      const withLogging = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
        loggingType: ExerciseInputType.repsOnly,
      );
      const withoutLogging = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
      );
      expect(withLogging, isNot(equals(withoutLogging)));
      expect(withLogging.hashCode, isNot(equals(withoutLogging.hashCode)));
    });

    test('toJson/fromJson round-trip with media paths', () {
      const withMedia = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
        thumbnailPath: 'exercises/thumbnails/squat.jpg',
        mediaPath: 'exercises/media/squat.mp4',
      );
      final json = withMedia.toJson();
      expect(json['thumbnailPath'], 'exercises/thumbnails/squat.jpg');
      expect(json['mediaPath'], 'exercises/media/squat.mp4');
      
      final restored = Exercise.fromJson(json);
      expect(restored, equals(withMedia));
      expect(restored.thumbnailPath, 'exercises/thumbnails/squat.jpg');
      expect(restored.mediaPath, 'exercises/media/squat.mp4');
    });

    test('fromJson handles null media paths', () {
      final json = {
        'id': 'e1',
        'name': 'Squat',
        'description': 'Compound leg exercise',
      };
      final exercise = Exercise.fromJson(json);
      expect(exercise.thumbnailPath, isNull);
      expect(exercise.mediaPath, isNull);
    });

    test('toJson/fromJson round-trip with bodyPart and equipment', () {
      const withMetadata = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
        bodyPart: 'Quads',
        equipment: 'Barbell',
      );
      final json = withMetadata.toJson();
      expect(json['bodyPart'], 'Quads');
      expect(json['equipment'], 'Barbell');
      
      final restored = Exercise.fromJson(json);
      expect(restored, equals(withMetadata));
      expect(restored.bodyPart, 'Quads');
      expect(restored.equipment, 'Barbell');
    });

    test('fromJson handles null bodyPart and equipment', () {
      final json = {
        'id': 'e1',
        'name': 'Squat',
        'description': 'Compound leg exercise',
      };
      final exercise = Exercise.fromJson(json);
      expect(exercise.bodyPart, isNull);
      expect(exercise.equipment, isNull);
    });

    test('toJson/fromJson round-trip with loggingType', () {
      const withLogging = Exercise(
        id: 'e1',
        name: 'Squat',
        description: 'Compound leg exercise',
        loggingType: ExerciseInputType.repsOnly,
      );
      final json = withLogging.toJson();
      expect(json['loggingType'], 'Reps only');

      final restored = Exercise.fromJson(json);
      expect(restored, equals(withLogging));
      expect(restored.loggingType, ExerciseInputType.repsOnly);
    });

    test('fromJson handles null loggingType', () {
      final json = {
        'id': 'e1',
        'name': 'Squat',
        'description': 'Compound leg exercise',
      };
      final exercise = Exercise.fromJson(json);
      expect(exercise.loggingType, isNull);
    });
  });
}