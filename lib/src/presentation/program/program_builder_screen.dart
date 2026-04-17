import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/domain/workout.dart';
import 'package:fytter/src/providers/data_providers.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_list_entry_animation.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/shared/app_stats_row.dart';
import 'package:fytter/src/presentation/shared/app_empty_state.dart';
import 'package:fytter/src/presentation/shared/app_loading_state.dart';
import 'package:fytter/src/presentation/shared/app_sheet_transition.dart';
import 'package:fytter/src/presentation/shared/dialog_utils.dart';
import 'package:fytter/src/services/notification_service.dart';
import 'package:fytter/src/utils/program_utils.dart';
import 'package:fytter/src/presentation/theme.dart';

class ProgramBuilderScreen extends ConsumerStatefulWidget {
  final String? programId;
  const ProgramBuilderScreen({super.key, this.programId});

  @override
  ConsumerState<ProgramBuilderScreen> createState() => _ProgramBuilderScreenState();
}

class _ProgramBuilderScreenState extends ConsumerState<ProgramBuilderScreen> {
  late final TextEditingController _nameCtrl;
  bool _canSave = false;
  List<ProgramWorkout> _schedule = [];
  bool _notificationEnabled = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _nameCtrl.addListener(() {
      final hasText = _nameCtrl.text.trim().isNotEmpty;
      if (hasText != _canSave) {
        setState(() => _canSave = hasText);
      }
    });

