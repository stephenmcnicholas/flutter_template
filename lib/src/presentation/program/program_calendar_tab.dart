import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:fytter/src/domain/exercise.dart';
import 'package:fytter/src/domain/pre_workout_check_in_args.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/domain/workout_session.dart';
import 'package:fytter/src/presentation/logger/workout_start_flow.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_sheet_transition.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/providers/exercise_history_provider.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:fytter/src/providers/workout_session_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:fytter/src/services/notification_service.dart';
import 'package:fytter/src/utils/program_utils.dart';

String _ordinalDay(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

class ProgramCalendarTab extends ConsumerStatefulWidget {
  const ProgramCalendarTab({super.key});

  @override
  ConsumerState<ProgramCalendarTab> createState() => _ProgramCalendarTabState();
}

class _ProgramCalendarTabState extends ConsumerState<ProgramCalendarTab> {
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
    final programsAsync = ref.watch(programsFutureProvider);
    final templatesAsync = ref.watch(workoutTemplatesFutureProvider);
    final sessionsAsync = ref.watch(workoutSessionsProvider);

    return programsAsync.when(
      data: (programs) {
        if (programs.isEmpty) {
          return const AppEmptyState(
            title: 'No programs yet',
            message: 'Create your first program to schedule workouts.',
            illustrationAsset: 'assets/illustrations/empty_state_generic.svg',
          );
        }
        return templatesAsync.when(
          data: (templates) {
            final workoutNameMap = {
              for (final t in templates) t.id: t.name,
            };
            final programMap = {for (final p in programs) p.id: p};
            return sessionsAsync.when(
              data: (sessions) {
                final items = _buildScheduleItems(programs, sessions);
                final selectedDay = _selectedDay ?? _focusedDay;
                final selectedItems = _itemsForDay(selectedDay, items);

                return Column(
                  children: [
                    TableCalendar<_ProgramScheduleItem>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      eventLoader: (day) => _itemsForDay(day, items),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month',
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                      ),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = selected;
                          _focusedDay = focused;
                        });
                      },
                      calendarStyle: CalendarStyle(
                        markerDecoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return null;
                          final shown = events.take(3).toList();
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final event in shown)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(event.status, colors),
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
                      child: selectedItems.isEmpty
                          ? AppEmptyState(
                              title: 'No workouts on ${_ordinalDay(selectedDay.day)} ${DateFormat('MMMM').format(selectedDay)}',
                              message: 'Pick another date to see scheduled workouts.',
                              illustrationAsset:
                                  'assets/illustrations/empty_state_calendar.svg',
                              illustrationSize: 60,
                            )
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                              itemCount: selectedItems.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: spacing.sm),
                              itemBuilder: (context, index) {
                                final item = selectedItems[index];
                                final workoutName =
                                    workoutNameMap[item.workoutId] ?? 'Unknown workout';
                                final dateLabel =
                                    DateFormat('d MMM, yyyy').format(item.scheduledDate);
                                final program = programMap[item.programId];
                                return AppCard(
                                  compact: true,
                                  onTap: () {
                                    if (program == null ||
                                        item.status == ProgramWorkoutStatus.completed) {
                                      return;
                                    }
                                    final workout = _findWorkout(program, item);
                                    if (workout == null) return;
                                    _showWorkoutActions(program, workout, item.status, templates: templates);
                                  },
                                  child: AppListRow(
                                    dense: true,
                                    leading: _statusDot(item.status, colors),
                                    title: AppText(item.programName, style: AppTextStyle.label),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppText(workoutName, style: AppTextStyle.caption),
                                        SizedBox(height: spacing.xs),
                                        AppText(dateLabel, style: AppTextStyle.caption),
                                      ],
                                    ),
                                    trailing: _statusPill(
                                      label: _statusLabel(item.status),
                                      color: _statusColor(item.status, colors),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
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
        title: 'Unable to load programs',
        message: 'Something went wrong. Please try again.',
        icon: Icons.error_outline,
      ),
    );
  }

  List<_ProgramScheduleItem> _buildScheduleItems(
    List<Program> programs,
    List<WorkoutSession> sessions,
  ) {
    final completedKeys = programCompletionKeysFromSessions(sessions);
    final items = <_ProgramScheduleItem>[];
    for (final program in programs) {
      final statusByKey = programStatusByKey(
        program.schedule,
        completedKeys,
        DateTime.now(),
      );
      for (final workout in program.schedule) {
        final status = statusByKey[programWorkoutKey(
              workout.workoutId,
              workout.scheduledDate,
            )] ??
            ProgramWorkoutStatus.planned;
        items.add(
          _ProgramScheduleItem(
            programId: program.id,
            programName: program.name,
            workoutId: workout.workoutId,
            scheduledDate: workout.scheduledDate,
            status: status,
          ),
        );
      }
    }
    return items;
  }

  List<_ProgramScheduleItem> _itemsForDay(
    DateTime day,
    List<_ProgramScheduleItem> items,
  ) {
    return items.where((item) => isSameDay(item.scheduledDate, day)).toList();
  }

  Widget _statusDot(ProgramWorkoutStatus status, AppColors colors) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: _statusColor(status, colors),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _statusPill({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: AppText(
        label,
        style: AppTextStyle.caption,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
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

  Color _statusColor(ProgramWorkoutStatus status, AppColors colors) {
    switch (status) {
      case ProgramWorkoutStatus.completed:
        return colors.success;
      case ProgramWorkoutStatus.planned:
        return colors.secondary;
      case ProgramWorkoutStatus.missed:
        return colors.error;
    }
  }

  ProgramWorkout? _findWorkout(Program program, _ProgramScheduleItem item) {
    final targetDate = normalizeProgramDate(item.scheduledDate);
    for (final workout in program.schedule) {
      if (workout.workoutId == item.workoutId &&
          normalizeProgramDate(workout.scheduledDate) == targetDate) {
        return workout;
      }
    }
    return null;
  }

  Future<void> _showWorkoutActions(
    Program program,
    ProgramWorkout workout,
    ProgramWorkoutStatus status, {
    required List<Workout> templates,
  }) async {
    if (status == ProgramWorkoutStatus.completed) return;
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
        await _editProgramWorkoutDate(program, workout);
        return;
      case 'remove':
        await _removeProgramWorkout(program, workout);
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
      if (!mounted) return;
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
      } catch (_) {
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

    final index = _indexOfWorkout(program.schedule, workout);
    if (index == -1) return;

    final updatedSchedule = scope == ProgramDateChangeScope.shiftAll
        ? shiftProgramScheduleByEditingIndex(
            program.schedule,
            index,
            selectedDate,
          )
        : updateProgramWorkoutDateAtIndex(
            program.schedule,
            index,
            selectedDate,
          );
    await _saveProgramSchedule(program, updatedSchedule);
  }

  Future<void> _removeProgramWorkout(
    Program program,
    ProgramWorkout workout,
  ) async {
    final updated = program.schedule.where((item) {
      return !(item.workoutId == workout.workoutId &&
          normalizeProgramDate(item.scheduledDate) ==
              normalizeProgramDate(workout.scheduledDate));
    }).toList();
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

  int _indexOfWorkout(List<ProgramWorkout> schedule, ProgramWorkout workout) {
    final targetDate = normalizeProgramDate(workout.scheduledDate);
    return schedule.indexWhere((item) {
      return item.workoutId == workout.workoutId &&
          normalizeProgramDate(item.scheduledDate) == targetDate;
    });
  }
}

class _ProgramScheduleItem {
  final String programId;
  final String programName;
  final String workoutId;
  final DateTime scheduledDate;
  final ProgramWorkoutStatus status;

  const _ProgramScheduleItem({
    required this.programId,
    required this.programName,
    required this.workoutId,
    required this.scheduledDate,
    required this.status,
  });
}
