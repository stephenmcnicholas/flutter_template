import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/utils/pr_utils.dart';

void main() {
  test('calculateExercisePr handles repsOnly', () {
    final entries = [
      WorkoutEntry(
        id: 'e1',
        exerciseId: 'pushup',
        reps: 10,
        weight: 0,
        isComplete: true,
      ),
      WorkoutEntry(
        id: 'e2',
        exerciseId: 'pushup',
        reps: 15,
        weight: 0,
        isComplete: true,
      ),
      WorkoutEntry(
        id: 'e3',
        exerciseId: 'pushup',
        reps: 20,
        weight: 0,
        isComplete: false,
      ),
    ];
    final pr = calculateExercisePr(
      inputType: ExerciseInputType.repsOnly,
      entries: entries,
    );
    expect(pr.maxReps, 15);
  });

  test('calculateExercisePr handles repsAndWeight', () {
    final entries = [
      WorkoutEntry(
        id: 'e1',
        exerciseId: 'bench',
        reps: 5,
        weight: 100,
        isComplete: true,
      ),
      WorkoutEntry(
        id: 'e2',
        exerciseId: 'bench',
        reps: 5,
        weight: 110,
        isComplete: true,
      ),
      WorkoutEntry(
        id: 'e3',
        exerciseId: 'bench',
        reps: 5,
        weight: 120,
        isComplete: false,
      ),
    ];
    final pr = calculateExercisePr(
      inputType: ExerciseInputType.repsAndWeight,
      entries: entries,
    );
    expect(pr.maxWeightKg, 110);
  });

  test('calculateExercisePr handles timeOnly', () {
    final entries = [
      WorkoutEntry(
        id: 'e1',
        exerciseId: 'plank',
        reps: 0,
        weight: 0,
        duration: 60,
        isComplete: true,
      ),
      WorkoutEntry(
        id: 'e2',
        exerciseId: 'plank',
        reps: 0,
        weight: 0,
        duration: 90,
        isComplete: true,
      ),
    ];
    final pr = calculateExercisePr(
      inputType: ExerciseInputType.timeOnly,
      entries: entries,
    );
    expect(pr.maxDurationSec, 90);
  });

  test('calculateExercisePr handles distanceAndTime', () {
    final entries = [
      WorkoutEntry(
        id: 'e1',
        exerciseId: 'run',
        reps: 0,
        weight: 0,
        distance: 5.0,
        duration: 1800,
        isComplete: true,
      ),
      WorkoutEntry(
        id: 'e2',
        exerciseId: 'run',
        reps: 0,
        weight: 0,
        distance: 4.9,
        duration: 1900,
        isComplete: true,
      ),
    ];
    final pr = calculateExercisePr(
      inputType: ExerciseInputType.distanceAndTime,
      entries: entries,
    );
    expect(pr.maxDistanceKm, 5.0);
    expect(pr.maxDurationSec, 1900);
  });

  test('calculateWorkoutTotals sums reps and volume', () {
    final entries = [
      WorkoutEntry(
        id: 'e1',
        exerciseId: 'bench',
        reps: 5,
        weight: 100,
        isComplete: true,
      ),
      WorkoutEntry(
        id: 'e2',
        exerciseId: 'pushup',
        reps: 12,
        weight: 0,
        isComplete: true,
      ),
      WorkoutEntry(
        id: 'e3',
        exerciseId: 'bench',
        reps: 3,
        weight: 100,
        isComplete: true,
      ),
    ];
    final totals = calculateWorkoutTotals(
      entries: entries,
      inputTypes: {
        'bench': ExerciseInputType.repsAndWeight,
        'pushup': ExerciseInputType.repsOnly,
      },
    );
    expect(totals.totalReps, 20);
    expect(totals.totalVolumeKg, 800);
  });

  test('exercisesWithNewPrsInSession flags only improvements', () {
    final priorSession = WorkoutSession(
      id: 's1',
      workoutId: 'w1',
      date: DateTime(2024, 1, 1),
      entries: [
        WorkoutEntry(
          id: 'e1',
          exerciseId: 'bench',
          reps: 5,
          weight: 100,
          isComplete: true,
        ),
      ],
    );
    final currentSession = WorkoutSession(
      id: 's2',
      workoutId: 'w1',
      date: DateTime(2024, 1, 2),
      entries: [
        WorkoutEntry(
          id: 'e2',
          exerciseId: 'bench',
          reps: 5,
          weight: 110,
          isComplete: true,
        ),
        WorkoutEntry(
          id: 'e3',
          exerciseId: 'bench',
          reps: 5,
          weight: 100,
          isComplete: true,
        ),
      ],
    );
    final prExercises = exercisesWithNewPrsInSession(
      session: currentSession,
      allSessions: [priorSession, currentSession],
      inputTypes: {'bench': ExerciseInputType.repsAndWeight},
    );
    expect(prExercises, contains('bench'));
  });
}
