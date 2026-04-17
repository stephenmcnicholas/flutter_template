import 'package:flutter/material.dart';
import 'package:fytter/src/presentation/shared/bottom_nav_bar.dart';
import 'package:fytter/src/presentation/exercise/exercise_list_screen.dart';
import 'package:fytter/src/presentation/shared/more_menu.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/presentation/logger/workout_logger_sheet.dart';
import 'package:fytter/src/presentation/logger/workout_start_flow.dart';
import 'package:fytter/src/presentation/program/program_list_screen.dart';
import 'package:fytter/src/presentation/progress/progress_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/presentation/workout/workouts_tabbed_screen_with_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fytter/src/providers/logger_sheet_provider.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/presentation/shared/modern_app_bar.dart';
import 'package:fytter/src/presentation/shared/app_sheet_transition.dart';
import 'package:fytter/src/presentation/program/program_calendar_tab.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:fytter/src/presentation/program/program_detail_screen.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/domain/auth_user.dart';
import 'package:fytter/src/providers/auth_providers.dart';
import 'package:fytter/src/providers/login_prompt_provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class RootScaffold extends ConsumerStatefulWidget {
  final int? initialTabIndex;
  final String? initialProgramId;

  const RootScaffold({
    super.key,
    this.initialTabIndex,
    this.initialProgramId,
  });

  @override
  ConsumerState<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends ConsumerState<RootScaffold> {
  bool _loginPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final initialTab = widget.initialTabIndex ??
          (widget.initialProgramId != null ? 2 : null);
      if (initialTab != null) {
        ref.read(selectedTabIndexProvider.notifier).state = initialTab;
      }
      if (widget.initialProgramId != null) {
        ref.read(selectedProgramIdProvider.notifier).state = widget.initialProgramId;
      }
    });
  }

  void _maybeShowLoginPrompt(
    AuthStatus authStatus,
    LoginPromptState promptState,
    bool authLoaded,
  ) {
    if (_loginPromptShown ||
        promptState.isLoading ||
        promptState.dismissed ||
        !authLoaded ||
        authStatus != AuthStatus.signedOut) {
      return;
    }

    _loginPromptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final shouldSignIn = await showConfirmDialog(
        context,
        title: 'Sign in to back up your data',
        message: 'Sign in to sync workouts across devices. You can keep using Fytter offline.',
        confirmText: 'Sign in',
        cancelText: 'Continue offline',
      );
      await ref.read(loginPromptProvider.notifier).dismiss();
      if (!mounted) return;
      if (shouldSignIn == true) {
        context.push('/auth/login');
      }
    });
  }

  Future<void> _showWorkoutLoggerSheet(
    String workoutName, {
    String? workoutId,
    List<Exercise> initialExercises = const [],
    Map<String, List<Map<String, dynamic>>>? initialSetsByExercise,
  }) async {
    final args = PreWorkoutCheckInArgs(
      workoutName: workoutName,
      workoutId: workoutId,
      initialExercises: initialExercises,
      initialSetsByExercise: initialSetsByExercise,
    );
    await startWorkoutFlow(context, ref, args);
  }

  void _onTabSelected(int index) {
    if (index == 4) {
      // Show More menu as a modal bottom sheet
      showModalBottomSheet(
        context: context,
        builder: (context) => const AppSheetTransition(
          child: MoreMenu(),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      );
      // Do not change the selected tab
      return;
    }
    ref.read(selectedTabIndexProvider.notifier).state = index;
  }

  void _handleProfileTap() {
    context.push('/profile');
  }

  String _profileInitials(AuthUser? user) {
    final displayName = user?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      final parts = displayName
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isEmpty) return 'U';
      final first = parts.first.characters.first;
      final second = parts.length > 1 ? parts[1].characters.first : '';
      return (first + second).toUpperCase();
    }
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.characters.first.toUpperCase();
    }
    return '';
  }

  SpeedDial _buildQuickstartFab({
    required BuildContext context,
    required List<SpeedDialChild> children,
  }) {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      tooltip: 'Actions',
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    final authUserAsync = ref.watch(authUserProvider);
    final authStatus = ref.watch(authStatusProvider);
    final loginPromptState = ref.watch(loginPromptProvider);
    final authUser = authUserAsync.maybeWhen(
      data: (user) => user,
      orElse: () => null,
    );
    final profileInitials = _profileInitials(authUser);
    final profileImageUrl = authUser?.photoUrl;
    final titles = [
      'Exercises',
      'Workouts',
      'Programs',
      'Progress',
    ];
    final showWorkoutsTabBar = selectedIndex == 1;
    final showProgramsTabBar = selectedIndex == 2;
    final showProgressTabBar = selectedIndex == 3;

    // FAB for Exercises tab
    Widget? exercisesFab = _buildQuickstartFab(
      context: context,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.add),
          label: 'Add Exercise',
          onTap: () => GoRouter.of(context).push('/exercise/new'),
        ),
        SpeedDialChild(
          child: const Icon(Icons.fitness_center),
          label: 'Quickstart Workout',
          onTap: () => _showWorkoutLoggerSheet('Quick Start'),
        ),
      ],
    );

    final loggerSheetState = ref.watch(loggerSheetProvider);

    _maybeShowLoginPrompt(authStatus, loginPromptState, !authUserAsync.isLoading);

    final mainContent = Builder(
      builder: (context) {
        if (showWorkoutsTabBar) {
          return DefaultTabController(
            length: 2,
            child: Builder(
              builder: (context) {
                return WorkoutsTabbedScreenWithFab(
                  onQuickstart: _showWorkoutLoggerSheet,
                  builder: (body, fab) => Scaffold(
                    body: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ModernAppBar(
                          title: titles[selectedIndex],
                          profileInitials: profileInitials,
                          profileImageUrl: profileImageUrl,
                          onProfileTap: _handleProfileTap,
                          streakCount: 5,
                        ),
                        const TabBar(
                          tabs: [
                            Tab(text: 'History'),
                            Tab(text: 'Templates'),
                          ],
                        ),
                        Expanded(child: body),
                      ],
                    ),
                    floatingActionButton: fab,
                    bottomNavigationBar: BottomNavBar(
                      currentIndex: selectedIndex,
                      onTap: _onTabSelected,
                    ),
                  ),
                );
              },
            ),
          );
        } else if (selectedIndex == 0) {
          return Scaffold(
            appBar: ModernAppBar(
              title: titles[selectedIndex],
              profileInitials: profileInitials,
              profileImageUrl: profileImageUrl,
              onProfileTap: _handleProfileTap,
              streakCount: 5,
            ),
            body: ExerciseListScreen(onStartWorkout: _showWorkoutLoggerSheet),
            floatingActionButton: exercisesFab,
            bottomNavigationBar: BottomNavBar(
              currentIndex: selectedIndex,
              onTap: _onTabSelected,
            ),
          );
        } else if (showProgramsTabBar) {
          final programsFab = _buildQuickstartFab(
            context: context,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.add),
                label: 'Create Program',
                onTap: () => GoRouter.of(context).push('/programs/new'),
              ),
              SpeedDialChild(
                child: const Icon(Icons.fitness_center),
                label: 'Quickstart Workout',
                onTap: () => _showWorkoutLoggerSheet('Quick Start'),
              ),
            ],
          );
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModernAppBar(
                    title: titles[selectedIndex],
                    profileInitials: profileInitials,
                    profileImageUrl: profileImageUrl,
                    onProfileTap: _handleProfileTap,
                    streakCount: 5,
                  ),
                  TabBar(
                    onTap: (index) {
                      final selectedProgramId =
                          ref.read(selectedProgramIdProvider);
                      if (index == 0 && selectedProgramId != null) {
                        ref.read(selectedProgramIdProvider.notifier).state = null;
                      } else if (index == 1) {
                        ref.read(selectedProgramIdProvider.notifier).state = null;
                      }
                    },
                    tabs: const [
                      Tab(text: 'List'),
                      Tab(text: 'Calendar'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final selectedProgramId =
                                ref.watch(selectedProgramIdProvider);
                            if (selectedProgramId != null) {
                              return ProgramDetailScreen(
                                programId: selectedProgramId,
                                embedded: true,
                              );
                            }
                            return const ProgramListScreen();
                          },
                        ),
                        const ProgramCalendarTab(),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: programsFab,
              bottomNavigationBar: BottomNavBar(
                currentIndex: selectedIndex,
                onTap: _onTabSelected,
              ),
            ),
          );
        } else if (showProgressTabBar) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              body: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModernAppBar(
                    title: titles[selectedIndex],
                    profileInitials: profileInitials,
                    profileImageUrl: profileImageUrl,
                    onProfileTap: _handleProfileTap,
                    streakCount: 5,
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Workout Frequency'),
                      Tab(text: 'Program Stats'),
                    ],
                  ),
                  Expanded(child: ProgressScreen()),
                ],
              ),
              bottomNavigationBar: BottomNavBar(
                currentIndex: selectedIndex,
                onTap: _onTabSelected,
              ),
              floatingActionButton: _buildQuickstartFab(
                context: context,
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.fitness_center),
                    label: 'Quickstart Workout',
                    onTap: () => _showWorkoutLoggerSheet('Quick Start'),
                  ),
                ],
              ),
            ),
          );
        } else {
          final screens = [
            const SizedBox.shrink(), // handled above
            const SizedBox.shrink(), // handled above
            const SizedBox.shrink(), // handled above
            const SizedBox.shrink(), // handled above
          ];
          return Scaffold(
            appBar: ModernAppBar(
              title: titles[selectedIndex],
              profileInitials: profileInitials,
              profileImageUrl: profileImageUrl,
              onProfileTap: _handleProfileTap,
              streakCount: 5,
            ),
            body: screens[selectedIndex],
            bottomNavigationBar: BottomNavBar(
              currentIndex: selectedIndex,
              onTap: _onTabSelected,
            ),
          );
        }
      },
    );

    return Stack(
      children: [
        mainContent,
        // Minimized logger bar at the top of the screen
        if (loggerSheetState.visible && loggerSheetState.minimized)
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).padding.top,
            child: WorkoutLoggerSheet(
              workoutName: loggerSheetState.workoutName ?? '',
              workoutId: loggerSheetState.workoutId,
              programId: loggerSheetState.programId,
              initialExercises: loggerSheetState.initialExercises,
              initialSetsByExercise: loggerSheetState.initialSetsByExercise,
              minimized: true,
              onMinimize: () => ref.read(loggerSheetProvider.notifier).minimize(),
              onMaximize: () => ref.read(loggerSheetProvider.notifier).maximize(),
              onClose: () => ref.read(loggerSheetProvider.notifier).hide(),
            ),
          ),
        // Modal popup overlay (maximized)
        if (loggerSheetState.visible && !loggerSheetState.minimized)
          Positioned.fill(
            child: WorkoutLoggerSheet(
              workoutName: loggerSheetState.workoutName ?? '',
              workoutId: loggerSheetState.workoutId,
              programId: loggerSheetState.programId,
              initialExercises: loggerSheetState.initialExercises,
              initialSetsByExercise: loggerSheetState.initialSetsByExercise,
              minimized: false,
              onMinimize: () => ref.read(loggerSheetProvider.notifier).minimize(),
              onMaximize: () => ref.read(loggerSheetProvider.notifier).maximize(),
              onClose: () => ref.read(loggerSheetProvider.notifier).hide(),
            ),
          ),
      ],
    );
  }
}
