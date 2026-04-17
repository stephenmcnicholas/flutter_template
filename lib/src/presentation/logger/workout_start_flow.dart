import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/presentation/logger/lets_go_transition_screen.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/presentation/logger/pre_workout_check_in_screen.dart';
import 'package:fytter/src/presentation/logger/workout_duration_estimate.dart';
import 'package:fytter/src/providers/logger_sheet_provider.dart';
import 'package:fytter/src/providers/rest_timer_settings_provider.dart';
import 'package:fytter/src/providers/workout_experience_settings_provider.dart';

/// Opens the logger sheet with [args] (no check-in or transition screens).
void openWorkoutLoggerFromArgs(WidgetRef ref, PreWorkoutCheckInArgs args) {
  ref.read(loggerSheetProvider.notifier).show(
        workoutName: args.workoutName,
        workoutId: args.workoutId,
        programId: args.programId,
        initialExercises: args.initialExercises,
        initialSetsByExercise: args.initialSetsByExercise,
      );
}

/// Runs the unified workout start flow.
///
/// **Guided** ([WorkoutExperienceMode.guided]): check-in → Let's go → logger sheet.
/// **Logger** ([WorkoutExperienceMode.logger]): opens the logger sheet immediately.
///
/// Call this instead of [LoggerSheetNotifier.show] from all "Start Workout" entry points.
Future<void> startWorkoutFlow(
  BuildContext context,
  WidgetRef ref,
  PreWorkoutCheckInArgs args,
) async {
  if (!context.mounted) return;

  // Skip check-in and Let's go for empty quickstart workouts — there are no
  // exercises yet, so the duration estimate is meaningless and the guided flow
  // adds no value.
  final isEmptyWorkout = args.initialExercises.isEmpty &&
      (args.initialSetsByExercise == null || args.initialSetsByExercise!.isEmpty);
  if (isEmptyWorkout) {
    openWorkoutLoggerFromArgs(ref, args);
    return;
  }

  final experience = ref.read(workoutExperienceSettingsProvider);
  if (!experience.isLoading && experience.isLoggerStart) {
    openWorkoutLoggerFromArgs(ref, args);
    return;
  }

  final checkInResult = await Navigator.of(context).push<PreWorkoutCheckInArgs>(
    MaterialPageRoute<PreWorkoutCheckInArgs>(
      builder: (context) => PreWorkoutCheckInScreen(args: args),
    ),
  );

  if (!context.mounted || checkInResult == null) return;

  final restState = ref.read(restTimerSettingsProvider);
  final restSeconds = restState.isLoading ? 120 : restState.defaultSeconds;
  final durationMinutes = estimateWorkoutDurationMinutes(
    initialSetsByExercise: args.initialSetsByExercise,
    restSeconds: restSeconds,
  );

  final transitionArgs = LetsGoTransitionArgs(
    args: checkInResult,
    workoutName: args.workoutName,
    durationMinutes: durationMinutes,
  );

  await Navigator.of(context).push<PreWorkoutCheckInArgs>(
    MaterialPageRoute<PreWorkoutCheckInArgs>(
      builder: (context) => LetsGoTransitionScreen(transitionArgs: transitionArgs),
    ),
  );

  if (!context.mounted) return;

  openWorkoutLoggerFromArgs(ref, checkInResult);
}
