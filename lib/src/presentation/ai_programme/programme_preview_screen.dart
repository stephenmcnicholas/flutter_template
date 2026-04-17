import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fytter/src/presentation/ai_programme/programme_audio_bootstrap.dart';
import 'package:fytter/src/providers/programme_generation_provider.dart';
import 'package:fytter/src/presentation/workout/workout_templates_screen.dart'
    show workoutTemplatesFutureProvider;
import 'package:fytter/src/presentation/shared/app_button.dart';
import 'package:fytter/src/presentation/shared/app_card.dart';
import 'package:fytter/src/presentation/shared/app_list_row.dart';
import 'package:fytter/src/presentation/shared/app_sheet_transition.dart';
import 'package:fytter/src/presentation/shared/app_text.dart';
import 'package:fytter/src/presentation/theme.dart';
import 'package:fytter/src/domain/program.dart';
import 'package:fytter/src/presentation/ai_programme/ai_programme_strings.dart';
import 'package:intl/intl.dart';

DateTime _weekStart(DateTime date) {
  final weekday = date.weekday;
  final daysFromMonday = weekday - DateTime.monday;
  return DateTime(date.year, date.month, date.day - daysFromMonday);
}

/// Use "Workouts this week" only when the first scheduled week is the current calendar week.
String _workoutListHeading(List<ProgramWorkout> sortedSchedule) {
  if (sortedSchedule.isEmpty) return AiProgrammeStrings.yourWorkouts;
  final now = DateTime.now();
  final firstWeekStart = _weekStart(sortedSchedule.first.scheduledDate);
  final thisWeekStart = _weekStart(now);
  return (firstWeekStart == thisWeekStart)
      ? AiProgrammeStrings.workoutsThisWeek
      : AiProgrammeStrings.yourWorkouts;
}

List<Widget> _buildWeekGroupedList(
  List<ProgramWorkout> sortedSchedule,
  Map<String, String> workoutNameMap,
  AppSpacing spacing,
  AppColors colors,
) {
  if (sortedSchedule.isEmpty) return [];
  final byWeek = <DateTime, List<ProgramWorkout>>{};
  for (final s in sortedSchedule) {
    final start = _weekStart(s.scheduledDate);
    byWeek.putIfAbsent(start, () => []).add(s);
  }
  final weekStarts = byWeek.keys.toList()..sort();
  final widgets = <Widget>[];
  for (var i = 0; i < weekStarts.length; i++) {
    final weekStart = weekStarts[i];
    final items = byWeek[weekStart]!;
    widgets.add(Padding(
      padding: EdgeInsets.only(top: i > 0 ? spacing.lg : 0, bottom: spacing.sm),
      child: AppText('Week ${i + 1}', style: AppTextStyle.label, color: colors.outline),
    ));
    for (final s in items) {
      final name = workoutNameMap[s.workoutId] ?? 'Workout';
      final dateLabel = DateFormat('EEE, d MMM').format(s.scheduledDate);
      widgets.add(Padding(
        padding: EdgeInsets.only(bottom: spacing.sm),
        child: AppListRow(
          title: AppText('$dateLabel — $name', style: AppTextStyle.label),
          dense: true,
        ),
      ));
    }
  }
  return widgets;
}

/// Shows the generated programme and "Start" / "Adjust" actions.
/// Prefetches programme description TTS so "Tell me about" can resolve audio without
/// cold-starting synthesis on that screen.
class ProgrammePreviewScreen extends ConsumerStatefulWidget {
  const ProgrammePreviewScreen({super.key});

  @override
  ConsumerState<ProgrammePreviewScreen> createState() => _ProgrammePreviewScreenState();
}

class _ProgrammePreviewScreenState extends ConsumerState<ProgrammePreviewScreen> {
  bool _programmeAudioPrefetchScheduled = false;

  void _acceptAndNavigate(
    BuildContext context,
    WidgetRef ref,
    Program program,
    AppSpacing spacing,
  ) {
    ref.read(programmeGenerationProvider.notifier).reset();
    context.go('/programs/${program.id}');
  }

