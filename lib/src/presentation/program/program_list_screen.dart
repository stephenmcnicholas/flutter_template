import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_list_entry_animation.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_stats_row.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/providers/filter_sort_providers.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/providers/navigation_provider.dart';
import 'package:fytter/src/providers/notification_settings_provider.dart';
import 'package:fytter/src/providers/programme_audio_provider.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';
import 'package:fytter/src/services/notification_service.dart';
import 'package:fytter/src/utils/program_utils.dart';

class ProgramListScreen extends ConsumerWidget {
  const ProgramListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final programsAsync = ref.watch(programsFutureProvider);
    final dateFilter = ref.watch(programDateFilterProvider);
    final notificationSettings = ref.watch(notificationSettingsProvider);

    return programsAsync.when(
      data: (List<Program> programs) {
        final filtered = dateFilter == null
            ? programs
            : programs.where((program) {
                return program.schedule.any((item) {
                  final date = item.scheduledDate;
                  return date.year == dateFilter.year &&
                      date.month == dateFilter.month &&
                      date.day == dateFilter.day;
                });
              }).toList();

        if (filtered.isEmpty) {
          return Column(
            children: [
              if (dateFilter == null) _buildAiProgrammeCard(context, ref, spacing),
              Expanded(
                child: AppEmptyState(
                  title: dateFilter == null ? 'No programs yet' : 'No programs on this day',
                  message: dateFilter == null
                      ? 'Create your first program to schedule workouts.'
                      : 'Clear the filter to see all programs.',
                  icon: Icons.list_alt,
                  illustrationAsset: dateFilter == null
                      ? 'assets/illustrations/empty_state_generic.svg'
                      : 'assets/illustrations/empty_state_calendar.svg',
                  actionLabel: dateFilter == null ? 'Create program' : 'Clear filter',
                  onAction: () {
                    if (dateFilter == null) {
                      context.push('/programs/new');
                    } else {
                      ref.read(programDateFilterProvider.notifier).state = null;
                    }
                  },
                ),
              ),
            ],
          );
        }
        return Column(
          children: [
            if (dateFilter == null) _buildAiProgrammeCard(context, ref, spacing),
            if (dateFilter != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.lg,
                  spacing.md,
                  spacing.lg,
                  spacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        'Showing programs on ${DateFormat('d MMM, yyyy').format(dateFilter)}',
                        style: AppTextStyle.caption,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(programDateFilterProvider.notifier).state = null;
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primary,
                      ),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: ListView.separated(
                  padding: EdgeInsets.only(top: spacing.md),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: spacing.sm),
                  itemBuilder: (context, index) {
                    final program = filtered[index];
                    final nextDate = _nextScheduledDate(program.schedule);
                    final reminderTimeLabel = DateFormat.jm().format(
                      DateTime(
                        2000,
                        1,
                        1,
                        notificationSettings.reminderTimeMinutes ~/ 60,
                        notificationSettings.reminderTimeMinutes % 60,
                      ),
                    );
                    return AppListEntryAnimation(
                      index: index,
                      child: AppCard(
                        compact: true,
                        onTap: () {
                          ref.read(selectedProgramIdProvider.notifier).state =
                              program.id;
                        },
                        child: AppListRow(
                          dense: true,
                          title: AppText(program.name, style: AppTextStyle.label),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppStatsRow(
                                items: [
                                  AppStatItem(
                                    label: '# Workouts',
                                    value: program.schedule.length.toString(),
                                  ),
                                  if (nextDate != null)
                                    AppStatItem(
                                      label: 'Next Workout',
                                      value: DateFormat('d MMM').format(nextDate),
                                    ),
                                ],
                              ),
                              SizedBox(height: spacing.xs),
                              AppText(
                                notificationSettings.notificationsEnabled
                                    ? 'Reminders on at $reminderTimeLabel'
                                    : 'Reminders off',
                                style: AppTextStyle.caption,
                                color: colors.outline,
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await _editProgram(context, ref, program);
                                return;
                              }
                              if (value == 'change_start_date') {
                                await _changeStartDate(context, ref, program);
                                return;
                              }
                              if (value == 'copy') {
                                await _copyProgram(context, ref, program);
                                return;
                              }
                              if (value == 'delete') {
                                await _deleteProgram(context, ref, program);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'change_start_date',
                                child: Text('Edit start date'),
                              ),
                              PopupMenuItem(
                                value: 'copy',
                                child: Text('Copy'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            icon: Icon(Icons.more_vert, color: colors.outline),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const AppLoadingState(
        useShimmer: true,
        variant: AppLoadingVariant.list,
      ),
      error: (_, __) => AppEmptyState(
        title: 'Unable to load programs',
        message: 'Something went wrong. Please try again.',
        icon: Icons.error_outline,
      ),
    );
  }

  DateTime? _nextScheduledDate(List<ProgramWorkout> schedule) {
    if (schedule.isEmpty) return null;
    final sorted = [...schedule]..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return sorted.first.scheduledDate;
  }

  Future<void> _editProgram(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) async {
    await context.push('/programs/edit/${program.id}');
    if (!context.mounted) return;
    ref.invalidate(programByIdProvider(program.id));
    ref.invalidate(programsFutureProvider);
  }

  Future<void> _changeStartDate(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) async {
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
    if (!context.mounted) return;
    if (selectedDate == null) return;

    final scope = await showProgramDateChangeScopeDialog(
      context,
      singleLabel: 'Only first workout',
      shiftAllLabel: 'Shift all workouts',
    );
    if (!context.mounted) return;
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

  Future<void> _copyProgram(BuildContext context, WidgetRef ref, Program program) async {
    if (program.schedule.isEmpty) {
      await showInfoDialog(
        context,
        title: 'Nothing to copy',
        message: 'This program has no scheduled workouts.',
      );
      if (!context.mounted) return;
      return;
    }

    final newName = await showProgramNameDialog(
      context,
      initial: '${program.name} (Copy)',
    );
    if (!context.mounted) return;
    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    final startDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('en', 'GB'),
      helpText: 'Select program start date',
    );
    if (!context.mounted) return;
    if (startDate == null) return;

    final sorted = [...program.schedule]
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final originalStart = DateTime(
      sorted.first.scheduledDate.year,
      sorted.first.scheduledDate.month,
      sorted.first.scheduledDate.day,
    );
    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);

    final newSchedule = sorted.map((item) {
      final itemDate = DateTime(
        item.scheduledDate.year,
        item.scheduledDate.month,
        item.scheduledDate.day,
      );
      final offsetDays = itemDate.difference(originalStart).inDays;
      return ProgramWorkout(
        workoutId: item.workoutId,
        scheduledDate: normalizedStart.add(Duration(days: offsetDays)),
      );
    }).toList();

    final repo = ref.read(programRepositoryProvider);
    final copy = Program(
      id: const Uuid().v4(),
      name: newName.trim(),
      schedule: newSchedule,
      notificationEnabled: false,
      notificationTimeMinutes: null,
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
    await repo.save(copy);
    if (!context.mounted) return;
    ref.invalidate(programsFutureProvider);
  }

  Future<void> _deleteProgram(
    BuildContext context,
    WidgetRef ref,
    Program program,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete program?',
      message:
          'Delete "${program.name}" and all of its scheduled workouts? This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
    );
    if (!context.mounted) return;
    if (confirmed != true) return;

    final repo = ref.read(programRepositoryProvider);
    final audioService = ref.read(programmeAudioServiceProvider);
    await audioService.deleteProgrammeAudioBundle(program);
    await repo.delete(program.id);
    if (!context.mounted) return;
    ref.read(programmeAudioNotifierProvider.notifier).removeProgram(program.id);
    if (!context.mounted) return;
    ref.invalidate(programByIdProvider(program.id));
    ref.invalidate(programsFutureProvider);
    await syncNotificationSchedule(ref);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${program.name}"'),
      ),
    );
  }

  Widget _buildAiProgrammeCard(BuildContext context, WidgetRef ref, AppSpacing spacing) {
    final colors = context.themeExt<AppColors>();
    final radii = context.themeExt<AppRadii>();
    final premium = ref.watch(aiProgrammePremiumProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(spacing.lg, spacing.md, spacing.lg, spacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: premium ? () => context.push('/ai-programme/create') : null,
          borderRadius: BorderRadius.circular(radii.lg),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(spacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radii.lg),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.08),
                  colors.primary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1,
                      color: premium ? colors.primary : colors.outline,
                    ),
                  ),
                ),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        AiProgrammeStrings.teaserTitle,
                        style: AppTextStyle.title,
                      ),
                      SizedBox(height: spacing.xs),
                      AppText(
                        AiProgrammeStrings.teaserBody,
                        style: AppTextStyle.body,
                        color: colors.outline,
                      ),
                      SizedBox(height: spacing.sm),
                      AppText(
                        AiProgrammeStrings.teaserFootnote,
                        style: AppTextStyle.caption,
                        color: colors.outline,
                      ),
                      if (!premium) ...[
                        SizedBox(height: spacing.sm),
                        Text(
                          AiProgrammeStrings.teaserCta,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 