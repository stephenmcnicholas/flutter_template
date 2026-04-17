import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/utils/exercise_utils.dart';

void main() {
  group('getExerciseInputType', () {
    test('returns repsAndWeight when loggingType is null', () {
      final exercise = Exercise(
        id: 'e1',
        name: 'Unknown',
        description: '',
        bodyPart: 'Chest',
        equipment: 'Barbell',
        loggingType: null,
      );
      expect(getExerciseInputType(exercise), ExerciseInputType.repsAndWeight);
    });

    test('returns distanceAndTime for running exercises', () {
      final exercise = Exercise(
        id: 'e1',
        name: 'Running',
        description: '',
        bodyPart: 'Cardio',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.distanceAndTime,
      );
      expect(getExerciseInputType(exercise), ExerciseInputType.distanceAndTime);
    });

    test('returns distanceAndTime for cardio machines', () {
      final treadmill = Exercise(
        id: 'e1',
        name: 'Treadmill',
        description: '',
        bodyPart: 'Cardio',
        equipment: 'Treadmill',
        loggingType: ExerciseInputType.distanceAndTime,
      );
      expect(getExerciseInputType(treadmill), ExerciseInputType.distanceAndTime);

      final bike = Exercise(
        id: 'e2',
        name: 'Stationary Bike',
        description: '',
        bodyPart: 'Cardio',
        equipment: 'Stationary Bike',
        loggingType: ExerciseInputType.distanceAndTime,
      );
      expect(getExerciseInputType(bike), ExerciseInputType.distanceAndTime);

      final rowing = Exercise(
        id: 'e3',
        name: 'Rowing',
        description: '',
        bodyPart: 'Cardio',
        equipment: 'Rowing Machine',
        loggingType: ExerciseInputType.distanceAndTime,
      );
      expect(getExerciseInputType(rowing), ExerciseInputType.distanceAndTime);
    });

    test('returns timeOnly for isometric exercises', () {
      final plank = Exercise(
        id: 'e1',
        name: 'Plank',
        description: '',
        bodyPart: 'Core',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.timeOnly,
      );
      expect(getExerciseInputType(plank), ExerciseInputType.timeOnly);

      final hollowHold = Exercise(
        id: 'e2',
        name: 'Hollow Hold',
        description: '',
        bodyPart: 'Core',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.timeOnly,
      );
      expect(getExerciseInputType(hollowHold), ExerciseInputType.timeOnly);

      final deadHang = Exercise(
        id: 'e3',
        name: 'Dead Hang',
        description: '',
        bodyPart: 'Back',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.timeOnly,
      );
      expect(getExerciseInputType(deadHang), ExerciseInputType.timeOnly);

      final wallSit = Exercise(
        id: 'e4',
        name: 'Wall Sit',
        description: '',
        bodyPart: 'Quads',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.timeOnly,
      );
      expect(getExerciseInputType(wallSit), ExerciseInputType.timeOnly);
    });

    test('returns repsOnly for bodyweight exercises (not cardio, not isometric)', () {
      final pushup = Exercise(
        id: 'e1',
        name: 'Push-up',
        description: '',
        bodyPart: 'Chest',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.repsOnly,
      );
      expect(getExerciseInputType(pushup), ExerciseInputType.repsOnly);

      final squat = Exercise(
        id: 'e2',
        name: 'Bodyweight Squat',
        description: '',
        bodyPart: 'Quads',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.repsOnly,
      );
      expect(getExerciseInputType(squat), ExerciseInputType.repsOnly);
    });

    test('returns repsAndWeight for traditional strength exercises', () {
      final benchPress = Exercise(
        id: 'e1',
        name: 'Bench Press',
        description: '',
        bodyPart: 'Chest',
        equipment: 'Barbell',
        loggingType: ExerciseInputType.repsAndWeight,
      );
      expect(getExerciseInputType(benchPress), ExerciseInputType.repsAndWeight);

      final deadlift = Exercise(
        id: 'e2',
        name: 'Deadlift',
        description: '',
        bodyPart: 'Back',
        equipment: 'Barbell',
        loggingType: ExerciseInputType.repsAndWeight,
      );
      expect(getExerciseInputType(deadlift), ExerciseInputType.repsAndWeight);

      final dumbbellCurl = Exercise(
        id: 'e3',
        name: 'Dumbbell Curl',
        description: '',
        bodyPart: 'Biceps',
        equipment: 'Dumbbell',
        loggingType: ExerciseInputType.repsAndWeight,
      );
      expect(getExerciseInputType(dumbbellCurl), ExerciseInputType.repsAndWeight);
    });

    test('prioritizes timeOnly over repsOnly for bodyweight isometric exercises', () {
      final plank = Exercise(
        id: 'e1',
        name: 'Plank',
        description: '',
        bodyPart: 'Core',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.timeOnly,
      );
      expect(getExerciseInputType(plank), ExerciseInputType.timeOnly);
    });

    test('prioritizes distanceAndTime over other types for running', () {
      final running = Exercise(
        id: 'e1',
        name: 'Running',
        description: '',
        bodyPart: 'Legs',
        equipment: 'None',
        loggingType: ExerciseInputType.distanceAndTime,
      );
      expect(getExerciseInputType(running), ExerciseInputType.distanceAndTime);
    });
  });

  group('exerciseRequiresWeight', () {
    test('returns true for repsAndWeight exercises', () {
      final benchPress = Exercise(
        id: 'e1',
        name: 'Bench Press',
        description: '',
        bodyPart: 'Chest',
        equipment: 'Barbell',
        loggingType: ExerciseInputType.repsAndWeight,
      );
      expect(exerciseRequiresWeight(benchPress), isTrue);
    });

    test('returns false for repsOnly exercises', () {
      final pushup = Exercise(
        id: 'e1',
        name: 'Push-up',
        description: '',
        bodyPart: 'Chest',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.repsOnly,
      );
      expect(exerciseRequiresWeight(pushup), isFalse);
    });

    test('returns false for distanceAndTime exercises', () {
      final running = Exercise(
        id: 'e1',
        name: 'Running',
        description: '',
        bodyPart: 'Cardio',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.distanceAndTime,
      );
      expect(exerciseRequiresWeight(running), isFalse);
    });

    test('returns false for timeOnly exercises', () {
      final plank = Exercise(
        id: 'e1',
        name: 'Plank',
        description: '',
        bodyPart: 'Core',
        equipment: 'Bodyweight',
        loggingType: ExerciseInputType.timeOnly,
      );
      expect(exerciseRequiresWeight(plank), isFalse);
    });
  });

  group('categoryForBodyPart', () {
    test('returns unknown for null or empty', () {
      expect(categoryForBodyPart(null), ExerciseCategory.unknown);
      expect(categoryForBodyPart(''), ExerciseCategory.unknown);
    });

    test('returns unknown for whitespace-only', () {
      expect(categoryForBodyPart('   '), ExerciseCategory.unknown);
    });

    test('matches cardio category', () {
      expect(categoryForBodyPart('Cardio'), ExerciseCategory.cardio);
    });

    test('matches chest category', () {
      expect(categoryForBodyPart('Upper Chest'), ExerciseCategory.chest);
    });

    test('matches back category', () {
      expect(categoryForBodyPart('Upper Back'), ExerciseCategory.back);
    });

    test('matches shoulders category', () {
      expect(categoryForBodyPart('Side Delts'), ExerciseCategory.shoulders);
    });

    test('matches upper arms category', () {
      expect(categoryForBodyPart('Biceps'), ExerciseCategory.upperArms);
    });

    test('matches legs category', () {
      expect(categoryForBodyPart('Glutes'), ExerciseCategory.legs);
    });

    test('matches core category', () {
      expect(categoryForBodyPart('Abs'), ExerciseCategory.core);
    });
  });
}
