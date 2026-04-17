import 'package:go_router/go_router.dart';
import 'ai_programme/context_capture_screen.dart';
import 'programme/end_programme_review_screen.dart';
import 'ai_programme/ai_programme_loading_screen.dart';
import 'ai_programme/ai_programme_premium_gate.dart';
import 'ai_programme/programme_preview_screen.dart';
import 'ai_programme/about_programme_screen.dart';
import 'exercise/exercise_edit_screen.dart';
import 'exercise/exercise_detail_screen.dart';
import 'exercise/exercise_selection_screen.dart';
import 'package:fytter/src/presentation/workout/workout_builder_screen.dart';
import 'history/history_detail_screen.dart';
import 'logger/workout_logger_screen.dart';
import 'logger/rest_timer_settings_screen.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';
import 'settings/settings_screen.dart';
import 'profile/profile_screen.dart';
import 'program/program_builder_screen.dart';
import 'splash/splash_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/presentation/root_scaffold.dart';
import 'workout/workout_completion_screen.dart';
import 'logger/pre_workout_check_in_screen.dart';
import 'logger/lets_go_transition_screen.dart';
import 'logger/post_workout_mood_screen.dart';
import 'program/mid_programme_check_in_screen.dart';

/// Global router for the Fytter app.
final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const RootScaffold(),
    ),
    GoRoute(
      path: '/logger',
      builder: (context, state) => const WorkoutLoggerScreen(),
    ),
    GoRoute(
      path: '/workout/check-in',
      builder: (context, state) {
        final args = state.extra as PreWorkoutCheckInArgs?;
        if (args == null) return const RootScaffold();
        return PreWorkoutCheckInScreen(args: args);
      },
    ),
    GoRoute(
      path: '/workout/lets-go',
      builder: (context, state) {
        final transitionArgs = state.extra as LetsGoTransitionArgs?;
        if (transitionArgs == null) return const RootScaffold();
        return LetsGoTransitionScreen(transitionArgs: transitionArgs);
      },
    ),
    GoRoute(
      path: '/workout/mood',
      builder: (context, state) {
        final args = state.extra as PostWorkoutMoodArgs?;
        if (args == null) return const RootScaffold();
        return PostWorkoutMoodScreen(args: args);
      },
    ),
    GoRoute(
      path: '/program/mid-check-in',
      builder: (context, state) {
        final args = state.extra as MidProgrammeCheckInArgs?;
        if (args == null) return const RootScaffold();
        return MidProgrammeCheckInScreen(args: args);
      },
    ),
    GoRoute(
      path: '/workout/completion',
      builder: (context, state) {
        final summary = state.extra as WorkoutCompletionSummary?;
        if (summary == null) {
          return const RootScaffold();
        }
        return WorkoutCompletionScreen(summary: summary);
      },
    ),
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/exercise/new',
      builder: (context, state) => const ExerciseEditScreen(),
    ),
    GoRoute(
      path: '/exercise/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final edit = state.queryParameters['edit'] == 'true';
        if (edit) {
          return ExerciseEditScreen(exerciseId: id);
        }
        return ExerciseDetailScreen(exerciseId: id);
      },
    ),
    GoRoute(
      path: '/exercises/select',
      builder: (context, state) {
        // Get already selected IDs from query parameter (comma-separated)
        final alreadySelectedParam = state.queryParameters['alreadySelected'] ?? '';
        final alreadySelectedIds = alreadySelectedParam.isEmpty
            ? <String>[]
            : alreadySelectedParam.split(',').where((id) => id.isNotEmpty).toList();
        final singleSelection = state.queryParameters['singleSelection'] == 'true';
        final title = state.queryParameters['title'] ?? 'Add Exercises';
        final actionLabel = state.queryParameters['actionLabel'] ?? 'Add';
        final minRequiredParam = state.queryParameters['minRequired'];
        final minRequired = minRequiredParam != null ? int.tryParse(minRequiredParam) ?? 1 : 1;
        return ExerciseSelectionScreen(
          alreadySelectedIds: alreadySelectedIds,
          singleSelection: singleSelection,
          title: title,
          actionLabel: actionLabel,
          minRequired: minRequired,
        );
      },
    ),
    GoRoute(
      path: '/workouts/new',
      builder: (context, state) => const WorkoutBuilderScreen(),
    ),
    GoRoute(
      path: '/workouts/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return WorkoutBuilderScreen(workoutId: id);
      },
    ),
    GoRoute(
      path: '/ai-programme/create',
      builder: (context, state) {
        final extra = state.extra;
        final previousSummary = extra is String ? extra : null;
        return AiProgrammePremiumGate(
          child: ContextCaptureScreen(previousProgrammeSummary: previousSummary),
        );
      },
    ),
    GoRoute(
      path: '/programme/end-review',
      builder: (context, state) {
        final args = state.extra as EndProgrammeReviewArgs?;
        if (args == null) return const RootScaffold();
        return EndProgrammeReviewScreen(args: args);
      },
    ),
    GoRoute(
      path: '/ai-programme/loading',
      builder: (context, state) => const AiProgrammePremiumGate(
        child: AiProgrammeLoadingScreen(),
      ),
    ),
    GoRoute(
      path: '/ai-programme/preview',
      builder: (context, state) => const AiProgrammePremiumGate(
        child: ProgrammePreviewScreen(),
      ),
    ),
    GoRoute(
      path: '/programs/new',
      builder: (context, state) => const ProgramBuilderScreen(),
    ),
    GoRoute(
      path: '/programs/edit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ProgramBuilderScreen(programId: id);
      },
    ),
    GoRoute(
      path: '/programs/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RootScaffold(
          initialTabIndex: 2,
          initialProgramId: id,
        );
      },
    ),
    GoRoute(
      path: '/programs/:id/about',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AboutProgrammeScreen(programId: id);
      },
    ),
    GoRoute(
      path: '/history/:id',
      name: 'historyDetail',
      builder: (context, state) {
        final workoutId = state.pathParameters['id']!;
        return HistoryDetailScreen(workoutId: workoutId);
      },
    ),
    GoRoute(
      path: '/settings/rest-timer',
      builder: (context, state) => const RestTimerSettingsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);