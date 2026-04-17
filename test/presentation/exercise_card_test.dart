import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/shared/exercise_card.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/domain/exercise_input_type.dart';
import 'package:fytter/src/domain/workout_entry.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Disable runtime font fetching so tests don't rely on network
  GoogleFonts.config.allowRuntimeFetching = false;
  testWidgets('ExerciseCard shows name and Add Set button', (tester) async {
    var addTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: ExerciseCard(
            exerciseName: 'Bench Press',
            setList: const [],
            onAddSet: () => addTapped = true,
            isExpanded: true,
          ),
        ),
      ),
    );

    expect(find.text('Bench Press'), findsOneWidget);
    final addSetButton = find.text('Add Set');
    expect(addSetButton, findsOneWidget);

    await tester.tap(addSetButton);
    expect(addTapped, isTrue);
  });

  testWidgets('ExerciseCard shows Reps and Weight headers for repsAndWeight', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: ExerciseCard(
            exerciseName: 'Bench Press',
            inputType: ExerciseInputType.repsAndWeight,
            setList: const [],
            onAddSet: () {},
            isExpanded: true,
          ),
        ),
      ),
    );

    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('Weight (kg)'), findsOneWidget);
  });

  testWidgets('ExerciseCard shows only Reps header for repsOnly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: ExerciseCard(
            exerciseName: 'Push-up',
            inputType: ExerciseInputType.repsOnly,
            setList: const [],
            onAddSet: () {},
            isExpanded: true,
          ),
        ),
      ),
    );

    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('Weight'), findsNothing);
  });

  testWidgets('ExerciseCard shows Distance and Time headers for distanceAndTime', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: ExerciseCard(
            exerciseName: 'Running',
            inputType: ExerciseInputType.distanceAndTime,
            setList: const [],
            onAddSet: () {},
            isExpanded: true,
          ),
        ),
      ),
    );

    expect(find.text('Distance (km)'), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Reps'), findsNothing);
    expect(find.text('Weight'), findsNothing);
  });

  testWidgets('ExerciseCard shows only Time header for timeOnly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: ExerciseCard(
            exerciseName: 'Plank',
            inputType: ExerciseInputType.timeOnly,
            setList: const [],
            onAddSet: () {},
            isExpanded: true,
          ),
        ),
      ),
    );

    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Reps'), findsNothing);
    expect(find.text('Weight'), findsNothing);
    expect(find.text('Distance'), findsNothing);
  });

  testWidgets('SetEditor shows correct fields for repsAndWeight', (tester) async {
    final set = WorkoutEntry(
      id: 's1',
      exerciseId: 'e1',
      reps: 5,
      weight: 100.0,
      isComplete: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: SetEditor(
            setNumber: 1,
            set: set,
            inputType: ExerciseInputType.repsAndWeight,
            onChanged: (reps, weight, distance, duration) {},
          ),
        ),
      ),
    );

    // Should have two text fields (reps and weight)
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('SetEditor shows correct fields for repsOnly', (tester) async {
    final set = WorkoutEntry(
      id: 's1',
      exerciseId: 'e1',
      reps: 10,
      weight: 0.0,
      isComplete: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: SetEditor(
            setNumber: 1,
            set: set,
            inputType: ExerciseInputType.repsOnly,
            onChanged: (reps, weight, distance, duration) {},
          ),
        ),
      ),
    );

    // Should have one text field (reps only)
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('SetEditor shows correct fields for distanceAndTime', (tester) async {
    final set = WorkoutEntry(
      id: 's1',
      exerciseId: 'e1',
      reps: 0,
      weight: 0.0,
      distance: 5.0,
      duration: 1800,
      isComplete: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: SetEditor(
            setNumber: 1,
            set: set,
            inputType: ExerciseInputType.distanceAndTime,
            onChanged: (reps, weight, distance, duration) {},
          ),
        ),
      ),
    );

    // Should have two text fields (distance and time)
    expect(find.byType(TextField), findsNWidgets(2));
  });

  testWidgets('SetEditor shows correct fields for timeOnly', (tester) async {
    final set = WorkoutEntry(
      id: 's1',
      exerciseId: 'e1',
      reps: 0,
      weight: 0.0,
      duration: 60,
      isComplete: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: FytterTheme.light,
        home: Scaffold(
          body: SetEditor(
            setNumber: 1,
            set: set,
            inputType: ExerciseInputType.timeOnly,
            onChanged: (reps, weight, distance, duration) {},
          ),
        ),
      ),
    );

    // Should have one text field (time only)
    expect(find.byType(TextField), findsOneWidget);
  });
}

