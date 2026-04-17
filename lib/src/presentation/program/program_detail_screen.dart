import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_list_entry_animation.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/app_sheet_transition.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/utils/program_utils.dart';
import 'package:fytter/src/presentation/program/mid_programme_check_in_screen.dart';
import 'package:fytter/src/presentation/programme/end_programme_review_screen.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/presentation/logger/workout_start_flow.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:fytter/src/providers/premium_provider.dart';
import 'package:fytter/src/providers/programme_audio_provider.dart';
import 'package:fytter/src/providers/notification_settings_provider.dart';
import 'package:fytter/src/services/notification_service.dart';
import 'package:fytter/src/providers/audio_providers.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programId;
  final bool embedded;
  final VoidCallback? onBack;

  const ProgramDetailScreen({
    super.key,
    required this.programId,
    this.embedded = false,
    this.onBack,
  });

  @override
  ConsumerState<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final programAsync = ref.watch(programByIdProvider(widget.programId));
    final templatesAsync = ref.watch(workoutTemplatesFutureProvider);
    final sessionsAsync = ref.watch(workoutSessionsProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);

    return programAsync.when(
      data: (program) {
        if (program == null) {
          return const Scaffold(
            body: AppEmptyState(
              title: 'Program not found',
              message: 'This program may have been deleted.',
              icon: Icons.event_busy,
            ),
          );
        }
        return templatesAsync.when(
          data: (templates) {
            final Map<String, String> workoutNameMap = {
              for (final t in templates) t.id: t.name,
            };
            return sessionsAsync.when(
              data: (sessions) {
                final completedKeys = programCompletionKeysFromSessions(sessions);
                final statusByKey = programStatusByKey(
                  program.schedule,
                  completedKeys,
                  DateTime.now(),
                );
                const tabBar = TabBar(
                  tabs: [
                    Tab(text: 'List'),
                    Tab(text: 'Calendar'),
                  ],
                );
                final tabViews = TabBarView(
                  children: [
                    _buildListView(
                      program,
                      workoutNameMap,
                      statusByKey,
                      templates,
                      notificationSettings,
                      sessions,
                    ),
                    _buildCalendarView(
                      program,
                      workoutNameMap,
                      statusByKey,
                      templates,
                      notificationSettings,
                      sessions,
                    ),
                  ],
                );

                if (widget.embedded) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          spacing.lg,
                          spacing.md,
                          spacing.lg,
                          spacing.sm,
                        ),
                        child: AppText(
                          program.name,
                          style: AppTextStyle.title,
                        ),
                      ),
                      Expanded(
                        child: _buildListView(
                          program,
                          workoutNameMap,
                          statusByKey,
                          templates,
                          notificationSettings,
                          sessions,
                        ),
                      ),
                    ],
                  );
                }

                final premium = ref.watch(premiumStatusProvider).valueOrNull == true;
                final programmeAudioAsync = ref.watch(programmeAudioStatusProvider(program.id));
                final programmeAudio = programmeAudioAsync.valueOrNull;

                return DefaultTabController(
                  length: 2,
                  child: Scaffold(
                    appBar: AppBar(
                      title: AppText(program.name, style: AppTextStyle.headline),
                      actions: [
                        if (premium && programmeAudio != null && (programmeAudio.isGenerating || programmeAudio.path != null))
                          programmeAudio.isGenerating
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : IconButton(
                                  tooltip: 'Play programme intro',
                                  icon: const Icon(Icons.volume_up_outlined),
                                  onPressed: programmeAudio.path != null
                                      ? () => _playProgrammeAudio(ref, programmeAudio.path!)
                                      : null,
                                ),
                        IconButton(
                          tooltip: 'Change start date',
                          icon: Icon(Icons.event, color: colors.primary),
                          onPressed: () => _changeStartDate(program),
                        ),
                        IconButton(
                          tooltip: 'Delete program',
                          icon: Icon(Icons.delete_outline, color: colors.error),
                          onPressed: () => _deleteProgram(program),
                        ),
                        TextButton(
                          onPressed: () async {
                            await context.push('/programs/edit/${program.id}');
                            ref.invalidate(programByIdProvider(program.id));
                            ref.invalidate(programsFutureProvider);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                          ),
                          child: const Text('Edit'),
                        ),
                      ],
                      bottom: tabBar,
                    ),
                    body: tabViews,
                  ),
                );
              },
              loading: () => const AppLoadingState(
                useShimmer: true,
                variant: AppLoadingVariant.card,
              ),
              error: (_, __) => AppEmptyState(
                title: 'Unable to load sessions',
                message: 'Something went wrong. Please try again.',
                icon: Icons.error_outline,
              ),
            );
          },
          loading: () => const AppLoadingState(
            useShimmer: true,
            variant: AppLoadingVariant.card,
          ),
          error: (_, __) => AppEmptyState(
            title: 'Unable to load templates',
            message: 'Something went wrong. Please try again.',
            icon: Icons.error_outline,
          ),
        );
      },
      loading: () => const AppLoadingState(
        useShimmer: true,
        variant: AppLoadingVariant.card,
      ),
      error: (_, __) => AppEmptyState(
        title: 'Unable to load program',
        message: 'Something went wrong. Please try again.',
        icon: Icons.error_outline,
      ),
    );
  }

  Widget _buildListView(
    Program program,
    Map<String, String> workoutNameMap,
    Map<String, ProgramWorkoutStatus> statusByKey,
    List<Workout> templates,
    NotificationSettingsState notificationSettings,
    List<WorkoutSession> sessions,
  ) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    if (program.schedule.isEmpty) {
      return const AppEmptyState(
        title: 'No workouts scheduled',
        message: 'Add workouts to your program to see them here.',
        illustrationAsset: 'assets/illustrations/empty_state_calendar.svg',
      );
    }

    final sortedEntries = program.schedule
        .asMap()
        .entries
        .toList()
      ..sort(
        (a, b) =>
            a.value.scheduledDate.compareTo(b.value.scheduledDate),
      );
    final hasAboutContent = (program.coachRationale != null && program.coachRationale!.trim().isNotEmpty) ||
        (program.workoutBreakdowns != null && program.workoutBreakdowns!.trim().isNotEmpty);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing.lg),
      child: Column(
        children: [
          _buildReminderInfoCard(program, notificationSettings),
          EndProgrammeCompletionBanner(
            program: program,
            statusByKey: statusByKey,
            sessions: sessions,
          ),
          if (hasAboutContent) ...[
            SizedBox(height: spacing.md),
            AppCard(
              compact: true,
              child: AppListRow(
                dense: true,
                leading: const Icon(Icons.auto_stories_outlined),
                title: const AppText('About this programme', style: AppTextStyle.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/programs/${program.id}/about'),
              ),
            ),
          ],
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.only(top: spacing.md),
              itemCount: sortedEntries.length,
              separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
              itemBuilder: (context, index) {
          final entry = sortedEntries[index];
          final scheduleIndex = entry.key;
          final item = entry.value;
          final workoutName = workoutNameMap[item.workoutId] ?? 'Unknown workout';
          final dateLabel = DateFormat('d MMM, yyyy').format(item.scheduledDate);
          final status = statusByKey[programWorkoutKey(
                item.workoutId,
                item.scheduledDate,
              )] ??
              ProgramWorkoutStatus.planned;
          return AppListEntryAnimation(
            index: index,
            child: AppCard(
              compact: true,
              onTap: status == ProgramWorkoutStatus.completed
                  ? null
                  : () => _showWorkoutActions(
                        program: program,
                        workout: item,
                        scheduleIndex: scheduleIndex,
                        templates: templates,
                        status: status,
                      ),
              child: AppListRow(
                dense: true,
                leading: _statusDot(status, colors),
                title: AppText(workoutName, style: AppTextStyle.label),
                subtitle: AppText(dateLabel, style: AppTextStyle.caption),
                trailing: _statusPill(
                  label: _statusLabel(status),
                  color: _statusColor(status, colors),
                ),
              ),
            ),
          );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(
    Program program,
    Map<String, String> workoutNameMap,
    Map<String, ProgramWorkoutStatus> statusByKey,
    List<Workout> templates,
    NotificationSettingsState notificationSettings,
    List<WorkoutSession> sessions,
  ) {
    final events = _eventsByDay(program.schedule);
    final selectedDay = _selectedDay != null
        ? DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day)
        : DateTime.now();
    final selectedEvents = events[selectedDay] ?? [];
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final dotSize = spacing.sm;
    final dotSpacing = spacing.xs / 4;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReminderInfoCard(program, notificationSettings),
              EndProgrammeCompletionBanner(
                program: program,
                statusByKey: statusByKey,
                sessions: sessions,
              ),
              MidProgrammeCheckInBanner(
                program: program,
                statusByKey: statusByKey,
                sessions: sessions,
              ),
            ],
          ),
        ),
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          startingDayOfWeek: StartingDayOfWeek.monday,
          onPageChanged: (day) => setState(() => _focusedDay = day),
          selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) {
            final date = DateTime(day.year, day.month, day.day);
            return (events[date] ?? []).map((e) => e.value).toList();
          },
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, items) {
              if (items.isEmpty) return null;
              final workouts = items.cast<ProgramWorkout>();
              final shown = workouts.take(3).toList();
              return Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final workout in shown)
                      Container(
                        width: dotSize,
                        height: dotSize,
                        margin: EdgeInsets.symmetric(horizontal: dotSpacing),
                        decoration: BoxDecoration(
                          color: _statusColor(
                            statusByKey[programWorkoutKey(
                                  workout.workoutId,
                                  workout.scheduledDate,
                                )] ??
                                ProgramWorkoutStatus.planned,
                            colors,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: spacing.md),
        Expanded(
          child: selectedEvents.isEmpty
              ? _buildEmptyDayState(program.id)
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                  itemCount: selectedEvents.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: spacing.sm),
                  itemBuilder: (context, index) {
                    final selectedEntry = selectedEvents[index];
                    final scheduleIndex = selectedEntry.key;
                    final item = selectedEntry.value;
                    final workoutName =
                        workoutNameMap[item.workoutId] ?? 'Unknown workout';
                    final dateLabel =
                        DateFormat('d MMM, yyyy').format(item.scheduledDate);
                    final status = statusByKey[programWorkoutKey(
                          item.workoutId,
                          item.scheduledDate,
                        )] ??
                        ProgramWorkoutStatus.planned;
                    return AppListEntryAnimation(
                      index: index,
                      child: AppCard(
                        compact: true,
                        onTap: status == ProgramWorkoutStatus.completed
                            ? null
                            : () => _showWorkoutActions(
                                  program: program,
                                  workout: item,
                                  scheduleIndex: scheduleIndex,
                                  templates: templates,
                                  status: status,
                                ),
                        child: AppListRow(
                          dense: true,
                          leading: _statusDot(status, colors),
                          title: AppText(workoutName, style: AppTextStyle.label),
                          subtitle: AppText(dateLabel, style: AppTextStyle.caption),
                          trailing: _statusPill(
                            label: _statusLabel(status),
                            color: _statusColor(status, colors),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReminderInfoCard(
    Program program,
    NotificationSettingsState notificationSettings,
  ) {
    final colors = context.themeExt<AppColors>();
    final reminderTime = DateFormat.jm().format(
      DateTime(
        2000,
        1,
        1,
        notificationSettings.reminderTimeMinutes ~/ 60,
        notificationSettings.reminderTimeMinutes % 60,
      ),
    );
    return AppCard(
      compact: true,
      child: AppListRow(
        dense: true,
        leading: const Icon(Icons.notifications_outlined),
        title: const AppText('Program reminders', style: AppTextStyle.label),
        subtitle: AppText(
          notificationSettings.notificationsEnabled
              ? 'On at $reminderTime (set in Settings)'
              : 'Off – turn on in Settings',
          style: AppTextStyle.caption,
          color: colors.outline,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/settings'),
      ),
    );
  }

  Widget _buildEmptyDayState(String programId) {
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final typography = context.themeExt<AppTypography>();
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: spacing.xxxl,
              color: colors.outline.withValues(alpha: 0.5),
            ),
            SizedBox(height: spacing.lg),
            const AppText('No workouts on this day', style: AppTextStyle.headline),
            SizedBox(height: spacing.sm),
            Text.rich(
              TextSpan(
                text: 'Have a rest day, or ',
                style: typography.body,
                children: [
                  TextSpan(
                    text: 'add a workout',
                    style: typography.body.copyWith(color: colors.primary),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        context.push('/programs/edit/$programId');
                      },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<DateTime, List<MapEntry<int, ProgramWorkout>>> _eventsByDay(
    List<ProgramWorkout> schedule,
  ) {
    final map = <DateTime, List<MapEntry<int, ProgramWorkout>>>{};
    for (var i = 0; i < schedule.length; i++) {
      final item = schedule[i];
      final key = DateTime(
        item.scheduledDate.year,
        item.scheduledDate.month,
        item.scheduledDate.day,
      );
      map.putIfAbsent(key, () => []).add(MapEntry(i, item));
    }
    return map;
  }

  Color _statusColor(ProgramWorkoutStatus status, AppColors colors) {
    switch (status) {
      case ProgramWorkoutStatus.completed:
        return colors.success;
      case ProgramWorkoutStatus.missed:
        return colors.error;
      case ProgramWorkoutStatus.planned:
        return colors.secondary;
    }
  }

  String _statusLabel(ProgramWorkoutStatus status) {
    switch (status) {
      case ProgramWorkoutStatus.completed:
        return 'Completed';
      case ProgramWorkoutStatus.missed:
        return 'Missed';
      case ProgramWorkoutStatus.planned:
        return 'Planned';
    }
  }

  Widget _statusDot(ProgramWorkoutStatus status, AppColors colors) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _statusColor(status, colors),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _statusPill({required String label, required Color color}) {
    final spacing = context.themeExt<AppSpacing>();
    final radii = context.themeExt<AppRadii>();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radii.full),
      ),
      child: AppText(
        label,
        style: AppTextStyle.caption,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _playProgrammeAudio(WidgetRef ref, String path) {
    ref.read(audioServiceProvider).playPath(path);
  }

  Future<void> _changeStartDate(Program program) async {
    if (program.schedule.isEmpty) {
      await showInfoDialog(
        context,
        title: 'No workouts scheduled',
        message: 'Add workouts before changing the start date.',
      );
      return;
    }
    final sorted = [...program.schedule]
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final currentStart = sorted.first.scheduledDate;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('en', 'GB'),
      helpText: 'Select program start date',
    );
    if (!mounted) return;
    if (selectedDate == null) return;

    final scope = await showProgramDateChangeScopeDialog(
      context,
      singleLabel: 'Only first workout',
      shiftAllLabel: 'Shift all workouts',
    );
    if (!mounted) return;
    if (scope == null) return;

    final earliestIndex = indexOfEarliestProgramWorkout(program.schedule);
    if (earliestIndex == -1) return;

    final updatedSchedule = scope == ProgramDateChangeScope.shiftAll
        ? shiftProgramScheduleToNewStart(program.schedule, selectedDate)
        : updateProgramWorkoutDateAtIndex(
            program.schedule,
            earliestIndex,
            selectedDate,
          );

    final repo = ref.read(programRepositoryProvider);
    final updated = Program(
      id: program.id,
      name: program.name,
      schedule: updatedSchedule,
      notificationEnabled: program.notificationEnabled,
      notificationTimeMinutes: program.notificationTimeMinutes,
      isAiGenerated: program.isAiGenerated,
      generationContext: program.generationContext,
      deloadWeek: program.deloadWeek,
      weeklyProgressionNotes: program.weeklyProgressionNotes,
      coachIntro: program.coachIntro,
      coachRationale: program.coachRationale,
      coachRationaleSpoken: program.coachRationaleSpoken,
      workoutBreakdowns: program.workoutBreakdowns,
      programmeDescriptionAudioRemotePath: program.programmeDescriptionAudioRemotePath,
    );
    await repo.save(updated);
    ref.invalidate(programByIdProvider(program.id));
    ref.invalidate(programsFutureProvider);
    await syncNotificationSchedule(ref);
  }

  Future<void> _deleteProgram(Program program) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete program?',
      message:
          'Delete "${program.name}" and all of its scheduled workouts? This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
    if (!mounted || confirmed != true) return;

    final repo = ref.read(programRepositoryProvider);
    final audioService = ref.read(programmeAudioServiceProvider);
    await audioService.deleteProgrammeAudioBundle(program);
    await repo.delete(program.id);
    if (!mounted) return;
    ref.read(programmeAudioNotifierProvider.notifier).removeProgram(program.id);
    if (!mounted) return;
    ref.invalidate(programByIdProvider(program.id));
    ref.invalidate(programsFutureProvider);
    await syncNotificationSchedule(ref);
    if (!mounted) return;

    if (widget.embedded) {
      widget.onBack?.call();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _showWorkoutActions({
    required Program program,
    required ProgramWorkout workout,
    required int scheduleIndex,
    required List<Workout> templates,
    required ProgramWorkoutStatus status,
  }) async {
    if (status == ProgramWorkoutStatus.completed) {
      return;
    }
    final isToday = DateUtils.isSameDay(workout.scheduledDate, DateTime.now());

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AppSheetTransition(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isToday)
                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: const Text('Start workout'),
                    onTap: () => Navigator.of(context).pop('start'),
                  ),
                ListTile(
                  leading: const Icon(Icons.fitness_center_outlined),
                  title: const Text('View workout'),
                  onTap: () => Navigator.of(context).pop('view'),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_calendar_outlined),
                  title: const Text('Edit date'),
                  onTap: () => Navigator.of(context).pop('edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Remove from program'),
                  onTap: () => Navigator.of(context).pop('remove'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;

    switch (action) {
      case 'start':
        await _startWorkoutFromTemplate(program, workout, templates);
        return;
      case 'view':
        if (!mounted) return;
        context.push('/workouts/edit/${workout.workoutId}');
        return;
      case 'edit':
        await _editProgramWorkoutDate(program, scheduleIndex, workout);
        return;
      case 'remove':
        await _removeProgramWorkout(program, scheduleIndex);
        return;
    }
  }

  Future<void> _startWorkoutFromTemplate(
    Program program,
    ProgramWorkout workout,
    List<Workout> templates,
  ) async {
    final template = templates.firstWhere(
      (t) => t.id == workout.workoutId,
      orElse: () => const Workout(id: '', name: '', entries: []),
    );
    if (template.id.isEmpty) {
      await showInfoDialog(
        context,
        title: 'Workout not found',
        message: 'This workout template no longer exists.',
      );
      return;
    }

    final allExercises = await ref.read(exercisesFutureProvider.future);
    if (!mounted) return;
    final exerciseMap = {for (final ex in allExercises) ex.id: ex};
    final initialExercises = <Exercise>[];
    for (final entry in template.entries) {
      final ex = exerciseMap[entry.exerciseId];
      if (ex != null && !initialExercises.any((e) => e.id == ex.id)) {
        initialExercises.add(ex);
      }
    }

    final initialSetsByExercise = <String, List<Map<String, dynamic>>>{};
    final lastValuesByExercise = <String, LastRecordedValues?>{};
    final uniqueExerciseIds = template.entries.map((e) => e.exerciseId).toSet();
    for (final exerciseId in uniqueExerciseIds) {
      try {
        final lastValues =
            await ref.read(lastRecordedValuesProvider(exerciseId).future);
        lastValuesByExercise[exerciseId] = lastValues;
      } catch (e) {
        lastValuesByExercise[exerciseId] = null;
      }
    }
    if (!mounted) return;

    for (final entry in template.entries) {
      final lastValues = lastValuesByExercise[entry.exerciseId];
      initialSetsByExercise.putIfAbsent(entry.exerciseId, () => []).add({
        'id': entry.id,
        'reps': lastValues?.reps ?? entry.reps,
        'weight': lastValues?.weight ?? entry.weight,
        'distance': lastValues?.distance ?? entry.distance,
        'duration': lastValues?.duration ?? entry.duration,
        'isComplete': false,
        'targetReps': entry.reps,
        'targetWeight': entry.weight,
        'targetDistance': entry.distance,
        'targetDuration': entry.duration,
        'supersetGroupId': entry.supersetGroupId,
      });
    }

    if (!mounted) return;
    ref.read(selectedTabIndexProvider.notifier).state = 2;
    final args = PreWorkoutCheckInArgs(
      workoutName: template.name,
      workoutId: template.id,
      programId: program.id,
      initialExercises: initialExercises,
      initialSetsByExercise: initialSetsByExercise,
    );
    await startWorkoutFlow(context, ref, args);
  }

  Future<void> _editProgramWorkoutDate(
    Program program,
    int scheduleIndex,
    ProgramWorkout workout,
  ) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: workout.scheduledDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('en', 'GB'),
    );
    if (!mounted || selectedDate == null) return;

    final scope = await showProgramDateChangeScopeDialog(
      context,
      singleLabel: 'Only this workout',
      shiftAllLabel: 'Shift all workouts',
    );
    if (!mounted || scope == null) return;

    if (scheduleIndex < 0 || scheduleIndex >= program.schedule.length) return;

    final updatedSchedule = scope == ProgramDateChangeScope.shiftAll
        ? shiftProgramScheduleByEditingIndex(
            program.schedule,
            scheduleIndex,
            selectedDate,
          )
        : updateProgramWorkoutDateAtIndex(
            program.schedule,
            scheduleIndex,
            selectedDate,
          );
    await _saveProgramSchedule(program, updatedSchedule);
  }

  Future<void> _removeProgramWorkout(
    Program program,
    int scheduleIndex,
  ) async {
    if (scheduleIndex < 0 || scheduleIndex >= program.schedule.length) return;
    final updated = [
      for (var i = 0; i < program.schedule.length; i++)
        if (i != scheduleIndex) program.schedule[i],
    ];
    await _saveProgramSchedule(program, updated);
  }

  Future<void> _saveProgramSchedule(
    Program program,
    List<ProgramWorkout> schedule,
  ) async {
    final repo = ref.read(programRepositoryProvider);
    final updated = Program(
      id: program.id,
      name: program.name,
      schedule: schedule,
      notificationEnabled: program.notificationEnabled,
      notificationTimeMinutes: program.notificationTimeMinutes,
      isAiGenerated: program.isAiGenerated,
      generationContext: program.generationContext,
      deloadWeek: program.deloadWeek,
      weeklyProgressionNotes: program.weeklyProgressionNotes,
      coachIntro: program.coachIntro,
      coachRationale: program.coachRationale,
      coachRationaleSpoken: program.coachRationaleSpoken,
      workoutBreakdowns: program.workoutBreakdowns,
      programmeDescriptionAudioRemotePath: program.programmeDescriptionAudioRemotePath,
    );
    await repo.save(updated);
    if (!mounted) return;
    ref.invalidate(programByIdProvider(program.id));
    ref.invalidate(programsFutureProvider);
    await syncNotificationSchedule(ref);
  }

}