  void _showAdjustmentSheet(
    BuildContext context,
    WidgetRef ref,
    Program program,
    AppSpacing spacing,
    AppColors colors,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return AppSheetTransition(
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, spacing.sm),
                  child: AppText(AiProgrammeStrings.adjustSheetTitle, style: AppTextStyle.title),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: AppText(AiProgrammeStrings.adjustChangeDates, style: AppTextStyle.label),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: spacing.xs),
                    child: AppText(
                      AiProgrammeStrings.adjustChangeDatesCaption,
                      style: AppTextStyle.caption,
                      color: colors.outline,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(programmeGenerationProvider.notifier).reset();
                    context.go('/programs/${program.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: AppText(AiProgrammeStrings.adjustSwapExercise, style: AppTextStyle.label),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: spacing.xs),
                    child: AppText(
                      AiProgrammeStrings.adjustSwapExerciseCaption,
                      style: AppTextStyle.caption,
                      color: colors.outline,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(programmeGenerationProvider.notifier).reset();
                    context.go('/programs/${program.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: AppText(AiProgrammeStrings.adjustSetsReps, style: AppTextStyle.label),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: spacing.xs),
                    child: AppText(
                      AiProgrammeStrings.adjustSetsRepsCaption,
                      style: AppTextStyle.caption,
                      color: colors.outline,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    ref.read(programmeGenerationProvider.notifier).reset();
                    context.go('/programs/${program.id}');
                  },
                ),
                SizedBox(height: spacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(programmeGenerationProvider);
    final typography = context.themeExt<AppTypography>();
    final spacing = context.themeExt<AppSpacing>();
    final colors = context.themeExt<AppColors>();
    final radii = context.themeExt<AppRadii>();

    if (state is! ProgrammeGenerationSuccess) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/ai-programme/create');
              }
            },
          ),
        ),
        body: Center(
          child: state is ProgrammeGenerationError
              ? AppText(state.message, style: AppTextStyle.body)
              : const CircularProgressIndicator(),
        ),
      );
    }

    final result = state.result;
    final program = result.program;

    if (!_programmeAudioPrefetchScheduled) {
      _programmeAudioPrefetchScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        bootstrapProgrammeDescriptionAudio(ref, program);
      });
    }

    final templates = ref.watch(workoutTemplatesFutureProvider).valueOrNull;
    final workoutNameMap = templates != null
        ? {for (final w in templates) w.id: w.name}
        : <String, String>{};

    final sortedSchedule = List.of(program.schedule)
      ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final personalisationNotes = result.personalisationNotes;
    final hasPersonalisation = personalisationNotes.isNotEmpty;
    final hasCoachIntro = program.coachIntro != null && program.coachIntro!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(programmeGenerationProvider.notifier).reset();
            context.go('/programs/${program.id}');
          },
        ),
        title: Text(AiProgrammeStrings.previewTitle, style: typography.label),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                AiProgrammeStrings.revealReady,
                style: AppTextStyle.caption,
                color: colors.primary,
              ),
              SizedBox(height: spacing.sm),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 8 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: AppText(program.name, style: AppTextStyle.headline),
              ),
              if (result.usedFallback) ...[
                SizedBox(height: spacing.sm),
                AppText(
                  'Built from your preferences (personalisation will improve when the AI service is available).',
                  style: AppTextStyle.caption,
                  color: colors.outline,
                ),
                if (result.generationFailureReason != null &&
                    result.generationFailureReason!.trim().isNotEmpty) ...[
                  SizedBox(height: spacing.xs),
                  AppText(
                    'Why: ${result.generationFailureReason}',
                    style: AppTextStyle.caption,
                    color: colors.outline,
                  ),
                ],
              ],
              if (hasCoachIntro) ...[
                SizedBox(height: spacing.md),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radii.md),
                    gradient: LinearGradient(
                      colors: [
                        colors.primary.withValues(alpha: 0.08),
                        colors.primary.withValues(alpha: 0.03),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            '✦',
                            style: TextStyle(
                              fontSize: 20,
                              height: 1,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        SizedBox(width: spacing.md),
                        Expanded(
                          child: AppText(
                            program.coachIntro!,
                            style: AppTextStyle.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (hasPersonalisation) ...[
                SizedBox(height: spacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final note in personalisationNotes)
                        Padding(
                          padding: EdgeInsets.only(bottom: spacing.xs),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.check_circle_outline, size: 18, color: colors.success),
                              SizedBox(width: spacing.sm),
                              Expanded(
                                child: AppText(note, style: AppTextStyle.caption, color: colors.outline),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (!hasCoachIntro &&
                  program.weeklyProgressionNotes != null &&
                  program.weeklyProgressionNotes!.isNotEmpty) ...[
                SizedBox(height: spacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(AiProgrammeStrings.progressionNote, style: AppTextStyle.label),
                      SizedBox(height: spacing.xs),
                      AppText(program.weeklyProgressionNotes!, style: AppTextStyle.body),
                    ],
                  ),
                ),
              ],
              if ((program.coachRationale != null && program.coachRationale!.trim().isNotEmpty) ||
                  (program.workoutBreakdowns != null && program.workoutBreakdowns!.trim().isNotEmpty)) ...[
                SizedBox(height: spacing.md),
                AppButton(
                  label: AiProgrammeStrings.tellMeAboutMyProgramme,
                  onPressed: () => context.push('/programs/${program.id}/about'),
                  isFullWidth: true,
                  variant: AppButtonVariant.secondary,
                ),
              ],
              SizedBox(height: spacing.lg),
              AppText(
                _workoutListHeading(sortedSchedule),
                style: AppTextStyle.title,
              ),
              SizedBox(height: spacing.sm),
              ..._buildWeekGroupedList(sortedSchedule, workoutNameMap, spacing, colors),
              SizedBox(height: spacing.xl),
              AppButton(
                label: AiProgrammeStrings.acceptProgramme,
                onPressed: () => _acceptAndNavigate(context, ref, program, spacing),
                isFullWidth: true,
              ),
              SizedBox(height: spacing.sm),
              OutlinedButton(
                onPressed: () => _showAdjustmentSheet(context, ref, program, spacing, colors),
                child: Text(AiProgrammeStrings.makeAdjustment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
