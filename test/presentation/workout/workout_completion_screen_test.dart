import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/presentation/workout/workout_completion_screen.dart';
import 'package:fytter/src/providers/audio_providers.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../support/fake_audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget buildScreen(WorkoutCompletionSummary summary) {
    return ProviderScope(
      overrides: [
        audioServiceProvider.overrideWithValue(FakeAudioService()),
      ],
      child: MaterialApp(
        theme: FytterTheme.light,
        home: WorkoutCompletionScreen(summary: summary),
      ),
    );
  }

  testWidgets('WorkoutCompletionScreen shows summary stats', (tester) async {
    const summary = WorkoutCompletionSummary(
      workoutName: 'Quick Start',
      exercisesCompleted: 3,
      totalSets: 8,
      totalReps: 64,
      totalVolume: 1240,
      duration: Duration(minutes: 12, seconds: 30),
    );

    await tester.pumpWidget(buildScreen(summary));

    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Great work!'), findsOneWidget);
    expect(find.text('Quick Start'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('12m 30s'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('Reps'), findsOneWidget);
    expect(find.text('64'), findsOneWidget);
    expect(find.text('Total volume'), findsOneWidget);
    expect(find.text('1240kg'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Done'), 200);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('shows programme progress, next workout text, and sub-minute duration', (tester) async {
    const summary = WorkoutCompletionSummary(
      workoutName: 'Day A',
      exercisesCompleted: 2,
      totalSets: 6,
      totalReps: 40,
      totalVolume: 800,
      duration: Duration(seconds: 45),
      programName: 'Strength block',
      workoutsCompletedInProgram: 3,
      totalWorkoutsInProgram: 12,
      nextWorkoutText: 'Next: pull day Thursday',
    );

    await tester.pumpWidget(buildScreen(summary));
    await tester.pumpAndSettle();

    expect(find.text('45s'), findsOneWidget);
    expect(find.textContaining('3 of 12'), findsOneWidget);
    expect(find.textContaining('Strength block'), findsOneWidget);
    expect(find.text('Next: pull day Thursday'), findsOneWidget);
  });
}