    final id = widget.programId;
    if (id != null) {
      Future<void>(() async {
        try {
          final program = await ref.read(programRepositoryProvider).findById(id);
          if (!mounted) return;
          setState(() {
            _nameCtrl.text = program.name;
            _schedule = [...program.schedule];
            _notificationEnabled = program.notificationEnabled;
          });
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _loadError = 'Program not found';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(programRepositoryProvider);
    final programId = widget.programId ?? const Uuid().v4();
    final sorted = [..._schedule]
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final program = Program(
      id: programId,
      name: _nameCtrl.text.trim(),
      schedule: sorted,
      notificationEnabled: _notificationEnabled,
      notificationTimeMinutes: null,
    );
    await repo.save(program);
    ref.invalidate(programsFutureProvider);
    if (mounted) {
      try {
        await syncNotificationSchedule(ref);
      } catch (_) {
        // Local save already succeeded; failing sync should not block closing.
      }
      if (mounted) context.pop();
    }
  }

  Future<void> _addScheduledWorkout(List<Workout> templates) async {
    if (templates.isEmpty) {
      await showInfoDialog(
        context,
        title: 'No templates',
        message: 'Create a workout template before scheduling it in a program.',
      );
      return;
    }

      final spacing = context.themeExt<AppSpacing>();
      final selectedWorkoutId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return AppSheetTransition(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.lg,
              vertical: spacing.md,
            ),
          itemCount: templates.length,
          separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
          itemBuilder: (context, index) {
            final template = templates[index];
            return AppListEntryAnimation(
              index: index,
              child: AppCard(
                compact: true,
                onTap: () => Navigator.of(context).pop(template.id),
                child: AppListRow(
                  dense: true,
                  title: AppText(template.name, style: AppTextStyle.label),
                  subtitle: AppStatsRow(
                    items: [
                      AppStatItem(label: 'Sets', value: template.entries.length.toString()),
                      AppStatItem(
                        label: 'Exercises',
                        value: template.entries.map((e) => e.exerciseId).toSet().length.toString(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          ),
        );
      },
    );

    if (selectedWorkoutId == null) return;

    final selectedDate = await _showProgramDatePicker(DateTime.now());
    if (!mounted) return;
    if (selectedDate == null) return;

    setState(() {
      _schedule = [
        ..._schedule,
        ProgramWorkout(workoutId: selectedWorkoutId, scheduledDate: selectedDate),
      ];
    });
  }

  Future<void> _editDate(int index) async {
    final existing = _schedule[index];
    final selectedDate = await _showProgramDatePicker(existing.scheduledDate);
    if (!mounted) return;
    if (selectedDate == null) return;
    final scope = await showProgramDateChangeScopeDialog(
      context,
      singleLabel: 'Only this workout',
      shiftAllLabel: 'Shift all workouts',
    );
    if (!mounted) return;
    if (scope == null) return;
    setState(() {
      if (scope == ProgramDateChangeScope.shiftAll) {
        _schedule = shiftProgramScheduleByEditingIndex(
          _schedule,
          index,
          selectedDate,
        );
      } else {
        _schedule = updateProgramWorkoutDateAtIndex(
          _schedule,
          index,
          selectedDate,
        );
      }
    });
  }

  void _removeAt(int index) {
    setState(() {
      _schedule = [
        for (var i = 0; i < _schedule.length; i++)
          if (i != index) _schedule[i],
      ];
    });
  }

  Future<DateTime?> _showProgramDatePicker(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      locale: const Locale('en', 'GB'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return const Scaffold(
        body: AppEmptyState(
          title: 'Program not found',
          message: 'This program may have been deleted.',
          icon: Icons.event_busy,
        ),
      );
    }

    final colors = context.themeExt<AppColors>();
    final spacing = context.themeExt<AppSpacing>();
    final templatesAsync = ref.watch(workoutTemplatesFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppText(
          widget.programId == null ? 'New Program' : 'Edit Program',
          style: AppTextStyle.headline,
        ),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Program name'),
            ),
            SizedBox(height: spacing.lg),
            AppCard(
              child: Column(
                children: [
                  AppListRow(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const AppText(
                      'Remind me for this program',
                      style: AppTextStyle.body,
                    ),
                    subtitle: AppText(
                      'Uses your global reminder time in Settings',
                      style: AppTextStyle.caption,
                      color: colors.outline,
                    ),
                    trailing: Switch(
                      value: _notificationEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationEnabled = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText('Scheduled workouts', style: AppTextStyle.title),
                templatesAsync.when(
                  data: (templates) => TextButton.icon(
                    onPressed: () => _addScheduledWorkout(templates),
                    icon: Icon(Icons.add, color: colors.primary),
                    label: const Text('Add workout'),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
            SizedBox(height: spacing.sm),
            Expanded(
              child: _schedule.isEmpty
                  ? const AppEmptyState(
                      title: 'No workouts scheduled',
                      message: 'Add workouts to build your program.',
                      illustrationAsset: 'assets/illustrations/empty_state_calendar.svg',
                    )
                  : _buildScheduleList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleList() {
    final sortedEntries = _schedule
        .asMap()
        .entries
        .toList()
      ..sort(
        (a, b) =>
            a.value.scheduledDate.compareTo(b.value.scheduledDate),
      );
    return Consumer(
      builder: (context, ref, _) {
        final colors = context.themeExt<AppColors>();
        final spacing = context.themeExt<AppSpacing>();
        final templatesAsync = ref.watch(workoutTemplatesFutureProvider);
        return templatesAsync.when(
          data: (templates) {
            final workoutNameMap = {
              for (final t in templates) t.id: t.name,
            };
            return ListView.separated(
              padding: EdgeInsets.only(top: spacing.md),
              itemCount: sortedEntries.length,
              separatorBuilder: (context, index) => SizedBox(height: spacing.sm),
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final item = entry.value;
                final originalIndex = entry.key;
                final workoutName =
                    workoutNameMap[item.workoutId] ?? 'Unknown workout';
                final dateLabel = DateFormat.yMMMd().format(item.scheduledDate);
                final template = templates.firstWhere(
                  (t) => t.id == item.workoutId,
                  orElse: () => const Workout(id: '', name: '', entries: []),
                );
                final setCount = template.entries.length;
                final exerciseCount =
                    template.entries.map((e) => e.exerciseId).toSet().length;
                return AppListEntryAnimation(
                  index: index,
                  child: AppCard(
                    compact: true,
                    child: AppListRow(
                      dense: true,
                      title: AppText(workoutName, style: AppTextStyle.label),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(dateLabel, style: AppTextStyle.caption),
                          SizedBox(height: spacing.xs),
                          AppStatsRow(
                            items: [
                              AppStatItem(label: 'Sets', value: setCount.toString()),
                              AppStatItem(label: 'Exercises', value: exerciseCount.toString()),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_calendar_outlined, color: colors.outline),
                          tooltip: 'Edit workout date',
                            onPressed: originalIndex == -1
                                ? null
                                : () => _editDate(originalIndex),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: colors.outline),
                          tooltip: 'Remove workout',
                            onPressed: originalIndex == -1
                                ? null
                                : () => _removeAt(originalIndex),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const AppLoadingState(
            useShimmer: true,
            variant: AppLoadingVariant.list,
          ),
          error: (_, __) => AppEmptyState(
            title: 'Unable to load templates',
            message: 'Something went wrong. Please try again.',
            icon: Icons.error_outline,
          ),
        );
      },
    );
  }
}
