import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/presentation/shared/exercise_progress_chart.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/utils/format_utils.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final repsExercise = const Exercise(
    id: 'ex1',
    name: 'Push Up',
    description: '',
    equipment: 'Bodyweight',
    loggingType: ExerciseInputType.repsOnly,
  );
  final weightExercise = const Exercise(
    id: 'ex2',
    name: 'Bench Press',
    description: '',
    equipment: 'Barbell',
    loggingType: ExerciseInputType.repsAndWeight,
  );
  final timeExercise = const Exercise(
    id: 'ex3',
    name: 'Plank',
    description: '',
    equipment: 'Bodyweight',
    loggingType: ExerciseInputType.timeOnly,
  );
  final distanceExercise = const Exercise(
    id: 'ex4',
    name: 'Running',
    description: '',
    bodyPart: 'Cardio',
    equipment: 'Bodyweight',
    loggingType: ExerciseInputType.distanceAndTime,
  );

  ExerciseWorkoutHistory historyFor(Exercise exercise) {
    final entry = WorkoutEntry(
      id: 'entry1',
      exerciseId: exercise.id,
      reps: 5,
      weight: 60,
      distance: 2.0,
      duration: 120,
      isComplete: true,
      timestamp: DateTime(2024, 1, 1),
    );
    final session = WorkoutSession(
      id: 'session1',
      workoutId: 'w1',
      date: DateTime(2024, 1, 1),
      name: 'Test',
      entries: [entry],
    );
    return ExerciseWorkoutHistory(session: session, entries: [entry]);
  }

  testWidgets('ExerciseProgressChart shows empty state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: ExerciseProgressChart(
          exercise: repsExercise,
          history: const [],
          weightUnit: WeightUnit.kg,
          distanceUnit: DistanceUnit.km,
        ),
      ),
    );
    expect(find.text('No exercise data available'), findsOneWidget);
  });

  testWidgets('ExerciseProgressChart renders repsOnly legend', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: ExerciseProgressChart(
          exercise: repsExercise,
          history: [historyFor(repsExercise)],
          weightUnit: WeightUnit.kg,
          distanceUnit: DistanceUnit.km,
        ),
      ),
    );
    expect(find.text('Reps'), findsOneWidget);
  });

  testWidgets('ExerciseProgressChart renders repsAndWeight legend', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: ExerciseProgressChart(
          exercise: weightExercise,
          history: [historyFor(weightExercise)],
          weightUnit: WeightUnit.kg,
          distanceUnit: DistanceUnit.km,
        ),
      ),
    );
    expect(find.textContaining('Weight'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
  });

  testWidgets('ExerciseProgressChart renders timeOnly legend', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: ExerciseProgressChart(
          exercise: timeExercise,
          history: [historyFor(timeExercise)],
          weightUnit: WeightUnit.kg,
          distanceUnit: DistanceUnit.km,
        ),
      ),
    );
    expect(find.text('Time (min)'), findsOneWidget);
  });

  testWidgets('ExerciseProgressChart renders distanceAndTime legend', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: ExerciseProgressChart(
          exercise: distanceExercise,
          history: [historyFor(distanceExercise)],
          weightUnit: WeightUnit.kg,
          distanceUnit: DistanceUnit.km,
        ),
      ),
    );
    expect(find.textContaining('Distance'), findsOneWidget);
    expect(find.text('Time (min)'), findsOneWidget);
  });
}
